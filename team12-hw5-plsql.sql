-- Andrew Imredy api5, Ted Balashov thb46, Christopher Flores cwf24
--TRIGGERS
create or replace function getLowestPrice()
returns int as
$$
    declare
        x int = 0;
        begin
select min(price) into x from
(select symbol, max(p_date) as p
from closing_price
group by symbol) x join closing_price on x.p = p_date;
return x;
end;
 $$ language plpgsql;


create or replace function getRecentPrice(s varchar(10))
returns int as
$$
    declare
        x int = 0;
        begin

        SELECT CLOSING_PRICE.price
        INTO x
        FROM CLOSING_PRICE
        WHERE CLOSING_PRICE.symbol = s
        ORDER BY CLOSING_PRICE.p_date DESC
        LIMIT 1;
        return x;
end;
 $$ language plpgsql;
                                                    
                                                    
--TRIGGER 1 - price_initialization
CREATE OR REPLACE FUNCTION price_initialization_helper()
returns trigger as
    $$
    declare
        s varchar(20);
        d TIMESTAMP;
    begin
        select NEW.symbol into s;
        select p_date into d from mutual_date;
        insert into closing_price VALUES (s, getLowestPrice(), d);
        return null;
    end;
$$ language plpgsql;

CREATE TRIGGER price_initialization
    AFTER INSERT ON mutual_fund
    FOR EACH ROW
    EXECUTE FUNCTION price_initialization_helper();

--TRIGGER 2 - sell_rebalance                    
                                                    
create or replace function sell_rebalance_helper()
returns trigger as
    $$
    declare
        p int;
        a int;
        old int;
        myLogin varchar(10);
    begin
        raise notice 'zyx' ;
        if(new.action = 'sell') then
        raise notice 'abc' ;
        select NEW.price into p;
        select NEW.num_shares into a;
        select NEW.login into myLogin;
        select balance into old from customer
            where customer.login = login;
        update customer set balance = (old+p*a) where customer.login = myLogin;
        end if;
        return null;

    end;
    $$ language plpgsql;

CREATE TRIGGER sell_rebalance
    AFTER INSERT ON trxlog
    FOR EACH ROW
    EXECUTE FUNCTION sell_rebalance_helper();
                                                    
--TRIGGER 3 - price_jump                                 

create or replace function price_jump_helper()
returns trigger as
    $$
    declare
    x int;
    curs1 refcursor;
    row record;
    myUser varchar(10);
    begin
        select getRecentPrice(new.symbol) into x;
        if(new.price-x>=10) then
            open curs1 for select * from owns;
            loop
                fetch curs1 into row;
                exit when not found;
                if(row.symbol = new.symbol) then
                    select row.login into myUser;
                    insert into trxlog values (DEFAULT, myUser, NULL, TO_DATE('29-MAR-20', 'DD-MON-YY'), 'sell', row.shares, new.price, (row.shares*new.price));
                    delete from owns where symbol=new.symbol and login = row.login;
                end if;
            end loop;
            close curs1;
        end if;
        return null;

    end;
    $$ language plpgsql;


CREATE TRIGGER  price_jump
    before insert on closing_price
    for each row
    execute function price_jump_helper();


CREATE or replace function recent_prices(input_date date)
returns table(symbol varchar(20), price decimal(10, 2))
as $$
    begin

    return query(
    select t.symbol, t.price from( --Gets the most recent prices
                        select CP.symbol, CP.price, row_number() over(partition by CP.symbol order by CP.symbol) as rn
                            from closing_price CP
                            where CP.p_date <= input_date
                            order by p_date desc) t
                    where rn = 1);
    end;
    $$ language plpgsql;



--Question 2:
DROP FUNCTION IF EXISTS search_mutual_funds(keyword_1 varchar(30), keyword_2 varchar(30));
CREATE OR REPLACE FUNCTION search_mutual_funds(keyword_1 varchar(30), keyword_2 varchar(30))
    RETURNS text AS
$$
DECLARE
    res text; -- local variable for string of symbols
    i   text; -- current record
