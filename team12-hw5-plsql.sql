
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

DROP PROCEDURE IF EXISTS buy_on_price(fund_symbol varchar, fund_price decimal);
--Question 6
--assume closing prices are not changed retroactively, only that tuples are added at the end of every day
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