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
            FROM closing_price
            WHERE symbol = fund_symbol AND closing_price.p_date = mutual_date.p_date - INTERVAL '1 DAY';

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
                ON CONFLICT ON CONSTRAINT owns_pk DO UPDATE
                SET owns.shares = owns.shares + n_shares;

                RETURN true;
            end if;
        end;
    $$ LANGUAGE plpgsql;


;
--Question 6
--assume closing prices are not changed retroactively, only that tuples are added at the end of every day
DROP PROCEDURE IF EXISTS buy_on_price(fund_symbol varchar, fund_price decimal);
CREATE OR REPLACE FUNCTION buy_on_price(fund_symbol varchar(20), fund_price decimal(10, 2))
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
        from OWNS where symbol = fund_symbol
        GROUP BY login) as a LEFT JOIN
        (select *    from OWNS) as b
        on a.login = b.login and a.shares = b.shares;


        --figure out how many shares
        SELECT INTO shares_to_buy
        balance FROM customer WHERE customer.login = buyer_login;
        shares_to_buy = FLOOR(shares_to_buy / fund_price);

        CALL buy_shares(buyer_login, fund_symbol, shares_to_buy::integer );


    end;
    $$ LANGUAGE plpgsql;

INSERT INTO owns values ('mike', 'MM', 20);

DROP TRIGGER IF EXISTS buy_on_price ON closing_price;
CREATE TRIGGER buy_on_price
    AFTER INSERT ON closing_price
    FOR EACH ROW
    EXECUTE PROCEDURE buy_on_price(symbol, price);

INSERT INTO closing_price values ('MM',1.00,TO_DATE('2020-04-28','YYYY-MM-DD'));
