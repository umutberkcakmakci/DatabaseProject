--PRTINCIPAL QUERIES

--QUERY 1
-- For each store, get its id, the list of products that need to be bought (id and name) and the minimum quantity

SELECT s.storeid AS store_id, p.productid AS product_id, p.name AS product_name,
COALESCE(s.reorderlevel - (s.stockquantity + COALESCE(SUM(sp.quantity), 0)), 0) AS
min_quantity_to_order
    FROM Stores AS s INNER JOIN Product AS p
        ON s.productid = p.productid
    LEFT JOIN Supplies AS sp
        ON s.productid = sp.productid AND s.storeid = sp.storeid
    GROUP BY s.storeid, p.productid, s.reorderlevel, s.stockquantity
    HAVING s.reorderlevel > (s.stockquantity + COALESCE(SUM(sp.quantity), 0));

--QUERY 2
-- For each customer in the loyalty program, get its email, the list of products that currently have a promotion on their preferred store, the discount info and the start and end dates of the promotion

SELECT c.email AS customer_email, p.name AS product_name, pr.discountinfo AS
discount_info, pr.startenddates AS promotion_dates
    FROM Customer c INNER JOIN Store AS s
        ON c.storeid = s.storeid
    INNER JOIN Promotion AS pr 
        ON s.storeid = pr.storeid
    INNER JOIN Product AS p
        ON pr.productid = p.productid
    WHERE pr.startenddates @> CURRENT_DATE;

--QUERY 3
-- For each cashier, get their surname and name, the id of the store they work for and how many times has a customer used the loyalty program when they were attending at the register, and how many of them were unique customers

SELECT storeid, surname, name, total_receipts, unique_customers
    FROM (SELECT e.surname, e.name, e.storeid, COUNT(r.receiptid) AS total_receipts,
    COUNT(DISTINCT b.email) AS unique_customers
            FROM Employee AS e INNER JOIN Receipt AS r
                ON e.employeeid = r.employeeid
            LEFT JOIN BelongsTo AS b
                ON r.receiptid = b.receiptid
            WHERE e.position = 'Cashier'
            GROUP BY e.surname, e.name, e.storeid)
ORDER BY storeid;

--QUERY 4
-- For each store, get its id and the percentage of products bought ordered by category during the current month

SELECT store_id, category_name, ROUND(100*category_quantity/total_quantity,2) AS percentage
    FROM (SELECT s.storeid AS store_id, c.categoryname AS category_name,
    SUM(COALESCE(co.quantity, 0)) AS category_quantity,
    SUM(SUM(COALESCE(co.quantity, 0))) OVER (PARTITION BY s.storeid) AS total_quantity
            FROM Category AS c LEFT JOIN Product AS p
                ON c.categoryname = p.category
            LEFT JOIN Contains AS co
                ON p.productid = co.productid
            LEFT JOIN Receipt AS r
                ON co.receiptid = r.receiptid
            LEFT JOIN Store AS s
                ON r.storeid = s.storeid
            WHERE DATE_TRUNC('month', r.date) = DATE_TRUNC('month', CURRENT_DATE)
            GROUP BY s.storeid, c.categoryname);

--QUERY 5
-- Obtain the category from which women between 40 and 60 years old buy the most products (and quantity)

SELECT categoryname, max_quantity
    FROM (SELECT p.category AS categoryname, SUM(co.quantity) AS max_quantity
        FROM Contains AS co INNER JOIN Product AS p
            ON co.productid = p.productid
        INNER JOIN Receipt AS r
            ON co.receiptid = r.receiptid
        INNER JOIN BelongsTo AS b
            ON co.receiptid = b.receiptid
        INNER JOIN Customer AS c
            ON b.email = c.email
        WHERE gender = 'Female' AND dateofbirth BETWEEN CURRENT_DATE - INTERVAL '60
        years' AND CURRENT_DATE - INTERVAL '40 years'
        GROUP BY p.category)
    WHERE max_quantity = (SELECT MAX(total_quantity) AS max_quantity
                            FROM (SELECT p.category AS categoryname, SUM(co.quantity) 
                            AS total_quantity
                                FROM Contains AS co INNER JOIN Product AS p
                                    ON co.productid = p.productid
                                INNER JOIN Receipt AS r
                                    ON co.receiptid = r.receiptid
                                INNER JOIN BelongsTo AS b
                                    ON co.receiptid = b.receiptid
                                INNER JOIN Customer AS c
                                    ON b.email = c.email
                                WHERE gender = 'Female' AND dateofbirth BETWEEN 
                                CURRENT_DATE - INTERVAL '60
                                years' AND CURRENT_DATE - INTERVAL '40 years'
                                GROUP BY p.category));