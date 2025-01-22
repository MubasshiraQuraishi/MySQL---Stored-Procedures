CREATE DATABASE RetailStore;

USE RetailStore;

CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    price DECIMAL(10, 2),
    quantity_in_stock INT
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(15)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    order_date DATE,
    customer_id INT,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE OrderDetails (
    order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    subtotal DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE Employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_name VARCHAR(100),
    job_title VARCHAR(50),
    salary DECIMAL(10, 2)
);

-- Insert sample data into Products table
INSERT INTO Products (product_name, price, quantity_in_stock)
VALUES 
('Laptop', 1200.00, 20),
('Smartphone', 800.00, 50),
('Tablet', 300.00, 30),
('Headphones', 100.00, 100),
('Smartwatch', 200.00, 40);

-- Insert sample data into Customers table
INSERT INTO Customers (customer_name, email, phone)
VALUES 
('Alice Johnson', 'alice.johnson@example.com', '1234567890'),
('Bob Smith', 'bob.smith@example.com', '0987654321'),
('Charlie Davis', 'charlie.davis@example.com', '1122334455'),
('Dana Lee', 'dana.lee@example.com', '6677889900'),
('Evan Brown', 'evan.brown@example.com', '4433221100');

-- Insert sample data into Orders table
INSERT INTO Orders (order_date, customer_id, total_amount)
VALUES 
('2024-01-01', 1, 2400.00),
('2024-01-03', 2, 1600.00),
('2024-01-05', 3, 600.00),
('2024-01-07', 4, 400.00),
('2024-01-10', 5, 1000.00);

-- Insert sample data into OrderDetails table
INSERT INTO OrderDetails (order_id, product_id, quantity, subtotal)
VALUES 
(1, 1, 2, 2400.00),
(2, 2, 2, 1600.00),
(3, 3, 2, 600.00),
(4, 4, 4, 400.00),
(5, 5, 5, 1000.00);

-- Insert sample data into Employees table
INSERT INTO Employees (employee_name, job_title, salary)
VALUES 
('Frank Miller', 'Manager', 60000.00),
('Grace Adams', 'Sales Associate', 40000.00),
('Hannah Wilson', 'Technician', 45000.00),
('Ian Thomas', 'Accountant', 50000.00),
('Julia Roberts', 'Cashier', 35000.00);


-- Retrieve Data:
-- Write a stored procedure to fetch all products with a quantity in stock below a specified threshold.
DELIMITER $$
CREATE procedure pr_first(p_quantity int)
BEGIN
	SELECT * FROM products 
    WHERE quantity_in_stock < p_quantity;
END $$
CALL pr_first(30);

-- Create a stored procedure to retrieve all orders placed by a specific customer.
DROP PROCEDURE IF EXISTS pr_second;
DELIMITER $$
CREATE procedure pr_second(p_customer_name VARCHAR(100))
BEGIN
	DECLARE v_customer_name VARCHAR(100);
	SELECT customer_name
    INTO v_customer_name
    FROM Customers WHERE p_customer_name = customer_name;
    
    IF v_customer_name = p_customer_name then 
		SELECT * FROM Orders o
		JOIN Customers c ON c.customer_id = o.customer_id
		WHERE customer_name = p_customer_name;
	ELSE 
		SELECT 'No Customer found';
	END IF;
END $$
CALL pr_second('Dana Lee');

-- Insert Operations:
-- Write a stored procedure to add a new customer to the Customers table.
DROP PROCEDURE IF EXISTS pr_third;
DELIMITER $$
CREATE PROCEDURE pr_third(p_customer_name VARCHAR(100), p_email VARCHAR(100), p_phone VARCHAR(100))
BEGIN
	INSERT INTO Customers (customer_name, email, phone)
    VALUES (p_customer_name, p_email, p_phone);
    
    SELECT * FROM Customers;
END $$
CALL pr_third('Amy Santiago', 'amy.santiago@example.com', '4586332154');