BEGIN
    res := '';
    FOR i IN
        SELECT symbol
        FROM mutual_fund
        WHERE description LIKE '%' || keyword_1 || '%'
          AND description LIKE '%' || keyword_2 || '%'
        LOOP
            res := res || ',' || i;
        END LOOP;
    res := res || ']';
    res := ltrim(res, ','); --trim extra ',' at beginning
    res := '[' || res;

    return res;
END;
$$ LANGUAGE plpgsql;
--Sanity Check:
SELECT symbol
FROM mutual_fund
WHERE description LIKE CONCAT('%', 'bonds', '%')
  AND description LIKE CONCAT('%', 'term', '%');
--test function: should be like: [STB, LTB]
SELECT search_mutual_funds('bonds', 'term');

--Question 3:
CREATE OR REPLACE PROCEDURE deposit_for_investment(login varchar(10), deposit decimal(10, 2))
AS
$$
DECLARE
    mutual_date_value date;
    row_count         int;
    alloc_no          int;
    pref              record;
    percentage        decimal(10, 2);
    symbol_price      decimal(10, 2);
    amount_to_buy     decimal(10, 2);
    num_of_shares     int;
    total_amount      decimal(10, 2);
    txc_amount        decimal(10, 2);
    remaining         decimal(10, 2);
    suffient_amount   boolean;
BEGIN
    --  Get the current date
    SELECT p_date
    INTO mutual_date_value
    FROM MUTUAL_DATE
    ORDER BY p_date DESC
    LIMIT 1;

    -- Check if user exists
    SELECT count(*)
    INTO row_count
    FROM CUSTOMER
    WHERE CUSTOMER.login = deposit_for_investment.login; -- The name of the procedure is used as a prefix (i.e., scope)
    IF row_count = 0 THEN
        RAISE EXCEPTION 'User % not found.', login;
    END IF;

    --  Total amount of all transaction
    total_amount = 0;

    --  Find the newest allocation_no for the user
    SELECT ALLOCATION.allocation_no
    INTO alloc_no
    FROM ALLOCATION
    WHERE ALLOCATION.login = deposit_for_investment.login
    ORDER BY ALLOCATION.p_date DESC
    LIMIT 1;

    -- Check if the deposit is enough to buy all symbols in the allocation
    SELECT SUM(P.percentage * deposit) > SUM(CP.price)
    INTO suffient_amount
    FROM PREFERS P
             JOIN CLOSING_PRICE CP ON CP.symbol = P.symbol
             JOIN (SELECT CLOSING_PRICE.symbol, max(p_date) AS max_date
                   FROM CLOSING_PRICE
                   GROUP BY CLOSING_PRICE.symbol) AS MOST_RECENT_CP
                  ON cp.symbol = MOST_RECENT_CP.symbol AND CP.p_date = MOST_RECENT_CP.max_date
    WHERE allocation_no = alloc_no;

    IF not suffient_amount THEN -- FALSE if deposit is not enough for a symbol
        RAISE NOTICE 'Partial allocation purchase is not allowed. The amount of % will be deposited to the account.', deposit;
    ELSE
        -- Buy the shares
        FOR pref in (SELECT * FROM PREFERS WHERE allocation_no = alloc_no)
            LOOP
                percentage = pref.percentage;
                amount_to_buy = deposit * percentage;

                -- Find latest mutual fund price associated with the preference symbol
                SELECT CLOSING_PRICE.price
                INTO symbol_price
                FROM CLOSING_PRICE
                WHERE CLOSING_PRICE.symbol = pref.symbol
                ORDER BY CLOSING_PRICE.p_date DESC
                LIMIT 1;

                -- Number of shares that we have to buy for the user for this symbol
                num_of_shares = FLOOR(amount_to_buy / symbol_price);

                -- transaction total amount
                txc_amount = num_of_shares * symbol_price;
                total_amount = total_amount + txc_amount;

                -- The transaction id will be generated automatically the sequence 'trx_sequence'
                INSERT INTO TRXLOG(login, symbol, action, num_shares, price, amount, t_date)
                VALUES (deposit_for_investment.login, pref.symbol, 'buy', num_of_shares,
                        symbol_price, txc_amount, mutual_date_value);

                -- Check if the user already own some shares of this symbol
                SELECT count(*)
                INTO row_count
                FROM OWNS
                WHERE OWNS.login = deposit_for_investment.login
                  AND OWNS.symbol = pref.symbol;
                IF row_count = 0 THEN
                    -- Create a new row
                    INSERT INTO OWNS(login, symbol, shares)
                    VALUES (deposit_for_investment.login, pref.symbol, num_of_shares);
                ELSE
                    -- Update the existing row
                    UPDATE OWNS
                    SET shares = shares + num_of_shares
                    WHERE OWNS.login = deposit_for_investment.login
                      AND OWNS.symbol = pref.symbol;
                END IF;
            END LOOP;
    END IF;

    -- deposit the remaining amount to user's balance
    remaining = deposit - total_amount;
    UPDATE CUSTOMER
    SET balance = balance + remaining
    WHERE CUSTOMER.login = deposit_for_investment.login;
