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
	username			   VARCHAR			  PRIMARY KEY REFERENCES Users(username) ON DELETE CASCADE,
	is_full_time		BOOLEAN			NOT NULL,
	avg_rating			FLOAT			   NOT NULL DEFAULT 0,
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


CREATE TABLE declares_availabilities(
    start_timestamp 		TIMESTAMP 	NOT NULL,
    end_timestamp 			TIMESTAMP 	NOT NULL,
    caretaker_username 		VARCHAR REFERENCES Caretakers(username) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (end_timestamp > start_timestamp),
    CHECK(end_timestamp <= CURRENT_TIMESTAMP + INTERVAL '2 years 8 hours'), -- Additional add hours is to account for converstion to SGT
    PRIMARY KEY(caretaker_username, start_timestamp) --Two availabilities belonging to the same caretaker should not have the same start date.
                                               --They will be merged
);


-- TIMINGS, BIDS
CREATE TABLE Timings (
	start_timestamp 	TIMESTAMP,
	end_timestamp 		TIMESTAMP,
	PRIMARY KEY (start_timestamp, end_timestamp),
	CHECK (end_timestamp > start_timestamp)
);

CREATE TABLE bids (
	  owner_username 			VARCHAR,
      pet_name 					VARCHAR,
      bid_start_timestamp 		TIMESTAMP,
      bid_end_timestamp 		TIMESTAMP,
      avail_start_timestamp 	TIMESTAMP,
	  avail_end_timestamp 		TIMESTAMP,
      caretaker_username 		VARCHAR,
      rating 					NUMERIC,
      review 					VARCHAR,
      is_successful 			BOOLEAN,
      payment_method 			VARCHAR,
      mode_of_transfer 			VARCHAR,
      is_paid 					BOOLEAN,
      total_price 				NUMERIC 		NOT NULL CHECK (total_price > 0),
      type_of_service 			VARCHAR 		NOT NULL,
	  PRIMARY KEY (pet_name, owner_username, bid_start_timestamp, bid_end_timestamp, caretaker_username, avail_start_timestamp),
      FOREIGN KEY (bid_start_timestamp, bid_end_timestamp) REFERENCES Timings(start_timestamp, end_timestamp),
      FOREIGN KEY (avail_start_timestamp, caretaker_username) REFERENCES declares_availabilities(start_timestamp, caretaker_username),
      FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
      UNIQUE (pet_name, owner_username, caretaker_username, bid_start_timestamp, bid_end_timestamp),
	  CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	  CHECK ((is_successful = true) OR (payment_method IS NULL AND is_paid IS NULL AND
	  mode_of_transfer IS NULL)),
	  CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
	  CHECK ((bid_start_timestamp >= avail_start_timestamp) AND (bid_end_timestamp <= avail_end_timestamp) AND (bid_end_timestamp > bid_start_timestamp))
);

CREATE TABLE Charges (
  daily_price NUMERIC,
  cat_name VARCHAR(10) REFERENCES Categories(cat_name),
  caretaker_username VARCHAR REFERENCES Caretakers(username),
  PRIMARY KEY (cat_name, caretaker_username)
);

CREATE OR REPLACE FUNCTION is_valid_price() RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
BEGIN
SELECT COUNT(*) INTO ctx FROM Caretakers C WHERE C.username = NEW.caretaker_username AND C.is_full_time = false;
IF ctx > 0 THEN RETURN NEW; END IF;
SELECT COUNT(*) INTO ctx FROM Categories A WHERE A.cat_name = NEW.cat_name AND A.base_price > NEW.daily_price;
IF ctx > 0 THEN RETURN NULL; ELSE RETURN NEW; END IF;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_daily_price
BEFORE INSERT OR UPDATE ON Charges
FOR EACH ROW EXECUTE PROCEDURE is_valid_price();

CREATE OR REPLACE FUNCTION is_pet_covered() RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
BEGIN
SELECT COUNT(*) INTO ctx FROM Charges C WHERE C.cat_name = (SELECT cat_name FROM ownsPets O WHERE O.username = NEW.owner_username AND O.name = NEW.pet_name) AND C.caretaker_username = NEW.caretaker_username;
IF ctx = 0 THEN RETURN NULL; ELSE RETURN NEW; END IF;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_pet_cover
BEFORE INSERT OR UPDATE ON bids
FOR EACH ROW EXECUTE PROCEDURE is_pet_covered();