-- Create a stored procedure to place a new order and update the stock levels of the products involved.
DROP PROCEDURE IF EXISTS pr_fourth;
DELIMITER $$
CREATE PROCEDURE pr_fourth(p_product_name VARCHAR(100), p_quantity INT)
BEGIN
	DECLARE v_cnt			INT;
    DECLARE v_customer_id	INT;
    DECLARE v_price			DECIMAL(10,2);
    DECLARE v_order_id		INT;
    DECLARE v_product_id	INT;
    
	SELECT COUNT(*) INTO v_cnt FROM Products p
    WHERE product_name = p_product_name
    AND quantity_in_stock >= p_quantity;
    
    SELECT c.customer_id, p.price, o.order_id, p.product_id 
	INTO v_customer_id, v_price, v_order_id, v_product_id
	FROM Customers c
	JOIN Orders o ON o.customer_id = c.customer_id
	JOIN Orderdetails od ON od.order_id = o.order_id
	JOIN Products p ON p.product_id = od.product_id
	WHERE p.product_name = p_product_name
	LIMIT 1;
		
    IF v_cnt > 0 THEN
		INSERT INTO Orders (order_date, customer_id, total_amount)
        VALUES (CURRENT_DATE(), v_customer_id, v_price);
        
        SET v_order_id = LAST_INSERT_ID();
        
        INSERT INTO Orderdetails (order_id, product_id, quantity, subtotal)
        VALUES (v_order_id, v_product_id, p_quantity, (p_quantity * v_price));
        
        UPDATE Products 
        SET quantity_in_stock = quantity_in_stock - p_quantity
        WHERE product_name = p_product_name;
        
	ELSE 
		SELECT 'Insufficient Quantity!';
	END IF;
END $$

CALL pr_fourth('Tablet', 10);

-- Write a stored procedure to update the price of a product based on its product ID.
DROP PROCEDURE IF EXISTS pr_fifth;
DELIMITER $$
CREATE PROCEDURE pr_fifth(p_product_id INT)
BEGIN
	UPDATE Products
    SET price = 250.00
    WHERE product_id = p_product_id;
END $$
CALL pr_fifth(4);

-- Create a stored procedure to increase the salaries of employees in a specific job title by a certain percentage.
DROP PROCEDURE IF EXISTS pr_sixth;
DELIMITER $$
CREATE PROCEDURE pr_sixth(p_job_title VARCHAR(100), p_percentage INT)
BEGIN
	UPDATE Employees
    SET salary = salary + salary * (p_percentage/100)
    WHERE job_title = p_job_title;
END $$

CALL pr_sixth('Technician', 3);

-- Delete Operations:
-- Write a stored procedure to delete a customer and all their associated orders and order details.
DROP PROCEDURE IF EXISTS pr_seventh;
DELIMITER $$
CREATE PROCEDURE pr_seventh(p_customer_id INT)
BEGIN
	DELETE oi FROM Orderdetails oi
    INNER JOIN Orders o ON o.order_id = oi.order_id
    WHERE customer_id = p_customer_id;
    
    DELETE FROM Orders
    WHERE Customer_id = p_customer_id;
    
	DELETE FROM Customer
    WHERE customer_id = p_customer_id;
END $$

CALL pr_seventh(2);

-- Create a stored procedure to remove a product from the Products table after confirming it has no associated orders.
DROP PROCEDURE IF EXISTS pr_eighth;
DELIMITER $$
CREATE PROCEDURE pr_eighth(p_product_id INT)
BEGIN
	DECLARE v_cnt	INT;
    
    SELECT COUNT(*) INTO v_cnt FROM Orderdetails WHERE product_id = p_product_id;
    
    IF v_cnt = 0 THEN
		DELETE FROM Products
        WHERE product_id = p_product_id;
	ELSE 
		SELECT 'Orders exists';
	END IF;
END $$

CALL pr_eighth(4);

-- Calculations:
-- Write a stored procedure to calculate the total sales for a specific product within a given date range.
DROP PROCEDURE IF EXISTS pr_ninth;
DELIMITER $$
CREATE PROCEDURE pr_ninth(p_product_id INT, p_start_date DATE, p_end_date DATE)
BEGIN
	DECLARE total_sales		DECIMAL(10, 2);
    
	SELECT SUM(oi.subtotal) INTO total_sales
    FROM Orderdetails oi
    JOIN Orders o ON o.order_id = oi.order_id
    WHERE oi.product_id = p_product_id
    AND order_date BETWEEN p_start_date AND p_end_date;
    SELECT total_sales AS TotalSales;
