CREATE TABLE Timings (
	p_start_date TIMESTAMP,
	p_end_date TIMESTAMP,
	PRIMARY KEY (p_start_date, p_end_date),
	CHECK (p_end_date > p_start_date)
)

CREATE TABLE Bids (
	owner_username VARCHAR,
	pet_name VARCHAR,
	p_start_date TIMESTAMP,
	p_end_date TIMESTAMP,
	starting_date TIMESTAMP,
	ending_date TIMESTAMP,
	caretaker_username VARCHAR,
	rating NUMERIC,
	review VARCHAR,
	is_successful BOOLEAN,
	payment_method VARCHAR,
	mode_of_transfer VARCHAR,
	is_paid BOOLEAN,
	total_price NUMERIC NOT NULL CHECK (total_price > 0),
	type_of_service VARCHAR NOT NULL,
	PRIMARY KEY (pet_name, owner_username, p_start_date, p_end_date, starting_date, ending_date, caretaker_username),
	FOREIGN KEY (p_start_date, p_end_date) REFERENCES Timings(p_start_date, p_end_date),
	FOREIGN KEY (starting_date, ending_date, caretaker_username) REFERENCES Availabilities(starting_date, ending_date,
	caretaker_username),
	FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
	UNIQUE (pet_name, owner_username, caretaker_username, p_start_date, p_end_date),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (payment_method IS NULL AND is_paid IS NULL AND
	mode_of_transfer IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
	CHECK ((p_start_date >= starting_date) AND (p_end_date <= ending_date) AND (p_end_date > p_start_date))
)

CREATE OR REPLACE PROCEDURE insert_bid(ou VARCHAR, pn VARCHAR, ps TIMESTAMP, pe TIMESTAMP, sd TIMESTAMP, ed TIMESTAMP, ct VARCHAR, ts VARCHAR) AS
$$ DECLARE tot_p NUMERIC;
BEGIN
tot_p := (EXTRACT(DAY FROM AGE(pe, ps)) + 1) * (SELECT daily_price FROM Charges WHERE username = ct AND cat_name IN (SELECT cat_name FROM ownsPets WHERE username = ou AND name = pn));
IF NOT EXISTS (SELECT 1 FROM Timings WHERE p_start_date = ps AND p_end_date = pe) THEN INSERT INTO Timings VALUES (ps, pe); END IF;
INSERT INTO Bids VALUES (ou, pn, ps, pe, sd, ed, ct, NULL, NULL, NULL, NULL, NULL, NULL, tot_p, ts);
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
	dob				DATE		NOT NULL CHECK (CURRENT_DATE - dob >= 6570),
	credit_card_no	VARCHAR		NOT NULL,
	unit_no			VARCHAR,
	postal_code		VARCHAR(6)	NOT NULL,
	reg_date		DATE		NOT NULL DEFAULT CURRENT_DATE,
	avatar			BYTEA		NOT NULL
);

CREATE TABLE ownsPets(
	username		VARCHAR		NOT NULL REFERENCES Owners(username) ON DELETE CASCADE, -- username of owner
	name 			NAME		NOT NULL, --name of pet
	description		TEXT, 
	cat_name		VARCHAR(10)	NOT NULL REFERENCES Categories(cat_name),
	size			VARCHAR		NOT NULL, 
	sociability		VARCHAR,
	special_req		VARCHAR,
	img				BYTEA		NOT NULL, 
	PRIMARY KEY (username, name)
);

CREATE TABLE Caretakers(
	username		VARCHAR		PRIMARY KEY,
	first_name		NAME		NOT NULL,
	last_name		NAME		NOT NULL,
	password		VARCHAR(64)	NOT NULL, 
	email			VARCHAR		NOT NULL UNIQUE, 
	dob				DATE		NOT NULL CHECK (CURRENT_DATE - dob >= 6570),
	credit_card_no	VARCHAR		NOT NULL,
	unit_no			VARCHAR,
	postal_code		VARCHAR(6)	NOT NULL,
	reg_date		DATE		NOT NULL DEFAULT CURRENT_DATE, 
	is_full_time	BOOLEAN		NOT NULL, 
	avg_rating		FLOAT		NOT NULL, 
	no_of_reviews	INT			NOT NULL, 
	avatar			BYTEA		NOT NULL,
	no_of_pets_taken INTEGER    CHECK(no_of_pets_taken > 0)
);

CREATE VIEW Users AS (
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date, avatar FROM Owners
	UNION
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date, avatar FROM Caretakers
);

CREATE TABLE isPaidSalaries (
	caretaker_id VARCHAR REFERENCES caretakers(username)
	ON DELETE cascade,
	year INTEGER,
	month INTEGER,
	salary_amount NUMERIC NOT NULL,
	PRIMARY KEY (caretaker_id, year, month)
);

CREATE TABLE Administrators (
	admin_id VARCHAR PRIMARY KEY,
	password VARCHAR(64) NOT NULL,
	last_login_time TIMESTAMP
);


-- Insert dummy values, the password hash is 'asdasd'
INSERT INTO caretakers (username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, 
						reg_date, is_full_time, avg_rating, no_of_reviews, no_of_pets_taken )
VALUES ('caretaker_1', ' $2b$10$4AyNzxs91dwycBYoBuGPT.cjSwtzWEmDQhQjzaDijewkTALzY57pO', 'sample_1',
		'sample_1', 's@s.com', '02-01-2000', '1231231231231231',
		'1', '123123', '02-10-2020', 'true', 3.5, 1, 1);

INSERT INTO caretakers (username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, 
						reg_date, is_full_time, avg_rating, no_of_reviews, no_of_pets_taken )
VALUES ('caretaker_2', ' $2b$10$4AyNzxs91dwycBYoBuGPT.cjSwtzWEmDQhQjzaDijewkTALzY57pO', 'sample_2',
		'sample_2', 's2@s.com', '02-01-2000', '1231231231231231',
		'2', '123123', '02-10-2020', 'true', 4.5, 2, 2);


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
									   postal_code		VARCHAR(6), 
									   avatar			BYTEA
									   ) AS
	$$ BEGIN
	   INSERT INTO Owners
	   VALUES (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, CURRENT_DATE, avatar);
	   END; $$
	LANGUAGE plpgsql;
	
CREATE OR REPLACE PROCEDURE add_pet (username			VARCHAR,
									 name 				NAME, 
									 description		VARCHAR, 
									 cat_name			VARCHAR(10),
									 size				VARCHAR, 
									 sociability		VARCHAR,
									 special_req		VARCHAR, 
									 img 				BYTEA
									 ) AS
	$$ BEGIN
	   INSERT INTO ownsPets
	   VALUES (username, name, description, cat_name, size, sociability, special_req, img);
	   END; $$
	LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_admin(	admin_id 		VARCHAR ,
										password 		VARCHAR(64),
										last_login_time TIMESTAMP 
										) AS
	$$ BEGIN
	   INSERT INTO Administrators (admin_id, password, last_login_time ) 
	   VALUES (admin_id, password, last_login_time ); 
	   END; $$
	LANGUAGE plpgsql;

