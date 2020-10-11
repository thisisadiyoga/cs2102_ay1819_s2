CREATE TABLE Timings (
	p_start_date DATE,
	p_end_date DATE,
	PRIMARY KEY (p_start_date, p_end_date),
	CHECK (p_end_date - p_start_date >= 0)
)

CREATE TABLE Bids (
	owner_username VARCHAR,
	pet_id VARCHAR,
	p_start_date DATE,
	p_end_date DATE,
	starting_date DATE,
	ending_date DATE,
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
	FOREIGN KEY (owner_username, pet_id) REFERENCES ownsPets(username, pet_id),
	CHECK ((is_successful = true) OR (rating IS NULL AND review IS NULL)),
	CHECK ((is_successful = true) OR (mode_of_transfer IS NULL AND is_paid IS NULL AND
	payment_method IS NULL)),
	CHECK ((rating IS NULL) OR (rating >= 0 AND rating <= 5))
)