END $$

CALL pr_ninth(3, '2024-01-05', '2024-01-10');

-- Create a stored procedure to calculate and return the total salary expense for all employees.
DROP PROCEDURE IF EXISTS pr_tenth;
DELIMITER $$
CREATE PROCEDURE pr_tenth()
BEGIN
	DECLARE v_salary	DECIMAL(10, 2);
    DECLARE v_employee_name	VARCHAR(200);
    
	SELECT Salary, employee_name
    INTO v_salary, v_employee_name
    FROM Employees
    LIMIT 1;
    
    SELECT v_salary AS Salary, v_employee_name AS employee_name;
END $$

CALL pr_tenth();

-- Conditional Logic:
-- Write a stored procedure to check if a product is available in sufficient quantity before adding it to an order.
DROP PROCEDURE IF EXISTS pr_eleventh
DELIMITER $$
CREATE PROCEDURE pr_eleventh(p_product_id INT, p_quantity INT)
BEGIN
	DECLARE v_cnt	INT;
    DECLARE v_customer_id	INT;
    DECLARE v_order_id	INT;
    DECLARE v_product_id	INT;
    DECLARE v_price		DECIMAL(10, 2);
    SELECT COUNT(*) INTO v_cnt 
    FROM Products 
    WHERE product_id = p_product_id AND quantity_in_stock >= p_quantity;
    
    SELECT c.customer_id, p.price, o.order_id, p.product_id 
	INTO v_customer_id, v_price, v_order_id, v_product_id
	FROM Customers c
	JOIN Orders o ON o.customer_id = c.customer_id
	JOIN Orderdetails od ON od.order_id = o.order_id
	JOIN Products p ON p.product_id = od.product_id
	WHERE p.product_id = p_product_id
	LIMIT 1;
    
    IF v_cnt > 0 THEN
		INSERT INTO Orders (order_date, customer_id, total_amount)
        VALUES (CURRENT_DATE(), v_customer_id, v_price);
        
        SET v_order_id = LAST_INSERT_ID();
        
        INSERT INTO Orderdetails (order_id, product_id, quantity, subtotal)
        VALUES(v_order_id, v_product_id, p_quantity, (p_quantity * v_price));
        
        UPDATE Products SET quantity_in_stock = quantity_in_stock - p_quantity;
	ELSE
		SELECT 'Insufficient quantity';
	END IF;
END $$

CALL pr_eleventh(2, 5);

-- Create a stored procedure to assign a discount to an order if the total amount exceeds a certain value.
DROP PROCEDURE IF EXISTS pr_twelveth
DELIMITER $$
CREATE PROCEDURE pr_twelveth(p_product_name VARCHAR(1000), p_value INT)
BEGIN
    DECLARE v_order_id	INT;
    DECLARE v_product_id	INT;
    DECLARE v_total_amount 	DECIMAL(10, 2);
    DECLARE v_customer_id	INT;
    DECLARE v_subtotal	DECIMAL(10, 2);
    DECLARE v_quantity INT;
    DECLARE v_discount_applied BOOLEAN DEFAULT FALSE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
		SELECT CONCAT('No records found for product: ', p_product_name, 'or total amount above threshold: ', p_value) AS ERROR_MESSAGE;
	END;
    SELECT c.customer_id, o.total_amount, o.order_id, p.product_id, od.subtotal, od.quantity
	INTO  v_customer_id, v_total_amount, v_order_id, v_product_id, v_subtotal, v_quantity
    FROM Customers c JOIN Orders o ON o.customer_id = c.customer_id
	JOIN Orderdetails od ON od.order_id = o.order_id
	JOIN Products p ON p.product_id = od.product_id
	WHERE p.product_name = p_product_name
    AND o.total_amount >= p_value
    LIMIT 1;
    
	IF v_total_amount >= p_value THEN
		INSERT INTO Orders (order_date, customer_id, total_amount)
		VALUES (CURRENT_DATE(), v_customer_id, v_total_amount);
			
		SET v_order_id = LAST_INSERT_ID();
			
		INSERT INTO Orderdetails (order_id, product_id, quantity, subtotal)
		VALUES(v_order_id, v_product_id, v_quantity, v_subtotal - (v_subtotal * 0.2));
        
        SET v_discount_applied = TRUE;
	END IF;
