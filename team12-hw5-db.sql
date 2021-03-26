DROP TABLE IF EXISTS MUTUALFUND cascade;
DROP TABLE IF EXISTS CLOSING_PRICE cascade;
DROP TABLE IF EXISTS CUSTOMER cascade;
DROP TABLE IF EXISTS OWNS cascade;
DROP TABLE IF EXISTS ALLOCATION cascade;
DROP TABLE IF EXISTS PREFERS cascade;
DROP TABLE IF EXISTS ADMINISTRATOR cascade;
DROP TABLE IF EXISTS TRXLOG cascade;
DROP TABLE IF EXISTS MUTUAL_DATE cascade;


--Added not null to name and category because it is necessary for the mutual fund.
--We have a check on category to make sure that the category is one of the ones that exist
CREATE TABLE MUTUALFUND(
    symbol varchar(20),
    name varchar(30) NOT NULL,
    description varchar(100),
    category varchar(10) NOT NULL,
    c_date date,
    CONSTRAINT MUTUALFUND_PK
        PRIMARY KEY (symbol),
    CONSTRAINT MUTUALFUND_CHECK
        CHECK ( category in ('fixed', 'bonds', 'stocks', 'mixed') )
);

--Added not null to the price because this table should have a closing price.
CREATE TABLE CLOSING_PRICE(
    symbol varchar(20),
    price decimal(10, 2) NOT NULL,
    p_date date,
    CONSTRAINT CLOSING_PRICE_PK
        PRIMARY KEY (symbol, p_date),
    CONSTRAINT CLOSING_PRICE_FK
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

-- The customer should not be allowed to trade if they do no include
-- their basic information so we made everything not null and made the
--defualt balance 0 because it should not be null but also should start at 0.
CREATE TABLE CUSTOMER(
    login varchar(10),
    name varchar(20) NOT NULL,
    email varchar(30) NOT NULL,
    address varchar(30) NOT NULL,
    password varchar(10) NOT NULL,
    balance decimal(10, 2) DEFAULT 0,
    CONSTRAINT CUSTOMER_PK
        PRIMARY KEY (login)
);


-- Added not null to the date because the date for allocation should always be included
CREATE TABLE ALLOCATION(
    allocation_no int,
    login varchar(10),
    p_date date NOT NULL,
    CONSTRAINT ALLOCATION_PK
        PRIMARY KEY (allocation_no),
    CONSTRAINT ALLOCATION_FK
        FOREIGN KEY (login) REFERENCES CUSTOMER (login)
);

-- Included a check constraint on percentage to ensure that the user uses a percentage between 0 and 1
-- Would be invalid to go over 100%
CREATE TABLE PREFERS(
    allocation_no int,
    symbol varchar(20),
    percentage decimal(3, 2),
    CONSTRAINT PREFERS_FK
        PRIMARY KEY (allocation_no, symbol),
    CONSTRAINT PREFERS_FK1
        FOREIGN KEY (allocation_no) REFERENCES ALLOCATION (allocation_no),
    CONSTRAINT PREFERS_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol),
    CONSTRAINT PREFERS_CHECK
        CHECK(percentage <= 1.00 and percentage > 0.00)
);

--shares should be not null because we need to know how many shares a customer owns.
CREATE TABLE OWNS(
    login varchar(10),
    symbol varchar(20),
    shares int NOT NULL,
    CONSTRAINT OWNS_PK
        PRIMARY KEY (login, symbol),
    CONSTRAINT OWNS_FK1
        FOREIGN KEY (login) REFERENCES CUSTOMER (login),
    CONSTRAINT OWNS_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

--Included not nulls because we want the administrators to include all of their basic information
CREATE TABLE ADMINISTRATOR(
    login varchar(10),
    name varchar(20) NOT NULL,
    email varchar(30) NOT NULL,
    address varchar(30) NOT NULL,
    password varchar(10) NOT NULL,
    CONSTRAINT ADMINISTRATOR_PK
        PRIMARY KEY (login)
);


--Included not null for date and amount because we need to know when
-- and how much is being transfered. Have a check on action to make sure
-- that the action is one of the valid ones
CREATE TABLE TRXLOG(
    trx_id serial,
    login varchar(10),
    symbol varchar(20),
    t_date date NOT NULL,
    action varchar(10),
    num_shares int,
    price decimal(10, 2),
    amount decimal(10, 2) NOT NULL,
    CONSTRAINT TRXLOG_PK
        PRIMARY KEY (trx_id),
    CONSTRAINT TRXLOG_FK1
        FOREIGN KEY (login) REFERENCES CUSTOMER (login),
    CONSTRAINT TRXLOG_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol),
    CONSTRAINT TRXLOG_CHECK
        CHECK(action in ('deposit', 'sell', 'buy'))
);

CREATE TABLE MUTUAL_DATE(
    p_date date,
    CONSTRAINT MUTUAL_DATE_PK
        PRIMARY KEY (p_date)
);


insert into customer
(login,name,email,address,password,balance) values
---------------------------------------
('mike','Mike Costa','mike@betterfuture.com','1st street','pwd',750.00),
('mary','Mary Chrysanthis','mary@betterfuture.com','2nd street','pwd',0.00);

