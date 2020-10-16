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
	no_of_reviews	INTEGER,
	no_of_pets_taken INTEGER
);

/*DROP TRIGGER IF EXISTS OnBid;
DELIMITER //
CREATE TRIGGER OnBid
  AFTER INSERT ON Bids FOR EACH ROW
  BEGIN
    UPDATE Caretakers
	SET Caretakers.avg_rating = ((Caretakers.avg_rating*no_of_reviews)+Bids.rating)/(Caretakers.no_of_reviews + 1)
	Caretakers.no_of_reviews = Caretakers.no_of_reviews + 1
	Caretakers.no_of_pets_taken = Caretakers.no_of_pets_taken + 1
     WHERE Caretaker.username = Bids.username
  END //
DELIMITER ;*/

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
