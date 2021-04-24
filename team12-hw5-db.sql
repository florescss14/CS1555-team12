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
    email    EMAIL_DOMAIN,
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

select * from allocation where allocation.login = 'mike' order by p_date desc limit 1;