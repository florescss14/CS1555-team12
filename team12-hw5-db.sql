

DROP TABLE IF EXISTS MUTUALFUND;
DROP TABLE IF EXISTS CLOSING_PRICE;
DROP TABLE IF EXISTS CUSTOMER;
DROP TABLE IF EXISTS ALLOCATION;
DROP TABLE IF EXISTS PREFERS;
DROP TABLE IF EXISTS ADMINISTRATOR;
DROP TABLE IF EXISTS TRXLOG;
DROP TABLE IF EXISTS MUTUAL_DATE;

CREATE TABLE MUTUALFUND(
    symbol varchar(20),
    name varchar(30),
    description varchar(100),
    category varchar(10),
    c_date date,
    CONSTRAINT MUTUALFUND_PK
        PRIMARY KEY (symbol)
);

CREATE TABLE CLOSING_PRICE(
    symbol varchar(20),
    price decimal(10, 2),
    p_date date,
    CONSTRAINT CLOSING_PRICE_PK
        PRIMARY KEY (symbol),
    CONSTRAINT CLOSING_PRICE_FK
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

CREATE TABLE CUSTOMER(
    login varchar(10),
    name varchar(20),
    email varchar(30),
    address varchar(30),
    password varchar(10),
    balance decimal(10, 2),
    CONSTRAINT CUSTOMER_PK
        PRIMARY KEY (login)
);

CREATE TABLE ALLOCATION(
    allocation_no int,
    login varchar(10),
    p_date date,
    CONSTRAINT ALLOCATION_PK
        PRIMARY KEY (allocation_no),
    CONSTRAINT ALLOCATION_FK
        FOREIGN KEY (login) REFERENCES CUSTOMER (login)
);

CREATE TABLE PREFERS(
    allocation_no int,
    symbol varchar(20),
    percentage decimal(3, 2),
    CONSTRAINT PREFERS_FK
        PRIMARY KEY (allocation_no, symbol),
    CONSTRAINT PREFERS_FK1
        FOREIGN KEY (allocation_no) REFERENCES ALLOCATION (allocation_no),
    CONSTRAINT PREFERS_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

CREATE TABLE OWNS(
    login varchar(10),
    symbol varchar(20),
    shares int,
    CONSTRAINT OWNS_PK
        PRIMARY KEY (login, symbol),
    CONSTRAINT OWNS_FK1
        FOREIGN KEY (login) REFERENCES CUSTOMER (login),
    CONSTRAINT OWNS_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

CREATE TABLE ADMINISTRATOR(
    login varchar(10),
    name varchar(20),
    email varchar(30),
    address varchar(30),
    password varchar(10),
    CONSTRAINT ADMINISTRATOR_PK
        PRIMARY KEY (login)
);

CREATE TABLE TRXLOG(
     trx_id serial,
    login varchar(10),
    symbol varchar(20),
    t_date date,
    action varchar(10),
    num_shares int,
    price decimal(10, 2),
    amount decimal(10, 2),
    CONSTRAINT TRXLOG_PK
        PRIMARY KEY (trx_id),
    CONSTRAINT TRXLOG_FK1
        FOREIGN KEY (login) REFERENCES CUSTOMER (login),
    CONSTRAINT TRXLOG_FK2
        FOREIGN KEY (symbol) REFERENCES MUTUALFUND (symbol)
);

CREATE TABLE MUTUAL_DATE(
    p_date date,
    CONSTRAINT MUTUAL_DATE_PK
        PRIMARY KEY (p_date)
);