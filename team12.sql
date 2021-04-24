-- Andrew Imredy api5, Ted Balashov thb46, Christopher Flores cwf24

--CREATE DOMAIN FOR EMAIL ATTRIBUTE
DROP DOMAIN IF EXISTS EMAIL_DOMAIN CASCADE;
CREATE DOMAIN EMAIL_DOMAIN AS varchar(30) CHECK (VALUE ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
--CREATE DOMAIN FOR MUTUAL FUND CATEGORY
DROP DOMAIN IF EXISTS CATEGORY_DOMAIN CASCADE;
CREATE DOMAIN CATEGORY_DOMAIN AS varchar(10) CHECK (VALUE IN ('fixed', 'bonds', 'mixed', 'stocks'));
--CREATE DOMAIN FOR ACTION CATEGORY
DROP DOMAIN IF EXISTS ACTION_DOMAIN CASCADE;
CREATE DOMAIN ACTION_DOMAIN AS varchar(10) CHECK (VALUE IN ('deposit', 'buy', 'sell'));

/**********************************************************************************
                        Assumptions:
1) Assume that Customers and Administrators are disjoint.
- That is, no administrator is a customer, vice versa.
2) Assume 'Name' from the Administrator and Customer tables are the Full Name.
3) Assume 'Balance' cannot be negative.
4) Assume that Emails can come from different websites.
- Ex: gol6@pitt.edu, gol6@cmu.edu
5) Assume customers and administrators can come from the same household.
6) Assume 'Password' can be the same for different users
- Ex: abcdefg
7) Assume that p_date in Allocation and Closing_Price tables are unrelated.
8) For the Closing_Price table, assume that price is recorded every day.
**********************************************************************************/

--Drop all tables to make sure the Schema is clear!
DROP TABLE IF EXISTS MUTUAL_DATE CASCADE;
DROP TABLE IF EXISTS CUSTOMER CASCADE;
DROP TABLE IF EXISTS ADMINISTRATOR CASCADE;
DROP TABLE IF EXISTS MUTUAL_FUND CASCADE;
DROP TABLE IF EXISTS OWNS CASCADE;
DROP TABLE IF EXISTS TRXLOG CASCADE;
DROP TABLE IF EXISTS ALLOCATION CASCADE;
DROP TABLE IF EXISTS PREFERS CASCADE;
DROP TABLE IF EXISTS CLOSING_PRICE CASCADE;

---CREATING MUTUAL DATE TABLE
-- The c_date is initialized once using INSERT and updated subsequently
CREATE TABLE MUTUAL_DATE
(
    p_date date,
    CONSTRAINT S_DATE_PK PRIMARY KEY (p_date)
);

---CREATING CUSTOMER TABLE
-- Assume emails are unique -> no two users registered on the same site can share an email address
CREATE TABLE CUSTOMER
(
    login    varchar(10),
    name     varchar(20)    NOT NULL,
    email    varchar(30),
    address  varchar(30),
    password varchar(10)    NOT NULL,
    balance  decimal(10, 2) NOT NULL,
    CONSTRAINT LOGIN_PK PRIMARY KEY (login),
    CONSTRAINT EMAIL_UNIQUE UNIQUE (email),
    CONSTRAINT BALANCE_CK CHECK ( balance >= 0 )
);

---CREATING ADMINISTRATOR TABLE
CREATE TABLE ADMINISTRATOR
(
    login    varchar(10),
    name     varchar(20) NOT NULL,
    email    EMAIL_DOMAIN,
    address  varchar(30) NOT NULL,
    password varchar(10) NOT NULL,
    CONSTRAINT ADMIN_LOGIN_PK PRIMARY KEY (login),
    CONSTRAINT ADMIN_EMAIL_UNIQUE UNIQUE (email)
);

---CREATING MUTUAL FUND TABLE
--Assume p_date from MutualDate is not same as c_date in MutualFund table
CREATE TABLE MUTUAL_FUND
(
    symbol      varchar(20),
    name        varchar(30)  NOT NULL,
    description varchar(100) NOT NULL,
    category    CATEGORY_DOMAIN,
    c_date      date         NOT NULL,
    CONSTRAINT MUTUAL_FUND_PK PRIMARY KEY (symbol),
    CONSTRAINT MF_NAME_UQ UNIQUE (name),
    CONSTRAINT MF_DESC_UQ UNIQUE (description)
);

---CREATING OWNS TABLE
CREATE TABLE OWNS
(
    login  varchar(10),
    symbol varchar(20),
    shares integer NOT NULL,
    CONSTRAINT OWNS_PK PRIMARY KEY (login, symbol),
    CONSTRAINT LOGIN_FK FOREIGN KEY (login) REFERENCES CUSTOMER (login) on delete cascade,
    CONSTRAINT SYMBOL_FK FOREIGN KEY (symbol) REFERENCES MUTUAL_FUND (symbol) on delete cascade,
    CONSTRAINT SHARES_CK CHECK ( shares > 0 )
);

---CREATING TRXLOG TABLE
--Symbol/Shares/Price can be null if the user simply wants to deposit
--No need to make a FK to PK from CLosingPrice or Allocation, in case of a deposit
CREATE TABLE TRXLOG
(
    trx_id     serial,
    login      varchar(10)    NOT NULL,
    symbol     varchar(20),
    t_date     date           NOT NULL,
    action     ACTION_DOMAIN,
    num_shares integer,
    price      decimal(10, 2),
    amount     decimal(10, 2) NOT NULL,
    CONSTRAINT TRXLOG_PK PRIMARY KEY (trx_id),
    CONSTRAINT LOGIN_FK FOREIGN KEY (login) REFERENCES CUSTOMER (login) on delete cascade,
    CONSTRAINT SYMBOL_FK FOREIGN KEY (symbol) REFERENCES MUTUAL_FUND (symbol) on delete cascade,
    CONSTRAINT AMOUNT_CK CHECK ( amount > 0),
    CONSTRAINT NUM_SHARES_CK CHECK ( num_shares > 0),
    CONSTRAINT PRICE_CK CHECK ( price > 0)
);

---CREATING ALLOCATION TABLE
CREATE TABLE ALLOCATION
(
    allocation_no integer,
    login         varchar(10) NOT NULL,
    p_date        date        NOT NULL, --processing date
    CONSTRAINT ALLOCATION_PK PRIMARY KEY (allocation_no),
    CONSTRAINT ALLOC_LOGIN_FK FOREIGN KEY (login) REFERENCES CUSTOMER (login) on delete cascade
);

---CREATING PREFERS TABLE
CREATE TABLE PREFERS
(
    allocation_no integer     NOT NULL,
    symbol        varchar(20) NOT NULL,
    percentage    decimal(3, 2)       NOT NULL,
    CONSTRAINT PREFERS_PK PRIMARY KEY (allocation_no, symbol),
    CONSTRAINT PREFERS_ALLOCATION_NO_FK FOREIGN KEY (allocation_no) REFERENCES ALLOCATION (allocation_no) on delete cascade,
    CONSTRAINT PREFERS_ALLOCATION_SYMBOL_FK FOREIGN KEY (symbol) REFERENCES MUTUAL_FUND (symbol) on delete cascade,
    CONSTRAINT PERCENTAGE_CK CHECK ( percentage > 0)
);

---CREATING CLOSING_PRICE TABLE
CREATE TABLE CLOSING_PRICE
(
    symbol varchar(20) NOT NULL,
    price  decimal(10, 2)       NOT NULL,
    p_date date        NOT NULL, --processing date
    CONSTRAINT CLOSING_PRICE_PK PRIMARY KEY (symbol, p_date),
    CONSTRAINT CLOSING_PRICE_SYMBOL_FK FOREIGN KEY (symbol) REFERENCES MUTUAL_FUND (symbol) on delete cascade,
    CONSTRAINT CLOSING_PRICE_CK CHECK ( price > 0)
);


--INSERT VALUES INTO THE MUTUAL DATE TABLE
INSERT INTO MUTUAL_DATE (p_date)
VALUES (TO_DATE('04-APR-20', 'DD-MON-YY'));


--INSERT VALUES INTO THE CUSTOMER TABLE
INSERT INTO CUSTOMER
VALUES ('mike', 'Mike Costa', 'mike@betterfuture.com', '1st street', 'pwd', 750);
INSERT INTO CUSTOMER
VALUES ('mary', 'Mary Chrysanthis', 'mary@betterfuture.com', '2nd street', 'pwd', 0);

--INSERT VALUES INTO THE ADMINISTRATOR TABLE
INSERT INTO ADMINISTRATOR
VALUES ('admin', 'Administrator', 'admin@betterfuture.com', '5th Ave, Pitt', 'root');

--INSERT VALUES INTO THE MUTUAL FUND TABLE
INSERT INTO MUTUAL_FUND
VALUES ('MM', 'money-market', 'money market, conservative', 'fixed', TO_DATE('06-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('RE', 'real-estate', 'real estate', 'fixed', TO_DATE('09-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('STB', 'short-term-bonds', 'short term bonds', 'bonds', TO_DATE('10-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('LTB', 'long-term-bonds', 'long term bonds', 'bonds', TO_DATE('11-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('BBS', 'balance-bonds-stocks', 'balance bonds and stocks', 'mixed', TO_DATE('12-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('SRBS', 'social-response-bonds-stocks', 'social responsibility and stocks', 'mixed',
        TO_DATE('12-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('GS', 'general-stocks', 'general stocks', 'stocks', TO_DATE('16-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('AS', 'aggressive-stocks', 'aggressive stocks', 'stocks', TO_DATE('23-JAN-20', 'DD-MON-YY'));
INSERT INTO MUTUAL_FUND
VALUES ('IMS', 'international-markets-stock', 'international markets stock, risky', 'stocks',
        TO_DATE('30-JAN-20', 'DD-MON-YY'));

--INSERT VALUES INTO THE OWNS TABLE
INSERT INTO OWNS
VALUES ('mike', 'RE', 50);

--INSERT VALUES INTO THE TRXLOG TABLE
INSERT INTO TRXLOG
VALUES (DEFAULT, 'mike', NULL, TO_DATE('29-MAR-20', 'DD-MON-YY'), 'deposit', NULL, NULL, 1000);
INSERT INTO TRXLOG
VALUES (DEFAULT, 'mike', 'MM', TO_DATE('29-MAR-20', 'DD-MON-YY'), 'buy', 50, 10, 500);
INSERT INTO TRXLOG
VALUES (DEFAULT, 'mike', 'RE', TO_DATE('29-MAR-20', 'DD-MON-YY'), 'buy', 50, 10, 500);
INSERT INTO TRXLOG
VALUES (DEFAULT, 'mike', 'MM', TO_DATE('01-APR-20', 'DD-MON-YY'), 'sell', 50, 15, 750);

--INSERT VALUES INTO THE ALLOCATION TABLE
INSERT INTO ALLOCATION
VALUES (0, 'mike', TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO ALLOCATION
VALUES (1, 'mary', TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO ALLOCATION
VALUES (2, 'mike', TO_DATE('03-MAR-20', 'DD-MON-YY'));

--INSERT VALUES INTO THE PREFERS TABLE
INSERT INTO PREFERS
VALUES (0, 'MM', .5);
INSERT INTO PREFERS
VALUES (0, 'RE', .5);
INSERT INTO PREFERS
VALUES (1, 'STB', .2);
INSERT INTO PREFERS
VALUES (1, 'LTB', .4);
INSERT INTO PREFERS
VALUES (1, 'BBS', .4);
INSERT INTO PREFERS
VALUES (2, 'GS', .3);
INSERT INTO PREFERS
VALUES (2, 'AS', .3);
INSERT INTO PREFERS
VALUES (2, 'IMS', .4);

--INSERT INTO THE CLOSING PRICE TABLE
INSERT INTO CLOSING_PRICE
VALUES ('MM', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 11, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 12, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 15, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 14, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 15, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('MM', 16, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('RE', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 12, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 15, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 14, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 16, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 17, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('RE', 15, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('STB', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 9, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 10, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 12, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 14, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 10, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('STB', 12, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('LTB', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 12, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 13, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 15, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 12, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 9, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('LTB', 10, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('BBS', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 11, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 14, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 18, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 13, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 15, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('BBS', 16, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 12, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 12, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 14, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 17, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 20, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('SRBS', 20, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('GS', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 12, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 13, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 15, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 14, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 15, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('GS', 12, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('AS', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 15, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 14, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 16, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 14, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 17, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('AS', 18, TO_DATE('03-APR-20', 'DD-MON-YY'));

INSERT INTO CLOSING_PRICE
VALUES ('IMS', 10, TO_DATE('28-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 12, TO_DATE('29-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 12, TO_DATE('30-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 14, TO_DATE('31-MAR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 13, TO_DATE('01-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 12, TO_DATE('02-APR-20', 'DD-MON-YY'));
INSERT INTO CLOSING_PRICE
VALUES ('IMS', 11, TO_DATE('03-APR-20', 'DD-MON-YY'));

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
                                            address varchar(30), password varchar(10), balance decimal(10, 2))
as
$$
declare
    input_balance int;
begin
    input_balance:= add_customer.balance;
    if input_balance is null then
        input_balance:= 0;
    end if;


    insert into customer(login, name, email, address, password, balance)
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
                                                                              
--Task 11                                                                                              
create or replace function getClosestPrice(input_date timestamp, s varchar(10))
returns int
as $$
    declare
        x int;
    begin
        select price into x from
        closing_price
        where symbol = s and (DATE_PART('month', input_date) = DATE_PART('month', p_date))
        order by abs(DATE_PART('day', input_date) - DATE_PART('day', p_date)) asc
        limit 1;
        return x;
    end;
$$ language plpgsql;


create or replace function ROI_from_date_bottom(t timestamp, s varchar(10))
returns int as
    $$
    declare
        x int;
    begin
        select getClosestPrice(t,s) into x;
        return x;
    end;
    $$ language plpgsql;

create or replace function ROI_from_date_top(t timestamp, s varchar(10))
returns int as
    $$
    declare
        x int;
    begin
        select getRecentPrice(s) into x;
        x = x - ROI_from_date_bottom(t,s);
        return x;
    end;
    $$ language plpgsql;

create or replace function ROI_date(t timestamp, n int)
returns float4 as
    $$
    declare
        curs1 refcursor;
        rec record;
        perc float4 = 0;
    begin
        open curs1 for select * from prefers where allocation_no = n;
        loop
            fetch curs1 into rec;
            exit when not found;
            perc = perc + rec.percentage*(1.0*(ROI_from_date_top(t, rec.symbol)))/(ROI_from_date_bottom(t, rec.symbol));
        end loop;
        return perc;
    end;
    $$ language plpgsql;

--Task #12: Show portfolio
Create or replace function cost_for_user(input_login varchar(10))
returns table(symbol varchar(20), cost decimal(10,2))
as $$
    begin
    return query (
        select trxlog.symbol, sum(amount) as total
        from trxlog
        where trxlog.login = input_login
        and action = 'buy'
        group by trxlog.symbol
    );
    end;
    $$language plpgsql;



Create or replace function sale_for_user(input_login varchar(10))
returns table(symbol varchar(20), cost decimal(10,2))
as $$
    begin
    return query (
        select mutual_fund.symbol, coalesce(TRX.total, 0) from(
            select trxlog.symbol, sum(amount) as total
            from trxlog
            where trxlog.login = input_login
            and action = 'sell'
            group by trxlog.symbol)TRX
        right join mutual_fund
        on mutual_fund.symbol = TRX.symbol
    );
    end;
    $$language plpgsql;


create or replace function show_portfolio(input_login varchar(10))
returns table(symbol varchar(20), shares integer, current_value decimal(10,2), cost decimal(10, 2), adjusted_cost decimal(10,2), yeild decimal(10,2))
as
$$
    DECLARE
        c_date date;
    begin
    select p_date into c_date from mutual_date order by p_date desc limit 1;
       return query(
           select O2.symbol, O2.shares, O2.current_price, O2.cost, (O2.cost - adj.cost) as adjusted_cost, (O2.current_price - (O2.cost - adj.cost)) as yeild from(
               select O.symbol, O.shares, O.current_price, C.cost from(
                   select t.symbol, t.shares, (RP.price * t.shares) as current_price from(
                   select * from customer_owns(input_login)) as t
                   join(select * from recent_prices(c_date)) as RP
                   on t.symbol = RP.symbol) as O
               join(select * from cost_for_user(input_login)) as C
               on O.symbol = C.symbol) as O2
           left join(select * from sale_for_user(input_login)) as adj
           on O2.symbol = adj.symbol
       );
    end;
$$ language plpgsql;


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

