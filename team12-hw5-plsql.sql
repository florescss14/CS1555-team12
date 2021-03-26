
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