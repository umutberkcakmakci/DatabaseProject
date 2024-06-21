-- Creation of the Mercadone database schema

-- ##########################################################################################
-- ## Database creation                                                                    ##
-- ##########################################################################################

-- Delete pre-existent database instance (if any)
DROP DATABASE IF EXISTS Mercadone;

-- Create the database
CREATE DATABASE Mercadone ENCODING 'UTF-8';

-- ##########################################################################################
-- ## Database connection                                                                  ##
-- ##########################################################################################

-- Connect to the database
\connect Mercadone

-- ##########################################################################################
-- ## Domains creation                                                                     ##
-- ##########################################################################################

-- Create new domains 
CREATE DOMAIN passwd AS VARCHAR(254) 
 CONSTRAINT properpassword CHECK (((VALUE)::text~* '[A-Za-z0-9._%!]{8,}'::text)); 
 
CREATE DOMAIN emailaddress AS VARCHAR(254) 
 CONSTRAINT properemail CHECK (((VALUE)::text~* '^[A-Za-z0-9._%]+@[A-Za-z0-9.]+[.][A-Za-z]+$'::text)); 


-- ##########################################################################################
-- ## Types creation                                                                       ##
-- ##########################################################################################

-- Create new types
CREATE TYPE timerange AS RANGE (subtype = time);


CREATE TYPE gender AS ENUM ( 
    'Male', 
    'Female', 
    'Other', 
    'I prefer not to say'
);


CREATE TYPE paymentmethod AS ENUM ( 
    'CASH', 
    'CARD'
);


-- ##########################################################################################
-- ## Tables creation                                                                      ##
-- ##########################################################################################

-- This table represents a category
CREATE TABLE Category (
	categoryname CHARACTER VARYING (250) PRIMARY KEY
);

COMMENT ON TABLE Category IS 'Categories to which products belong.';
COMMENT ON COLUMN Category.categoryname IS 'Unique identifier for the category.';


-- This table represents a product
CREATE TABLE Product (
	productid SERIAL PRIMARY KEY,
	upc BIGINT NOT NULL,
	name CHARACTER VARYING (250) NOT NULL,
	vat REAL NOT NULL,
	price DECIMAL(19, 4) NOT NULL,
	category CHARACTER VARYING (250) NOT NULL,
	FOREIGN KEY ( category ) REFERENCES Category (categoryname) 
);

COMMENT ON TABLE Product IS 'Represents a product.';
COMMENT ON COLUMN Product.productid IS 'Unique identifier for the product.';
COMMENT ON COLUMN Product.upc IS 'Universal Product Code.';
COMMENT ON COLUMN Product.name IS 'Name of the product.';
COMMENT ON COLUMN Product.vat IS 'Value Added Tax.';
COMMENT ON COLUMN Product.price IS 'Price of the product.';
COMMENT ON COLUMN Product.category IS 'Unique identifier for the category of the product.';


-- This table represents a store
CREATE TABLE Store (
	storeid SERIAL PRIMARY KEY,
	location CHARACTER VARYING (250) NOT NULL,
	schedule timerange[7] NOT NULL
);

COMMENT ON TABLE Store IS 'Represents a store.';
COMMENT ON COLUMN Store.storeid IS 'Unique identifier for the store.';
COMMENT ON COLUMN Store.location IS 'Address of the store.';
COMMENT ON COLUMN Store.schedule IS 'Timetable of the store.';


-- This table represents the quantity of a specific product stored in a store and its re-order level
CREATE TABLE Stores (
	productid SERIAL,
	storeid SERIAL,
	stockquantity INTEGER NOT NULL,
	reorderlevel INTEGER NOT NULL,
	FOREIGN KEY ( productid ) REFERENCES Product (productid),
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid),
	PRIMARY KEY ( productid, storeid )
);

COMMENT ON TABLE Stores IS 'Represents the quantity of a specific product stored in a store
and its re-order level.';
COMMENT ON COLUMN Stores.productid IS 'Unique identifier for the product.';
COMMENT ON COLUMN Stores.storeid IS 'Unique identifier for the store.';
COMMENT ON COLUMN Stores.stockquantity IS 'Quantity available in the store.';
COMMENT ON COLUMN Stores.reorderlevel IS 'Minimum quantity that must be in the store.';


