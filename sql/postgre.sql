CREATE TABLE Caretakers (
	username   	VARCHAR PRIMARY KEY,
	first_name 	VARCHAR NOT NULL,
	last_name  	VARCHAR NOT NULL,
	password   	VARCHAR(64) NOT NULL,
	email		VARCHAR NOT NULL UNIQUE CHECK(email LIKE '%@%.%'),
	credit_card_no	VARCHAR NOT NULL,
	DOB			DATE NOT NULL,
	postal_code	VARCHAR(6),
	unit_no		VARCHAR,
	reg_date	DATE NOT NULL DEFAULT GETDATE(),
	is_full_time	BIT,
	avg_rating	FLOAT CHECK (avg_rating >= 0),
	no_of_reviews	INTEGER
);

CREATE OR REPLACE FUNCTION update_review_rating() RETURNS trigger AS $ret$
/*Need to fix later*/
	BEGIN
		UPDATE Caretakers
		SET no_of_reviews=no_of_reviews+1;
		UPDATE Caretakers
		SET avg_rating=(avg_rating+rating)/no_of_reviews
		WHERE (Bids.username=Caretakers.username);
		RETURN NEW;
	END;
$ret$ LANGUAGE plpgsql;


CREATE TRIGGER check_review_rating
	AFTER INSERT ON Bids
	FOR EACH ROW
	EXECUTE PROCEDURE update_review_rating;

CREATE TABLE Requested_by (
	username  	VARCHAR(9)  NOT NULL,
	p_start_date  	DATE NOT NULL,
	p_end_date  	DATE NOT NULL,
	PRIMARY KEY(username,p_start_date,p_end_date),
	FOREIGN KEY(username) REFERENCES Caretakers(username),
	FOREIGN KEY(p_start_date) REFERENCES Bids(p_start_date),
	FOREIGN KEY(p_end_date) REFERENCES Bids(p_end_date),
	CHECK(p_start_date <= p_end_date)
);