CREATE OR REPLACE FUNCTION is_pet_limit_reached() RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
DECLARE rate NUMERIC;
DECLARE is_part_time NUMERIC;
BEGIN
SELECT COUNT(*) INTO ctx FROM bids B WHERE B.is_successful = true AND B.caretaker_username = NEW.caretaker_username AND B.bid_end_timestamp > CURRENT_TIMESTAMP;
SELECT AVG(rating) INTO rate FROM bids Bo WHERE Bo.is_successful = true AND Bo.caretaker_username = NEW.caretaker_username;
SELECT COUNT(*) INTO is_part_time FROM Caretakers C WHERE C.username = NEW.caretaker_username AND is_full_time = false;
IF (ctx >= 5) THEN RETURN NULL; END IF;
IF (is_part_time > 0 AND ctx >= 2 AND (rate IS NULL OR rate < 4)) THEN RETURN NULL; END IF;
RETURN NEW;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_pet_limit
BEFORE INSERT OR UPDATE ON bids
FOR EACH ROW EXECUTE PROCEDURE is_pet_limit_reached();

CREATE OR REPLACE FUNCTION is_enddate_valid() RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
BEGIN
SELECT COUNT(*) INTO ctx FROM declares_availabilities a WHERE NEW.caretaker_username = a.caretaker_username AND NEW.avail_start_timestamp = a.start_timestamp AND NEW.avail_end_timestamp = a.end_timestamp;
IF (ctx > 0) THEN RETURN NEW; ELSE RETURN NULL; END IF;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_enddate
BEFORE INSERT OR UPDATE ON bids
FOR EACH ROW EXECUTE PROCEDURE is_enddate_valid();

CREATE TABLE isPaidSalaries (
	caretaker_id 				VARCHAR 		REFERENCES caretakers(username) ON DELETE cascade,
	year 						INTEGER,
	month 						INTEGER,
	salary_amount 				NUMERIC 		NOT NULL,
	PRIMARY KEY (caretaker_id, year, month)
);

CREATE TABLE Administrators (
	admin_username				VARCHAR 		PRIMARY KEY,
	password 					VARCHAR(64) 	NOT NULL
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

    IF EXISTS (SELECT 1 FROM Caretakers WHERE NEW.caretaker_username = username AND is_full_time IS TRUE) THEN
    -- Do not need to merge availability for full-time caretakers as they do not insert availability, but take leave instead
    RETURN NEW;
    END IF;



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
--This is only called when the table is manually deleted
CREATE OR REPLACE PROCEDURE delete_availability(old_username VARCHAR, old_start_timestamp TIMESTAMP WITH TIME ZONE) AS
$$
   BEGIN
   IF EXISTS (SELECT 1
              FROM bids b1
              WHERE b1.caretaker_username = OLD.caretaker_username
              AND (GREATEST (b1.bid_start_timestamp, NEW.start_timestamp) < LEAST (b1.bid_end_timestamp, NEW.end_timestamp))
               AND b1.is_successful IS TRUE)
               THEN --There is overlap

   RAISE EXCEPTION 'The period cannot be deleted as there is a successful bid within that period';
   ELSE
   DELETE FROM declares_availabilities WHERE old_username = username AND old_start_timestamp = start_timestamp;
   END IF;

   END $$
LANGUAGE plpgsql;



--Update availabilities while checking if it can be shrunked and merging if it is expanded
--Break update down into delete and insertion
CREATE OR REPLACE FUNCTION update_availabilities()
RETURNS TRIGGER AS
$$ DECLARE first_result INTEGER := 0;
  DECLARE second_result INTEGER := 0;
  DECLARE total_result INTEGER;
  BEGIN
  RAISE NOTICE 'update avail function is called ...';



  IF (OLD.start_timestamp < NEW.start_timestamp)
  THEN
    RAISE NOTICE 'entering 1st part';
    IF EXISTS(SELECT 1
              FROM bids b1
              WHERE b1.caretaker_username = OLD.caretaker_username
              AND GREATEST(b1.bid_start_timestamp, OLD.start_timestamp) < LEAST(b1.bid_end_timestamp, NEW.start_timestamp)
              AND b1.is_successful IS TRUE)
              THEN
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
              WHERE b2.caretaker_username = OLD.caretaker_username
              AND GREATEST(b2.bid_start_timestamp, NEW.end_timestamp) < LEAST(b2.bid_end_timestamp, OLD.end_timestamp)
              AND b2.is_successful IS TRUE)
              THEN
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

