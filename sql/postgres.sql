DROP TABLE IF EXISTS cp_passenger_rates;
DROP TABLE IF EXISTS cp_driver_rates;
DROP TABLE IF EXISTS cp_driver_bid_journey;
DROP TABLE IF EXISTS cp_passenger_bid_journey;
DROP TABLE IF EXISTS cp_driver_bid;
DROP TABLE IF EXISTS cp_passenger_bid;
DROP TABLE IF EXISTS cp_requested_journey;
DROP TABLE IF EXISTS cp_advertised_journey;
DROP TABLE IF EXISTS cp_driver_drives;
DROP TABLE IF EXISTS cp_driver;
DROP TABLE IF EXISTS cp_passenger;
DROP TABLE IF EXISTS cp_user;

--General User information
/*user information is added when an account is created*/
CREATE TABLE cp_user (
    email TEXT PRIMARY KEY,
    account_creation_time TIMESTAMP NOT NULL,
    dob DATE NOT NULL,
    gender TEXT NOT NULL,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    password TEXT NOT NULL

    CHECK (gender = 'm' OR gender = 'f' OR gender = 'na')
);

--Driver information referenced by email
CREATE TABLE cp_driver (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE cp_passenger (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE,
    home_address TEXT, --can be null in case user does not want to share --used to autofill address or something
    work_address TEXT  --can be null for similar reasons --used to auto fill address or something
);

/*Relationship of cars and drivers*/
-- in the ER diagram, a car is a weak entity of driver
-- this table depicts that relationship and ensures that every car will be associated with a driver
-- note that a driver can drive multiple cars
CREATE TABLE cp_driver_drives (
    car_plate_no TEXT NOT NULL,
    car_model TEXT NOT NULL,
    max_passengers INTEGER NOT NULL,
    email TEXT NOT NULL,

    PRIMARY KEY(car_plate_no, email),
    FOREIGN KEY(email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (max_passengers > 0), --passenger includes the driver
    CHECK (max_passengers < 8) --this isn't a bus service
);

/*Advertised journey entity put up by the driver*/
CREATE TABLE  cp_advertised_journey (
    email TEXT NOT NULL,
    car_plate_no TEXT NOT NULL,
    max_passengers INTEGER NOT NULL,
    pick_up_area TEXT NOT NULL,
    drop_off_area TEXT NOT NULL,
    min_bid FLOAT NOT NULL,
    bid_start_time TIMESTAMP NOT NULL,
    bid_end_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL, 
    --include estimated price (query)

    PRIMARY KEY (email, car_plate_no, pick_up_time),
    FOREIGN KEY (email, car_plate_no) REFERENCES cp_driver_drives ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (bid_end_time > (bid_start_time + (10 * interval '1 minute'))), --check to ensure bid end time is after bid start time
    CHECK (min_bid > 0.0), --check to ensure that min bid is set to greater than 0
    CHECK ((pick_up_time - (30 * interval '1 minute')) > bid_end_time), --check to ensure that the pick up time is at least 10 mins after bid ends
    CHECK (max_passengers > 0)--check to ensure that the maximum number of passengers the driver can take is more than 0
);

/*Requested journey entity put up by the passengers looking for a driver*/
/*
CREATE TABLE cp_requested_journey (
    email TEXT NOT NULL,
    no_of_passengers INTEGER NOT NULL,
    pick_up_address TEXT NOT NULL,
    drop_off_address TEXT NOT NULL,
    pick_up_area TEXT NOT NULL,
    drop_off_area TEXT NOT NULL,
    max_bid FLOAT NOT NULL,
    bid_start_time TIMESTAMP NOT NULL,
    bid_end_time TIMESTAMP NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,

    PRIMARY KEY (email, pick_up_time),
    FOREIGN KEY (email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (bid_end_time > (bid_start_time + (10 * interval '1 minute'))), --check to ensure bid end time is after bid start time
    CHECK (max_bid > 0.0), --check to ensure that max bid is set to greater than 0
    CHECK ((pick_up_time - (30 * interval '1 minute')) > bid_end_time), --check to ensure that the pick up time is at least 10 mins after bid ends
    CHECK (no_of_passengers > 0), --check to ensure that the maximum number of passengers the driver can take is more than 0
    CHECK (pick_up_address <> drop_off_address), --ensure pick up and drop off is not the same
    CHECK (no_of_passengers < 8) --idk max 7 passengers makes sense
);
*/

/*table that stores the bids that the passengers make on the driver bids*/
-- allowed to make multiple bids 
CREATE TABLE cp_passenger_bid (
    passenger_email TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    car_plate_no TEXT NOT NULL, /*NEED TO CHECK IF CAR CAN FIT EVERYONE*/
    pick_up_time TIMESTAMP NOT NULL,
    pick_up_address TEXT NOT NULL, --input when bid is made --need check to ensure in pick up area
    drop_off_address TEXT NOT NULL, --input when bid is made --need check to ensure in drop off area
    bid_time TIMESTAMP NOT NULL, --input when bid is made
    bid_price FLOAT NOT NULL, --input when bid is made

    PRIMARY KEY (passenger_email, driver_email, car_plate_no, pick_up_time),
    FOREIGN KEY (passenger_email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (driver_email, car_plate_no, pick_up_time) REFERENCES cp_advertised_journey ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (passenger_email <> driver_email) --passenger cannot bid on own job
);

/*table that stores the bids that the drivers make on the passenger requests*/
/*
CREATE TABLE cp_driver_bid (
    driver_email TEXT NOT NULL,
    car_plate_no TEXT NOT NULL,
    passenger_email TEXT NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    bid_time TIMESTAMP NOT NULL, --input when bid is made
    bid_price FLOAT NOT NULL, --input when bid is made

    PRIMARY KEY (driver_email, car_plate_no, passenger_email, pick_up_time),
    FOREIGN KEY (driver_email, car_plate_no) REFERENCES cp_driver_drives ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (passenger_email, pick_up_time) REFERENCES cp_requested_journey ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (passenger_email <> driver_email) --driver cannot bid for own job request
);
*/
/*
--once a driver bid or passenger bid is accepted, it is added to this table
CREATE TABLE cp_source (
    type TEXT NOT NULL,
    journey_id NOT NULL, --unforunate but necessary to index each journey without referencing everything
    PRIMARY KEY (type, journey_id)
);

CREATE TABLE cp_passenger_bid_journey (
    journey_id TEXT NOT NULL, --necessary to reference the journey from the ratings
    passenger_email TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    car_plate_no TEXT NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    journey_start_time TIMESTAMP, --initially null and filled when customer is picked up
    journey_end_time TIMESTAMP, --initially null and filled when customer is picked up
    driver_rating INTEGER, --initially null and filled if passenger rates journey
    passenger_rating INTEGER, --initially null and filled if driver rates journey

    PRIMARY KEY (journey_id, passenger_email, driver_email, car_plate_no, pick_up_time),
    FOREIGN KEY (passenger_email, driver_email, car_plate_no, pick_up_time) REFERENCES cp_passenger_bid ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (journey_start_time < journey_end_time)
);

CREATE TABLE cp_driver_bid_journey (
    journey_id TEXT NOT NULL, --necessary to reference the journey from the ratings
    passenger_email TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    journey_start_time TIMESTAMP, --initially null and filled when customer is picked up
    journey_end_time TIMESTAMP, --initially null and filled when customer is picked up
    driver_rating INTEGER, --initially null and filled if passenger rates journey
    passenger_rating INTEGER, --initially null and filled if driver rates journey

    PRIMARY KEY (journey_id, driver_email, passenger_email, pick_up_time),
    FOREIGN KEY (driver_email, passenger_email, pick_up_time) REFERENCES cp_driver_bid ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (journey_start_time < journey_end_time)
);

CREATE TABLE cp_driver_rates (
    journey_id TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    passenger_rating INTEGER, --the value to be input by the driver

    PRIMARY KEY (journey_id),
    FOREIGN KEY (journey_id) REFERENCES cp_journey,
    FOREIGN KEY (driver_email) REFERENCES cp_driver ON UPDATE CASCADE --if email changes the email should change but if account is deleted rating should stay
);

CREATE TABLE cp_passenger_rates (
    journey_id TEXT NOT NULL,
    passenger_email TEXT NOT NULL,
    driver_rating INTEGER, --the value to be input by the driver

    PRIMARY KEY (journey_id),
    FOREIGN KEY (journey_id) REFERENCES cp_journey,
    FOREIGN KEY (passenger_email) REFERENCES cp_passenger ON UPDATE CASCADE --if email changes the email should change but if account is deleted rating should stay
);
*/

/******************TRIGGERS******************/

/*Trigger that checks whether the driver can put up a job*/
-- driver must have a car with the correct car he/she owns
-- number of passengers specified must be less than or equal to the maximum number of passengers
-- the time the bid is put up must be after the account was created
-- the driver can only pick up the next customer TEN MINUTES after the pick up time (rationale is that if driver puts up a request before he can complete his earlier journey then he gets a lower rating)
-- if driver is also a passenger, it must be ensured that he cannot put up a drive request until 10 minutes after his ride as a passenger ends 
-- or 10 mins before another ride as a passenger
-- check cp_advertised_journey, cp_requested_journey, passenger_bid, driver_bid to check that there is no request or bid for a pick up time within 30 mins
CREATE OR REPLACE FUNCTION f_check_cp_advertised_journey()
RETURNS TRIGGER
AS $$
    DECLARE car_exists BOOLEAN;
    DECLARE account_creation_time TIMESTAMP;
    DECLARE driver_requests_overlap BOOLEAN;
    --DECLARE passenger_requests_overlap BOOLEAN;
    --DECLARE driver_bid_overlap BOOLEAN;
    DECLARE passenger_bid_overlap BOOLEAN;
BEGIN
    --check for car validity
    car_exists := EXISTS (
            SELECT * FROM cp_driver_drives d
            WHERE d.email = NEW.email AND d.car_plate_no = NEW.car_plate_no AND d.max_passengers >= NEW.max_passengers
    );
    IF NOT car_exists THEN
        RAISE NOTICE 'CAR EXISTS';
        RETURN NULL;
    END IF;

    --check for bid start time validity
    account_creation_time := (
        SELECT g.account_creation_time FROM cp_user g
        WHERE g.email = NEW.email
    );
    IF account_creation_time > NEW.bid_start_time THEN
        RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
        RETURN NULL;
    END IF;

    --check for overlaps
    driver_requests_overlap := EXISTS(
            SELECT * FROM cp_advertised_journey a
            WHERE a.email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );
    /*
    passenger_requests_overlap := EXISTS(
            SELECT * FROM cp_requested_journey a
            WHERE a.email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );
    
    driver_bid_overlap := EXISTS(
            SELECT * FROM cp_driver_bid a
            WHERE a.driver_email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );
    */

    passenger_bid_overlap := EXISTS(
            SELECT * FROM cp_passenger_bid a
            WHERE a.passenger_email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );

    IF driver_requests_overlap OR passenger_bid_overlap THEN
        RAISE NOTICE 'OVERLAP IN TIMINGS';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER t_check_cp_advertised_journey
BEFORE INSERT OR UPDATE ON cp_advertised_journey
FOR EACH ROW EXECUTE PROCEDURE f_check_cp_advertised_journey();


/*Trigger that checks whether the passennger can request a ride*/
-- the time the bid is put up must be after the account was created
-- passenger can only be picked up 10 mins after the pick up time of the previous requested ride
-- if passenger is also a driver, it must be ensured that he cannot put up a pick up request until 10 minutes after his ride as a driver ends 
-- or 10 mins before another ride as a passenger
/*
CREATE OR REPLACE FUNCTION f_check_cp_requested_journey()
RETURNS TRIGGER
AS $$
    DECLARE account_creation_time TIMESTAMP;
    DECLARE driver_requests_overlap BOOLEAN;
    --DECLARE passenger_requests_overlap BOOLEAN;
    --DECLARE driver_bid_overlap BOOLEAN;
    DECLARE passenger_bid_overlap BOOLEAN;
BEGIN
    --check for bid start time validity
    account_creation_time := (
        SELECT g.account_creation_time FROM cp_user g
        WHERE g.email = NEW.email
    );
    IF account_creation_time > NEW.bid_start_time THEN
        RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
        RETURN NULL;
    END IF;

    --check for overlaps
    driver_requests_overlap := EXISTS(
            SELECT * FROM cp_advertised_journey a
            WHERE a.email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );

    
    passenger_requests_overlap := EXISTS(
            SELECT * FROM cp_requested_journey a
            WHERE a.email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );

    driver_bid_overlap := EXISTS(
            SELECT * FROM cp_driver_bid a
            WHERE a.driver_email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );
    

    passenger_bid_overlap := EXISTS(
            SELECT * FROM cp_passenger_bid a
            WHERE a.passenger_email = NEW.email
              AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
                OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
                OR a.pick_up_time = NEW.pick_up_time)
        );

    IF driver_requests_overlap OR passenger_bid_overlap THEN
        RAISE NOTICE 'OVERLAP IN TIMINGS';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER t_check_cp_requested_journey
BEFORE INSERT OR UPDATE ON cp_requested_journey
FOR EACH ROW EXECUTE PROCEDURE f_check_cp_requested_journey();
*/


/*trigger for passenger bids*/
-- the bid time must be before the bid time ends and after the bid time starts
-- bid time must be after the account was created
-- check that the bid price is greater than the minimum bid
-- can bid on multiple rides at once. deleted if one is accepted
CREATE OR REPLACE FUNCTION f_check_passenger_bid()
RETURNS TRIGGER
AS $$
    DECLARE job_bid_time_start TIMESTAMP;
    DECLARE job_bid_time_end TIMESTAMP;
    DECLARE minimum_bid FLOAT;
    DECLARE account_creation_time TIMESTAMP;
    DECLARE driver_requests_overlap BOOLEAN;
    DECLARE passenger_requests_overlap BOOLEAN;
    DECLARE driver_bid_overlap BOOLEAN;
    DECLARE passenger_bid_overlap BOOLEAN;

BEGIN
    -- check for valid bid time
    job_bid_time_start := (
        SELECT a.bid_start_time FROM cp_advertised_journey a
        WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
    );

    job_bid_time_end := (
        SELECT a.bid_end_time FROM cp_advertised_journey a
        WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
    );

    IF NEW.bid_time > job_bid_time_end OR NEW.bid_time < job_bid_time_start THEN
        RAISE NOTICE 'INVALID BID TIME';
        RETURN NULL;
    END IF;

    -- check to ensure bid is more than the minimum
    minimum_bid := (
        SELECT a.min_bid FROM cp_advertised_journey a
        WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
    );

    IF minimum_bid > NEW.bid_price THEN
        RAISE NOTICE 'BELOW MINIMUM BID';
        RETURN NULL;
    END IF;

    --check for bid start time validity
    account_creation_time := (
        SELECT g.account_creation_time FROM cp_user g
        WHERE g.email = NEW.passenger_email
    );
    IF account_creation_time > NEW.bid_time THEN
        RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
        RETURN NULL;
    END IF;

    --check for overlaps
    driver_requests_overlap := EXISTS(
        SELECT * FROM cp_advertised_journey a
        WHERE a.email = NEW.passenger_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
        OR a.pick_up_time = NEW.pick_up_time)
    );

    /*
    passenger_requests_overlap := EXISTS(
        SELECT * FROM cp_requested_journey a
        WHERE a.email = NEW.passenger_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
        OR a.pick_up_time = NEW.pick_up_time)
    );
    */

    --bids can be placed at any time, even with overlaps
    /*
    driver_bid_overlap := EXISTS(
        SELECT * FROM cp_driver_bid a 
        WHERE a.driver_email = NEW.passenger_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time) 
        OR a.pick_up_time = NEW.pick_up_time)
    );


    passenger_bid_overlap := EXISTS(
        SELECT * FROM cp_passenger_bid a 
        WHERE a.passenger_email = NEW.passenger_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time) 
        OR a.pick_up_time = NEW.pick_up_time)
    );
    */

    IF driver_requests_overlap /*OR driver_bid_overlap OR passenger_bid_overlap*/ THEN
        RAISE NOTICE 'OVERLAP IN TIMINGS';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER t_check_passenger_bid
BEFORE INSERT OR UPDATE ON cp_passenger_bid
FOR EACH ROW EXECUTE PROCEDURE f_check_passenger_bid();

/*
--trigger for driver bids
-- the bid time must be before the bid time ends and after the bid time starts
-- bid time must be after the account was created
-- check that the bid price is smaller than the maximum bid
-- cannot bid on 
CREATE OR REPLACE FUNCTION f_check_driver_bid()
RETURNS TRIGGER
AS $$
    DECLARE job_bid_time_start TIMESTAMP;
    DECLARE job_bid_time_end TIMESTAMP;
    DECLARE maximum_bid FLOAT;
    DECLARE account_creation_time TIMESTAMP;
    DECLARE driver_requests_overlap BOOLEAN;
    --DECLARE passenger_requests_overlap BOOLEAN;
    --DECLARE driver_bid_overlap BOOLEAN;
    DECLARE passenger_bid_overlap BOOLEAN;
BEGIN
    -- check for valid bid time
    job_bid_time_start := (
        SELECT a.bid_start_time FROM cp_requested_journey a
        WHERE a.email = NEW.passenger_email AND a.pick_up_time = NEW.pick_up_time
    );

    job_bid_time_end := (
        SELECT a.bid_end_time FROM cp_requested_journey a
        WHERE a.email = NEW.passenger_email AND a.pick_up_time = NEW.pick_up_time
    );

    IF NEW.bid_time > job_bid_time_end OR NEW.bid_time < job_bid_time_start THEN
        RAISE NOTICE 'INVALID BID TIME';
        RETURN NULL;
    END IF;

    -- check to ensure bid is more than the minimum
    maximum_bid := (
        SELECT a.max_bid FROM cp_requested_journey a
        WHERE a.email = NEW.passenger_email AND a.pick_up_time = NEW.pick_up_time
    );

    IF maximum_bid < NEW.bid_price THEN
        RAISE NOTICE 'ABOVE MAXIMUM BID';
        RETURN NULL;
    END IF;

    --check for bid start time validity
    account_creation_time := (
        SELECT g.account_creation_time FROM cp_user g
        WHERE g.email = NEW.driver_email
    );
    IF account_creation_time > NEW.bid_time THEN
        RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
        RETURN NULL;
    END IF;

    --check for overlaps
    driver_requests_overlap := EXISTS(
        SELECT * FROM cp_advertised_journey a
        WHERE a.email = NEW.driver_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
        OR a.pick_up_time = NEW.pick_up_time)
    );
    
    passenger_requests_overlap := EXISTS(
        SELECT * FROM cp_requested_journey a
        WHERE a.email = NEW.driver_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
        OR a.pick_up_time = NEW.pick_up_time)
    );
    
    
    driver_bid_overlap := EXISTS(
        SELECT * FROM cp_driver_bid a 
        WHERE a.driver_email = NEW.driver_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time) 
        OR a.pick_up_time = NEW.pick_up_time)
    );


    passenger_bid_overlap := EXISTS(
        SELECT * FROM cp_passenger_bid a 
        WHERE a.passenger_email = NEW.driver_email
        AND (((a.pick_up_time + (30 * interval '1 minute')) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
        OR ((a.pick_up_time - (30 * interval '1 minute')) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time) 
        OR a.pick_up_time = NEW.pick_up_time)
    );
    

    IF driver_requests_overlap OR driver_bid_overlap OR passenger_bid_overlap THEN
        RAISE NOTICE 'OVERLAP IN TIMINGS';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER t_check_driver_bid
BEFORE INSERT OR UPDATE ON cp_driver_bid
FOR EACH ROW EXECUTE PROCEDURE f_check_driver_bid();
*/