END;
$$ LANGUAGE PLPGSQL;

CALL deposit_for_investment('mary', 5);
CALL deposit_for_investment('mike', 100);

--Question 4:
CREATE OR REPLACE FUNCTION buy_shares(login varchar(10), symbol varchar(20), number_of_shares int)
    RETURNS BOOLEAN AS
$$
DECLARE
    mutual_date_value date;
    row_count         int;
    symbol_price      decimal(10, 2);
    customer_balance  decimal(10, 2);
BEGIN

    --  Get the current date
    SELECT p_date
    INTO mutual_date_value
    FROM MUTUAL_DATE
    ORDER BY p_date DESC
    LIMIT 1;

    -- Check if customer exists
    SELECT count(*)
    INTO row_count
    FROM CUSTOMER
    WHERE CUSTOMER.login = buy_shares.login; -- The name of the procedure is used as a prefix (i.e., scope)
    IF row_count = 0 THEN
        RAISE EXCEPTION 'User % not found.', login;
    END IF;

    -- Check if the symbol exists
    SELECT count(*)
    INTO row_count
    FROM MUTUAL_FUND
    WHERE MUTUAL_FUND.symbol = buy_shares.symbol; -- The name of the procedure is used as a prefix (i.e., scope)
    IF row_count = 0 THEN
        RAISE EXCEPTION 'Symbol % not found.', symbol;
    END IF;

    -- get the customer's balance
    SELECT balance
    INTO customer_balance
    FROM CUSTOMER
    WHERE CUSTOMER.login = buy_shares.login;

    -- Get the latest price for the desired symbol
    SELECT CLOSING_PRICE.price
    INTO symbol_price
    FROM CLOSING_PRICE
    WHERE CLOSING_PRICE.symbol = buy_shares.symbol
    ORDER BY CLOSING_PRICE.p_date DESC
    LIMIT 1;

    -- no sufficient funds to buy the shares
    IF (symbol_price * number_of_shares) > customer_balance THEN
        RETURN FALSE;
    END IF;

    -- buy shares section ==

    -- The transaction id will be generated automatically the sequence 'trx_sequence'
    INSERT INTO TRXLOG(login, symbol, action, num_shares, price, amount, t_date)
    VALUES (login, symbol, 'buy', number_of_shares, symbol_price, (symbol_price * number_of_shares),
            mutual_date_value);

    -- Check if the user already own some shares of this symbol
    SELECT count(*)
    INTO row_count
    FROM OWNS
    WHERE OWNS.login = buy_shares.login
      AND OWNS.symbol = buy_shares.symbol;

    -- if no shares are owned of the same symbol
    IF row_count = 0 THEN
        -- add an ownership of shares
        INSERT INTO OWNS(login, symbol, shares)
        VALUES (buy_shares.login, buy_shares.symbol, buy_shares.number_of_shares);
    ELSE
        -- Update the existing row
        UPDATE OWNS
        SET shares = shares + buy_shares.number_of_shares
        WHERE OWNS.login = buy_shares.login
          AND OWNS.symbol = buy_shares.symbol;
    END IF;
    -- end buy shares section ==

    -- update the customer's balance section ==
    UPDATE CUSTOMER
    SET balance = balance - (symbol_price * number_of_shares)
    WHERE CUSTOMER.login = buy_shares.login;
    -- end update customer's balance section ==

    -- shares are bought
    RETURN TRUE;

END;
$$ LANGUAGE PLPGSQL;

SELECT buy_shares('mary', 'MM', 1);

