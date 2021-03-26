
-- Question 5
CREATE OR REPLACE function buying_on_date()
returns trigger
as $$
    declare
    minimum owns%rowtype;
    least_owned_fund varchar(20);
    shares_to_buy decimal(10, 2);
    buyer_login varchar(10);
    begin
        select a.login, symbol, a.shares as shares into minimum
        from
        (select login, min(shares) as shares
        from OWNS
        GROUP BY login) as a LEFT JOIN
        (select *
        from OWNS) as b
        on a.login = b.login and a.shares = b.shares;

        SELECT into shares_to_buy
        balance from customer where CUSTOMER.login = minimum.login;
        shares_to_buy = floor(shares_to_buy / minimum.shares);

        call buy_shares(minimum.login, minimum.symbol, shares_to_buy);
        return new;
    end;

$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS buy_on_date ON MUTUAL_DATE CASCADE;
CREATE TRIGGER buy_on_date
    AFTER UPDATE
    ON MUTUAL_DATE
    FOR EACH ROW
    EXECUTE PROCEDURE buying_on_date();

INSERT INTO MUTUAL_DATE values (TO_DATE('2020-04-06', 'YYYY-MM-DD'));

select buy_shares('mike'::varchar(10), 'RE'::varchar(20), 1);