END $$

CALL pr_twelveth('Tablet', 600);

-- Transactions:
-- Write a stored procedure to handle the process of placing an order, ensuring it either succeeds fully or rolls back if an error occurs.
DROP PROCEDURE IF EXISTS pr_thirteenth;
DELIMITER $$
CREATE PROCEDURE pr_thirteenth(IN p_quantity INT, OUT o_order_id INT)
BEGIN
	DECLARE v_customer_id	INT;
    DECLARE v_order_id	INT;
    DECLARE v_product_id	INT;
    DECLARE v_price		DECIMAL(10, 2);
    DECLARE v_stock	INT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction failed, rolling back.';
	END;
    
    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
		ROLLBACK;
        SIGNAL SQLSTATE '45000'	
        SET MESSAGE_TEXT = 'Transaction encountered a warning, rolling back.';
	END;
    
    START TRANSACTION;
    
    SELECT c.customer_id, p.price, o.order_id, p.product_id, p.quantity_in_stock 
	INTO v_customer_id, v_price, v_order_id, v_product_id, v_stock
	FROM Customers c
	JOIN Orders o ON o.customer_id = c.customer_id
	JOIN Orderdetails od ON od.order_id = o.order_id
	JOIN Products p ON p.product_id = od.product_id
    WHERE p.quantity_in_stock >= p_quantity
	LIMIT 1;
    
    IF v_stock >= p_quantity THEN
		INSERT INTO Orders (order_date, customer_id, total_amount)
        VALUES (CURRENT_DATE(), v_customer_id, (p_quantity * v_price));
        
        SET o_order_id = LAST_INSERT_ID();
        
        INSERT INTO Orderdetails (order_id, product_id, quantity, subtotal)
        VALUES(o_order_id, v_product_id, p_quantity, (p_quantity * v_price));
        
        UPDATE Products SET quantity_in_stock = quantity_in_stock - p_quantity
        WHERE product_id = v_product_id;
	COMMIT;
	ELSE
		SELECT 'Insufficient stock for the product.';
	END IF;
END $$

SET @order_id = 0;
CALL pr_thirteenth(5, @order_id);
SELECT @order_id AS NewOrderID

-- Create a stored procedure to transfer an employee to a new job title and update their salary in a single transaction.
DROP PROCEDURE IF EXISTS pr_fourteenth;
DELIMITER $$
CREATE PROCEDURE pr_fourteenth(p_employee_name	VARCHAR(100))
BEGIN
	START TRANSACTION;
		UPDATE Employees
		SET Salary = (Salary + (Salary * 0.25))
		WHERE employee_name = p_employee_name;
    COMMIT;
END $$

CALL pr_fourteenth('Julia Roberts')

-- Loops:
-- Write a stored procedure to loop through all employees and give a bonus to those whose salaries are below a specified amount.
ALTER TABLE Employees
ADD Bonus DECIMAL(10, 2);

DROP PROCEDURE IF EXISTS pr_fifteenth;
DELIMITER $$
CREATE PROCEDURE pr_fifteenth(IN p_bonus_threshold DECIMAL(10, 2))
BEGIN
	DECLARE v_employee_id	INT;
	DECLARE v_salary	DECIMAL(10, 2);
    DECLARE done INT DEFAULT 0;
    
    DECLARE emp_cursor cursor for
    SELECT employee_id, salary FROM Employees;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN emp_cursor;
		read_loop: LOOP
			FETCH emp_cursor INTO v_employee_id, v_salary;
		
        IF done THEN
			LEAVE read_loop;
		END IF;
        
        IF v_salary < p_bonus_threshold THEN
			UPDATE Employees
			SET bonus = v_salary * 0.10
            WHERE employee_id = v_employee_id;
		ELSE
			UPDATE Employees
			SET bonus = 0.0
            WHERE employee_id = v_employee_id;
		END IF;
	END LOOP;
    CLOSE emp_cursor;
END $$

CALL pr_fifteenth(50000.00);

