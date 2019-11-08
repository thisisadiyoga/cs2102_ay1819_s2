--General User information
/*user information is added when an account is created*/
CREATE TABLE IF NOT EXISTS cp_user (
    email TEXT PRIMARY KEY,
    account_creation_time TIMESTAMP NOT NULL,
    dob DATE NOT NULL,
    gender TEXT NOT NULL,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    password TEXT NOT NULL
);

--Driver information referenced by email
CREATE TABLE IF NOT EXISTS cp_driver (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS cp_passenger (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE,
    home_address TEXT, --can be null in case user does not want to share --used to autofill address or something
    work_address TEXT  --can be null for similar reasons --used to auto fill address or something
);

/*Relationship of cars and drivers*/
-- in the ER diagram, a car is a weak entity of driver
-- this table depicts that relationship and ensures that every car will be associated with a driver
-- note that a driver can drive multiple cars
CREATE TABLE IF NOT EXISTS cp_driver_drives (
    car_plate_no TEXT NOT NULL,
    car_model TEXT NOT NULL,
    max_passengers INTEGER not NULL,
    email TEXT NOT NULL,

    PRIMARY KEY(car_plate_no, email),
    FOREIGN KEY(email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (max_passengers > 0), --passenger includes the driver
    CHECK (max_passengers < 8) --this isn't a bus service
);


/*Advertised journey entity put up by the driver*/
CREATE TABLE IF NOT EXISTS cp_advertised_journey (
    car_plate_no TEXT NOT NULL,
    max_passengers INTEGER NOT NULL,
    pick_up_area TEXT NOT NULL,
    destination_area TEXT NOT NULL,
    min_bid FLOAT NOT NULL,
    bid_start_time TIMESTAMP NOT NULL,
    bid_end_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    email TEXT NOT NULL,
    --include estimated price (query)

    PRIMARY KEY (email, pick_up_time),
    FOREIGN KEY (email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (bid_end_time > bid_start_time), --check to ensure bid end time is after bid start time
    CHECK (min_bid > 0.0), --check to ensure that min bid is set to greater than 0
    CHECK ((pick_up_time - (30 * interval '1 minute')) > bid_end_time), --check to ensure that the pick up time is at least 10 mins after bid ends
    CHECK (max_passengers > 0) --check to ensure that the maximum number of passengers the driver can take is more than 0
);

/*Requested journey entity put up by the passengers looking for a driver*/
CREATE TABLE IF NOT EXISTS cp_requested_journey (
    no_of_passengers INTEGER NOT NULL,
    pick_up_address TEXT NOT NULL,
    destination_address TEXT NOT NULL,
    max_bid FLOAT NOT NULL,
    bid_start_time TIMESTAMP NOT NULL,
    bid_end_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    email TEXT NOT NULL,
    --include estimated price (query)

    PRIMARY KEY (email, pick_up_time),
    FOREIGN KEY (email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (bid_end_time > bid_start_time), --check to ensure bid end time is after bid start time
    CHECK (max_bid > 0.0), --check to ensure that max bid is set to greater than 0
    CHECK ((pick_up_time - (30 * interval '1 minute')) > bid_end_time), --check to ensure that the pick up time is at least 10 mins after bid ends
    CHECK (no_of_passengers > 0), --check to ensure that the maximum number of passengers the driver can take is more than 0
    CHECK (pick_up_address <> destination_address), --ensure pick up and drop off is not the same
    CHECK (no_of_passengers < 8) --idk max 7 passengers makes sense
);

/*table that stores the bids that the passengers make on the driver bids*/
-- allowed to make multiple bids
CREATE TABLE IF NOT EXISTS cp_passenger_bid (
    passenger_email TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    pick_up_area TEXT NOT NULL, -- in an ideal world this will not be here but otherwise will be unable to map address to area
    destination_area TEXT NOT NULL, -- in an ideal world this will not be here but otherwise will be unable to map address to area
    pick_up_address TEXT NOT NULL,
    drop_off_address TEXT NOT NULL,
    bid_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    bid_price FLOAT NOT NULL,

    PRIMARY KEY (passenger_email, driver_email, pick_up_time),
    FOREIGN KEY (passenger_email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (driver_email, pick_up_time) REFERENCES cp_advertised_journey ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (passenger_email <> driver_email) --passenger cannot bid on own job
);

/*table that stores the bids that the drivers make on the passenger requests*/
CREATE TABLE IF NOT EXISTS cp_driver_bid (
    driver_email TEXT NOT NULL,
    passenger_email TEXT NOT NULL,
    bid_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    bid_price FLOAT NOT NULL,

    PRIMARY KEY (driver_email, passenger_email, pick_up_time),
    FOREIGN KEY (driver_email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (passenger_email, pick_up_time) REFERENCES cp_requested_journey ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (passenger_email <> driver_email) --driver cannot bid for own job request
);
