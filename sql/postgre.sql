CREATE TABLE declares_availabilities(
    start_timestamp TIMESTAMP NOT NULL,
    end_timestamp TIMESTAMP NOT NULL,
    caretaker_username VARCHAR, --TODO: REFERENCES caretakers(username) ON DELETE CASCADE ON UPDATE CASCADE,
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
  DECLARE total_result INTEGER;
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

CREATE OR REPLACE PROCEDURE add_admin(	admin_id 		VARCHAR ,
										password 		VARCHAR(64),
										last_login_time TIMESTAMP
										) AS
	$$ BEGIN
	   INSERT INTO Administrators (admin_id, password, last_login_time )
	   VALUES (admin_id, password, last_login_time );
	   END; $$
	LANGUAGE plpgsql;


-- TIMINGS, BIDS
CREATE TABLE Timings (
	start_timestamp TIMESTAMP,
	end_timestamp TIMESTAMP,
	PRIMARY KEY (start_timestamp, end_timestamp),
	CHECK (end_timestamp > start_timestamp)
);

CREATE TABLE bids (
	owner_username VARCHAR,
      pet_name VARCHAR,
      bid_start_timestamp TIMESTAMP,
      bid_end_timestamp TIMESTAMP,
      avail_start_timestamp TIMESTAMP,
      avail_end_timestamp TIMESTAMP,
      caretaker_username VARCHAR,
      rating NUMERIC,
      review VARCHAR,
      is_successful BOOLEAN,
      payment_method VARCHAR,
      mode_of_transfer VARCHAR,
      is_paid BOOLEAN,
      total_price NUMERIC NOT NULL CHECK (total_price > 0),
      type_of_service VARCHAR NOT NULL,
      PRIMARY KEY (pet_name, owner_username, bid_start_timestamp,  caretaker_username, avail_start_timestamp),
      FOREIGN KEY (bid_start_timestamp, bid_end_timestamp) REFERENCES Timings(start_timestamp, end_timestamp),
      FOREIGN KEY (avail_start_timestamp, caretaker_username) REFERENCES declares_availabilities(start_timestamp, caretaker_username),
      FOREIGN KEY (pet_name, owner_username) REFERENCES ownsPets(name, username),
      CHECK (bid_start_timestamp >= avail_start_timestamp),
      CHECK (bid_end_timestamp <= avail_end_timestamp)
);

CREATE OR REPLACE PROCEDURE insert_bid(ou VARCHAR, pn VARCHAR, ps TIMESTAMP, pe TIMESTAMP, sd TIMESTAMP, ed TIMESTAMP, ct VARCHAR, ts VARCHAR) AS
$$ DECLARE tot_p NUMERIC;
BEGIN
SELECT DATE_PART('day', pe - ps) INTO tot_p;
tot_p := tot_p * 10;
IF NOT EXISTS (SELECT 1 FROM TIMINGS WHERE start_timestamp = ps AND end_timestamp = pe) THEN INSERT INTO TIMINGS VALUES (ps, pe); END IF;
INSERT INTO bids VALUES (ou, pn, ps, pe, sd, ed, ct, NULL, NULL, NULL, NULL, NULL, NULL, tot_p, ts);
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


--Update bids
-- Check that the new bid period coincide with availability period
-- TODO: Check that pet belongs ot a category that caretaker can care for
CREATE OR REPLACE FUNCTION update_bids()
RETURNS TRIGGER AS
$$ DECLARE first_result INTEGER := 0;
  DECLARE second_result INTEGER := 0;
  DECLARE total_result INTEGER;
  BEGIN

  END $$
LANGUAGE plpgsql;

CREATE TRIGGER update_bids
BEFORE UPDATE ON bids
FOR EACH ROW EXECUTE PROCEDURE update_bids();



-- SEED VALUES
--Owners
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('umilnekw', 'Ursola', 'Milne', 'NSi0QM', 'umilnekw@1688.com', '1966-06-28', '3540690534311344', null, '683160', 'https://robohash.org/quibusdamquilibero.jpg?size=50x50&set=set1', '2020-03-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pbaughkx', 'Payton', 'Baugh', 'X3qaHuwHt', 'pbaughkx@narod.ru', '1963-03-28', '670624704771977496', null, '554407', 'https://robohash.org/etnesciuntsaepe.jpg?size=50x50&set=set1', '2020-08-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('scheakeky', 'Sheena', 'Cheake', 'ZuuoBL7OPh', 'scheakeky@cdc.gov', '1963-08-28', '3581330542772753', '65-915', '647281', 'https://robohash.org/nontotamad.bmp?size=50x50&set=set1', '2020-03-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('byglesiakz', 'Beniamino', 'Yglesia', 'maA37U', 'byglesiakz@ocn.ne.jp', '1954-08-29', '5443802514077901', null, '504239', 'https://robohash.org/quidemrerumest.bmp?size=50x50&set=set1', '2020-04-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lgriegl0', 'Lovell', 'Grieg', 'lhWDIgguY', 'lgriegl0@yahoo.co.jp', '1975-12-21', '3587063167852642', null, '886734', 'https://robohash.org/placeatvelitaperiam.jpg?size=50x50&set=set1', '2020-07-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jedinborol1', 'Jodee', 'Edinboro', 'nycAiwH2s', 'jedinborol1@umn.edu', '1994-10-31', '3555447838763429', null, '887293', 'https://robohash.org/doloremidut.bmp?size=50x50&set=set1', '2020-05-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('qlawrinsonl2', 'Quincey', 'Lawrinson', 'atJPNr', 'qlawrinsonl2@cdbaby.com', '1951-05-29', '3576017341566596', '99-216', '836002', 'https://robohash.org/placeatblanditiissimilique.jpg?size=50x50&set=set1', '2020-04-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ehedditchl3', 'Etheline', 'Hedditch', 'Zcq0Sq', 'ehedditchl3@surveymonkey.com', '1963-12-30', '4936284651162066847', '86-641', '485285', 'https://robohash.org/avoluptatemquia.png?size=50x50&set=set1', '2020-03-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('amasserl4', 'Amory', 'Masser', '1UQYfk8D', 'amasserl4@prnewswire.com', '1971-08-18', '5602241213067532', null, '943404', 'https://robohash.org/architectocorporisillum.png?size=50x50&set=set1', '2020-09-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dhoyl5', 'Devina', 'Hoy', 'HvXD8z', 'dhoyl5@lulu.com', '1978-09-01', '3583323729133657', '20-395', '953841', 'https://robohash.org/rerumlaborumnostrum.bmp?size=50x50&set=set1', '2020-10-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cdrewittl6', 'Conney', 'Drewitt', 'YgUcgW6j', 'cdrewittl6@storify.com', '1960-08-07', '5602252408926150', '59-879', '190404', 'https://robohash.org/eosomnisearum.png?size=50x50&set=set1', '2020-05-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('fwyethl7', 'Fin', 'Wyeth', 'WmTWRBABU43', 'fwyethl7@google.es', '1971-01-10', '4917379534988789', '83-887', '163494', 'https://robohash.org/animiutid.bmp?size=50x50&set=set1', '2020-04-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mrickesiesl8', 'Mala', 'Rickesies', 'h5szKI', 'mrickesiesl8@phpbb.com', '1996-07-25', '30142405680467', '76-968', '950638', 'https://robohash.org/rerumimpeditdolore.jpg?size=50x50&set=set1', '2020-09-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mkaradzasl9', 'Martie', 'Karadzas', 'kXKvGaZdnj', 'mkaradzasl9@businessinsider.com', '1990-02-11', '3588148496479768', null, '529195', 'https://robohash.org/culpatemporibusut.bmp?size=50x50&set=set1', '2020-10-23');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('eillidgela', 'Etti', 'Illidge', 'WVOZxv', 'eillidgela@blogger.com', '1974-01-06', '6759648992201661015', null, '236460', 'https://robohash.org/adnatusblanditiis.jpg?size=50x50&set=set1', '2020-07-04');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ccarisslb', 'Clive', 'Cariss', 'tChIzYV', 'ccarisslb@nytimes.com', '1999-02-25', '3536955009692288', '76-587', '078861', 'https://robohash.org/voluptatemeumnon.jpg?size=50x50&set=set1', '2020-02-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pchillingworthlc', 'Phillie', 'Chillingworth', 'zCTxb4qFoFJ', 'pchillingworthlc@desdev.cn', '1995-09-09', '5602252374399119', '57-258', '061191', 'https://robohash.org/repudiandaequivoluptatem.png?size=50x50&set=set1', '2020-05-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bshwennld', 'Blakeley', 'Shwenn', 'YQGfZeXAZ', 'bshwennld@trellian.com', '1997-10-13', '36362836853707', '80-176', '554352', 'https://robohash.org/eaquereiciendisoptio.png?size=50x50&set=set1', '2020-10-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('iwaulkerle', 'Ingeborg', 'Waulker', 'NZwNuaTb', 'iwaulkerle@exblog.jp', '1983-02-02', '3567094224016818', null, '221557', 'https://robohash.org/saepealiquamsed.jpg?size=50x50&set=set1', '2020-02-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cbonseylf', 'Carissa', 'Bonsey', 'jJD4gVX', 'cbonseylf@google.co.jp', '1996-12-16', '3574699436485758', '87-087', '831778', 'https://robohash.org/situtet.bmp?size=50x50&set=set1', '2020-10-29');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tapedailelg', 'Tedmund', 'Apedaile', 'j6G28DKVSYOe', 'tapedailelg@scribd.com', '1997-11-30', '5018534431531100161', null, '479795', 'https://robohash.org/utsolutaat.png?size=50x50&set=set1', '2020-09-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('acuschierilh', 'Ameline', 'Cuschieri', '246vRkT4a', 'acuschierilh@altervista.org', '1975-03-04', '6391195931438248', null, '286357', 'https://robohash.org/recusandaequasinatus.jpg?size=50x50&set=set1', '2020-03-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mhealingsli', 'Mab', 'Healings', 'Rv42pxd2I0', 'mhealingsli@google.com.au', '1956-10-06', '3568608289430629', null, '948168', 'https://robohash.org/velitvoluptatumalias.jpg?size=50x50&set=set1', '2020-05-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rsuggeylj', 'Rodd', 'Suggey', 'ueXGZQU', 'rsuggeylj@csmonitor.com', '1960-09-30', '4913349493244155', '72-972', '519872', 'https://robohash.org/quinisiqui.jpg?size=50x50&set=set1', '2020-01-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ideminicolk', 'Isidora', 'De Minico', '1sLd0w6WfX2', 'ideminicolk@si.edu', '1971-06-01', '4508960560353983', null, '546171', 'https://robohash.org/similiquesinttenetur.jpg?size=50x50&set=set1', '2020-07-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tsimecekll', 'Tanya', 'Simecek', 'PFfBhJ0tpbL', 'tsimecekll@huffingtonpost.com', '1977-10-04', '3571272527529869', null, '714671', 'https://robohash.org/eumipsamnisi.bmp?size=50x50&set=set1', '2020-08-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dabramzonlm', 'Dewain', 'Abramzon', 'Y3dIq8', 'dabramzonlm@multiply.com', '2001-07-05', '3588380864294277', '16-680', '904262', 'https://robohash.org/reprehenderitcorporisprovident.jpg?size=50x50&set=set1', '2020-11-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mcastaignetln', 'Merrielle', 'Castaignet', 'ruhpd4tR', 'mcastaignetln@xrea.com', '1984-02-01', '3589641000137319', null, '972819', 'https://robohash.org/repellatdeseruntminus.png?size=50x50&set=set1', '2020-06-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lmarnanelo', 'Lelah', 'Marnane', 'TNiuYK8', 'lmarnanelo@samsung.com', '1952-08-04', '5602237293155288', '51-177', '825487', 'https://robohash.org/autvoluptatibusmollitia.bmp?size=50x50&set=set1', '2020-03-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rbambrughlp', 'Ricki', 'Bambrugh', 'O4CTnNz5maoq', 'rbambrughlp@sphinn.com', '1965-09-24', '67590366636305302', '66-891', '395798', 'https://robohash.org/voluptasautemtenetur.bmp?size=50x50&set=set1', '2020-10-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('spleaselq', 'Sosanna', 'Please', 'jJJzbe3B', 'spleaselq@youku.com', '1977-09-27', '337941035656791', null, '802914', 'https://robohash.org/autessequas.bmp?size=50x50&set=set1', '2020-02-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hhebsonlr', 'Harlie', 'Hebson', 'le1sJcURA2', 'hhebsonlr@jimdo.com', '1971-03-25', '630441852788474653', '93-744', '508001', 'https://robohash.org/possimusmagnimaxime.png?size=50x50&set=set1', '2020-11-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jgyerls', 'Jaquith', 'Gyer', 'c4QI8D4goM7', 'jgyerls@nba.com', '1958-04-29', '3576475926532153', '50-194', '117255', 'https://robohash.org/eaeiuseum.bmp?size=50x50&set=set1', '2020-10-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rmaylinglt', 'Robbie', 'Mayling', '0Kq6H59W3G4', 'rmaylinglt@businessweek.com', '1974-11-06', '3570483688993767', null, '535667', 'https://robohash.org/nobissolutanecessitatibus.png?size=50x50&set=set1', '2020-04-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('akayzerlu', 'Arie', 'Kayzer', 'OWqfsYdaEh', 'akayzerlu@bing.com', '1970-07-05', '3584744136541019', null, '193764', 'https://robohash.org/molestiasvoluptatumperferendis.jpg?size=50x50&set=set1', '2020-04-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('vcroshamlv', 'Vere', 'Crosham', '3NtNZnvoUIuN', 'vcroshamlv@accuweather.com', '1959-12-09', '3543938280593194', null, '630694', 'https://robohash.org/quiaveniamquis.jpg?size=50x50&set=set1', '2020-08-29');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lholahlw', 'Lezley', 'Holah', 'WV93XUHeP5K1', 'lholahlw@ted.com', '1960-12-13', '3540376102886756', null, '324013', 'https://robohash.org/eosquaesed.png?size=50x50&set=set1', '2020-05-21');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kbottenlx', 'Kelli', 'Botten', 'iBLuJ4DE', 'kbottenlx@4shared.com', '1997-02-10', '67636935095568760', '02-282', '451461', 'https://robohash.org/minimaexplicaboautem.png?size=50x50&set=set1', '2020-07-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ccrawforthly', 'Carie', 'Crawforth', 'F0x882JuHs', 'ccrawforthly@ebay.com', '1988-03-08', '4026755187146726', null, '854290', 'https://robohash.org/impediteumconsequatur.bmp?size=50x50&set=set1', '2020-07-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mrigollelz', 'Mirabel', 'Rigolle', 'hAxxCMwZwg', 'mrigollelz@toplist.cz', '1991-05-01', '30121547285005', '89-169', '189218', 'https://robohash.org/sunteaqueet.jpg?size=50x50&set=set1', '2020-09-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('afoyem0', 'Abigail', 'Foye', 'wZ7DVK4', 'afoyem0@icq.com', '1985-06-23', '3582060055667343', '86-050', '575803', 'https://robohash.org/nonofficiisnatus.jpg?size=50x50&set=set1', '2020-10-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rmadrellm1', 'Rodi', 'Madrell', 'NtKsLnCaJ', 'rmadrellm1@vkontakte.ru', '1982-10-05', '201981168129292', '58-069', '385415', 'https://robohash.org/officiaeligendiatque.jpg?size=50x50&set=set1', '2020-09-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kwarrm2', 'Kev', 'Warr', 'n4Ig63IY6', 'kwarrm2@smh.com.au', '1989-12-31', '337941348211565', '56-697', '065349', 'https://robohash.org/quodquamoccaecati.png?size=50x50&set=set1', '2020-06-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ajanuszkiewiczm3', 'Adi', 'Januszkiewicz', 'JQb3Vi', 'ajanuszkiewiczm3@amazonaws.com', '1990-11-23', '3567732475902968', null, '154815', 'https://robohash.org/eaqueperferendisomnis.png?size=50x50&set=set1', '2020-06-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mmateuszczykm4', 'Madison', 'Mateuszczyk', 'eDLSPUK', 'mmateuszczykm4@illinois.edu', '1971-02-13', '3539891729285045', '24-581', '914116', 'https://robohash.org/aspernaturliberoerror.png?size=50x50&set=set1', '2020-02-27');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('oglynem5', 'Olva', 'Glyne', 'o3sxJOG', 'oglynem5@opera.com', '2001-05-22', '5100176044861801', null, '507220', 'https://robohash.org/aperiammollitiafacere.png?size=50x50&set=set1', '2020-07-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hruitm6', 'Heather', 'Ruit', 'okqBA3l3g', 'hruitm6@g.co', '1999-12-11', '3564302732877016', '29-889', '423997', 'https://robohash.org/utnihilcumque.png?size=50x50&set=set1', '2020-04-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lmcginnism7', 'Letitia', 'McGinnis', 'f9hqr8Pa3bNf', 'lmcginnism7@acquirethisname.com', '1999-02-27', '3569155102121208', '38-340', '732506', 'https://robohash.org/solutaaliquidvoluptatum.jpg?size=50x50&set=set1', '2020-05-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tdemkowiczm8', 'Trude', 'Demkowicz', 'yIoPnTAf', 'tdemkowiczm8@ow.ly', '1996-09-16', '5007668873654533', '86-668', '108862', 'https://robohash.org/quasiinventoredolores.png?size=50x50&set=set1', '2020-01-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('twolfem9', 'Tybalt', 'Wolfe', 'SmzG5l', 'twolfem9@freewebs.com', '1998-02-07', '374622573075081', null, '421052', 'https://robohash.org/quisiureaut.bmp?size=50x50&set=set1', '2020-07-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ocollierma', 'Oswell', 'Collier', 'P7hpkYTE9', 'ocollierma@marriott.com', '1982-05-23', '3564660066835722', '07-062', '687899', 'https://robohash.org/eumdistinctiooccaecati.bmp?size=50x50&set=set1', '2020-07-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gporchmb', 'Grissel', 'Porch', 'A4nRQvN', 'gporchmb@cisco.com', '1950-04-06', '3557535789632656', '88-948', '300590', 'https://robohash.org/veritatisquashic.png?size=50x50&set=set1', '2020-06-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ngillimghammc', 'Nalani', 'Gillimgham', 'r7qqVKDz', 'ngillimghammc@umich.edu', '1974-11-04', '36061587283797', '49-150', '730470', 'https://robohash.org/sedquaserror.jpg?size=50x50&set=set1', '2020-08-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('aashpitalmd', 'Andrea', 'Ashpital', 'ebnoqmfPFH6e', 'aashpitalmd@wp.com', '1993-12-20', '5602233896164215', '59-072', '720251', 'https://robohash.org/aliasquideserunt.jpg?size=50x50&set=set1', '2020-08-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('amacteggartme', 'Adelaida', 'MacTeggart', 'D4zK0TqPFBV4', 'amacteggartme@barnesandnoble.com', '1956-02-02', '3579058362057617', null, '549669', 'https://robohash.org/quisetqui.jpg?size=50x50&set=set1', '2020-06-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kmacmenamiemf', 'Katherina', 'MacMenamie', '3x3X4cKGH', 'kmacmenamiemf@chronoengine.com', '1975-01-21', '6391200004635512', '72-270', '578274', 'https://robohash.org/isteveliusto.png?size=50x50&set=set1', '2020-08-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('iheaneymg', 'Isidor', 'Heaney', '8Kkmlf7P5y', 'iheaneymg@geocities.jp', '1967-05-28', '3574672355963543', '68-961', '791093', 'https://robohash.org/velitdignissimosiusto.jpg?size=50x50&set=set1', '2020-08-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('goscroftmh', 'Ginnifer', 'Oscroft', '428JWU', 'goscroftmh@google.co.uk', '1950-05-18', '3566399337864322', null, '911374', 'https://robohash.org/utdoloremqueaspernatur.jpg?size=50x50&set=set1', '2020-10-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gmerigotmi', 'Giustina', 'Merigot', 'w4DAFN', 'gmerigotmi@weather.com', '1970-01-17', '3556226712780926', null, '695777', 'https://robohash.org/temporibusofficiisincidunt.png?size=50x50&set=set1', '2020-10-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('narnleymj', 'Nikoletta', 'Arnley', 'BMuOlM', 'narnleymj@a8.net', '1991-01-21', '3565898466738794', null, '090324', 'https://robohash.org/pariaturvoluptatemrepellendus.png?size=50x50&set=set1', '2020-01-21');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('aboltmk', 'Arnaldo', 'Bolt', 'fVQB1L', 'aboltmk@ucsd.edu', '1995-05-18', '374622173721498', '01-663', '252844', 'https://robohash.org/sequiconsequaturvitae.jpg?size=50x50&set=set1', '2020-06-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ddanilovml', 'Dyan', 'Danilov', 'FJablDG8', 'ddanilovml@360.cn', '1993-04-10', '3567633796252010', null, '544614', 'https://robohash.org/mollitiadelectustemporibus.png?size=50x50&set=set1', '2020-06-23');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jhalesworthmm', 'Jennee', 'Halesworth', 'rrRqHqSVT', 'jhalesworthmm@digg.com', '1955-01-20', '50203709714594898', null, '804393', 'https://robohash.org/nequeasperioresa.jpg?size=50x50&set=set1', '2020-05-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kkingerbymn', 'Kiel', 'Kingerby', 'fepEFipMNU', 'kkingerbymn@typepad.com', '1979-05-11', '201782948809157', '57-667', '810064', 'https://robohash.org/magnirerumrepellendus.png?size=50x50&set=set1', '2020-01-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ukrinkmo', 'Ursola', 'Krink', 'eKDj1IVfR78', 'ukrinkmo@prnewswire.com', '1989-11-03', '201604843557857', '36-184', '958055', 'https://robohash.org/itaquesapienteet.bmp?size=50x50&set=set1', '2020-06-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jgyrgorcewicxmp', 'Johan', 'Gyrgorcewicx', 'vyT3fMDM', 'jgyrgorcewicxmp@dagondesign.com', '1961-01-13', '5602223486813784', null, '594635', 'https://robohash.org/consequunturperspiciatisaut.bmp?size=50x50&set=set1', '2020-10-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('vamthormq', 'Virgina', 'Amthor', 'mzDKvo6dDEK', 'vamthormq@scientificamerican.com', '1966-04-20', '5602213021461710', '37-201', '126216', 'https://robohash.org/quiseoseaque.jpg?size=50x50&set=set1', '2020-01-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mbenfieldmr', 'Matthias', 'Benfield', 'chKiMILfsdc', 'mbenfieldmr@alexa.com', '1987-08-01', '06042124386539956', '05-854', '887049', 'https://robohash.org/optioetet.jpg?size=50x50&set=set1', '2020-03-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sheusticems', 'Sheila-kathryn', 'Heustice', 'PzeyBwEmc', 'sheusticems@theatlantic.com', '1997-11-28', '201820543517583', null, '531191', 'https://robohash.org/eiusquidemsed.jpg?size=50x50&set=set1', '2020-02-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mdiemmt', 'Molli', 'Diem', 'tmpMSR', 'mdiemmt@theglobeandmail.com', '1963-12-16', '201886410623333', '43-475', '087305', 'https://robohash.org/enimdelectustotam.jpg?size=50x50&set=set1', '2020-03-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sfarrantsmu', 'Salvidor', 'Farrants', 'CyUQQSlKvsi', 'sfarrantsmu@hostgator.com', '1963-08-14', '3545106368112315', null, '244209', 'https://robohash.org/illoconsequunturducimus.bmp?size=50x50&set=set1', '2020-09-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bcanningsmv', 'Brianna', 'Cannings', '3aR6qY', 'bcanningsmv@furl.net', '1961-02-18', '3583134364569067', '89-676', '124172', 'https://robohash.org/fugaofficiisvero.png?size=50x50&set=set1', '2020-03-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('okennellymw', 'Olia', 'Kennelly', 'jLRi8H2lE', 'okennellymw@reddit.com', '1984-08-18', '30397823798545', '36-242', '304256', 'https://robohash.org/nihillaudantiumconsequatur.jpg?size=50x50&set=set1', '2020-09-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rbruntjemx', 'Roi', 'Bruntje', 'nAsFTO', 'rbruntjemx@lulu.com', '1991-03-08', '3561861054772041', '98-203', '362535', 'https://robohash.org/nihilpariaturet.bmp?size=50x50&set=set1', '2020-05-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cbrenardmy', 'Chad', 'Brenard', 'ryKStvXb', 'cbrenardmy@free.fr', '1972-06-10', '5002357380629577', '02-767', '986676', 'https://robohash.org/iddelenitivelit.jpg?size=50x50&set=set1', '2020-05-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cmcclaymz', 'Carson', 'McClay', 'ERVeOZF', 'cmcclaymz@marketwatch.com', '1965-10-13', '201576811891114', null, '341233', 'https://robohash.org/aliasquianihil.bmp?size=50x50&set=set1', '2020-07-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sbuzekn0', 'Slade', 'Buzek', 'FtgemuT', 'sbuzekn0@smh.com.au', '1966-01-29', '5602244214084030189', null, '592390', 'https://robohash.org/pariaturnatusincidunt.jpg?size=50x50&set=set1', '2020-05-31');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nswitzern1', 'Nelli', 'Switzer', 'lndMSlG9GV', 'nswitzern1@instagram.com', '1994-06-17', '3560437923220453', '65-855', '180198', 'https://robohash.org/odiovelitdolor.bmp?size=50x50&set=set1', '2020-04-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('blivermoren2', 'Barris', 'Livermore', 'Ou2uIL', 'blivermoren2@virginia.edu', '2001-02-17', '4844998918736726', '54-457', '824866', 'https://robohash.org/autquiet.jpg?size=50x50&set=set1', '2020-05-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gchallonern3', 'Godwin', 'Challoner', 'LSjG88', 'gchallonern3@plala.or.jp', '1958-10-12', '5602244207075078738', null, '392103', 'https://robohash.org/quisinciduntat.png?size=50x50&set=set1', '2020-03-27');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cmilillon4', 'Cassondra', 'Milillo', 'zhG1ax', 'cmilillon4@earthlink.net', '1957-05-10', '4175005809673734', null, '760609', 'https://robohash.org/quasvoluptateexcepturi.bmp?size=50x50&set=set1', '2020-05-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('yhatheralln5', 'Yoshiko', 'Hatherall', 'hYxghIinM', 'yhatheralln5@discovery.com', '1991-08-18', '3555298644990072', null, '734630', 'https://robohash.org/quoevenietducimus.bmp?size=50x50&set=set1', '2020-09-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mpeaseen6', 'Maryanne', 'Peasee', 'yNfBsCBv', 'mpeaseen6@edublogs.org', '1976-02-13', '4041370341724201', null, '944330', 'https://robohash.org/autquisquamet.jpg?size=50x50&set=set1', '2020-04-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jtroweln7', 'Jody', 'Trowel', 'NrxzntTH', 'jtroweln7@twitpic.com', '1953-12-24', '201406239373463', '90-904', '343664', 'https://robohash.org/autnesciuntut.bmp?size=50x50&set=set1', '2020-02-23');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dsmalemann8', 'Dianna', 'Smaleman', '38futC', 'dsmalemann8@infoseek.co.jp', '1974-11-24', '3552328345772777', '48-158', '659324', 'https://robohash.org/facilislaboriosamut.bmp?size=50x50&set=set1', '2020-07-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('alightwoodn9', 'Ardelia', 'Lightwood', 'Y1iR3qUz', 'alightwoodn9@fotki.com', '2000-05-09', '6334758305658452978', null, '277258', 'https://robohash.org/voluptatumodiodelectus.jpg?size=50x50&set=set1', '2020-02-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('zilyuchyovna', 'Zulema', 'Ilyuchyov', 'Ma7gVq7Je', 'zilyuchyovna@about.me', '1999-08-29', '4405771546835942', null, '357675', 'https://robohash.org/idquisadipisci.bmp?size=50x50&set=set1', '2020-06-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bmessagenb', 'Burl', 'Message', 'jY0SoTxl', 'bmessagenb@cdc.gov', '1994-04-18', '3544078920481143', null, '926141', 'https://robohash.org/nisinamdeserunt.png?size=50x50&set=set1', '2020-10-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hblucknc', 'Hattie', 'Bluck', 'OUEo6Aw', 'hblucknc@chicagotribune.com', '1975-09-28', '3550508189889652', '50-650', '983426', 'https://robohash.org/autquiab.jpg?size=50x50&set=set1', '2020-05-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('vwinsparnd', 'Veronika', 'Winspar', '13PrDkg', 'vwinsparnd@patch.com', '1985-07-31', '5223266386816349', '10-560', '200133', 'https://robohash.org/atquevoluptatemest.jpg?size=50x50&set=set1', '2020-04-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pdockreayne', 'Paulina', 'Dockreay', 'cZvgpfzjc', 'pdockreayne@vk.com', '1996-02-25', '3533395202271635', '43-656', '360026', 'https://robohash.org/itaquevoluptasut.bmp?size=50x50&set=set1', '2020-02-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mlovienf', 'Margalit', 'Lovie', 'EQlJmg', 'mlovienf@amazonaws.com', '2000-12-15', '3541071164682396', null, '269006', 'https://robohash.org/suntesseofficia.bmp?size=50x50&set=set1', '2020-10-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kbedsonng', 'Kippie', 'Bedson', 'X0bEm1l6a7', 'kbedsonng@imageshack.us', '1972-07-06', '630474348893417752', '83-457', '328660', 'https://robohash.org/quisautemvoluptatem.bmp?size=50x50&set=set1', '2020-09-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sdrustnh', 'Shelia', 'Drust', 'keQ7939N27Vc', 'sdrustnh@ask.com', '1983-06-30', '6334962116500690', null, '356919', 'https://robohash.org/repellendusomnisquas.png?size=50x50&set=set1', '2020-07-04');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cpilkintonni', 'Cathi', 'Pilkinton', 'jH9t3OSZQ', 'cpilkintonni@fc2.com', '1965-10-20', '3548028183652720', '12-481', '661357', 'https://robohash.org/aliquamdelenitinon.bmp?size=50x50&set=set1', '2020-04-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sfeeknj', 'Sergei', 'Feek', '0y5IcaWl12ya', 'sfeeknj@imgur.com', '2001-07-04', '3569729397538829', '45-915', '619592', 'https://robohash.org/odiovitaeexercitationem.bmp?size=50x50&set=set1', '2020-05-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dinnocentnk', 'Darwin', 'Innocent', 'PpwnMFMATHU', 'dinnocentnk@state.gov', '1979-08-26', '372301337216958', null, '697922', 'https://robohash.org/enimnonsuscipit.png?size=50x50&set=set1', '2020-07-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bmacdearmaidnl', 'Brittany', 'MacDearmaid', 'NFf09uD', 'bmacdearmaidnl@scribd.com', '2000-10-21', '4405085045262205', null, '641334', 'https://robohash.org/molestiaeadipisciut.png?size=50x50&set=set1', '2020-02-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('fpymarnm', 'Florance', 'Pymar', 'hGSg6b2xBS', 'fpymarnm@statcounter.com', '1972-06-27', '5371035806800021', '05-770', '955445', 'https://robohash.org/illumrepudiandaeest.bmp?size=50x50&set=set1', '2020-04-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('egisburnenn', 'Elisha', 'Gisburne', '6EWwbJQv', 'egisburnenn@canalblog.com', '1961-10-08', '3564645140988597', null, '319847', 'https://robohash.org/ipsamautex.jpg?size=50x50&set=set1', '2020-10-23');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hpetono', 'Holmes', 'Peto', 'UnB6GlP5p', 'hpetono@hugedomains.com', '1964-01-27', '3556020566089231', '76-850', '025716', 'https://robohash.org/autminimaquo.bmp?size=50x50&set=set1', '2020-09-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cethertonnp', 'Currie', 'Etherton', 'v6MWBczQ9qQx', 'cethertonnp@washington.edu', '1984-08-12', '6763105630610906583', null, '858615', 'https://robohash.org/quibusdamdebitisenim.jpg?size=50x50&set=set1', '2020-08-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bmattheissennq', 'Brooks', 'Mattheissen', 'MEgHfb5O7t', 'bmattheissennq@dot.gov', '1954-11-10', '50187653919855359', '06-979', '085280', 'https://robohash.org/estetet.jpg?size=50x50&set=set1', '2020-02-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('glamplughnr', 'Gianna', 'Lamplugh', 'PsZKexye9b', 'glamplughnr@wp.com', '1984-03-06', '6759035978764047602', '97-063', '703225', 'https://robohash.org/voluptasetet.bmp?size=50x50&set=set1', '2020-05-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cdrissellns', 'Curry', 'Drissell', 'GvxrvCgC', 'cdrissellns@ezinearticles.com', '1982-01-24', '6304362760153571', '04-430', '660533', 'https://robohash.org/maioresvelodit.png?size=50x50&set=set1', '2020-02-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nlabinnt', 'Nicki', 'Labin', 'fZLDbXRD', 'nlabinnt@newsvine.com', '1999-07-30', '5641825832538506077', '36-576', '124689', 'https://robohash.org/doloreeumrecusandae.jpg?size=50x50&set=set1', '2020-08-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('yamottnu', 'Yanaton', 'Amott', 'H0nfdgV4S0G', 'yamottnu@indiegogo.com', '2000-12-19', '560222017469676364', '34-464', '554530', 'https://robohash.org/rationeenimullam.png?size=50x50&set=set1', '2020-01-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ngodwinnv', 'Nichol', 'Godwin', '50dLTzpEJ', 'ngodwinnv@netlog.com', '1999-08-22', '5002350675424572', '05-470', '154065', 'https://robohash.org/doloresapientedeleniti.png?size=50x50&set=set1', '2020-07-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bwyeldnw', 'Bernarr', 'Wyeld', 'NyqtpeB', 'bwyeldnw@home.pl', '1959-01-13', '3573830462443863', null, '014992', 'https://robohash.org/occaecatiautexplicabo.bmp?size=50x50&set=set1', '2020-02-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sholbynx', 'Sherline', 'Holby', '2RKWZssi9wZ', 'sholbynx@springer.com', '1981-12-12', '3555826390289214', '00-093', '558314', 'https://robohash.org/quasivitaequod.jpg?size=50x50&set=set1', '2020-04-21');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gprandony', 'Georgy', 'Prando', 'SsbiXsVV3ds', 'gprandony@huffingtonpost.com', '1957-08-16', '5641824995660206773', '55-220', '069347', 'https://robohash.org/quamtotamconsequuntur.png?size=50x50&set=set1', '2020-07-04');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ebordesnz', 'Edee', 'Bordes', 'ZTJlk72e6H', 'ebordesnz@github.io', '1970-08-07', '3559118314410472', null, '296139', 'https://robohash.org/voluptatumesteius.png?size=50x50&set=set1', '2020-09-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rfedynskio0', 'Rubina', 'Fedynski', 'H1YjzjQ', 'rfedynskio0@nifty.com', '1994-04-09', '201860851366629', '49-119', '639960', 'https://robohash.org/etvoluptatemsed.png?size=50x50&set=set1', '2020-04-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cnorreso1', 'Calla', 'Norres', 'am7Vlako3', 'cnorreso1@w3.org', '1986-08-11', '378780700664577', null, '398581', 'https://robohash.org/consequaturnonrepellendus.bmp?size=50x50&set=set1', '2020-02-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pcattlowo2', 'Prudence', 'Cattlow', 'fXM066SDTds', 'pcattlowo2@hibu.com', '1970-02-20', '5002350908579978', null, '532882', 'https://robohash.org/ataccusantiumtempora.jpg?size=50x50&set=set1', '2020-10-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('acroxallo3', 'Arvy', 'Croxall', 'JZNKJOkrOkSa', 'acroxallo3@symantec.com', '1963-01-02', '3547482211481373', '21-891', '645625', 'https://robohash.org/nemodoloremfacere.jpg?size=50x50&set=set1', '2020-09-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gmccuiso4', 'Giffie', 'McCuis', 'MIkB4K0sv2O', 'gmccuiso4@admin.ch', '1952-02-18', '5321551316325409', null, '470059', 'https://robohash.org/nesciuntisterem.png?size=50x50&set=set1', '2020-07-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('eraundo5', 'Eartha', 'Raund', '3tKlmBS8pdc4', 'eraundo5@amazon.com', '1971-06-08', '4017956176986', '19-659', '698159', 'https://robohash.org/velpossimusa.bmp?size=50x50&set=set1', '2020-05-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dcargillo6', 'Davidson', 'Cargill', 'bDogl8M', 'dcargillo6@biblegateway.com', '1989-06-26', '3572628323540815', '65-354', '226812', 'https://robohash.org/utcumqueeveniet.jpg?size=50x50&set=set1', '2020-05-31');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ldurrado7', 'Lyndy', 'Durrad', 'U5u4WaZyoV', 'ldurrado7@bloglovin.com', '1984-05-14', '5010121924745590', '31-219', '490606', 'https://robohash.org/iustocommodidignissimos.bmp?size=50x50&set=set1', '2020-03-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('aizakoffo8', 'Aura', 'Izakoff', 'vB7KbjJ', 'aizakoffo8@diigo.com', '1971-03-09', '3557170103223683', null, '120387', 'https://robohash.org/exercitationemvoluptasab.png?size=50x50&set=set1', '2020-03-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ttymo9', 'Tanhya', 'Tym', '3y4Zbz9Ayt', 'ttymo9@facebook.com', '1969-09-17', '5610628388535089', '32-709', '493111', 'https://robohash.org/molestiaspraesentiumsit.jpg?size=50x50&set=set1', '2020-08-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kbassanooa', 'Kristofer', 'Bassano', 'iNN8Skh2w6HX', 'kbassanooa@hexun.com', '1957-12-17', '3538257411599229', '09-209', '367471', 'https://robohash.org/insequisit.png?size=50x50&set=set1', '2020-03-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rmarskellob', 'Rosina', 'Marskell', 'PyW5QQM', 'rmarskellob@vk.com', '1964-12-30', '201770620588199', null, '904784', 'https://robohash.org/minimavoluptasquia.jpg?size=50x50&set=set1', '2020-08-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dharsentoc', 'Devlen', 'Harsent', 'QCN6w2ROX', 'dharsentoc@google.de', '2001-10-26', '4405769458838318', null, '182911', 'https://robohash.org/explicaborerumad.jpg?size=50x50&set=set1', '2020-11-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nquibellod', 'Neal', 'Quibell', 'PHWtGTrw2', 'nquibellod@dion.ne.jp', '1952-05-23', '4017958105041', null, '806283', 'https://robohash.org/estcorporisnihil.bmp?size=50x50&set=set1', '2020-01-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bbatramoe', 'Berty', 'Batram', 'cfMM5Zh9tuh', 'bbatramoe@myspace.com', '1981-12-14', '6304881817756946', null, '082817', 'https://robohash.org/sitvoluptatemullam.bmp?size=50x50&set=set1', '2020-11-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ltoftof', 'Lina', 'Toft', 'QE1mp6Mc', 'ltoftof@indiatimes.com', '2001-12-21', '3586688183968534', '72-944', '456782', 'https://robohash.org/nisiquaeneque.png?size=50x50&set=set1', '2020-11-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('oroundingog', 'Osbourn', 'Rounding', 'NIL9sxB', 'oroundingog@chronoengine.com', '1955-04-09', '5310035079444089', '15-779', '505644', 'https://robohash.org/cumerrorvelit.png?size=50x50&set=set1', '2020-02-27');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dlomaxoh', 'Deonne', 'Lomax', 'JP0d8acxUAs', 'dlomaxoh@simplemachines.org', '1965-08-27', '5602246590036299', null, '545035', 'https://robohash.org/sequiharumexcepturi.bmp?size=50x50&set=set1', '2020-09-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('yjoisceoi', 'Yelena', 'Joisce', 'DU2P65Xr', 'yjoisceoi@state.gov', '1952-04-17', '3586487299070818', '76-966', '682969', 'https://robohash.org/accusamusreprehenderitquod.bmp?size=50x50&set=set1', '2020-03-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cvahloj', 'Cynthia', 'Vahl', 'ZhsqbK94O1', 'cvahloj@earthlink.net', '1962-04-15', '30272537463159', '23-653', '529070', 'https://robohash.org/ametinciduntut.bmp?size=50x50&set=set1', '2020-03-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('priddingok', 'Pepita', 'Ridding', 'qecppiFIccK', 'priddingok@cpanel.net', '1959-03-29', '5007668866230903', '04-639', '227538', 'https://robohash.org/solutaautrerum.jpg?size=50x50&set=set1', '2020-04-23');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gbrittol', 'Giavani', 'Britt', 'RZyQjvF1s39', 'gbrittol@china.com.cn', '1972-11-12', '630487925677083101', '94-393', '535964', 'https://robohash.org/delectuslaudantiumconsequatur.png?size=50x50&set=set1', '2020-10-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pdangeliom', 'Philomena', 'D''Angeli', 'YYnQ2H6OBWeB', 'pdangeliom@bbb.org', '1981-07-05', '201885056984058', '42-981', '762903', 'https://robohash.org/doloremquefacerefugit.jpg?size=50x50&set=set1', '2020-05-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nblowickon', 'Nyssa', 'Blowick', '8E9hidf9Z6C', 'nblowickon@intel.com', '1975-09-22', '30207305858198', null, '296278', 'https://robohash.org/reprehenderitpariaturquisquam.png?size=50x50&set=set1', '2020-09-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jjeppensenoo', 'Jemmie', 'Jeppensen', 'jVHG98J', 'jjeppensenoo@surveymonkey.com', '1978-07-30', '5602219274759312', '89-771', '091444', 'https://robohash.org/voluptatemestinventore.bmp?size=50x50&set=set1', '2020-11-04');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gputmanop', 'Grace', 'Putman', 'tPFFd9Gbu', 'gputmanop@feedburner.com', '1989-11-29', '3530961603515913', '92-929', '355884', 'https://robohash.org/temporibuseligendiimpedit.png?size=50x50&set=set1', '2020-09-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('heydeloq', 'Hermann', 'Eydel', 'H1ObcAaD', 'heydeloq@dmoz.org', '1973-02-24', '3548772155559617', '14-637', '144083', 'https://robohash.org/etfacilisexercitationem.png?size=50x50&set=set1', '2020-04-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('vpymmor', 'Verge', 'Pymm', 'k6NLcccYa', 'vpymmor@admin.ch', '1993-09-16', '3586880559766903', '99-792', '677322', 'https://robohash.org/etistebeatae.jpg?size=50x50&set=set1', '2020-10-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('egwinnettos', 'Estele', 'Gwinnett', 'ptJqBAU', 'egwinnettos@jimdo.com', '1978-02-17', '633432632620561304', '70-969', '329806', 'https://robohash.org/voluptatemquiaaut.png?size=50x50&set=set1', '2020-09-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('oeldrittot', 'Orazio', 'Eldritt', 'LsNZRk', 'oeldrittot@ocn.ne.jp', '1976-11-23', '4936579224214288217', '48-400', '589012', 'https://robohash.org/enimeiusid.png?size=50x50&set=set1', '2020-02-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('wgrinovou', 'Waldo', 'Grinov', '7bkxyM', 'wgrinovou@weibo.com', '1973-07-03', '630431503412167310', '25-455', '765717', 'https://robohash.org/rerumrecusandaereiciendis.bmp?size=50x50&set=set1', '2020-06-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('edarganov', 'Ema', 'Dargan', 'SqcUIOarnI', 'edarganov@forbes.com', '1991-03-03', '3536085246057093', null, '741147', 'https://robohash.org/sedquisquamfacere.png?size=50x50&set=set1', '2020-06-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ivedekhovow', 'Ivett', 'Vedekhov', '7fVDzak7q3sr', 'ivedekhovow@mtv.com', '1962-10-19', '3583659305981989', '91-267', '119299', 'https://robohash.org/sednatusautem.png?size=50x50&set=set1', '2020-08-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sfarmarox', 'Spense', 'Farmar', '3ezHcuI', 'sfarmarox@dropbox.com', '1965-12-20', '3549734188560797', null, '816218', 'https://robohash.org/quastotamaut.png?size=50x50&set=set1', '2020-01-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nrenneoy', 'Nancee', 'Renne', 'qscBAFSe', 'nrenneoy@domainmarket.com', '1968-10-10', '67710238811956776', null, '496691', 'https://robohash.org/nobisremdoloribus.bmp?size=50x50&set=set1', '2020-10-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tseabornoz', 'Tove', 'Seaborn', '3MKZFi6dZ', 'tseabornoz@fastcompany.com', '1954-06-03', '6381236804278642', null, '488535', 'https://robohash.org/etmolestiasdolorum.png?size=50x50&set=set1', '2020-01-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cpopplewellp0', 'Cynthea', 'Popplewell', 'pVpxKsqza', 'cpopplewellp0@oaic.gov.au', '1982-03-21', '5495743920441934', '61-122', '224236', 'https://robohash.org/natusimpeditatque.png?size=50x50&set=set1', '2020-05-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mhenstonep1', 'Morey', 'Henstone', 'YUz7uWLGcqM', 'mhenstonep1@nbcnews.com', '1974-07-03', '6333485545691675', null, '124141', 'https://robohash.org/suscipitprovidentet.jpg?size=50x50&set=set1', '2020-10-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('colomanp2', 'Cal', 'Oloman', 'PWeYAsxhPss', 'colomanp2@intel.com', '1994-03-27', '3556475862763261', null, '892474', 'https://robohash.org/debitissuntvero.jpg?size=50x50&set=set1', '2020-09-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rlintheadp3', 'Rosalie', 'Linthead', '4RqlVu', 'rlintheadp3@uol.com.br', '1971-11-24', '3548014794171920', null, '907157', 'https://robohash.org/autvoluptasporro.png?size=50x50&set=set1', '2020-03-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cgheorghiep4', 'Chane', 'Gheorghie', '9yq403ecTd', 'cgheorghiep4@freewebs.com', '1976-05-17', '5038656480855941171', null, '165288', 'https://robohash.org/hicquiaeos.png?size=50x50&set=set1', '2020-02-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('afewingsp5', 'Ashia', 'Fewings', 'OiUou8zO3b5', 'afewingsp5@printfriendly.com', '2000-05-04', '3550614199979812', null, '161803', 'https://robohash.org/consequaturquiafugit.bmp?size=50x50&set=set1', '2020-05-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jbanbriggep6', 'Jacquie', 'Banbrigge', 'JR6XhX45', 'jbanbriggep6@w3.org', '1967-05-03', '3547743192468287', null, '985247', 'https://robohash.org/etrerumipsa.bmp?size=50x50&set=set1', '2020-05-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('abrookp7', 'Agace', 'Brook', '4zHGxIIfOrT', 'abrookp7@nasa.gov', '1976-05-01', '371742199513969', null, '395028', 'https://robohash.org/quisauttotam.jpg?size=50x50&set=set1', '2020-04-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('fslaneyp8', 'Filide', 'Slaney', '4pruBv', 'fslaneyp8@blogspot.com', '1983-12-19', '6761996762228233575', '04-868', '499912', 'https://robohash.org/eligendiprovidentfacere.jpg?size=50x50&set=set1', '2020-10-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('clagdenp9', 'Celie', 'Lagden', '9XXn3ccmvwD', 'clagdenp9@businessweek.com', '1968-04-03', '3575843880776218', '30-175', '449692', 'https://robohash.org/repudiandaedoloremquesaepe.bmp?size=50x50&set=set1', '2020-07-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('churranpa', 'Clo', 'Hurran', 'M4FQXYyF', 'churranpa@google.fr', '1966-02-15', '3538369337924686', '06-461', '871118', 'https://robohash.org/voluptasdignissimosatque.bmp?size=50x50&set=set1', '2020-01-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mpoggpb', 'Marne', 'Pogg', '8TBBIV', 'mpoggpb@biglobe.ne.jp', '1989-01-28', '6771885931749707', null, '736321', 'https://robohash.org/mollitiaanimimolestias.bmp?size=50x50&set=set1', '2020-05-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bstormpc', 'Bidget', 'Storm', 'vcd9e7IY', 'bstormpc@sina.com.cn', '1966-04-22', '5610231028180349', null, '892555', 'https://robohash.org/estimpeditdolor.bmp?size=50x50&set=set1', '2020-08-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('oscolepd', 'Olenolin', 'Scole', 'oN8KysfEusg', 'oscolepd@unicef.org', '1990-12-08', '30137291192882', '79-861', '996021', 'https://robohash.org/omnisautvoluptas.jpg?size=50x50&set=set1', '2020-07-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('oharriskinepe', 'Olva', 'Harriskine', 'MxDIwhhKWfp3', 'oharriskinepe@theguardian.com', '1952-08-05', '5380721983673104', '00-991', '605933', 'https://robohash.org/repudiandaemaximeatque.jpg?size=50x50&set=set1', '2020-01-29');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('soaklandpf', 'Shelli', 'Oakland', 'hhFz5J7P', 'soaklandpf@issuu.com', '1994-05-05', '5602210121520635275', '69-072', '195486', 'https://robohash.org/velhicfacilis.png?size=50x50&set=set1', '2020-05-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('akeddeypg', 'Araldo', 'Keddey', 'BMSljOyfGB', 'akeddeypg@imgur.com', '1956-06-04', '3542986574573266', null, '738544', 'https://robohash.org/quaequisquamtotam.jpg?size=50x50&set=set1', '2020-05-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('aicetonph', 'Antonietta', 'Iceton', 'UtrYyWmj2', 'aicetonph@mapquest.com', '1974-11-24', '3539826065063135', null, '025110', 'https://robohash.org/ipsumutporro.jpg?size=50x50&set=set1', '2020-07-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bbeggspi', 'Becca', 'Beggs', 's4sVjSGN5', 'bbeggspi@sakura.ne.jp', '1965-11-23', '6304180820872224', '99-603', '620669', 'https://robohash.org/molestiaequosenim.jpg?size=50x50&set=set1', '2020-01-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gpashepj', 'Gigi', 'Pashe', 'VDiTwvlkvx', 'gpashepj@google.ca', '1962-03-06', '3556873036039578', null, '470425', 'https://robohash.org/quaeratnumquamtenetur.png?size=50x50&set=set1', '2020-09-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('fkimmerlingpk', 'Free', 'Kimmerling', 'PHRE9Fa9fAY', 'fkimmerlingpk@foxnews.com', '1999-05-04', '560224077857333653', '81-684', '947335', 'https://robohash.org/quamrerumet.png?size=50x50&set=set1', '2020-05-27');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('wreaganpl', 'Winn', 'Reagan', 't1fvIp', 'wreaganpl@abc.net.au', '1982-01-19', '4936874350581077339', null, '828599', 'https://robohash.org/aspernaturetut.jpg?size=50x50&set=set1', '2020-10-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pruzickapm', 'Paola', 'Ruzicka', 'V40a6ZU', 'pruzickapm@toplist.cz', '1997-10-23', '63048736902391292', null, '390423', 'https://robohash.org/exetlaborum.jpg?size=50x50&set=set1', '2020-02-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jjewittpn', 'Johny', 'Jewitt', 'EFshNHPhG', 'jjewittpn@wired.com', '1955-02-07', '3580135840249326', '62-553', '358013', 'https://robohash.org/estipsumcupiditate.bmp?size=50x50&set=set1', '2020-08-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mfeatenbypo', 'Matthus', 'Featenby', 'wCfxWvwTQ', 'mfeatenbypo@mozilla.com', '1972-11-24', '5100177206051587', null, '817091', 'https://robohash.org/nonipsaarchitecto.bmp?size=50x50&set=set1', '2020-11-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bbartoccipp', 'Billy', 'Bartocci', '68VzKW', 'bbartoccipp@github.com', '1984-04-14', '201609888051062', '67-611', '182750', 'https://robohash.org/autrepellendusexpedita.bmp?size=50x50&set=set1', '2020-06-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dmillsappq', 'Derby', 'Millsap', '8rtenS', 'dmillsappq@baidu.com', '1976-10-25', '3570530303135933', '95-360', '026801', 'https://robohash.org/sedrerumlaborum.png?size=50x50&set=set1', '2020-07-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('emixworthypr', 'Elvis', 'Mixworthy', 'Y7WgoyLB', 'emixworthypr@hugedomains.com', '1998-04-28', '3552627011344971', '91-973', '563862', 'https://robohash.org/pariaturaliquiditaque.png?size=50x50&set=set1', '2020-02-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tgyngellps', 'Tanner', 'Gyngell', 'iMsGuXsm29y2', 'tgyngellps@hhs.gov', '1989-04-01', '6706039499381863', null, '872907', 'https://robohash.org/quisreiciendismolestias.png?size=50x50&set=set1', '2020-09-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('aburridgept', 'Ailey', 'Burridge', 'bsnUV4PPbIQ', 'aburridgept@wix.com', '1995-04-18', '3581825707686854', null, '486080', 'https://robohash.org/quiaaliquamfugit.bmp?size=50x50&set=set1', '2020-03-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rhalegarthpu', 'Rainer', 'Halegarth', 'MtfOgyaE', 'rhalegarthpu@merriam-webster.com', '1980-12-05', '374288279868391', null, '879317', 'https://robohash.org/hicconsequaturdolores.png?size=50x50&set=set1', '2020-07-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('amandreypv', 'Armando', 'Mandrey', '8x2uzhVbSC', 'amandreypv@rediff.com', '1987-01-19', '3539929161959105', '37-151', '773507', 'https://robohash.org/fugaaccusamusdebitis.png?size=50x50&set=set1', '2020-01-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('imingauldpw', 'Isidore', 'Mingauld', 'nI7fcK', 'imingauldpw@irs.gov', '1998-04-30', '5100178684416169', '53-456', '830037', 'https://robohash.org/eaquequiest.bmp?size=50x50&set=set1', '2020-05-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('abancepx', 'Audrye', 'Bance', 'CMd0qrldLWM', 'abancepx@angelfire.com', '1986-11-02', '3564217664290261', '20-519', '546055', 'https://robohash.org/beataeidvoluptate.jpg?size=50x50&set=set1', '2020-09-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cmattiessenpy', 'Clarette', 'Mattiessen', '99QCgILnJEA', 'cmattiessenpy@nhs.uk', '1980-03-23', '3561933378855255', '86-354', '174618', 'https://robohash.org/minusteneturnon.bmp?size=50x50&set=set1', '2020-10-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('gbeddinpz', 'Georgetta', 'Beddin', 'ifyFt1UZwA', 'gbeddinpz@aboutads.info', '1980-02-20', '3580291907527920', null, '815157', 'https://robohash.org/remdebitisipsam.jpg?size=50x50&set=set1', '2020-10-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sorumq0', 'Shaine', 'Orum', 'xzbBG3O81X', 'sorumq0@vistaprint.com', '2000-09-26', '201810106650947', null, '764927', 'https://robohash.org/quiaautaut.bmp?size=50x50&set=set1', '2020-05-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('msilvestonq1', 'Minnaminnie', 'Silveston', 'kIxt0BqDi', 'msilvestonq1@drupal.org', '1973-07-27', '3530841171867559', null, '944038', 'https://robohash.org/estvoluptasfacilis.jpg?size=50x50&set=set1', '2020-03-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ttellenbrokq2', 'Timothee', 'Tellenbrok', 'FJxTmmNq50Zj', 'ttellenbrokq2@lulu.com', '1952-10-25', '3539806538898259', null, '496813', 'https://robohash.org/eiussitaut.jpg?size=50x50&set=set1', '2020-07-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kmaywardq3', 'Kristy', 'Mayward', 'oufh1k9ygqm', 'kmaywardq3@ycombinator.com', '1958-07-12', '3541731527402697', null, '136114', 'https://robohash.org/fugavoluptatemipsum.bmp?size=50x50&set=set1', '2020-04-21');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ccolvineq4', 'Cammy', 'Colvine', 'dIYUWAy', 'ccolvineq4@arizona.edu', '1968-08-07', '5018673077162587', null, '078213', 'https://robohash.org/utestpariatur.jpg?size=50x50&set=set1', '2020-07-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cmacadieq5', 'Christine', 'MacAdie', 'zmMqVc652gZR', 'cmacadieq5@taobao.com', '1994-12-03', '201656590408403', null, '225821', 'https://robohash.org/molestiaenatusvoluptatum.jpg?size=50x50&set=set1', '2020-07-27');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('csantoreq6', 'Cordey', 'Santore', 'Ib76BZ79', 'csantoreq6@economist.com', '1982-08-13', '4911600560406229113', '27-080', '628956', 'https://robohash.org/saepecommodiporro.bmp?size=50x50&set=set1', '2020-04-16');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cplanteq7', 'Cicely', 'Plante', 'YAE8IHv', 'cplanteq7@rediff.com', '1988-01-30', '5610713342512125', '43-234', '152172', 'https://robohash.org/nonquiseligendi.bmp?size=50x50&set=set1', '2020-08-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lbrazenerq8', 'Lacee', 'Brazener', 'NvKhx5aFtCe', 'lbrazenerq8@miibeian.gov.cn', '1961-11-10', '5641823746733194', '12-913', '882097', 'https://robohash.org/velfacilisquaerat.png?size=50x50&set=set1', '2020-06-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bbaddamq9', 'Brody', 'Baddam', '4VoJaqxQl0C', 'bbaddamq9@cdbaby.com', '1989-12-01', '6304535322039582', '79-220', '899701', 'https://robohash.org/etomnisconsequatur.jpg?size=50x50&set=set1', '2020-10-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hbritianqa', 'Hurleigh', 'Britian', '14nkSo3M', 'hbritianqa@exblog.jp', '1992-01-29', '3541091953042180', '12-513', '034834', 'https://robohash.org/nobisvoluptatemaut.bmp?size=50x50&set=set1', '2020-09-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mtonbridgeqb', 'Milli', 'Tonbridge', 'ZJvdV5Oes', 'mtonbridgeqb@sakura.ne.jp', '1973-12-27', '3530712174052566', '56-501', '374841', 'https://robohash.org/etquasiaperiam.jpg?size=50x50&set=set1', '2020-08-09');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('eugolottiqc', 'Ediva', 'Ugolotti', '0CO7YxEOkm', 'eugolottiqc@addtoany.com', '1984-06-07', '5602224082327632689', '51-220', '800772', 'https://robohash.org/teneturminimaofficia.png?size=50x50&set=set1', '2020-10-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('agarryqd', 'Anneliese', 'Garry', 'e2gUnDx', 'agarryqd@nationalgeographic.com', '1997-03-16', '201790977215576', null, '235152', 'https://robohash.org/quodcorporisaccusantium.jpg?size=50x50&set=set1', '2020-06-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sbrevittqe', 'Stevena', 'Brevitt', 'aFnns9y6EH', 'sbrevittqe@virginia.edu', '1973-05-16', '3558282130125218', null, '708922', 'https://robohash.org/eteaut.bmp?size=50x50&set=set1', '2020-02-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bgoodaleqf', 'Becka', 'Goodale', 'sZPFPLzhRLn', 'bgoodaleqf@ft.com', '1986-06-06', '3558161062636139', null, '057606', 'https://robohash.org/ipsammagniexcepturi.png?size=50x50&set=set1', '2020-11-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('schinnqg', 'Sheela', 'Chinn', 'COAQNI', 'schinnqg@tripadvisor.com', '1977-09-01', '6767563094595678889', null, '852846', 'https://robohash.org/aasperioresvoluptatem.jpg?size=50x50&set=set1', '2020-07-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cpedlowqh', 'Christen', 'Pedlow', 'Xhinv9QMy', 'cpedlowqh@about.me', '1956-09-22', '63041576599651302', '79-961', '036677', 'https://robohash.org/quimolestiasdolorem.bmp?size=50x50&set=set1', '2020-02-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('emorganqi', 'Ephrem', 'Morgan', 'qYHIROG', 'emorganqi@state.gov', '1969-04-20', '3540374555482959', '09-347', '121629', 'https://robohash.org/perferendisinea.jpg?size=50x50&set=set1', '2020-09-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('stallowqj', 'Saxe', 'Tallow', 'PMB5G2gd', 'stallowqj@ovh.net', '1955-08-17', '5002358325448370', '07-674', '149449', 'https://robohash.org/nostrumautemmaxime.bmp?size=50x50&set=set1', '2020-04-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hdurrellqk', 'Howey', 'Durrell', '2vpZKLYlYajU', 'hdurrellqk@squidoo.com', '1955-03-20', '3554643154270806', null, '568515', 'https://robohash.org/teneturillummagni.jpg?size=50x50&set=set1', '2020-04-26');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('cshelsherql', 'Caresse', 'Shelsher', 'a24WOslK', 'cshelsherql@europa.eu', '2001-11-02', '3560993118042409', null, '007021', 'https://robohash.org/impeditdolorsit.jpg?size=50x50&set=set1', '2020-11-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nbatteyqm', 'Nolie', 'Battey', 'mPscCsfNFP5a', 'nbatteyqm@barnesandnoble.com', '1967-10-23', '3534279189635997', null, '208528', 'https://robohash.org/officiapossimusnobis.jpg?size=50x50&set=set1', '2020-10-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lharkessqn', 'Lorraine', 'Harkess', 'OQtEURI4HMtt', 'lharkessqn@rambler.ru', '1971-05-24', '6759755506820978250', null, '243209', 'https://robohash.org/cumqueiustovoluptatem.jpg?size=50x50&set=set1', '2020-01-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('kstradlingqo', 'Kris', 'Stradling', 'HTI6Pk', 'kstradlingqo@discuz.net', '1966-04-10', '372301625397130', null, '784327', 'https://robohash.org/repellatvelharum.png?size=50x50&set=set1', '2020-04-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('spridittqp', 'Sibella', 'Priditt', 'XzkPRR', 'spridittqp@lycos.com', '1994-08-08', '5476893143788083', null, '525280', 'https://robohash.org/sedrecusandaererum.png?size=50x50&set=set1', '2020-08-25');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('esofeqq', 'Elli', 'Sofe', 'P8iYeKmPn', 'esofeqq@vk.com', '1986-11-21', '3561289192810079', null, '946860', 'https://robohash.org/optioharumodio.png?size=50x50&set=set1', '2020-02-19');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('pcroalqr', 'Pammi', 'Croal', 'vx6E461X6', 'pcroalqr@163.com', '1987-02-23', '50187168194185042', null, '925217', 'https://robohash.org/corruptidoloremqui.bmp?size=50x50&set=set1', '2020-05-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lkinghamqs', 'Leelah', 'Kingham', 'ed4s8T', 'lkinghamqs@yandex.ru', '1960-10-31', '3534908538760508', '19-827', '159448', 'https://robohash.org/eaharumaccusantium.bmp?size=50x50&set=set1', '2020-08-20');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ijeskinqt', 'Iona', 'Jeskin', 'UxWQROg', 'ijeskinqt@sitemeter.com', '1958-03-28', '6771774419601241926', '95-958', '101242', 'https://robohash.org/autemquiscorporis.bmp?size=50x50&set=set1', '2020-03-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('easpinellqu', 'Evy', 'Aspinell', 'pfAoeWgFujwV', 'easpinellqu@google.nl', '1976-09-13', '4405141780299561', '95-091', '104014', 'https://robohash.org/sedsimiliqueomnis.png?size=50x50&set=set1', '2020-04-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ssabateqv', 'Stanleigh', 'Sabate', 'WazvFjJyHi', 'ssabateqv@pinterest.com', '1969-10-22', '201566947333925', '26-040', '100662', 'https://robohash.org/istesimiliqueharum.png?size=50x50&set=set1', '2020-04-07');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('jcharleqw', 'Janot', 'Charle', 'HIuHKsL', 'jcharleqw@dell.com', '1990-12-05', '201917680280148', null, '953864', 'https://robohash.org/sapientepraesentiumneque.png?size=50x50&set=set1', '2020-02-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bcoldwellqx', 'Beitris', 'Coldwell', 'OZdIcw2eXE6', 'bcoldwellqx@paginegialle.it', '2001-06-14', '6771597836501412569', null, '763444', 'https://robohash.org/quiarepellatexercitationem.bmp?size=50x50&set=set1', '2020-10-18');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mpetersenqy', 'Marianne', 'Petersen', 'Rowds6ym', 'mpetersenqy@buzzfeed.com', '1977-06-02', '372301610283972', null, '092434', 'https://robohash.org/cumametpariatur.jpg?size=50x50&set=set1', '2020-09-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tbosnellqz', 'Tony', 'Bosnell', 'qDjc2UU', 'tbosnellqz@dailymail.co.uk', '1953-05-22', '5225195450481045', '23-793', '755822', 'https://robohash.org/sintsuntdignissimos.bmp?size=50x50&set=set1', '2020-05-30');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dcroixr0', 'Delmore', 'Croix', 'HSKx4v', 'dcroixr0@ow.ly', '1965-03-14', '56022578896335917', '34-214', '384086', 'https://robohash.org/quisadmaxime.jpg?size=50x50&set=set1', '2020-05-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nbrightyr1', 'Nevile', 'Brighty', 'R3YIJ4luyZ', 'nbrightyr1@last.fm', '1987-11-16', '3536366565650407', '69-751', '583560', 'https://robohash.org/nequequianobis.jpg?size=50x50&set=set1', '2020-11-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rkilmisterr2', 'Roseanna', 'Kilmister', 'ZKabcT', 'rkilmisterr2@wikipedia.org', '1985-11-26', '201505973326650', null, '727265', 'https://robohash.org/rerumitaquepraesentium.jpg?size=50x50&set=set1', '2020-04-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('amordyr3', 'Andrea', 'Mordy', 'uq88mfU0H', 'amordyr3@cloudflare.com', '1974-09-09', '3532672712915054', null, '311446', 'https://robohash.org/delenitiadex.bmp?size=50x50&set=set1', '2020-05-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ajerwoodr4', 'Alaine', 'Jerwood', 'BHRwwUINBQqc', 'ajerwoodr4@fda.gov', '1981-03-16', '5100130091714736', null, '935209', 'https://robohash.org/autharumea.jpg?size=50x50&set=set1', '2020-06-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('acasollar5', 'Antony', 'Casolla', '32UGsl', 'acasollar5@uiuc.edu', '1966-04-21', '374288580061413', null, '194517', 'https://robohash.org/quosapienteplaceat.png?size=50x50&set=set1', '2020-03-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nbushrodr6', 'Neysa', 'Bushrod', '6wxWJC0', 'nbushrodr6@issuu.com', '1953-09-16', '30130936860427', null, '893746', 'https://robohash.org/nonquidemsimilique.jpg?size=50x50&set=set1', '2020-11-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nfilippuccir7', 'Norry', 'Filippucci', 'F8XXVyJaC', 'nfilippuccir7@abc.net.au', '1990-04-22', '5610487180485310', null, '399710', 'https://robohash.org/atqueimpeditaut.png?size=50x50&set=set1', '2020-07-24');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dsimmoniter8', 'Duffy', 'Simmonite', 'iqK7tJ', 'dsimmoniter8@seesaa.net', '1963-03-15', '5108753787996127', null, '957391', 'https://robohash.org/repudiandaequidemquo.png?size=50x50&set=set1', '2020-01-15');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('schillingworthr9', 'Shayla', 'Chillingworth', 'mAIgccBmRX', 'schillingworthr9@about.me', '2001-10-19', '3589708012549136', '98-102', '889676', 'https://robohash.org/corporisautemea.bmp?size=50x50&set=set1', '2020-08-03');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nspearera', 'Norrie', 'Speare', 'LqnEA0E1Wuts', 'nspearera@blogger.com', '1978-10-11', '4017954291493949', '06-210', '959551', 'https://robohash.org/facilisillumab.bmp?size=50x50&set=set1', '2020-07-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('lmangonrb', 'L;urette', 'Mangon', 'hza5YA7DG8', 'lmangonrb@drupal.org', '1979-05-13', '3548193647389648', null, '711206', 'https://robohash.org/reprehenderitteneturet.png?size=50x50&set=set1', '2020-04-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sredingtonrc', 'Stavros', 'Redington', 'FbHS99wxR', 'sredingtonrc@vimeo.com', '1992-07-14', '3528523812326823', '91-164', '402920', 'https://robohash.org/dignissimosaccusamusid.png?size=50x50&set=set1', '2020-01-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('dhaglingtonrd', 'Dulcinea', 'Haglington', 'uTJHgnWya', 'dhaglingtonrd@addtoany.com', '1990-09-01', '6334603308516691131', '88-165', '997095', 'https://robohash.org/exercitationemfacerevelit.bmp?size=50x50&set=set1', '2020-05-01');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('tfenningre', 'Thia', 'Fenning', 'bIwCt28cymj', 'tfenningre@businessinsider.com', '1984-10-23', '3585953824288176', null, '648178', 'https://robohash.org/doloremdoloresexpedita.bmp?size=50x50&set=set1', '2020-08-12');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hferrottirf', 'Hilary', 'Ferrotti', '9ZhtBHyc', 'hferrottirf@devhub.com', '1986-04-28', '3533182892852811', '55-428', '274121', 'https://robohash.org/nequevelitdoloremque.png?size=50x50&set=set1', '2020-04-08');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('toldacrerg', 'Titus', 'Oldacre', 'rBcQ6CAq', 'toldacrerg@yale.edu', '1979-07-15', '5602241840192992', '50-955', '750896', 'https://robohash.org/exeteos.png?size=50x50&set=set1', '2020-07-11');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('mbraybrookerh', 'Mellisa', 'Braybrooke', 'djncT6JL', 'mbraybrookerh@freewebs.com', '2000-01-29', '6762846991205619', null, '964192', 'https://robohash.org/teneturassumendanon.png?size=50x50&set=set1', '2020-07-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('sthornewillri', 'Stephine', 'Thornewill', 'XKyMDi', 'sthornewillri@psu.edu', '1974-10-01', '6384554886828978', null, '472740', 'https://robohash.org/doloremnesciuntalias.png?size=50x50&set=set1', '2020-05-28');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('nmcmylerrj', 'Nari', 'McMyler', 'bc8YtKjUZ', 'nmcmylerrj@scribd.com', '1991-01-30', '3582207517670296', '56-790', '604191', 'https://robohash.org/sedsitvoluptatem.jpg?size=50x50&set=set1', '2020-09-10');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('ethorndycraftrk', 'Elisha', 'Thorndycraft', 'sPPwnVF', 'ethorndycraftrk@godaddy.com', '1974-06-09', '374288438460825', '65-117', '687991', 'https://robohash.org/quipraesentiumrerum.png?size=50x50&set=set1', '2020-04-02');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rstebbinsrl', 'Raleigh', 'Stebbins', 'jRLPfLP3Xo7Q', 'rstebbinsrl@webeden.co.uk', '1987-02-05', '503821689865109557', null, '638467', 'https://robohash.org/eaistevoluptas.jpg?size=50x50&set=set1', '2020-09-14');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('bwhithalghrm', 'Beatrisa', 'Whithalgh', 'Bk4TWOt9Ivb', 'bwhithalghrm@craigslist.org', '1960-10-12', '3569063620019278', null, '036501', 'https://robohash.org/autemintempore.bmp?size=50x50&set=set1', '2020-02-06');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('eredwinrn', 'Enos', 'Redwin', 'N6nqCl980UOD', 'eredwinrn@goo.gl', '1968-02-03', '374288646251941', '47-966', '535589', 'https://robohash.org/quiassumendased.bmp?size=50x50&set=set1', '2020-02-05');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('rperaccoro', 'Ros', 'Peracco', 'cmdpHTlDNw2', 'rperaccoro@gizmodo.com', '1958-10-11', '5308840615049225', null, '904685', 'https://robohash.org/reprehenderitpariaturmaxime.png?size=50x50&set=set1', '2020-10-22');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('hsharlandrp', 'Helen', 'Sharland', '3k6oyzbqP5', 'hsharlandrp@merriam-webster.com', '1988-11-17', '36786476630902', null, '799251', 'https://robohash.org/quimolestiaeperspiciatis.bmp?size=50x50&set=set1', '2020-07-17');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('eemettrq', 'Ewen', 'Emett', '0FLKPIQ7g7re', 'eemettrq@google.com', '1984-08-16', '4911432579397543146', '25-672', '506471', 'https://robohash.org/voluptatemconsecteturvoluptatum.jpg?size=50x50&set=set1', '2020-08-13');
insert into Users (username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, reg_date) values ('vjandacrr', 'Violet', 'Jandac', 'QWNbqFKM2R', 'vjandacrr@smh.com.au', '1981-11-11', '3564289361243299', null, '836817', 'https://robohash.org/saepemagniqui.png?size=50x50&set=set1', '2020-07-22');