CREATE OR REPLACE PROCEDURE delete_coincide_availabilities(leave_start_timestamp TIMESTAMP WITH TIME ZONE, leave_end_timestamp TIMESTAMP WITH TIME ZONE, username VARCHAR) AS
$$
BEGIN
DELETE FROM declares_availabilities
WHERE caretaker_username = username AND GREATEST (start_timestamp, leave_start_timestamp) <= LEAST (end_timestamp, leave_end_timestamp);
END; $$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE take_leave(leave_start TIMESTAMP WITH TIME ZONE, leave_end TIMESTAMP WITH TIME ZONE, username VARCHAR) AS
$$ DECLARE avail_first_start TIMESTAMP;
DECLARE avail_second_start TIMESTAMP;
DECLARE avail_second_end TIMESTAMP;

DECLARE consecutive_days_first NUMERIC;
DECLARE consecutive_days_second NUMERIC;


DECLARE result NUMERIC;

BEGIN
result := 0;
RAISE NOTICE 'in take_leave procedure';

IF EXISTS (SELECT 1
            FROM bids
            WHERE caretaker_username = username
                AND bid_start_timestamp >= leave_start
                    AND bid_start_timestamp <= leave_end
                       AND is_successful IS TRUE) THEN
RAISE EXCEPTION 'Leave cannot be taken as there are scheduled pet-care jobs within the leave period';
END IF;

SELECT start_timestamp INTO avail_first_start
FROM declares_availabilities
WHERE caretaker_username = username AND leave_start > start_timestamp AND leave_start < end_timestamp;

SELECT start_timestamp, end_timestamp INTO avail_second_start, avail_second_end
FROM declares_availabilities
WHERE caretaker_username = username AND leave_end < end_timestamp AND leave_end > start_timestamp;

SELECT DATE_PART('day', leave_start - avail_first_start) INTO consecutive_days_first;
SELECT DATE_PART('day', avail_second_end - leave_end) INTO consecutive_days_second;

WITH days_interval AS
(SELECT DATE_PART('day', end_timestamp - start_timestamp) AS days
FROM declares_availabilities
WHERE caretaker_username = username
       AND start_timestamp < avail_first_start
       OR start_timestamp > avail_second_start)

SELECT COALESCE(SUM(CASE
           WHEN days < 150 THEN 0
           WHEN days >= 150 AND days < 300 THEN 1
           WHEN days >= 300 THEN 2
           END), 0) INTO result FROM days_interval;

 RAISE NOTICE '1. result is %', result;

IF (consecutive_days_first >= 300) THEN
 result := result + 2;
ELSIF (consecutive_days_first >= 150)  THEN
 result := result + 1;
 END IF;

 RAISE NOTICE '2. result is %', result;

IF (consecutive_days_second >= 300) THEN
 result := result + 2;
 ELSIF (consecutive_days_second >= 150)  THEN
 result := result + 1;
 END IF;

  RAISE NOTICE '3. result is %', result;


IF (result < 2) THEN
    RAISE EXCEPTION 'Cannot take leave as you are not working for 2 X 150 consecutive days this year';
END IF;


UPDATE bids SET avail_end_timestamp = leave_start WHERE bid_start_timestamp >= avail_first_start AND bid_end_timestamp <= leave_start;

UPDATE declares_availabilities SET end_timestamp = leave_start WHERE start_timestamp = avail_first_start;

INSERT INTO declares_availabilities VALUES (leave_end, avail_second_end, username);

UPDATE bids SET avail_start_timestamp = leave_end WHERE bid_start_timestamp >= avail_second_start AND bid_end_timestamp <= avail_second_end;

IF (avail_first_start <> avail_second_start) THEN
DELETE FROM declares_availabilities WHERE start_timestamp = avail_second_start;
END IF;

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
	   INSERT INTO Users VALUES (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, CURRENT_DATE);
	   INSERT INTO Owners VALUES (username);
	   END; $$
	LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_ct (username 		VARCHAR,
									first_name		NAME,
									last_name		NAME,
									password		VARCHAR(64),
									email			VARCHAR,
									dob				DATE,
									credit_card_no	VARCHAR,
									unit_no			VARCHAR,
									postal_code		VARCHAR(6), 
									avatar			BYTEA,
									is_full_time	BOOLEAN
									) AS
	$$ BEGIN
	
	   INSERT INTO Users VALUES (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, CURRENT_DATE);
	   INSERT INTO Caretakers VALUES (username, is_full_time);
	   END; $$
	LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fill_availabilities()
