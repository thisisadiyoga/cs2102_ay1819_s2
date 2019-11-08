-- DROP TRIGGER IF EXISTS t_check_cp_advertised_journey ON cp_advertised_journey;
-- DROP TRIGGER IF EXISTS t_check_passenger_bid ON cp_passenger_bid;
-- DROP TRIGGER IF EXISTS t_check_journey_occurs ON cp_journey_occurs;
-- DROP TRIGGER IF EXISTS t_check_driver_rates ON cp_driver_rates;
-- DROP TRIGGER IF EXISTS t_check_passenger_rates ON cp_passenger_rates;
-- DROP TRIGGER IF EXISTS t_check_payment ON cp_payment;

--General User information
--User information is added when account is created
CREATE TABLE IF NOT EXISTS cp_user (
    email TEXT PRIMARY KEY, --the main way to id users
    account_creation_time TIMESTAMP NOT NULL, --CURRENT_TIMESTAMP when user is registered
    dob DATE NOT NULL, --format 'YYYY-MM-DD'
    gender TEXT NOT NULL, --either 'm' 'f' or 'na' gotta be open minded
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    password TEXT NOT NULL --needs to be encrypted with bcrypt

    CHECK (gender = 'm' OR gender = 'f' OR gender = 'na'), --ensure gender is specified
    CHECK (dob < (NOW() - '18 years'::interval)), --ensure more than 18 years old
    CHECK (account_creation_time > dob) --ensure
);


-- Driver information
-- Information is added when user specifies to be a driver
CREATE TABLE IF NOT EXISTS cp_driver (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE,
    bank_account_no INTEGER, --must not be null for driver to receive money
    license_no TEXT --driver must state license
);

