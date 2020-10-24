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

CREATE TABLE caretakers (
	username   	VARCHAR PRIMARY KEY,
	first_name 	VARCHAR NOT NULL,
	last_name  	VARCHAR NOT NULL,
	password   	VARCHAR(64) NOT NULL,
	email		VARCHAR NOT NULL UNIQUE CHECK(email LIKE '%@%.%'),
	credit_card_no	VARCHAR NOT NULL,
	DOB			DATE NOT NULL,
	postal_code	VARCHAR(6),
	unit_no		VARCHAR,
	reg_date	DATE NOT NULL,
	is_full_time	BIT,
	avg_rating	FLOAT CHECK (avg_rating >= 0),
	no_of_reviews	INTEGER,
	no_of_pets_taken INTEGER
);



CREATE TABLE declares_availabilities(
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    caretaker_username VARCHAR, --REFERENCES caretakers(username) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (end_timestamp > start_timestamp),
    PRIMARY KEY(caretaker_username, start_timestamp) --Two availabilities belonging to the same caretaker should not have the same start date.
                                                --They will be merged
);




CREATE VIEW Users AS (
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date FROM Owners
	UNION
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date FROM caretakers
);

-- INSERT categories
CREATE OR REPLACE PROCEDURE add_category(cat_name		VARCHAR(10),
							  			 base_price		NUMERIC) AS
	$$ BEGIN
	   INSERT INTO Categories (cat_name, base_price)
	   VALUES (cat_name, base_price);
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

CREATE TABLE Timings (
	bid_start_timestamp DATE,
	bid_end_timestamp DATE,
	PRIMARY KEY (bid_start_timestamp, bid_end_timestamp),
	CHECK (bid_end_timestamp > bid_start_timestamp)
)

CREATE TABLE bids (
	owner_username VARCHAR,
	pet_name VARCHAR,
	availability_start_timestamp TIMESTAMP NOT NULL,
	availability_end_timestamp TIMESTAMP NOT NULL,
    bid_start_timestamp TIMESTAMP NOT NULL,
	bid_end_timestamp TIMESTAMP NOT NULL,
    caretaker_username VARCHAR, 
	rating NUMERIC,
	review VARCHAR,
	is_successful BOOLEAN,
	payment_method VARCHAR,
	mode_of_transfer VARCHAR,
	is_paid BOOLEAN,
	total_price NUMERIC NOT NULL CHECK (total_price > 0),
	type_of_service VARCHAR NOT NULL,
	PRIMARY KEY (pet_name, owner_username, caretaker_username, availability_start_timestamp, bid_start_timestamp, bid_end_timestamp),
	FOREIGN KEY (bid_start_timestamp, bid_end_timestamp) REFERENCES Timings(bid_start_timestamp, bid_end_timestamp),
	FOREIGN KEY (caretaker_username, availability_start_timestamp, availability_end_timestamp) REFERENCES declares_availabilities(caretaker_username, start_timestamp, end_timestamp)
	FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
	UNIQUE (pet_name, owner_username, caretaker_username, bid_start_timestamp, bid_end_timestamp),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (payment_method IS NULL AND is_paid IS NULL AND
	mode_of_transfer IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
	CHECK ((bid_start_timestamp >= availability_starting_timestamp) AND (bid_end_timestamp <= availability_end_timestamp) AND (bid_end_timestamp > bid_start_timestamp))
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