RETURNS TRIGGER AS
$$
  BEGIN
  IF NEW.is_full_time IS TRUE THEN
 INSERT INTO declares_availabilities VALUES (CURRENT_TIMESTAMP + INTERVAL '8 hours', CURRENT_TIMESTAMP + INTERVAL '1 year 8 hours' , NEW.username); --To account for Singapore time

  END IF;
  RETURN NEW;
  END $$
LANGUAGE plpgsql;

CREATE TRIGGER fill_availabilities
AFTER INSERT ON Caretakers
FOR EACH ROW EXECUTE PROCEDURE fill_availabilities();


--trigger to enable and disable account
CREATE OR REPLACE FUNCTION update_disable()
RETURNS TRIGGER AS
	$$ DECLARE total NUMERIC;
	BEGIN
		SELECT COUNT(*) INTO total FROM ownsPets WHERE username = NEW.username;
		IF total = 0 THEN UPDATE Owners SET is_disabled = TRUE WHERE username = NEW.username;
		ELSIF total = 1 THEN UPDATE Owners SET is_disabled = FALSE WHERE username = NEW.username;
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

CREATE OR REPLACE PROCEDURE insert_bids(ou VARCHAR, pn VARCHAR, ps TIMESTAMP WITH TIME ZONE, pe TIMESTAMP WITH TIME ZONE, ct VARCHAR, ts VARCHAR) AS
$$ DECLARE tot_p NUMERIC;
DECLARE sd TIMESTAMP WITH TIME ZONE;
DECLARE ed TIMESTAMP WITH TIME ZONE;
BEGIN

IF NOT EXISTS (SELECT 1
               FROM declares_availabilities
               WHERE start_timestamp <= ps AND end_timestamp >= pe AND caretaker_username = ct) THEN
RAISE EXCEPTION 'The bid period is not within the availability period of caretaker.';
END IF;

SELECT start_timestamp, end_timestamp INTO sd, ed
FROM declares_availabilities
WHERE start_timestamp <= ps AND end_timestamp >= pe AND caretaker_username = ct;

SELECT DATE_PART('day', pe - ps) INTO tot_p;
tot_p := tot_p * (SELECT daily_price
                    FROM Charges
                    WHERE caretaker_username = ct AND cat_name = (SELECT cat_name
                                                                 FROM ownsPets
                                                                 WHERE ou = username AND pn = name));

IF NOT EXISTS (SELECT 1
              FROM TIMINGS
              WHERE start_timestamp = ps AND end_timestamp = pe) THEN
INSERT INTO TIMINGS VALUES (ps, pe);
END IF;

INSERT INTO bids VALUES (ou, pn, ps, pe, sd, ed, ct, NULL, NULL, NULL, NULL, NULL, NULL, tot_p, ts);

UPDATE bids SET is_successful = (CASE
                                    WHEN random() < 0.5 THEN
                                    true
                                     ELSE
                                     false
                                     END) WHERE is_successful IS NULL;
END; $$
LANGUAGE plpgsql;

--delete bids only if they are in the future and unsuccessful (pending bids). Cannot delete confirmed or expired bids.
CREATE OR REPLACE FUNCTION check_deletable_bid()
RETURNS TRIGGER AS
$$
   BEGIN
    IF (OLD.is_successful IS TRUE OR OLD.bid_start_timestamp <= CURRENT_TIMESTAMP) THEN
   RAISE EXCEPTION 'The bid cannot be deleted as it is accepted by caretaker or it is expired.';
   ELSE
   RETURN OLD;
   END IF;
   END $$
LANGUAGE plpgsql;


CREATE TRIGGER check_deletable_bid
BEFORE DELETE ON bids
FOR EACH ROW EXECUTE PROCEDURE check_deletable_bid();




--insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hchilcotte1', 'Hannah', 'Chilcotte', 'VxyTOEHQQ', 'hchilcotte1@bigcartel.com', '2000-01-19', '5048372273574703', null, '688741', 'https://robohash.org/expeditaquiaea.png?size=50x50&set=set1', '2020-01-27');
--insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mlongridge2', 'Maynard', 'Longridge', 'Wwa1uuMOUiB2', 'mlongridge2@nih.gov', '1956-09-27', '4041378363311', null, '760607', 'https://robohash.org/consequaturquasiet.jpg?size=50x50&set=set1', '2020-09-19');
--
--insert into Caretakers (username, is_full_time, avg_rating, no_of_reviews, no_of_pets_taken,is_disabled) values ('hchilcotte1', TRUE, 4.45, 1, 1, FALSE);
--insert into categories(cat_name, base_price) values ('dog', 3.10);
--
--insert into Owners (username, is_disabled) values ('mlongridge2', FALSE);
--INSERT INTO ownsPets (username, name, description,	cat_name, size, sociability, special_req, img) values ('mlongridge2', 'pet1', 'asdasdasd', 'dog', 'Large', 'very', 'none', 'https://robohash.org/atareiciendis.png?size=50x50&set=set1');
--INSERT INTO Timings (p_start_date ,p_end_date) values ('2020-10-10', '2020-10-15');
--insert into Bids(owner_username ,pet_name ,p_start_date ,p_end_date ,starting_date ,ending_date ,username ,rating ,review ,is_successful ,payment_method ,mode_of_transfer ,is_paid ,total_price,type_of_service)
--          values ( 'mlongridge2', 'pet1', '2020-10-10', '2020-10-15', '2020-10-05', '2020-10-20', 'hchilcotte1', null, null, TRUE, null, null, FALSE, 30, 'something' );
--
--
--
--
--
--CREATE OR REPLACE PROCEDURE rate_or_review(rat NUMERIC, rev VARCHAR, ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
--$$ BEGIN
--UPDATE Bids SET rating = rat, review = rev WHERE owner_username = ou AND pet_name = pn AND
--username = ct AND p_start_date = ps AND p_end_date = pe;
--END; $$
--LANGUAGE plpgsql;
--
--CREATE OR REPLACE PROCEDURE set_transac_details(pm VARCHAR, mot VARCHAR, ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
--$$ BEGIN
--UPDATE Bids SET payment_method = pm, mode_of_transfer = mot WHERE owner_username = ou AND pet_name = pn AND
--username = ct AND p_start_date = ps AND p_end_date = pe;
--END; $$
--LANGUAGE plpgsql;
--
--CREATE OR REPLACE PROCEDURE pay_bid(ou VARCHAR, pn VARCHAR, ct VARCHAR, ps DATE, pe DATE) AS
--$$ BEGIN
--UPDATE Bids SET is_paid = true WHERE owner_username = ou AND pet_name = pn AND username = ct AND
--p_start_date = ps AND p_end_date = pe;
--END; $$
--LANGUAGE plpgsql;
--
--
--INSERT INTO caretakers (username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code,
--						reg_date, is_full_time, avg_rating, no_of_reviews, no_of_pets_taken )
--VALUES ('caretaker_2', ' $2b$10$4AyNzxs91dwycBYoBuGPT.cjSwtzWEmDQhQjzaDijewkTALzY57pO', 'sample_2',
--		'sample_2', 's2@s.com', '02-01-2000', '1231231231231231',
--		'2', '123123', '02-10-2020', 'true', 4.5, 2, 2);
--
--
---- INSERT categories
--CREATE OR REPLACE PROCEDURE add_category(cat_name		VARCHAR(10),
--							  			 base_price		NUMERIC) AS
--	$$ BEGIN
--	   INSERT INTO Categories (cat_name, base_price)
--	   VALUES (cat_name, base_price);
--	   END; $$
--	LANGUAGE plpgsql;
--
--
--
--CREATE OR REPLACE PROCEDURE add_pet (username			VARCHAR,
--									 name 				NAME,
--									 description		VARCHAR,
--									 cat_name			VARCHAR(10),
--									 size				VARCHAR,
--									 sociability		VARCHAR,
--									 special_req		VARCHAR,
--									 img 				BYTEA
--									 ) AS
--	$$ BEGIN
--	   INSERT INTO ownsPets
--	   VALUES (username, name, description, cat_name, size, sociability, special_req, img);
--	   END; $$
--	LANGUAGE plpgsql;
--
--
--CREATE OR REPLACE PROCEDURE add_admin(	admin_id 		VARCHAR ,
--										password 		VARCHAR(64),
--										last_login_time TIMESTAMP
--										) AS
--	$$ BEGIN
--	   INSERT INTO Administrators (admin_id, password, last_login_time )
--	   VALUES (admin_id, password, last_login_time );
--	   END; $$
--	LANGUAGE plpgsql;
