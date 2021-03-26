-- Andrew Imredy api5, Ted Balashov thb46, Christopher Flores cwf24

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
