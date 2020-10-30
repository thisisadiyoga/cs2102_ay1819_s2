-- USERS, OWNERS, CARETAKERS, CATEGORIES, OWNSPETS

CREATE TABLE Categories (
	cat_name		VARCHAR(10) 	PRIMARY KEY, 
	base_price		NUMERIC
);

CREATE TABLE Users (
	username		VARCHAR			PRIMARY KEY, 
	first_name		NAME			NOT NULL, 
	last_name		NAME			NOT NULL, 
	password		VARCHAR(64)		NOT NULL, 
	email			VARCHAR			NOT NULL UNIQUE CHECK(email LIKE '%@%.%'),
	dob				DATE			NOT NULL CHECK (CURRENT_DATE - dob >= 6750), 
	credit_card_no	VARCHAR			NOT NULL, 
	unit_no			VARCHAR			CHECK (unit_no LIKE ('__-%') OR NULL), 
	postal_code		VARCHAR			NOT NULL, 
	avatar			BYTEA			NOT NULL, 
	reg_date		DATE			NOT NULL DEFAULT CURRENT_DATE, 
	is_owner		BOOLEAN			NOT NULL DEFAULT FALSE, 
	is_caretaker	BOOLEAN			NOT NULL DEFAULT FALSE
);

CREATE TABLE Owners (
	username		VARCHAR			PRIMARY KEY REFERENCES Users(username) ON DELETE CASCADE, 
	is_disabled		BOOLEAN			NOT NULL DEFAULT TRUE
);

CREATE TABLE Caretakers (
	username			VARCHAR			PRIMARY KEY REFERENCES Users(username) ON DELETE CASCADE, 
	is_full_time		BOOLEAN			NOT NULL, 
	avg_rating			FLOAT			NOT NULL DEFAULT 0, 
	no_of_reviews		INT				NOT NULL DEFAULT 0, 
	no_of_pets_taken	INT				CHECK (no_of_pets_taken >= 0) DEFAULT 0, 
	is_disabled			BOOLEAN			NOT NULL DEFAULT FALSE
);

CREATE TABLE ownsPets (
	username		VARCHAR			NOT NULL REFERENCES Owners(username) ON DELETE CASCADE, 
	name			NAME			NOT NULL, 
	description		TEXT, 
	cat_name		VARCHAR(10)		NOT NULL REFERENCES Categories(cat_name), 
	size			VARCHAR 		NOT NULL CHECK (size IN ('Extra Small', 'Small', 'Medium', 'Large', 'Extra Large')), 
	sociability		TEXT, 
	special_req		TEXT, 
	img				BYTEA, 
	PRIMARY KEY (username, name)
);

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
	   INSERT INTO Users VALUES (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, CURRENT_DATE);
	   INSERT INTO Owners VALUES (username);
	   END; $$
	LANGUAGE plpgsql;

--trigger to enable and disable account
CREATE OR REPLACE FUNCTION update_disable() 
RETURNS TRIGGER AS 
	$$ DECLARE total NUMERIC;
	BEGIN
		SELECT COUNT(*) INTO total FROM ownsPets WHERE username = NEW.username;
		IF total = 0 THEN UPDATE Owners SET is_disabled = TRUE;
		ELSIF total = 1 THEN UPDATE Owners SET is_disabled = FALSE;
		END IF;
		
		RETURN NEW;
	END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_status 
AFTER INSERT OR DELETE ON ownsPets
FOR EACH ROW EXECUTE PROCEDURE update_disable();

--------------------------------------------------------

--trigger to show type of account (caretaker, owner, user)
CREATE OR REPLACE FUNCTION update_caretaker()
RETURNS TRIGGER AS 
	$$ DECLARE is_caretaker BOOLEAN;
	BEGIN
		SELECT 1 INTO is_caretaker FROM Caretakers WHERE username = NEW.username;
		IF is_caretaker THEN UPDATE Users SET is_caretaker = TRUE WHERE username = NEW.username;
		ELSE UPDATE Users SET is_caretaker = FALSE WHERE username = NEW.username;
		END IF;

		RETURN NEW;
	END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_caretaker_status
AFTER INSERT OR DELETE ON Caretakers
FOR EACH ROW EXECUTE PROCEDURE update_caretaker();

CREATE OR REPLACE FUNCTION update_owner()
RETURNS TRIGGER AS 
	$$ DECLARE is_owner BOOLEAN;
	BEGIN
		SELECT 1 INTO is_owner FROM Owners WHERE username = NEW.username;
		IF is_owner THEN UPDATE Users SET is_owner = TRUE WHERE username = NEW.username;
		ELSE UPDATE Users SET is_owner = FALSE WHERE username = NEW.username;
		END IF;

		RETURN NEW;
	END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_owner_status
AFTER INSERT OR DELETE ON Owners
FOR EACH ROW EXECUTE PROCEDURE update_owner();
--------------------------------------------------------

CREATE TABLE Timings (
	p_start_date DATE,
	p_end_date DATE,
	PRIMARY KEY (p_start_date, p_end_date),
	CHECK (p_end_date >= p_start_date)
);

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
	--FOREIGN KEY (starting_date, ending_date, username) REFERENCES Availabilities(starting_date, ending_date, username),
	FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
	UNIQUE (pet_name, owner_username, username, p_start_date, p_end_date),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (payment_method IS NULL AND is_paid IS NULL AND
	mode_of_transfer IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
	CHECK ((p_start_date >= starting_date) AND (p_end_date <= ending_date) AND (p_end_date >= p_start_date))
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


CREATE OR REPLACE PROCEDURE add_admin(	admin_id 		VARCHAR ,
										password 		VARCHAR(64),
										last_login_time TIMESTAMP 
										) AS
	$$ BEGIN
	   INSERT INTO Administrators (admin_id, password, last_login_time ) 
	   VALUES (admin_id, password, last_login_time ); 
	   END; $$
	LANGUAGE plpgsql;