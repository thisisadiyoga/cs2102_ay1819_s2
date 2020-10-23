CREATE TABLE Timings (
	p_start_date DATE,
	p_end_date DATE,
	PRIMARY KEY (p_start_date, p_end_date),
	CHECK (p_end_date >= p_start_date)
)

CREATE TABLE Bids (
	owner_username VARCHAR,
	pet_name VARCHAR,
	p_start_date DATE,
	p_end_date DATE,
	starting_date DATE,
	ending_date DATE,
	username VARCHAR,
	rating NUMERIC,
	review VARCHAR,
	is_successful BOOLEAN,
	payment_method VARCHAR,
	mode_of_transfer VARCHAR,
	is_paid BOOLEAN,
	total_price NUMERIC NOT NULL CHECK (total_price > 0),
	type_of_service VARCHAR NOT NULL,
	PRIMARY KEY (pet_name, owner_username, p_start_date, p_end_date, starting_date, ending_date, username),
	FOREIGN KEY (p_start_date, p_end_date) REFERENCES Timings(p_start_date, p_end_date),
	FOREIGN KEY (starting_date, ending_date, username) REFERENCES Availabilities(starting_date, ending_date,
	username),
	FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
	UNIQUE (pet_name, owner_username, username, p_start_date, p_end_date),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (payment_method IS NULL AND is_paid IS NULL AND
	mode_of_transfer IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
	CHECK ((p_start_date >= starting_date) AND (p_end_date <= ending_date) AND (p_end_date >= p_start_date))
)

CREATE OR REPLACE PROCEDURE insert_bid(ou VARCHAR, pn VARCHAR, ps DATE, pe DATE, sd DATE, ed DATE, ct VARCHAR, ts VARCHAR) AS
$$ DECLARE tot_p NUMERIC;
BEGIN
tot_p := (pe - ps + 1) * (SELECT daily_price FROM Charges WHERE username = ct AND cat_name IN (SELECT cat_name FROM ownsPets WHERE username = ou AND name = pn));
INSERT INTO Bids VALUES (ou, pn, ps, pe, sd, ed, ct, NULL, NULL, NULL, NULL, NULL, NULL, tot_p, ts);
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE choose_bids() AS
$$ BEGIN
UPDATE Bids SET is_successful = (CASE WHEN random() < 0.5 THEN true ELSE false END)
WHERE is_successful IS NULL;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE rate_or_review(rat NUMERIC, rev VARCHAR, ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
$$ BEGIN
UPDATE Bids SET rating = rat, review = rev WHERE owner_username = ou AND pet_name = pn AND
username = ct AND p_start_date = ps AND p_end_date = pe;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE set_transac_details(pm VARCHAR, mot VARCHAR, ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
$$ BEGIN
UPDATE Bids SET payment_method = pm, mode_of_transfer = mot WHERE owner_username = ou AND pet_name = pn AND
username = ct AND p_start_date = ps AND p_end_date = pe;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE pay_bid(ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
$$ BEGIN
UPDATE Bids SET is_paid = true WHERE owner_username = ou AND pet_name = pn AND username = ct AND
p_start_date = ps AND p_end_date = pe;
END; $$
LANGUAGE plpgsql;

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
