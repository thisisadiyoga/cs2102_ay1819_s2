CREATE TABLE categories (
	cat_name		VARCHAR(10) 	PRIMARY KEY, 
	base_price		NUMERIC
);

CREATE TABLE owners(
	username		VARCHAR		PRIMARY KEY,
	first_name		NAME		NOT NULL,
	last_name		NAME		NOT NULL,
	password		VARCHAR(64)	NOT NULL, 
	email			VARCHAR		NOT NULL UNIQUE, 
	dob				DATE		NOT NULL, --check today - DOB >= 13 
	unit_no			VARCHAR,
	postal_code		VARCHAR(6)	NOT NULL,
	credit_card_no	VARCHAR		NOT NULL,
	reg_date		DATE		NOT NULL DEFAULT CURRENT_DATE,
	photo			BYTEA		NOT NULL
);

CREATE TABLE owns_pets(
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


CREATE TABLE declares_availabilities(
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    caretaker_username VARCHAR REFERENCES caretakers(username) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (end_timestamp > start_timestamp),
    PRIMARY KEY(caretaker_username, start_timestamp) --Two availabilities belonging to the same caretaker should not have the same start date.
                                                --They will be merged


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
									   unit_no			VARCHAR,
									   postal_code		VARCHAR(6),
									   credit_card_no	VARCHAR) AS
	$$ BEGIN
	   INSERT INTO Owners(username, first_name, last_name, password, email, dob, unit_no, postal_code, credit_card_no, reg_date)
	   VALUES (username, first_name, last_name, password, email, dob, unit_no, postal_code, credit_card_no, CURRENT_DATE);
	   END; $$
	LANGUAGE plpgsql;
	
CREATE OR REPLACE PROCEDURE add_pet (pet_id				VARCHAR,
									 username			VARCHAR,
									 name 				NAME, 
									 description		VARCHAR, 
									 cat_name			VARCHAR(10),
									 size				VARCHAR, 
									 sociability		VARCHAR,
									 special_req		VARCHAR,
									 img				BYTEA) AS
	$$ BEGIN
	   INSERT INTO ownsPets (pet_id, username, name, description, cat_name, size, sociability, special_req, img)
	   VALUES (pet_id, username, name, description, cat_name, size, sociability, special_req, BYTEA(img));
	   END; $$
	LANGUAGE plpgsql;


---Availabilities Trigger

--Merge availabilities if they coincide
CREATE OR REPLACE FUNCTION merge_availabilities()
RETURNS TRIGGER AS
$$ DECLARE new_start, new_end, old_start TIMESTAMP
    BEGIN
    IF NEW.start_timestamp >= NRW.end_timestamp THEN
    RETURN NULL;
    ELSIF
    NOT EXISTS (SELECT 1 FROM declares_availabilities a1 WHERE a1.caretaker_username = NEW.caretaker_username AND (GREATEST (a1.start_timestamp, NEW.start_timestamp) < LEAST (a1.end_timestamp, NEW.end_timestamp))) THEN --No overlap
    RETURN NEW;
    ELSIF
    EXISTS (SELECT 1 FROM declares_availabilities a2 WHERE a2.caretaker_username = NEW.caretaker_username AND (a2.start_timestamp <= NEW.start_timestamp AND a2.end_timestamp >= NEW.end_timestamp)) THEN --New period is a subset of an existing periond
    RETURN NULL;
    ELSE
    SELECT LEAST(a3.start_timestamp, NEW.start_timestamp) INTO new_start, GREATEST(a3.end_timestamp, NEW.end_timestamp) INTO new_end, a1.start_timestamp INTO old_start
    FROM declares_availabilities a3
    WHERE a3.caretaker_username = NEW.caretaker_username AND (GREATEST (a3.start_timestamp, NEW.start_timestamp) < LEAST (a3.end_timestamp, NEW.end_timestamp));

    DELETE FROM declares_availabilities a4
    WHERE a4.caretaker_username = NEW.caretaker_username AND a4.start_timestamp = old_start;


    RETURN (new_start, new_start, NEW.caretaker_username);
    END IF;
    END $$
 LANGUAGE plpgsql;

CREATE TRIGGER merge_availabilities
BEFORE UPDATE ON declares_availabilities
FOR EACH ROW EXECUTE PROCEDURE merge_availabilities();

--delete availabilities only if there are no pets the caretaker is scheduled to care for
CREATE OR REPLACE FUNCTION check_deletable()
RETURNS TRIGGER AS
$$
   BEGIN
   IF EXISTS (SELECT 1
              FROM bids b1
              WHERE b1.caretaker_username = OLD.caretaker_username AND (GREATEST (b1.start_timestamp, NEW.start_timestamp) < LEAST (b1.end_timestamp, NEW.end_timestamp)) ) THEN --There is overlap

   RAISE EXCEPTION 'The period cannot be deleted as there is a successful bid within that period'
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
$$
  BEGIN
  DELETE FROM declares_availabilities a1 WHERE a1.caretaker_username = OLD.caretaker_username AND a1.start_timestamp = OLD.start_timestamp;
  INSERT INTO declares_availabilities (start_timestamp, end_timestamp, caretaker_username) VALUES(NEW.start_timestamp, NEW.end_timestamp, NEW.caretaker_username);
  END $$
LANGUAGE plpgsql;

CREATE TRIGGER update_availabilities
INSTEAD OF UPDATE ON declares_availabilities
FOR EACH ROW EXECUTE PROCEDURE update_availabilities();