-- Question 5:
CREATE OR REPLACE FUNCTION buy_on_date_helper()
    RETURNS trigger AS
$$
DECLARE
    num_of_shares   int;
    customer_symbol varchar(20);
    symbol_price    decimal(10, 2);
    c_customer      record;
BEGIN

    FOR c_customer in (SELECT * FROM CUSTOMER)
        LOOP
            -- Get the symbol with the minimum shares
            SELECT symbol
            into customer_symbol
            FROM OWNS
            WHERE login = c_customer.login
            ORDER BY shares
            LIMIT 1;

            IF customer_symbol IS NOT NULL THEN
                -- Get the latest price for the desired symbol
                SELECT CLOSING_PRICE.price
                INTO symbol_price
                FROM CLOSING_PRICE
                WHERE CLOSING_PRICE.symbol = customer_symbol
                ORDER BY CLOSING_PRICE.p_date DESC
                LIMIT 1;

                num_of_shares = FLOOR(c_customer.balance / symbol_price);

                RAISE NOTICE 'Did the customer % buy % shares of % symbol? (%).',c_customer.login,  num_of_shares,customer_symbol,
                    buy_shares(c_customer.login, customer_symbol, num_of_shares);
            END IF;

        END LOOP;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER buy_on_date
    AFTER UPDATE OR INSERT
    ON mutual_date
    FOR EACH ROW
EXECUTE FUNCTION buy_on_date_helper();

-- QUESTION 6:
CREATE OR REPLACE FUNCTION buy_on_price_helper()
    RETURNS trigger AS
$$
DECLARE
    num_of_shares   int;
    customer_symbol varchar(20);
    symbol_price    decimal(10, 2);
    c_customer      record;
BEGIN

    FOR c_customer in (SELECT * FROM CUSTOMER)
        LOOP
            -- Get the symbol with the minimum shares
            SELECT symbol
            into customer_symbol
            FROM OWNS
            WHERE login = c_customer.login AND symbol = NEW.symbol -- This can be optimize
            ORDER BY shares
            LIMIT 1;

            IF customer_symbol IS NOT NULL THEN
                -- Get the latest price for the desired symbol
                SELECT CLOSING_PRICE.price
                INTO symbol_price
                FROM CLOSING_PRICE
                WHERE CLOSING_PRICE.symbol = customer_symbol
                ORDER BY CLOSING_PRICE.p_date DESC
                LIMIT 1;

                num_of_shares = FLOOR(c_customer.balance / symbol_price);

                RAISE NOTICE 'Did the customer % buy % shares of % symbol? (%).',c_customer.login,  num_of_shares,customer_symbol,
                    buy_shares(c_customer.login, customer_symbol, num_of_shares);
            END IF;

        END LOOP;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER buy_on_price
    AFTER UPDATE OF PRICE
    ON closing_price
    FOR EACH ROW
EXECUTE FUNCTION buy_on_price_helper();

                                                                                      
--ADMINISTRATOR TASKS:                                                                                      
                                                                                      
--Task #1: Erase the database
CREATE OR REPLACE PROCEDURE erase_database()
AS
$$
BEGIN
    delete from mutual_fund;
    delete from closing_price;
    delete from customer;
    delete from allocation;
    delete from prefers;
    delete from owns;
    delete from administrator;
    delete from trxlog;
    delete from mutual_date; --Still unsure about this one
END;
$$ LANGUAGE plpgsql;

--call erase_database();

