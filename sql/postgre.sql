


CREATE TABLE declares_availabilities(
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    caretaker_username VARCHAR, --REFERENCES caretakers(username) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (end_timestamp > start_timestamp),
    PRIMARY KEY(caretaker_username, start_timestamp) --Two availabilities belonging to the same caretaker should not have the same start date.
                                                --They will be merged
);






	---Availabilities Trigger

--Merge availabilities if they coincide
CREATE OR REPLACE FUNCTION merge_availabilities()
RETURNS TRIGGER AS
$$ DECLARE new_start TIMESTAMP WITHOUT TIME ZONE;
 new_end TIMESTAMP WITHOUT TIME ZONE;
  old_start TIMESTAMP WITHOUT TIME ZONE;
    BEGIN
    RAISE NOTICE 'Entering merge_availabilities function ...';
    IF NEW.start_timestamp >= NEW.end_timestamp THEN
    RETURN NULL;
    ELSIF
    NOT EXISTS (SELECT 1 FROM declares_availabilities a1 WHERE a1.caretaker_username = NEW.caretaker_username AND (GREATEST (a1.start_timestamp, NEW.start_timestamp) <= LEAST (a1.end_timestamp, NEW.end_timestamp))) THEN --No overlap
    RETURN NEW;
    ELSIF
    EXISTS (SELECT 1 FROM declares_availabilities a2 WHERE a2.caretaker_username = NEW.caretaker_username AND (a2.start_timestamp <= NEW.start_timestamp AND a2.end_timestamp >= NEW.end_timestamp)) THEN --New period is a subset of an existing periond
    RETURN NULL;
    ELSE
    RAISE NOTICE 'Going to merge 2 periods ...';
    SELECT LEAST(a3.start_timestamp, NEW.start_timestamp), GREATEST(a3.end_timestamp, NEW.end_timestamp), a3.start_timestamp INTO new_start, new_end, old_start
    FROM declares_availabilities a3
    WHERE a3.caretaker_username = NEW.caretaker_username AND (GREATEST (a3.start_timestamp, NEW.start_timestamp) <= LEAST (a3.end_timestamp, NEW.end_timestamp));

    DELETE FROM declares_availabilities a4
    WHERE a4.caretaker_username = NEW.caretaker_username AND a4.start_timestamp = old_start;


    RETURN (new_start, new_end, NEW.caretaker_username);
    END IF;
    END $$
 LANGUAGE plpgsql;

CREATE TRIGGER merge_availabilities
BEFORE INSERT ON declares_availabilities
FOR EACH ROW EXECUTE PROCEDURE merge_availabilities();


--delete availabilities only if there are no pets the caretaker is scheduled to care for
CREATE OR REPLACE FUNCTION check_deletable()
RETURNS TRIGGER AS
$$
   BEGIN
   IF EXISTS (SELECT 1
              FROM bids b1
              WHERE b1.caretaker_username = OLD.caretaker_username AND (GREATEST (b1.start_timestamp, NEW.start_timestamp) < LEAST (b1.end_timestamp, NEW.end_timestamp)) ) THEN --There is overlap

   RAISE EXCEPTION 'The period cannot be deleted as there is a successful bid within that period';
   ELSE
   RETURN OLD;
   END IF;

   END $$
LANGUAGE plpgsql;


CREATE TRIGGER check_deletable
BEFORE DELETE ON declares_availabilities
FOR EACH ROW EXECUTE PROCEDURE check_deletable();

--Update availabilities while checking if it can be shrunked and merging if it is expanded
--Break update down into delete and insertion
CREATE OR REPLACE FUNCTION update_availabilities()
RETURNS TRIGGER AS
$$ DECLARE first_result INTEGER := 0;
  DECLARE second_result INTEGER := 0;
  DEClare total_result INTEGER;
  BEGIN
  RAISE NOTICE 'update avail function is called ...';

  IF (OLD.start_timestamp < NEW.start_timestamp)
  THEN
    RAISE NOTICE 'entering 1st part';
    IF EXISTS(SELECT 1
              FROM bids b1
              WHERE b1.caretaker_username = OLD.caretaker_username AND GREATEST(b1.start_timestamp, OLD.start_timestamp) < LEAST(b1.end_timestamp, NEW.start_timestamp)) THEN
               RAISE NOTICE 'there is a bid between the old and new starting timestamp';
    first_result := 1;
    ELSE
    first_result := 0;
    END IF;
    END IF;


  IF (OLD.end_timestamp > NEW.end_timestamp)
  THEN
    RAISE NOTICE 'entering 2nd part';
    IF EXISTS(SELECT 1
              FROM bids b2
              WHERE b2.caretaker_username = OLD.caretaker_username AND GREATEST(b2.start_timestamp, NEW.end_timestamp) < LEAST(b2.end_timestamp, OLD.end_timestamp)) THEN
    RAISE NOTICE 'there is a bid between the old and new ending timestamp';
    second_result := 1;
    ELSE
    second_result := 0;
    END IF;
   END IF;

   total_result := first_result + second_result;
   RAISE NOTICE 'total result is %', total_result;
   IF total_result = 0 THEN
   RETURN NEW;
   ELSE
   RAISE EXCEPTION 'Availability cannot be updated as there as pet caring tasks in the original availability period';
   END IF;
  END $$
LANGUAGE plpgsql;

CREATE TRIGGER update_availabilities
BEFORE UPDATE ON declares_availabilities
FOR EACH ROW EXECUTE PROCEDURE update_availabilities();

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
	unit_no			VARCHAR			CHECK (unit_no LIKE ('__-___') OR NULL),
	postal_code		VARCHAR			NOT NULL,
	avatar			BYTEA			NOT NULL,
	reg_date		DATE			NOT NULL DEFAULT CURRENT_DATE
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
	username		VARCHAR			NOT NULL REFERENCES Owners(username),
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


-- SEED VALUES
--Owners
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('umilnekw', 'Ursola', 'Milne', 'NSi0QM', 'umilnekw@1688.com', '1966-06-28', '3540690534311344', null, '683160', 'https://robohash.org/quibusdamquilibero.jpg?size=50x50&set=set1', '2020-03-07');

