-- Andrew Imredy api5, Ted Balashov thb46, Christopher Flores cwf24


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

call erase_database();

--Task #2: Add a customer
DROP DOMAIN IF EXISTS EMAIL_DOMAIN CASCADE;
CREATE DOMAIN EMAIL_DOMAIN AS varchar(30) CHECK (VALUE ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
CREATE OR REPLACE PROCEDURE add_customer(login varchar(10), name varchar(20), email EMAIL_DOMAIN,
                                            address  varchar(30), password varchar(10), balance  decimal(10, 2))
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

call new_mutual_fund('CF', 'Chris-Forbes', 'Chris Flores money corp', 'fixed', TO_DATE('06-JAN-20', 'DD-MON-YY'));

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

call update_share_quotes('{MM,15.00, RE,14.20, STB,11.40}');
                                                
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

--select rank_all_investors();

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

--Customer Tasks
--Task #1: Show the customer’s balance and total number of shares
CREATE OR REPLACE FUNCTION customer_balance_and_shares(input_login varchar(10))
returns table (name varchar(20), balance  decimal(10, 2), shares integer)
as
$$
    begin

        return query(
            select customer.name, customer.balance, sum.shares
            from customer
            join(
            select owns.login, sum(owns.shares) as shares
            from owns
            where input_login = owns.login
            group by owns.login
                ) sum
            on customer.login = sum.login
        );
    end;
$$LANGUAGE plpgsql;

--select customer_balance_and_shares('mike');

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

select customer_balance_and_shares();