--Task #2: Add a customer
DROP DOMAIN IF EXISTS EMAIL_DOMAIN CASCADE;
CREATE DOMAIN EMAIL_DOMAIN AS varchar(30) CHECK (VALUE ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
CREATE OR REPLACE PROCEDURE add_customer(login varchar(10), name varchar(20), email EMAIL_DOMAIN,
                                            address  varchar(30), password varchar(10), balance decimal(10, 2))
as
$$
declare
    input_balance int;
begin
    input_balance:= add_customer.balance;
    if input_balance is null then
        input_balance:= 0;
    end if;


    insert into customer
    values(add_customer.login, add_customer.name, add_customer.email,
            add_customer.address, add_customer.password, input_balance);

end;
$$ LANGUAGE plpgsql;

--call add_customer('Chris2', 'Chris213 Flores', 'chrisf@betterfuture.com', null, 'pwd', null);

--Task #3: Add new mutual fund
CREATE OR REPLACE PROCEDURE new_mutual_fund(symbol varchar(20), name varchar(30), description varchar(100),
                                            category CATEGORY_DOMAIN, c_date date)
as
$$
BEGIN

    insert into mutual_fund
    values(new_mutual_fund.symbol, new_mutual_fund.name, new_mutual_fund.description, new_mutual_fund.category,
           new_mutual_fund.c_date);

end;
$$ LANGUAGE plpgsql;

--call new_mutual_fund('CF', 'Chris-Forbes', 'Chris Flores money corp', 'fixed', TO_DATE('06-JAN-20', 'DD-MON-YY'));

--Task #4: Update share quotes for a day
-- I think I just have to change the Closing_Price table but I'm not sure
CREATE OR REPLACE PROCEDURE update_share_quotes(strings text[]) --symbol varchar(20), price decimal(10, 2))
as
$$
declare
    number_strings integer := array_length(strings, 1);
    string_index integer := 1;
    input_symbol varchar(20);
    input_price decimal(10, 2);
begin
WHILE string_index <= number_strings LOOP
      --RAISE NOTICE '%', strings[string_index];
      if mod(string_index, 2) = 1 then
        input_symbol := strings[string_index];
      else
        input_price := strings[string_index];
        insert into closing_price
        values(input_symbol, input_price, current_date);--TO_DATE(CURRENT_DATE, 'DD-MON-YY'));
        --update closing_price
        --    set price = input_price
        --where symbol = input_symbol;
        RAISE NOTICE 'Inserted: %, %', input_symbol, input_price;
      end if;
      string_index = string_index + 1;
   END LOOP;

end;
$$ LANGUAGE plpgsql;

--call update_share_quotes('{MM,15.00, RE,14.20, STB,11.40}');
                                                
--Task #5: Show top-k highest volume categories
CREATE OR REPLACE FUNCTION show_k_highest_volume_categories(k integer) RETURNS table (category CATEGORY_DOMAIN)
AS
    $$
DECLARE top_k int;
BEGIN
    top_k = k;
    RETURN QUERY
        (SELECT mutual_fund.category FROM mutual_fund JOIN owns o ON mutual_fund.symbol = o.symbol
        GROUP BY mutual_fund.category ORDER BY SUM(shares) DESC LIMIT top_k);
END;
    $$
    LANGUAGE plpgsql;

SELECT show_k_highest_volume_categories(2);


--Task #6: Rank all investors
CREATE OR REPLACE FUNCTION rank_all_investors()
    RETURNS table (login varchar(10), wealth decimal(10, 2), rank bigint)
AS
    $$
    BEGIN
        RETURN QUERY (
        SELECT owns.login, SUM(owns.shares * maxprices.price) AS wealth, RANK()
            over (ORDER BY SUM(owns.shares * maxprices.price) DESC)
        FROM owns
        JOIN
        (SELECT a.symbol, a.price, a.p_date FROM closing_price a inner join
            (SELECT symbol, max(p_date) as max_date FROM closing_price GROUP BY symbol) b
                on a.symbol = b.symbol AND a.p_date = b.max_date) maxprices
        ON owns.symbol = maxprices.symbol
        GROUP BY owns.login
        ORDER BY wealth DESC
        );
    END;
    $$
    LANGUAGE plpgsql;

select rank_all_investors();

--Task #7: Update the current (pseudo) date
--note that this takes an argument of type date
CREATE OR REPLACE PROCEDURE set_current_date(new_date date)
AS
    $$
    BEGIN
        UPDATE mutual_date
        SET p_date = new_date;
    END;
    $$
LANGUAGE plpgsql;

--CALL set_current_date(TO_DATE('01-01-2000', 'DD-MM-YYYY'));

--*****************Customer Tasks*************************************************************************************************

--Task #1: Show the customer’s balance and total number of shares
CREATE OR REPLACE FUNCTION customer_balance_and_shares(input_login varchar(10))
returns table (name varchar(20), balance  decimal(10, 2), shares integer)
as
$$
    begin

        return query(
            select customer.name, customer.balance::decimal(10,2), sum.shares::integer
            from customer
            left join(
            select owns.login, sum(owns.shares) as shares
            from owns
            where input_login = owns.login
            group by owns.login
                ) sum
            on customer.login = sum.login
            where input_login = customer.login
        );
    end;