insert into allocation
(allocation_no,login,p_date) values
---------------------------------------
(0,'mike',TO_DATE('2020-03-28','YYYY-MM-DD')),
(1,'mary',TO_DATE('2020-03-29','YYYY-MM-DD')),
(2,'mike',TO_DATE('2020-03-03', 'YYYY-MM-DD'));

insert into mutualfund
(symbol,name,description,category,c_date) values
---------------------------------------
('MM','money-market','money market, conservative','fixed',TO_DATE('2020-01-06', 'YYYY-MM-DD')),
('RE','real-estate','real estate','fixed',TO_DATE('2020-01-09', 'YYYY-MM-DD')),
('STB','short-term-bonds','short term bonds','bonds',TO_DATE('2020-01-10', 'YYYY-MM-DD')),
('LTB','long-term-bonds','long term bonds','bonds',TO_DATE('2020-01-11', 'YYYY-MM-DD')),
('BBS','balance-bonds-stocks','balance bonds and stocks','mixed',TO_DATE('2020-01-12', 'YYYY-MM-DD')),
('SRBS','social-response-bonds-stocks','social responsibility and stocks','mixed',TO_DATE('2020-01-12', 'YYYY-MM-DD')),
('GS','general-stocks','general stocks','stocks',TO_DATE('2020-01-16', 'YYYY-MM-DD')),
('AS','aggressive-stocks','aggressive stocks','stocks',TO_DATE('2020-01-23', 'YYYY-MM-DD')),
('IMS','international-markets-stock','international markets stock, risky','stocks',TO_DATE('2020-01-30', 'YYYY-MM-DD'));


insert into closing_price
(symbol,price,p_date) values
---------------------------------------
('MM',10.00,TO_DATE('2020-03-28','YYYY-MM-DD')),
('MM',11.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('MM',12.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('MM',15.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('MM',14.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('MM',15.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('MM',16.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('RE',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('RE',12.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('RE',15.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('RE',14.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('RE',16.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('RE',17.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('RE',15.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('STB',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('STB',9.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('STB',10.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('STB',12.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('STB',14.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('STB',10.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('STB',12.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('LTB',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('LTB',12.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('LTB',13.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('LTB',15.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('LTB',12.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('LTB',9.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('LTB',10.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('BBS',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('BBS',11.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('BBS',14.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('BBS',18.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('BBS',13.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('BBS',15.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('BBS',16.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('SRBS',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('SRBS',12.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('SRBS',12.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('SRBS',14.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('SRBS',17.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('SRBS',20.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('SRBS',20.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('GS',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('GS',12.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('GS',13.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('GS',15.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('GS',14.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('GS',15.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('GS',12.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('AS',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('AS',15.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('AS',14.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('AS',16.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('AS',14.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('AS',17.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('AS',18.00,TO_DATE('2020-04-03', 'YYYY-MM-DD')),
('IMS',10.00,TO_DATE('2020-03-28', 'YYYY-MM-DD')),
('IMS',12.00,TO_DATE('2020-03-29', 'YYYY-MM-DD')),
('IMS',12.00,TO_DATE('2020-03-30', 'YYYY-MM-DD')),
('IMS',14.00,TO_DATE('2020-03-31', 'YYYY-MM-DD')),
('IMS',13.00,TO_DATE('2020-04-01', 'YYYY-MM-DD')),
('IMS',12.00,TO_DATE('2020-04-02', 'YYYY-MM-DD')),
('IMS',11.00,TO_DATE('2020-04-03', 'YYYY-MM-DD'));

insert into mutual_date
(p_date) values
---------------------------------------
(TO_DATE('2020-04-04', 'YYYY-MM-DD'));


insert into owns
(login,symbol,shares) values
---------------------------------------
('mike','RE',50);

insert into prefers
(allocation_no,symbol,percentage) values
---------------------------------------
(0,'MM',0.50),
(0,'RE',0.50),
(1,'STB',0.20),
(1,'LTB',0.40),
(1,'BBS',0.40),
(2,'GS',0.30),
(2,'AS',0.30),
(2,'IMS',0.40);

insert into trxlog
(trx_id,login,symbol,t_date,action,num_shares,price,amount) values
---------------------------------------
(1,'mike',NULL,TO_DATE('2020-03-29,', 'YYYY-MM-DD'),'deposit',NULL,NULL,1000.00),
(2,'mike','MM',TO_DATE('2020-03-29', 'YYYY-MM-DD'),'buy',50,10.00,500.00),
(3,'mike','RE',TO_DATE('2020-03-29', 'YYYY-MM-DD'),'buy',50,10.00,500.00),
(4,'mike','MM',TO_DATE('2020-04-01', 'YYYY-MM-DD'),'sell',50,15.00,750.00);

         
CREATE OR REPLACE FUNCTION search_mutual_funds(s1 varchar(30) , s2 varchar(30) )
returns varchar(60)
as $$
    declare
    final varchar(60);
    begin
        select string_agg(symbol, ', ') into final
        from mutualfund
        where (description like ('%' || s1  || '%' || s2 || '%'));
        return ('[' || final || ']');
    end;
        $$language plpgsql;