SELECT * FROM Employees;
-- Create a stored procedure to generate a report of all customers and their total number of orders.
DROP PROCEDURE IF EXISTS pr_sixteenth
DELIMITER $$
CREATE PROCEDURE pr_sixteenth()
BEGIN

	DECLARE v_orders	INT;
    DECLARE v_customer_id	INT;
    DECLARE v_customer_name	VARCHAR(100);
    DECLARE v_email	VARCHAR(100);
    DECLARE v_phone	VARCHAR(15);
    DECLARE done INT DEFAULT 0;
    
    DECLARE rep_cursor CURSOR FOR 
	SELECT COUNT(DISTINCT o.order_id) AS total_orders, c.customer_id, c.customer_name, c.email, c.phone
    FROM Customers c
    JOIN Orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_customer_summary (
        customer_id INT,
        customer_name VARCHAR(100),
        email VARCHAR(100),
        phone VARCHAR(15),
        total_orders INT
    );
    
    OPEN rep_cursor;
		read_loop : LOOP
        FETCH rep_cursor INTO v_orders, v_customer_id, v_customer_name, v_email, v_phone;
        
        IF done THEN
			LEAVE read_loop;
		END IF;
        INSERT INTO temp_customer_summary (customer_id, customer_name, email, phone, total_orders)
        VALUES (v_customer_id, v_customer_name, v_email, v_phone, v_orders);
        END LOOP;
	CLOSE rep_cursor;
    SELECT * FROM temp_customer_summary;
END $$

CALL pr_sixteenth();

