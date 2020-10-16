CREATE TABLE caretakers(
	username VARCHAR PRIMARY KEY
);

CREATE TABLE is_paid_salaries (
	caretaker_id VARCHAR REFERENCES caretakers(username)
	ON DELETE cascade,
	year INTEGER,
	month INTEGER,
	salary_amount NUMERIC NOT NULL,
	PRIMARY KEY (caretaker_id, year, month)
);

CREATE TABLE administrators (
	admin_id VARCHAR PRIMARY KEY,
	password VARCHAR(64) NOT NULL,
	last_login_time DATE,
)
	