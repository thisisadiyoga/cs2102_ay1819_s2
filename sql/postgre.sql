CREATE TABLE Timings (
	p_start_date DATE,
	p_end_date DATE,
	PRIMARY KEY (p_start_date, p_end_date),
	CHECK (p_end_date - p_start_date >= 0)
)

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
)