-- 1. Order Processing
/*Write a stored procedure to process an order for a specific product. The procedure should:
Accept inputs: p_product_id, p_customer_id, p_quantity.
Check if sufficient stock is available.
If stock is available, create a new order and update the quantity_in_stock in the Products table.
If stock is insufficient, raise an error message.*/
DELIMITER $$
CREATE PROCEDURE pr_seventeenth(p_product_id INT, p_customer_id INT, p_quantity INT)
BEGIN
	DECLARE v_cnt	INT;
    DECLARE v_customer_id	INT;
    DECLARE v_order_id	INT;
    DECLARE v_product_id	INT;
    DECLARE v_price		DECIMAL(10, 2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			ROLLBACK;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Transaction failed, rolling back.';
		END;
        
    SELECT COUNT(*) INTO v_cnt 
    FROM Products 
    WHERE product_id = p_product_id AND quantity_in_stock >= p_quantity;
    
    IF v_cnt > 0 THEN
		SELECT c.customer_id, p.price, o.order_id, p.product_id 
		INTO v_customer_id, v_price, v_order_id, v_product_id
		FROM Customers c
		JOIN Orders o ON o.customer_id = c.customer_id
		JOIN Orderdetails od ON od.order_id = o.order_id
		JOIN Products p ON p.product_id = od.product_id
		WHERE p.product_id = p_product_id
		LIMIT 1;
    
		INSERT INTO Orders (order_date, customer_id, total_amount)
        VALUES (CURRENT_DATE(), p_customer_id, v_price);
        
        SET v_order_id = LAST_INSERT_ID();
        
        INSERT INTO Orderdetails (order_id, product_id, quantity, subtotal)
        VALUES(v_order_id, v_product_id, p_quantity, (p_quantity * v_price));
        
        UPDATE Products SET quantity_in_stock = quantity_in_stock - p_quantity;
	COMMIT;
	END IF;
END $$

CALL pr_seventeenth(5, 3, 1)

/* 2. Total Sales for a Product
Write a stored procedure to calculate the total sales for a specific product within a given date range. The procedure should:
Accept inputs: p_product_id, p_start_date, p_end_date.
Return the total quantity sold and the total revenue for that product.*/
DROP PROCEDURE IF EXISTS pr_eighteenth
DELIMITER $$
CREATE PROCEDURE pr_eighteenth(p_product_id INT, p_start_date DATE, p_end_date DATE)
BEGIN
	DECLARE v_revenue	DECIMAL(10, 2);
    DECLARE v_quantity_sold	INT;
        
	SELECT SUM(od.subtotal), SUM(od.quantity)
	INTO v_revenue, v_quantity_sold
	FROM Products p
	JOIN Orderdetails od ON od.product_id = p.product_id
    JOIN Orders o ON o.order_id = od.order_id
	WHERE p.product_id = p_product_id AND o.order_date BETWEEN p_start_date AND p_end_date;
    
    SELECT v_revenue AS total_revenue, v_quantity_sold AS total_quantity_sold;
END $$
CALL pr_eighteenth(5, '2024-01-01', '2025-01-15')

/*4. Restock Notification
Write a stored procedure to identify products that need restocking:
Accept input: p_threshold (minimum quantity to maintain in stock).
Return a list of products where quantity_in_stock is less than the threshold.*/
DROP PROCEDURE IF EXISTS pr_nineteenth
DELIMITER $$
CREATE PROCEDURE pr_nineteenth(p_minimum_quantity INT)
BEGIN
    
	SELECT product_name, quantity_in_stock
    FROM Products
    WHERE quantity_in_stock < p_minimum_quantity;

END $$
CALL pr_nineteenth(20);

/*5. Customer Purchase Summary
Write a stored procedure to generate a purchase summary for a customer:
Accept input: p_customer_id.
Return the total amount spent, the number of orders placed, and the most expensive product they purchased.*/
DROP PROCEDURE IF EXISTS pr_twenty
DELIMITER $$
CREATE PROCEDURE pr_twenty(p_customer_id INT)
BEGIN
	DECLARE v_subtotal	DECIMAL(10, 2);
    DECLARE v_order_id	INT;
    DECLARE	v_expensive_product	VARCHAR(100);
	SELECT SUM(od.subtotal), COUNT(DISTINCT o.order_id)
	INTO v_subtotal, v_order_id
	FROM Orders o
	JOIN Orderdetails od ON od.order_id = o.order_id
    JOIN Products p ON p.product_id = od.product_id
    JOIN Customers c ON c.customer_id = o.customer_id
    WHERE c.customer_id = p_customer_id;
	
	SELECT p.product_name
	INTO v_expensive_product
	FROM Products p
	JOIN Orderdetails od ON od.product_id = p.product_id
    JOIN Orders o ON o.order_id = od.order_id
    JOIN Customers c ON c.customer_id = o.customer_id
    WHERE c.customer_id = p_customer_id
    ORDER BY p.price DESC
    LIMIT 1;
	
    SELECT v_subtotal AS amount_paid, v_order_id AS total_orders, v_expensive_product AS Most_expensive_order;
END $$

CALL pr_twenty(2)

/*6. Refund an Order
Write a stored procedure to handle order refunds:
Accept input: p_order_id.
Calculate the refund amount (total amount of the order).
Update the stock levels for the products in the refunded order.
Delete the order and its details from the database.*/
DROP PROCEDURE IF EXISTS pr_twentyone
DELIMITER $$
CREATE PROCEDURE pr_twentyone(p_order_id INT)
BEGIN
	DECLARE v_quantity	INT;
    
	SELECT od.quantity
    INTO v_quantity
    FROM orderdetails od
    JOIN orders o ON o.order_id = od.order_id
    JOIN products p ON p.product_id = od.product_id
    WHERE od.order_id = p_order_id;
    
    UPDATE Products
    SET quantity_in_stock = quantity_in_stock + v_quantity;
	
    DELETE FROM orderdetails
    WHERE order_id = p_order_id;
    
    DELETE FROM orders
    WHERE order_id = p_order_id;
    
END $$
CALL pr_twentyone(10);

/*7. Best-Selling Products
Write a stored procedure to identify the best-selling products:
Accept input: p_top_n (number of top products to return).
Return a list of the top N products based on total quantity sold.*/
DROP PROCEDURE IF EXISTS pr_twentytwo
DELIMITER $$
CREATE PROCEDURE pr_twentytwo(IN p_top_n INT)
BEGIN
	SELECT p.product_name AS Product_Name, SUM(od.quantity) AS Total_Quantity_Sold
    FROM Products p
    JOIN orderdetails od ON od.product_id = p.product_id
    GROUP BY p.product_id
    ORDER BY Total_Quantity_Sold DESC
    LIMIT p_top_n;
END $$

CALL pr_twentytwo(5)