--Car is a weak entity of driver
--Information is added when user specifies to be a driver
--Can add any number of cars to driver
--This table will be referenced in the future to put up rides
CREATE TABLE IF NOT EXISTS cp_driver_drives (
    car_plate_no TEXT NOT NULL, --partial key for car
    car_model TEXT NOT NULL, --the model of the car
    max_passengers INTEGER NOT NULL, --the max number of passengers car can hold *impt*
    email TEXT NOT NULL, --the email of the driver who owns the car

    PRIMARY KEY(car_plate_no, email),
    FOREIGN KEY(email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (max_passengers > 0), --passenger includes the driver
    CHECK (max_passengers < 8) --this isn't a bus service
);

--Passenger information
--Information is added when the user specifies as a passenger
CREATE TABLE IF NOT EXISTS cp_passenger (
    email TEXT PRIMARY KEY REFERENCES cp_user ON DELETE CASCADE ON UPDATE CASCADE,
    home_address TEXT, --can be null in case user does not want to share --used to autofill address or something
    work_address TEXT  --can be null for similar reasons --used to auto fill address or something
);

--Payment information for the customer
--If the passenger chooses to not have a card then have_card is set to 'f' and 't' otherwise
--If passenger has a card then all the information must be filled
CREATE TABLE IF NOT EXISTS cp_payment_method (
    have_card TEXT NOT NULL,
    cardholder_name TEXT,
    cvv INTEGER,
    expiry_date DATE,
    card_number TEXT,
    email TEXT NOT NULL,

    PRIMARY KEY (email, have_card),
    FOREIGN KEY (email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (have_card = 't' OR have_card = 'f'),
    CHECK ((have_card = 'f' AND cardholder_name IS NULL AND cvv IS NULL AND expiry_date IS NULL AND card_number IS NULL) OR (have_card = 't' AND cardholder_name IS NOT NULL AND cvv IS NOT NULL AND expiry_date IS NOT NULL AND card_number IS NOT NULL)),
    CHECK (expiry_date IS NULL OR expiry_date > NOW())
);

--Advertised journey put up by the driver
--It is a weak entity with partial key being the pick_up_time
--Strong entity is cp_driver_drives
--Entry is made when driver puts up a request
CREATE TABLE IF NOT EXISTS cp_advertised_journey (
    email TEXT NOT NULL, --email of driver who puts up ride
    car_plate_no TEXT NOT NULL, --car which driver wants to take
    max_passengers INTEGER NOT NULL, --the maximum number of passengers the driver wants to take
    pick_up_area TEXT NOT NULL,
    drop_off_area TEXT NOT NULL,
    min_bid FLOAT NOT NULL,
    bid_start_time TIMESTAMP NOT NULL, --bid_start_time is when the entry is made into the table
    bid_end_time TIMESTAMP NOT NULL, --the ending time of the bid at which a bid is selected
    pick_up_time TIMESTAMP NOT NULL,  --the pick up time of the passenger

    --INCLUDE ESTIMATED PRICE OF RIDE BASED ON PAST JOURNEYS (done with a query)--

    PRIMARY KEY (email, car_plate_no, pick_up_time),
    FOREIGN KEY (car_plate_no, email) REFERENCES cp_driver_drives ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (bid_end_time > (bid_start_time + '10 minute'::interval)), --bids must minimally last for 10 mins
    CHECK (min_bid > 0.0), --check to ensure that min bid is set to greater than 0
    CHECK ((pick_up_time - '30 minute'::interval) > bid_end_time), --pick up time must be at least 30 mins after bid ends
    CHECK (max_passengers > 0)--check to ensure that the maximum number of passengers the driver can take is more than 0

    --TRIGGER CHECKS--
    --1. check to ensure the pick_up_time is not 30 mins within another advertised journey pick_up_time put up by the driver
    --2. check to ensure the pick_up_time is not 30 mins within the pick_up_time of a bid made by the driver using a passenger account
    --3. ensure that the max_passenger is less than the actual max_passenger of the car
    --4. ensure that the bid starts after the account has been created
    --5. check that the driver has put in his license number and bank account number
);

--Passenger bids made by passengers
--Entries are inserted when passenger makes a bid on a requested journey
CREATE TABLE IF NOT EXISTS cp_passenger_bid (
    passenger_email TEXT NOT NULL, --email of passenger who bids on the ride
    driver_email TEXT NOT NULL, --information from cp_advertised_journey
    car_plate_no TEXT NOT NULL, --information from cp_advertised_journey
    pick_up_time TIMESTAMP NOT NULL, --information from cp_advertised_journey
    pick_up_address TEXT NOT NULL, --input when bid is made
    drop_off_address TEXT NOT NULL, --input when bid is made
    bid_time TIMESTAMP NOT NULL, --input when bid is made (CURRENT_TIMESTAMP)
    bid_price FLOAT NOT NULL, --input when bid is made
    number_of_passengers INTEGER NOT NULL, --input when bid is made
    bid_won BOOLEAN, --set to null when the bid is ongoing, false if bid not won and true if bid won

    PRIMARY KEY (passenger_email, driver_email, car_plate_no, pick_up_time),
    FOREIGN KEY (passenger_email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (driver_email, car_plate_no, pick_up_time) REFERENCES cp_advertised_journey ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK (passenger_email <> driver_email) --passenger cannot bid on own job

    --TRIGGER CHECKS--
    --1. check that the pick_up_time is not 30 mins within another advertised journey pick_up_time put up by the user as a driver
    --2. check that the bid_time is after the account was created
    --3. check that the bid_price is greater than the min_bid
    --4. check that the number_of_passengers is less than the max_passengers
    --5. check that the bid occurs after the advertisement was put up and before it ends
    --6. CHECK that same journeys only 1 is set to true

    --BONUS--
    --1. check that pick up address is actually in pick up area
    --2. check that drop off address is actually in drop off area
);

--table for a journey that has occured
--entries are inserted when the winning bid has been selected from cp_passenger_bid either by the selection query or by the driver
CREATE TABLE IF NOT EXISTS cp_journey_occurs (
    passenger_email TEXT NOT NULL,
    driver_email TEXT NOT NULL,
    car_plate_no TEXT NOT NULL,
    pick_up_time TIMESTAMP NOT NULL,
    journey_start_time TIMESTAMP, --the time the driver picks up the passenger (initially null)
    journey_end_time TIMESTAMP, --the time the driver drops off the passenger (initially null)
    journey_distance FLOAT, --the distance of the journey (not actually necessary)

    PRIMARY KEY (passenger_email, driver_email, car_plate_no, pick_up_time, journey_start_time),
    FOREIGN KEY (passenger_email, driver_email, car_plate_no, pick_up_time) REFERENCES cp_passenger_bid ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK ((journey_start_time IS NULL AND journey_end_time IS NULL) OR (journey_start_time IS NOT NULL AND journey_end_time IS NULL) OR (journey_start_time IS NOT NULL AND journey_end_time IS NOT NULL AND journey_start_time < journey_end_time)),
    CHECK (journey_distance IS NULL OR journey_distance > 0.0)

    --TRIGGER CHECKS--
    -- 1. check that the journey started after the bid ended (bid_won = true)
);

--table to store driver ratings of journeys
--insert when RIDE is complete (journey_end_time is not null)
CREATE TABLE IF NOT EXISTS cp_driver_rates (
    journey_start_time TIMESTAMP NOT NULL,
    driver_email TEXT NOT NULL,
    rating INTEGER,

    PRIMARY KEY (driver_email, journey_start_time),
    FOREIGN KEY (driver_email) REFERENCES cp_driver ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK ((rating >= 0 AND rating <= 5) OR rating IS NULL)

    --TRIGGER CHECKS--
    --1. check that the journey is over (journey_end_time IS NOT NULL)
);

--table to store passenger ratings of journeys
--insert when RIDE is complete (journey_end_time is not null)
CREATE TABLE IF NOT EXISTS cp_passenger_rates (
    journey_start_time TIMESTAMP NOT NULL,
    passenger_email TEXT NOT NULL,
    rating INTEGER,

    PRIMARY KEY (passenger_email, journey_start_time),
    FOREIGN KEY (passenger_email) REFERENCES cp_passenger ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK ((rating >= 0 AND rating <= 5) OR rating IS NULL)
    --TRIGGER CHECKS--
    --1. check that the journey is over (journey_end_time IS NOT NULL)
);

--table that stores the payment information for the journey
--insert when the RIDE is complete and the passenger has paid for the ride
CREATE TABLE IF NOT EXISTS cp_payment (
    journey_start_time TIMESTAMP NOT NULL,
    passenger_email TEXT NOT NULL,
    have_card TEXT NOT NULL,
    transaction_type TEXT NOT NULL, --indicate whether paid by cash or by card

    PRIMARY KEY (journey_start_time, passenger_email, have_card),
    FOREIGN KEY (passenger_email, have_card) REFERENCES cp_payment_method ON UPDATE CASCADE,
    CHECK ((transaction_type = 'card' AND have_card = 't') OR transaction_type = 'cash') --cannot pay with card if user does not have card registerd

    --TRIGGER CHECKS--
    --1. check that the journey is over (journey_end_time IS NOT NULL)
);



-- ----------TRIGGER FOR cp_advertised_journey----------
-- CREATE OR REPLACE FUNCTION f_check_cp_advertised_journey()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_car_max_passenger BOOLEAN;
--     DECLARE check_correct_bid_time BOOLEAN;
--     DECLARE check_driver_requests_overlap BOOLEAN;
--     DECLARE check_passenger_bid_overlap BOOLEAN;
-- BEGIN
--     --check for correct max passengers
--     check_car_max_passenger := EXISTS (
--             SELECT * FROM cp_driver_drives d
--             WHERE d.email = NEW.email
--             AND d.car_plate_no = NEW.car_plate_no
--             AND d.max_passengers >= NEW.max_passengers
--     );
--     IF NOT check_car_max_passenger THEN
--         RAISE NOTICE 'CAR CANNOT HOLD THAT MANY PASSENGERS';
--         RETURN NULL;
--     END IF;
--
--     --check for bid start time validity
--     check_correct_bid_time := EXISTS (
--         SELECT * FROM cp_user g
--         WHERE g.email = NEW.email
--         AND g.account_creation_time < NEW.bid_start_time
--     );
--     IF NOT check_correct_bid_time THEN
--         RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
--         RETURN NULL;
--     END IF;
--
--     --check for overlaps with other driver requests
--     check_driver_requests_overlap := EXISTS(
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.email
--         AND (((a.pick_up_time + '30 minute'::interval) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
--         OR ((a.pick_up_time - '30 minute'::interval) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
--         OR a.pick_up_time = NEW.pick_up_time)
--     );
--     IF check_driver_requests_overlap AND check_driver_requests_overlap IS NOT NULL THEN
--         RAISE NOTICE 'OVERLAP WITH OTHER REQUESTS';
--         RETURN NULL;
--     END IF;
--
--     --check for overlaps with passenger bids
--     check_passenger_bid_overlap := EXISTS(
--         SELECT * FROM cp_passenger_bid a
--         WHERE a.passenger_email = NEW.email
--         AND ((a.pick_up_time + '30 minute'::interval > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
--         OR (a.pick_up_time - '30 minute'::interval < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
--         OR a.pick_up_time = NEW.pick_up_time)
--     );
--
--     IF check_passenger_bid_overlap AND check_passenger_bid_overlap IS NOT NULL THEN
--         RAISE NOTICE 'OVERLAP WITH OTHER BIDS';
--         RETURN NULL;
--     END IF;
--
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_cp_advertised_journey
-- BEFORE INSERT OR UPDATE ON cp_advertised_journey
-- FOR EACH ROW EXECUTE PROCEDURE f_check_cp_advertised_journey();
--
--
-- ----------TRIGGER FOR cp_passenger_bid----------
-- CREATE OR REPLACE FUNCTION f_check_passenger_bid()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_advertised_ride_bid_start BOOLEAN;
--     DECLARE check_advertised_ride_bid_end BOOLEAN;
--     DECLARE check_enough_seats BOOLEAN;
--     DECLARE check_minimum_bid BOOLEAN;
--     DECLARE check_correct_bid_time BOOLEAN;
--     DECLARE check_driver_requests_overlap BOOLEAN;
-- BEGIN
--     --check that bid occurs after it was put up
--     check_advertised_ride_bid_start := EXISTS (
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
--         AND a.bid_start_time <= NEW.bid_time
--     );
--
--     IF NOT check_advertised_ride_bid_start THEN
--         RAISE NOTICE 'BID OCCURS BEFORE IT WAS PUT UP';
--         RETURN NULL;
--     END IF;
--
--     --check that bid occurs before it ends
--     check_advertised_ride_bid_end := EXISTS (
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
--         AND a.bid_end_time >= NEW.bid_time
--     );
--
--     IF NOT check_advertised_ride_bid_end THEN
--         RAISE NOTICE 'BID OCCURS AFTER IT WAS PUT UP';
--         RETURN NULL;
--     END IF;
--
--     --check to ensure there are enough seats
--     check_enough_seats := EXISTS (
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
--         AND a.max_passengers >= NEW.number_of_passengers
--     );
--
--     IF NOT check_enough_seats THEN
--         RAISE NOTICE 'NOT ENOUGH SEATS';
--         RETURN NULL;
--     END IF;
--
--     -- check to ensure bid is more than the minimum
--     check_minimum_bid := EXISTS (
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.driver_email AND a.pick_up_time = NEW.pick_up_time
--         AND a.min_bid <= NEW.bid_price
--     );
--
--     IF NOT check_minimum_bid THEN
--         RAISE NOTICE 'BELOW MINIMUM BID';
--         RETURN NULL;
--     END IF;
--
--     --check for bid_time is after account was created
--     check_correct_bid_time := EXISTS (
--         SELECT * FROM cp_user g
--         WHERE g.email = NEW.passenger_email
--         AND g.account_creation_time < NEW.bid_time
--     );
--     IF NOT check_correct_bid_time THEN
--         RAISE NOTICE 'BID WAS PUT UP BEFORE ACCOUNT CREATION';
--         RETURN NULL;
--     END IF;
--
--     --check for overlaps with advertised journies
--     check_driver_requests_overlap := EXISTS(
--         SELECT * FROM cp_advertised_journey a
--         WHERE a.email = NEW.passenger_email
--         AND (((a.pick_up_time + '30 minute'::interval) > NEW.pick_up_time AND a.pick_up_time < NEW.pick_up_time)
--         OR ((a.pick_up_time - '30 minute'::interval) < NEW.pick_up_time AND a.pick_up_time > NEW.pick_up_time)
--         OR a.pick_up_time = NEW.pick_up_time)
--     );
--
--     IF check_driver_requests_overlap AND check_driver_requests_overlap IS NOT NULL THEN
--         RAISE NOTICE 'OVERLAP WITH ADVERTISED JOURNIES';
--         RETURN NULL;
--     END IF;
--
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_passenger_bid
-- BEFORE INSERT OR UPDATE ON cp_passenger_bid
-- FOR EACH ROW EXECUTE PROCEDURE f_check_passenger_bid();
--
-- --TRIGGER FOR cp_journey_occurs--
-- CREATE OR REPLACE FUNCTION f_check_journey_occurs()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_won_bid BOOLEAN;
-- BEGIN
--     check_won_bid := EXISTS(
--         SELECT * FROM cp_passenger_bid b
--         WHERE b.passenger_email = NEW.passenger_email
--         AND b.driver_email = NEW.driver_email
--         AND b.car_plate_no = NEW.car_plate_no
--         AND b.pick_up_time = NEW.pick_up_time
--         AND b.bid_won = TRUE
--     );
--     IF NOT check_won_bid THEN
--         RAISE NOTICE 'BID NOT WON YET';
--         RETURN NULL;
--     END IF;
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_journey_occurs
-- BEFORE INSERT OR UPDATE ON cp_journey_occurs
-- FOR EACH ROW EXECUTE PROCEDURE f_check_journey_occurs();
--
-- --TRIGGER FOR cp_driver_rates--
-- CREATE OR REPLACE FUNCTION f_check_driver_rates()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_journey_over BOOLEAN;
-- BEGIN
--     check_journey_over := EXISTS(
--         SELECT * FROM cp_journey_occurs j
--         WHERE j.driver_email = NEW.driver_email
--         AND j.journey_start_time = NEW.journey_start_time
--         AND j.journey_end_time IS NOT NULL
--     );
--     IF NOT check_journey_over THEN
--         RAISE NOTICE 'JOURNEY NOT OVER YET';
--         RETURN NULL;
--     END IF;
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_driver_rates
-- BEFORE INSERT OR UPDATE ON cp_driver_rates
-- FOR EACH ROW EXECUTE PROCEDURE f_check_driver_rates();
--
-- --TRIGGER FOR cp_passenger_rates--
-- CREATE OR REPLACE FUNCTION f_check_passenger_rates()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_journey_over BOOLEAN;
-- BEGIN
--     check_journey_over := EXISTS(
--         SELECT * FROM cp_journey_occurs j
--         WHERE j.passenger_email = NEW.passenger_email
--         AND j.journey_start_time = NEW.journey_start_time
--         AND j.journey_end_time IS NOT NULL
--     );
--     IF NOT check_journey_over THEN
--         RAISE NOTICE 'JOURNEY NOT OVER YET';
--         RETURN NULL;
--     END IF;
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_passenger_rates
-- BEFORE INSERT OR UPDATE ON cp_passenger_rates
-- FOR EACH ROW EXECUTE PROCEDURE f_check_passenger_rates();
--
-- --TRIGGER FOR cp_payment--
-- CREATE OR REPLACE FUNCTION f_check_payment()
-- RETURNS TRIGGER
-- AS $$
--     DECLARE check_journey_over BOOLEAN;
-- BEGIN
--     check_journey_over := EXISTS(
--         SELECT * FROM cp_journey_occurs j
--         WHERE j.passenger_email = NEW.passenger_email
--         AND j.journey_start_time = NEW.journey_start_time
--         AND j.journey_end_time IS NOT NULL
--     );
--     IF NOT check_journey_over THEN
--         RAISE NOTICE 'JOURNEY NOT OVER YET';
--         RETURN NULL;
--     END IF;
--     RETURN NEW;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE TRIGGER t_check_payment
-- BEFORE INSERT OR UPDATE ON cp_payment
-- FOR EACH ROW EXECUTE PROCEDURE f_check_payment();