$$LANGUAGE plpgsql;

select * from customer_balance_and_shares('mike');

--Task #2: Show mutual funds sorted by name
CREATE OR REPLACE FUNCTION customer_balance_and_shares()
returns table(symbol varchar(20), name varchar(30), description varchar(100),
                category CATEGORY_DOMAIN, c_date date)
as
    $$
    begin
        return query(
        Select MF.symbol, MF.name, MF.description,
                MF.category, MF.c_date
        from mutual_fund MF
        order by MF.name
        );
    end;
    $$ Language plpgsql;

--select * from customer_balance_and_shares();

--Task #3: Show mutual funds sorted by prices on a date
CREATE OR REPLACE FUNCTION mutual_funds_on_date(s_date date, input_login varchar(10))
returns table(symbol varchar(20), name varchar(30), description varchar(100),
                category CATEGORY_DOMAIN, c_date date, price decimal(10, 2), owned varchar(20))
as
    $$
    begin
        return query(

            select curr.symbol as symbol, curr.name, curr.description, curr.category, curr.c_date, curr.price, owned.symbol as owned from(
            select CF.symbol as symbol, CF.name, CF.description, CF.category, CF.c_date, Closing_Prices.price from(
                    select *
                    from mutual_fund
                    where mutual_fund.c_date <= s_date
                    ) as CF
                join(
                    select RP.symbol, RP.price
                    from recent_prices(s_date) RP
                    ) as Closing_Prices
                on CF.symbol = Closing_Prices.symbol
                ORDER BY price DESC) as curr
                left join (
                    select *
                        from owns
                        where owns.login = input_login) as owned
                    on owned.symbol = curr.symbol
            ORDER BY curr.price DESC
        );
    end;
    $$ Language plpgsql;

select * from mutual_funds_on_date(to_date('30-03-20','DD-MM-YY'), 'mike');

CREATE OR REPLACE FUNCTION customer_owns(input_login varchar(10))
returns table(login varchar(10) ,symbol varchar(20), name varchar(30), description varchar(100),
                category CATEGORY_DOMAIN, c_date date, shares integer)
as
    $$
    begin
        return query (
            select OW.login, OW.symbol, MF.name, MF.description, MF.category, MF.c_date, OW.shares from(
            select *
            from owns
            where login = input_login) as OW
            join mutual_fund MF
            on OW.symbol = MF.symbol
        );
    end;
$$ LANGUAGE plpgsql;

--select mutual_funds_on_date(TO_DATE('30-MAR-20', 'DD-MON-YY') ,'mike');



DROP PROCEDURE buy_shares(log varchar(10), symb varchar(20), amount decimal(10, 2));
CREATE OR REPLACE PROCEDURE buy_shares(log varchar(10), symb varchar(20), amount decimal(10, 2)) AS
    $$
    DECLARE
        price decimal(10, 2);
        bal decimal(10, 2);
        n_shares integer;
        cost decimal(10, 2);
        buy_date date;
    BEGIN
        SELECT closing_price.price FROM closing_price
            WHERE closing_price.symbol = symb
            ORDER BY closing_price.p_date DESC
            FETCH FIRST ROW ONLY INTO price;
        SELECT balance FROM customer WHERE login = log INTO bal;
        SELECT p_date FROM mutual_date FETCH FIRST ROW ONLY into buy_date;
        SELECT FLOOR(amount/price) INTO n_shares;
        SELECT price * n_shares INTO cost;
        IF (n_shares > 0) THEN
            UPDATE customer
                SET balance = (balance - cost)
                WHERE login = log;
            INSERT INTO owns(login, symbol, shares)
                VALUES (log, symb, n_shares)
                ON CONFLICT ON CONSTRAINT OWNS_PK DO
                UPDATE SET shares = owns.shares + n_shares
                    WHERE owns.login = log AND owns.symbol = symb;
             INSERT INTO trxlog VALUES (DEFAULT, log, symb, buy_date, 'buy', n_shares, price, (price * n_shares));
            ELSE
                RAISE EXCEPTION 'not enough money to buy shares';
        end if;
    end
    $$ LANGUAGE plpgsql;