-- This table represents the discounts for the products in a store
CREATE TABLE Promotion (
	productid SERIAL,
	storeid SERIAL,
	startenddates DATERANGE NOT NULL,
	discountinfo CHARACTER VARYING (250) NOT NULL,
	FOREIGN KEY ( productid ) REFERENCES Product (productid),
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid),
	PRIMARY KEY ( productid, storeid )
);

COMMENT ON TABLE Promotion IS 'Represents a promotion.';
COMMENT ON COLUMN Promotion.productid IS 'Unique identifier for the product.';
COMMENT ON COLUMN Promotion.storeid IS 'Unique identifier for the store.';
COMMENT ON COLUMN Promotion.startenddates IS 'Initial and final date of a promotion.';
COMMENT ON COLUMN Promotion.discountinfo IS 'Information or description of the promotion.';


-- This table represents a supplier
CREATE TABLE Supplier (
	supplierid SERIAL PRIMARY KEY,
	address CHARACTER VARYING (250) NOT NULL,
	email EMAILADDRESS NOT NULL,
	contractdetails CHARACTER VARYING (250) NOT NULL,
	phone CHARACTER VARYING (25) NOT NULL
);

COMMENT ON TABLE Supplier IS 'Represents a supplier.';
COMMENT ON COLUMN Supplier.supplierid IS 'Unique identifier for the supplier.';
COMMENT ON COLUMN Supplier.address IS 'Address of the supplier.';
COMMENT ON COLUMN Supplier.email IS 'Email of the supplier.';
COMMENT ON COLUMN Supplier.contractdetails IS 'Details and description of the contract between store 
and supplier.';
COMMENT ON COLUMN Supplier.phone IS 'Phone number of the supplier.';


-- This table represents the quantity of a specific product supply by a supplier to a store
CREATE TABLE Supplies (
	productid SERIAL,
	storeid SERIAL,
	supplierid SERIAL,
	quantity INTEGER NOT NULL,
	FOREIGN KEY ( productid ) REFERENCES Product (productid),
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid),
	FOREIGN KEY ( supplierid ) REFERENCES Supplier (supplierid),
	PRIMARY KEY ( productid, storeid, supplierid )
);

COMMENT ON TABLE Supplies IS 'Represents the quantity of a specific product supply 
by a supplier to a store.';
COMMENT ON COLUMN Supplies.productid IS 'Unique identifier for the product.';
COMMENT ON COLUMN Supplies.storeid IS 'Unique identifier for the store.';
COMMENT ON COLUMN Supplies.supplierid IS 'Unique identifier for the supplier.';
COMMENT ON COLUMN Supplies.quantity IS 'Quantity ordered.';


-- This table represents a position
CREATE TABLE Position (
	positionname CHARACTER VARYING (250) PRIMARY KEY
);

COMMENT ON TABLE Position IS 'A title of an employee.';
COMMENT ON COLUMN Position.positionname IS 'Unique identifier for the position.';


-- This table represents an employee
CREATE TABLE Employee (
	employeeid SERIAL PRIMARY KEY,
	name CHARACTER VARYING (250) NOT NULL,
	surname CHARACTER VARYING (250) NOT NULL,
	salary DECIMAL(19, 4) NOT NULL,
	position CHARACTER VARYING (250) NOT NULL,
	storeid SERIAL NOT NULL,
	FOREIGN KEY ( position ) REFERENCES Position (positionname),
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid)
);

COMMENT ON TABLE Employee IS 'Represents an employee.';
COMMENT ON COLUMN Employee.employeeid IS 'Unique identifier for the employee.';
COMMENT ON COLUMN Employee.name IS 'Name of the employee.';
COMMENT ON COLUMN Employee.surname IS 'Surname of the employee.';
COMMENT ON COLUMN Employee.salary IS 'Salary of the employee.';
COMMENT ON COLUMN Employee.position IS 'Unique identifier for the position of the employee.';
COMMENT ON COLUMN Employee.storeid IS 'Unique identifier for the store where the employee works.';


