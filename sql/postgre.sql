CREATE TABLE Categories (
	cat_name		VARCHAR(10) 	PRIMARY KEY, 
	base_price		NUMERIC
);

CREATE TABLE Owners(
	username		VARCHAR		PRIMARY KEY,
	first_name		NAME		NOT NULL,
	last_name		NAME		NOT NULL,
	password		VARCHAR(64)	NOT NULL, 
	email			VARCHAR		NOT NULL UNIQUE, 
	dob				DATE		NOT NULL, --check today - DOB >= 13 
	credit_card_no	VARCHAR		NOT NULL,
	unit_no			VARCHAR,
	postal_code		VARCHAR(6)	NOT NULL,
	reg_date		DATE		NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE ownsPets(
	username		VARCHAR		NOT NULL REFERENCES Owners(username) ON DELETE CASCADE, -- username of owner
	name 			NAME		NOT NULL, --name of pet
	description		TEXT, 
	cat_name		VARCHAR(10)	NOT NULL REFERENCES Categories(cat_name),
	size			VARCHAR		NOT NULL, 
	sociability		VARCHAR,
	special_req		VARCHAR,
	PRIMARY KEY (username, name)
);

CREATE VIEW Users AS (
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date FROM Owners
	UNION
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date FROM Caretakers
);

-- INSERT categories
CREATE OR REPLACE PROCEDURE add_category(cat_name		VARCHAR(10), 
							  			 base_price		NUMERIC) AS
	$$ BEGIN
	   INSERT INTO Categories (cat_name, base_price) 
	   VALUES (cat_name, base_price);
	   END; $$
	LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_owner (username 		VARCHAR,
									   first_name		NAME,
									   last_name		NAME,
									   password			VARCHAR(64),
									   email			VARCHAR,
									   dob				DATE,
									   credit_card_no	VARCHAR,
									   unit_no			VARCHAR,
									   postal_code		VARCHAR(6)
									   ) AS
	$$ BEGIN
	   INSERT INTO Owners
	   VALUES (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, CURRENT_DATE);
	   END; $$
	LANGUAGE plpgsql;
	
CREATE OR REPLACE PROCEDURE add_pet (username			VARCHAR,
									 name 				NAME, 
									 description		VARCHAR, 
									 cat_name			VARCHAR(10),
									 size				VARCHAR, 
									 sociability		VARCHAR,
									 special_req		VARCHAR
									 ) AS
	$$ BEGIN
	   INSERT INTO ownsPets
	   VALUES (username, name, description, cat_name, size, sociability, special_req);
	   END; $$
	LANGUAGE plpgsql;

CREATE TABLE Caretakers (
	username   	VARCHAR PRIMARY KEY,
	first_name 	NAME NOT NULL,
	last_name  	NAME NOT NULL,
	password   	VARCHAR(64) NOT NULL,
	email		VARCHAR NOT NULL UNIQUE CHECK(email LIKE '%@%.%'),
	credit_card_no	VARCHAR NOT NULL,
	DOB			DATE NOT NULL,
	postal_code	VARCHAR(6),
	unit_no		VARCHAR,
	reg_date	DATE NOT NULL DEFAULT CURRENT_DATE,
	is_full_time	BOOLEAN,
	avg_rating	FLOAT CHECK (avg_rating >= 0) DEFAULT 0,
	no_of_reviews	INTEGER DEFAULT 0,
	no_of_pets_taken INTEGER DEFAULT 0
);

/*Borrowing a part of the table for debugging*/
CREATE TABLE Bids (
	p_start_date DATE,
	p_end_date DATE,
	username VARCHAR,
	rating NUMERIC,
	review VARCHAR
);

CREATE OR REPLACE PROCEDURE add_caretaker (username 		VARCHAR,
									   first_name		NAME,
									   last_name		NAME,
									   password			VARCHAR(64),
									   email			VARCHAR,
									   dob				DATE,
									   credit_card_no	VARCHAR,
									   unit_no			VARCHAR,
									   postal_code		VARCHAR(6),
									   is_full_time		BOOLEAN
									   ) AS
	$$ BEGIN
	   INSERT INTO Owners
	   VALUES (username, first_name, last_name, password, email, credit_card_no, dob, postal_code, unit_no, CURRENT_DATE, is_full_time, 0, 0, 0);
	   END; $$
	LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION OnBid() RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		UPDATE Caretakers
		SET (avg_rating, no_of_reviews, no_of_pets_taken) = (((avg_rating*no_of_reviews)+NEW.rating)/(no_of_reviews + 1),
		no_of_reviews + 1,
		no_of_pets_taken + 1)
		FROM Bids
		WHERE Caretakers.username = NEW.username;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER ChangeCaretakerDetails
AFTER INSERT OR UPDATE OR DELETE ON Bids
FOR EACH ROW EXECUTE PROCEDURE OnBid();

/*CREATE TABLE Requested_by (
	username  	VARCHAR(9)  NOT NULL,
	p_start_date  	DATE NOT NULL,
	p_end_date  	DATE NOT NULL,
	PRIMARY KEY(username,p_start_date,p_end_date),
	FOREIGN KEY(username) REFERENCES Caretakers(username),
	FOREIGN KEY(p_start_date) REFERENCES Bids(p_start_date),
	FOREIGN KEY(p_end_date) REFERENCES Bids(p_end_date),
	CHECK(p_start_date <= p_end_date)
);*/