--CALL buy_shares('mike', 'RE', 100.00);

--Task 7:
CREATE OR REPLACE FUNCTION sell_shares(login varchar(10), symbol varchar(20), number_of_shares int)
    RETURNS BOOLEAN AS
$$
DECLARE
    mutual_date_value date;
    row_count         int;
    symbol_price      decimal(10, 2);
    customer_balance  decimal(10, 2);
    customer_shares   int;
BEGIN

    --  Get the current date
    SELECT p_date
    INTO mutual_date_value
    FROM MUTUAL_DATE
    ORDER BY p_date DESC
    LIMIT 1;

    -- Check if customer exists
    SELECT count(*)
    INTO row_count
    FROM CUSTOMER
    WHERE CUSTOMER.login = sell_shares.login; -- The name of the procedure is used as a prefix (i.e., scope)
    IF row_count = 0 THEN
        RAISE EXCEPTION 'User % not found.', login;
    END IF;

    -- Check if the symbol exists
    SELECT count(*)
    INTO row_count
    FROM MUTUAL_FUND
    WHERE MUTUAL_FUND.symbol = sell_shares.symbol; -- The name of the procedure is used as a prefix (i.e., scope)
    IF row_count = 0 THEN
        RAISE EXCEPTION 'Symbol % not found.', symbol;
    END IF;

    -- get the customer's balance
    SELECT balance
    INTO customer_balance
    FROM CUSTOMER
    WHERE CUSTOMER.login = sell_shares.login;

    -- get the number of shares the customer owns
    SELECT shares
    INTO customer_shares
    FROM owns
    WHERE owns.login = sell_shares.login AND owns.symbol = sell_shares.symbol;

    -- Get the latest price for the desired symbol
    SELECT CLOSING_PRICE.price
    INTO symbol_price
    FROM CLOSING_PRICE
    WHERE CLOSING_PRICE.symbol = sell_shares.symbol
    ORDER BY CLOSING_PRICE.p_date DESC
    LIMIT 1;

    -- no sufficient shares to sell
    IF customer_shares < sell_shares.number_of_shares THEN
        RETURN FALSE;
    END IF;

    -- sell  shares section ==

    -- The transaction id will be generated automatically the sequence 'trx_sequence'
    INSERT INTO TRXLOG(login, symbol, action, num_shares, price, amount, t_date)
    VALUES (login, symbol, 'sell', number_of_shares, symbol_price, (symbol_price * number_of_shares),
            mutual_date_value);
    --balance updated automatically by trigger

    --update OWNS
    --delete entry if cust sells all shares
    IF customer_shares = sell_shares.number_of_shares THEN
        DELETE FROM OWNS AS o
        WHERE o.symbol = sell_shares.symbol AND o.login = sell_shares.login;
    ELSE
        --modify entry
        UPDATE OWNS
        SET shares = shares - number_of_shares
        WHERE OWNS.symbol = sell_shares.symbol AND OWNS.login = sell_shares.login;
    end if;


    -- end sell shares section ==

    -- shares are sold
    RETURN TRUE;

END;
$$ LANGUAGE PLPGSQL;

--SELECT sell_shares('andrew', 'RE', 1);

--Task 8
                                                                                               
CREATE OR REPLACE FUNCTION get_roi_top(l varchar(10), s varchar(10))
returns int as
$$
    declare
        subtracted int = 0;
        current int = 0;
    begin
        select coalesce(sum(amount),0) into subtracted
            from trxlog
                where trxlog.login = l and trxlog.symbol = s and action = 'sell';
        select coalesce((shares*getRecentPrice(s)),0) into current
            from owns
            where owns.symbol = s and owns.login = l;

        return current+subtracted-get_roi_bottom(l,s);
    end;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION get_roi_bottom(l varchar(10), s varchar(10))
returns int as
$$
    declare
        added int = 0;
    begin
        select coalesce(sum(amount),0) into added
            from trxlog
                where trxlog.login = l and trxlog.symbol = s and action = 'buy';


        return added;
    end;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION show_roi(l varchar(10))