-- This table represents a receipt
CREATE TABLE Receipt (
	receiptid SERIAL PRIMARY KEY,
	totalamount DECIMAL(19, 4) NOT NULL,
	date TIMESTAMP NOT NULL,
	paymentmethod PAYMENTMETHOD NOT NULL,
	storeid SERIAL NOT NULL,
	employeeid SERIAL NOT NULL,
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid),
	FOREIGN KEY ( employeeid ) REFERENCES Employee (employeeid)
);

COMMENT ON TABLE Receipt IS 'Represents a receipt.';
COMMENT ON COLUMN Receipt.receiptid IS 'Unique identifier for the receipt.';
COMMENT ON COLUMN Receipt.totalamount IS 'Total price of the purchase.';
COMMENT ON COLUMN Receipt.date IS 'Date of the purchase.';
COMMENT ON COLUMN Receipt.paymentmethod IS 'Type of payment used.';
COMMENT ON COLUMN Receipt.storeid IS 'Unique identifier for the store where the purchase was made.';
COMMENT ON COLUMN Receipt.employeeid IS 'Unique identifier for the employee who attended during 
the purchase.';


-- This table represents the quantity of a specific product contained in a receipt
CREATE TABLE Contains (
	receiptid SERIAL,
	productid SERIAL,
	quantity INTEGER NOT NULL,
	FOREIGN KEY ( receiptid ) REFERENCES Receipt (receiptid),
	FOREIGN KEY ( productid ) REFERENCES Product (productid),
	PRIMARY KEY ( receiptid, productid )
);

COMMENT ON TABLE Contains IS 'Represents the quantity of a specific product contained in a receipt.';
COMMENT ON COLUMN Contains.receiptid IS 'Unique identifier for the receipt.';
COMMENT ON COLUMN Contains.productid IS 'Unique identifier for the product.';
COMMENT ON COLUMN Contains.quantity IS 'Quantity of product bought.';


-- This table represents a customer
CREATE TABLE Customer (
	email EMAILADDRESS PRIMARY KEY,
	name CHARACTER VARYING (250) NOT NULL,
	surname CHARACTER VARYING (250) NOT NULL,
	gender GENDER NOT NULL,
	password CHARACTER VARYING (250) NOT NULL,
	dateofbirth DATE NOT NULL,
	loyaltypoints INTEGER NOT NULL,
	storeid SERIAL,
	FOREIGN KEY ( storeid ) REFERENCES Store (storeid)
);

COMMENT ON TABLE Customer IS 'Represents a customer.';
COMMENT ON COLUMN Customer.email IS 'Unique identifier for the customer.';
COMMENT ON COLUMN Customer.name IS 'Name of the customer.';
COMMENT ON COLUMN Customer.surname IS 'Surname of the customer.';
COMMENT ON COLUMN Customer.gender IS 'Gender of the customer.';
COMMENT ON COLUMN Customer.password IS 'Password of the customer.';
COMMENT ON COLUMN Customer.dateofbirth IS 'Date of Birth of the customer.';
COMMENT ON COLUMN Customer.loyaltypoints IS 'Points obtained by the customer.';
COMMENT ON COLUMN Customer.storeid IS 'Unique identifier for the store prefered by the customer.';


-- This table represents which receipt belongs to which customer (if customer used the loyalty program while purchasing)
CREATE TABLE BelongsTo (
	receiptid SERIAL PRIMARY KEY,
	email EMAILADDRESS,
	FOREIGN KEY ( receiptid ) REFERENCES Receipt (receiptid),
	FOREIGN KEY ( email ) REFERENCES Customer (email)
);

COMMENT ON TABLE BelongsTo IS 'Associates the customer with the receipt 
(if customer used the loyalty program while purchasing).';
COMMENT ON COLUMN BelongsTo.receiptid IS 'Unique identifier for the receipt.';
COMMENT ON COLUMN BelongsTo.email IS 'Unique identifier for the product.';