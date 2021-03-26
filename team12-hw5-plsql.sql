-- Andrew Imredy api5, Ted Balashov thb46, Christopher Flores cwf24


--QUESTION 2

CREATE OR REPLACE FUNCTION search_mutual_funds(s1 varchar(30) , s2 varchar(30) )
returns varchar(60)
as $$
    declare
    final varchar(60);
    begin
        select string_agg(symbol, ', ') into final
        from mutualfund
        where ((description like ('%' || s1  || '%' || s2 || '%')) or (description like ('%' || s2  || '%' || s1 || '%')));
        return ('[' || final || ']');
    end;
        $$language plpgsql;

--QUESTION 3

CREATE OR REPLACE PROCEDURE deposit_for_investment(loginname varchar(30), amount integer)
AS
    $$
    declare
    howmany integer;
    tot integer;
    currentAmount integer;
    currentTransactionNum integer;
    today date;
    minAmount integer;

    depcursor cursor for
        (select row_number() OVER () as rnum, symbol as s, floor((amount*(percentage/howmany))/price) as amt, balance as b, price as p
        from ((((prefers left join allocation on prefers.allocation_no=allocation.allocation_no) x
            natural join customer)) y natural join
            (select h.symbol, price
            from
            closing_price h inner join (select symbol, max(p_date) as max from closing_price group by symbol) g on h.p_date = g.max and g.symbol = h.symbol) i)
        where (login = loginname));
    depositRow record;
    begin

        tot = amount;

        select count(allocation_no) into howmany
        from allocation
        where login = loginname
        group by login;

        select max(p_date) into today
        from closing_price;

        select max(trx_id) into currentTransactionNum
        from trxlog;
        minAmount = 1;
        open depcursor;
        loop
            fetch depcursor into depositRow;
            exit when not found;
            if(depositRow.amt = 0)then
                raise notice 'just deposit';
                minAmount = 0;
            end if;
        end loop;
        close depcursor;

        if (minAmount > 0) then

        open depcursor;
        loop
            fetch depcursor into depositRow;
            exit when not found;
            currentTransactionNum = currentTransactionNum+1;
            currentAmount = depositRow.amt * depositRow.p;
            raise notice 'current amt %',depositRow.amt;
            raise notice 'current price %', depositRow.p;
            raise notice 'current dep %', currentAmount;
            insert into trxlog (trx_id,login,symbol,t_date,action,num_shares,price,amount) values
            (currentTransactionNum, loginname, depositRow.s, today, 'buy', depositRow.amt, depositRow.p, currentAmount);

            tot = tot - depositRow.amt*depositRow.p;

        end loop;
        close depcursor;

        end if;
        currentTransactionNum = currentTransactionNum+1;
        if(tot>0) then
        insert into trxlog (trx_id,login,symbol,t_date,action,num_shares,price,amount) values
            (currentTransactionNum, loginname, NULL, today, 'deposit', NULL, NULL, tot);
        update customer SET balance = balance + tot where login = loginname;
        end if;

    end;

    $$language plpgsql;

CALL deposit_for_investment('mike', 1000);
               
--Question 4
CREATE OR REPLACE FUNCTION buy_shares(user_login varchar(10),
                                      fund_symbol varchar(20),
                                      n_shares integer)
    RETURNS boolean AS
    $$
        DECLARE
            shares_cost decimal(10, 2);
            user_balance decimal(10, 2);
        BEGIN
            SELECT price INTO shares_cost
            FROM closing_price JOIN mutual_date md on closing_price.p_date = md.p_date - INTERVAL '1 DAY'
            WHERE symbol = fund_symbol ;

            shares_cost = shares_cost * n_shares;

            SELECT balance INTO user_balance
            FROM customer
            WHERE customer.login =  user_login;

            IF user_balance < shares_cost THEN
                RETURN false;
            ELSE
                --reduce balance, increase owns
                UPDATE customer
                SET balance = balance - shares_cost
                WHERE customer.login = user_login;

                INSERT INTO owns values (user_login, fund_symbol, n_shares)
                ON CONFLICT ON CONSTRAINT OWNS_PK DO UPDATE
                SET shares = owns.shares + n_shares;

                RETURN true;
            end if;
        end;
    $$ LANGUAGE plpgsql;

SELECT buy_shares('mike', 'MM', 1);
               
-- Question 5
CREATE OR REPLACE function buying_on_date()
returns trigger
as $$
    declare
    minimum owns%rowtype;
    least_owned_fund varchar(20);
    shares_to_buy decimal(10, 2);
    buyer_login varchar(10);
    begin
        select a.login, symbol, a.shares as shares into minimum
        from
        (select login, min(shares) as shares
        from OWNS
        GROUP BY login) as a LEFT JOIN
        (select *
        from OWNS) as b
        on a.login = b.login and a.shares = b.shares;

        SELECT into shares_to_buy
        balance from customer where CUSTOMER.login = minimum.login;
        shares_to_buy = floor(shares_to_buy / minimum.shares);

        call buy_shares(minimum.login, minimum.symbol, shares_to_buy);
        return new;
    end;

$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS buy_on_date ON MUTUAL_DATE CASCADE;
CREATE TRIGGER buy_on_date
    AFTER UPDATE
    ON MUTUAL_DATE
    FOR EACH ROW
    EXECUTE PROCEDURE buying_on_date();

INSERT INTO MUTUAL_DATE values (TO_DATE('2020-04-06', 'YYYY-MM-DD'));

select buy_shares('mike'::varchar(10), 'RE'::varchar(20), 1);

               
               

--Question 6
--assume closing prices are not changed retroactively, only that tuples are added at the end of every day
DROP PROCEDURE IF EXISTS buy_on_price();
CREATE OR REPLACE FUNCTION buy_on_price()
RETURNS TRIGGER
AS
    $$
    DECLARE
        least_owned_fund varchar(20);
        shares_to_buy decimal(10, 2);
        buyer_login varchar(10);
    BEGIN
        select a.login INTO buyer_login
        from
        (select login, min(shares) as shares
        from OWNS where symbol = new.symbol
        GROUP BY login) as a LEFT JOIN
        (select *    from OWNS) as b
        on a.login = b.login and a.shares = b.shares;


        --figure out how many shares
        SELECT INTO shares_to_buy
        balance FROM customer WHERE customer.login = buyer_login;
        shares_to_buy = FLOOR(shares_to_buy / new.price);

        PERFORM buy_shares(buyer_login, new.symbol, shares_to_buy::integer );
    RETURN new;
    end;
    $$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS buy_on_price ON closing_price;
CREATE TRIGGER buy_on_price
    AFTER INSERT ON closing_price
    FOR EACH ROW
    EXECUTE PROCEDURE buy_on_price(symbol, price);

INSERT INTO closing_price values ('MM', 2.00, TO_DATE('2020-05-03', 'YYYY-MM-DD'));