returns varchar(100) as
$$
    DECLARE
    curs1 refcursor;
    row record;
    output varchar(100);
    n varchar(20);
    BEGIN
        open curs1 for select * from owns where login = l;
        output = '';
        loop
            fetch curs1 into row;
            exit when not found;
            select name into n
            from mutual_fund
                where symbol = row.symbol;
            output = output || row.symbol || ', '|| n || ' = '|| ((1.0*get_roi_top(l, row.symbol)/get_roi_bottom(l, row.symbol))::float4)||' ';
        end loop;
        raise notice 'ddd %',output;
        return output;
    end;
$$ LANGUAGE PLPGSQL;

--task 9
create or replace view predicted as
    select login,action,amount-num_shares*getRecentPrice(symbol) as difference, num_shares*getRecentPrice(symbol) as predicted
    from trxlog where action != 'deposit';

--Task #10: Change allocation preference
Create or replace procedure change_allocation_preferences(strings text[], input_login varchar(10))
as
$$
declare
    number_strings integer := array_length(strings, 1);
    string_index integer := 1;
    input_symbol varchar(20);
    input_percent decimal(3, 2);
    c_date date;
    recent_alloc_date date;
    alloc_no integer;
begin
select max(allocation_no) into alloc_no from allocation limit 1;
alloc_no:= alloc_no + 1;
select p_date into recent_alloc_date from allocation where allocation.login = input_login order by p_date desc limit 1;
raise notice 'recent alloc_date = %, c_date = %',recent_alloc_date, c_date;

select p_date into c_date from mutual_date order by p_date desc limit 1;
if recent_alloc_date = c_date then
    Raise Exception 'Already updated Allocations today. Come Back tomorrow!';
else
    insert into allocation(allocation_no, login, p_date)
    values(alloc_no, input_login, c_date);
end if;
    RAISE NOTICE 'Inserted into allocation: %, %, %', alloc_no, input_login, c_date;
WHILE string_index <= number_strings LOOP
      --RAISE NOTICE '%', strings[string_index];
      if mod(string_index, 2) = 1 then
        input_symbol := strings[string_index];
      else
        input_percent := strings[string_index];

        --select allocation_no into alloc_no from allocation where allocation.login = input_login;
        insert into prefers(allocation_no, symbol, percentage)
        values(alloc_no, input_symbol, input_percent);

        RAISE NOTICE 'Inserted: %, %', input_symbol, input_percent;
      end if;
      string_index = string_index + 1;
   END LOOP;

end;
$$ LANGUAGE plpgsql;

call change_allocation_preferences('{MM,0.5,RE,0.5}', 'mike');

--Task #12: Show portfolio
create or replace function show_portfolio(input_login varchar(10))
returns table(symbol varchar(20), shares integer, current_value decimal(10,2), cost (how_much paid for it), adjusted_cost , yeild)
as
$$
    DECLARE
        c_date date;
    begin
    select p_date into c_date from mutual_date order by p_date desc limit 1;
       return query(
           select t.symbol, t.shares, RP.price from(
           select * from customer_owns(input_login)) as t
           join(select * from recent_prices(c_date)) as RP
           on t.symbol = RP.symbol
       );
    end;
$$ language plpgsql;


select * from show_portfolio('mike');

create or replace function total_value_of_portfolio(input_login varchar(10))
returns decimal (10,2)
as
$$
    DECLARE
        total decimal(10,2):= 0;
        rec record;
    begin
    FOR rec in SELECT * FROM owns_with_price(input_login) LOOP
        total:= total + (rec.shares * rec.current_price);
    END LOOP;
        return total;
    end;
$$language plpgsql;

select total_value_of_portfolio('mike');

create or replace function owns_with_price(input_login varchar(10)) returns table(login  varchar(10), symbol varchar(20), shares integer, current_price decimal(10,2))
as
$$
    DECLARE
        c_date date;
    begin
    select p_date into c_date from mutual_date order by p_date desc limit 1;
    return query(
        select owns.symbol, owns.symbol, owns.shares, RP.price from(
            select *
            from owns
            where input_login = owns.login)owns join recent_prices(c_date)RP
        on owns.symbol = RP.symbol
    );
    end;
$$language plpgsql;

select * from owns_with_price('mike')
