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
	avatar			BYTEA		NOT NULL
);

CREATE VIEW Users AS (
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date, avatar FROM Owners
	UNION
	SELECT username, password, first_name, last_name, email, dob, credit_card_no, unit_no, postal_code, reg_date, avatar FROM Caretakers
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



-- Profile Seed --
INSERT INTO Owners VALUES ('Brutea', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Alphantom', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Videogre', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Corsairway', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('GlitteringBoy', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('BrightMonkey', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('MudOtter', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ChiefMole', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ArchTadpole', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CarefulKitten', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Classhopper', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Knightmare', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Weaselfie', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Conquerry', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('BadJaguar', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CorruptFury', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CandidHedgehog', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('JollyPapaya', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('TinyGuardian', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('RustyPhantom', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('HoneyBeetle', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Pandaily', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Goliatlas', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Tweetail', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('PeaceMinotaur', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('GraciousBullfrog', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('OriginalEmu', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ArchDots', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('SelfishDove', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CharmingMonster', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Gorillala', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Knighttime', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Vertighost', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Sheeple', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ClumsyToad', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('EmotionalCandy', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('GrimAlbatross', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('DoctorDeer', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CleanNestling', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('WriterThief', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('TheClosedGamer', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ExcitingShows', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('CurvyTweets', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Tjolme', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Dalibwyn', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Miram', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Medon', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Aseannor', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Angleus', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Umussa', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Etiredan', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Gwendanna', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Adwardonn', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Lariramma', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Celap', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Higollan', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Umardoli', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Craumeth', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Nydoredon', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Zeama', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Legaehar', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Praulian', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Crarerin', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Dwigosien', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Kaoabard', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Taomos', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Caregorn', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Etigomas', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Agreawyth', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Komabwyn', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Sirental', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Slotherworld', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Yakar', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Boaris', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('BrutishThief', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('StormWeasel', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('QuickOctopus', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('WorthyTiger', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ImaginaryMammoth', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ScentedWarlock', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Walruse', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Herose', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Spookworm', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Grapeshifter', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('AdvicePeanut', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('KindPig', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('UnusualSmile', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ExoticWalrus', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('FearlessMage', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('HeavyLord', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Gorillala', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Barracupid', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Goath', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('Alphairy', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('WindWizard', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('DimNestling', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('LovableSardine', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('ShowFrog', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('IslandBeetle', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('OceanBrownie', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());
INSERT INTO Owners VALUES ('', '', '', '', '', , '', '', '', CURRENT_DATE());