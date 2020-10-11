/*Group member's codes for ref*/
CREATE TABLE Bids (
	pet_id VARCHAR REFERENCES Owns(pet_id),
	p_start_date DATE,
	p_end_date DATE,
	starting_date DATE, -- change data type
	ending_date DATE, -- change data type
	username VARCHAR,
	rating NUMERIC,
	review VARCHAR,
	is_successful BOOLEAN,
	payment_method VARCHAR,
	is_paid BOOLEAN,
	mode_of_transfer VARCHAR,
	total_price NUMERIC NOT NULL CHECK (total_price >= 0),
	type_of_service VARCHAR NOT NULL,
	PRIMARY KEY (pet_id, p_start_date, p_end_date, starting_date, ending_date, username),
	FOREIGN KEY (p_start_date, p_end_date) REFERENCES Timings(p_start_date, p_end_date),
	FOREIGN KEY (starting_date, ending_date, username) REFERENCES
	Availabilities(starting_date, ending_date, username),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (mode_of_transfer IS NULL AND is_paid IS NULL AND
	payment_method IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5)) -- change depending on maximum rating
);

/*PROJECT CODES*/
CREATE TABLE Users (
	username   	varchar(50) PRIMARY KEY,
	password   	varchar(64) NOT NULL,
	email		varchar(64) UNIQUE NOT NULL CHECK(email LIKE '%@%.%'),
	credit_card_no	varchar(64) NOT NULL,
	DOB		date NOT NULL,
	**photo		varchar(64)(how to store?),
	reg_date	date NOT NULL DEFAULT GETDATE(),
);

CREATE TABLE UsersName (
	first_name 	varchar(64) NOT NULL,
	last_name  	varchar(64) NOT NULL
	username 	varchar(50) NOT NULL REFERENCES Users(username) ON DELETE CASCADE
);

CREATE TABLE UsersAddress (
	street_address	varchar(64),
	block_no	varchar(64),
	postal_code	varchar(6),
	unit_no		varchar(20),
	username 	varchar(50) NOT NULL REFERENCES Users(username) ON DELETE CASCADE
);

CREATE TABLE Caretakers (
	is_full_time	bit(or integer where 0 is false),
	avg_rating	float8,
	no_of_reviews	integer,
	username 	varchar(50) NOT NULL REFERENCES Users(username) ON DELETE CASCADE
);

CREATE TABLE Reviews (
	username  	varchar(50)  NOT NULL,
	ref_no  	varchar(50) NOT NULL,
	comments	varchar(512),
	rating		integer,
	PRIMARY KEY(username,ref_no),
	FOREIGN KEY(username) REFERENCES Caretakers(username),
	FOREIGN KEY(ref_no) REFERENCES Service(ref_no)
);

CREATE OR REPLACE FUNCTION update_review_rating() RETURNS trigger AS $ret$
	BEGIN
		UPDATE Caretakers
		SET no_of_reviews=no_of_reviews+1;
		UPDATE Caretakers
		SET avg_rating=(avg_rating+rating)/no_of_reviews(+1?)(NEED TO FIX)
		WHERE (
			SELECT COUNT(*) FROM game_plays WHERE username=NEW.user1
		) > 20;
		RETURN NEW;
	END;
$ret$ LANGUAGE plpgsql;


CREATE TRIGGER check_review_rating
	AFTER INSERT ON Reviews
	FOR EACH ROW
	EXECUTE PROCEDURE update_review_rating;

CREATE TABLE Requested_by (
	username  	varchar(9)  NOT NULL,
	p_start_date  	date NOT NULL,
	p_end_date  	date NOT NULL,
	PRIMARY KEY(username,p_start_date,p_end_date),
	FOREIGN KEY(username) REFERENCES Caretakers(username),
	FOREIGN KEY(p_start_date) REFERENCES Bids(p_start_date),
	FOREIGN KEY(p_end_date) REFERENCES Bids(p_end_date)
);