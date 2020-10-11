CREATE TABLE availabilities (
	start_timestamp  timestamp  NOT NULL CHECK (start_timestamp > NOW()),
	end_timestamp  timestamp NOT NULL CHECK (start_timestamp > NOW()),
	pet_count int DEFAULT 0 NOT NULL CHECK (pet_count <= 5),
	caretaker_username varchar(90) NOT NULL, --REFERENCES caretaker.username ON DELETE CASCADE,
	CHECK(start_timestamp < end_timestamp)
);

CREATE TABLE username_password (
	username   varchar(9)  PRIMARY KEY,
	password   varchar(64) NOT NULL,
	status     varchar(6)  NOT NULL,
	first_name varchar(64) NOT NULL,
	last_name  varchar(64) NOT NULL
);

CREATE TABLE game_list (
	gamename  varchar(64) PRIMARY KEY,
	rating    real        NOT NULL,
	ranking   int         NOT NULL
);

CREATE TABLE user_games (
	username  varchar(9)  NOT NULL,
	gamename  varchar(64) NOT NULL,
	PRIMARY KEY(username,gamename),
	FOREIGN KEY(username) REFERENCES username_password(username),
	FOREIGN KEY(gamename) REFERENCES game_list(gamename)
);

CREATE TABLE game_plays (
	user1     varchar(9)  NOT NULL,
	user2     varchar(9)  NOT NULL,
	gamename  varchar(64) NOT NULL,
	winner    varchar(9)  NOT NULL,
	FOREIGN KEY(user1)    REFERENCES username_password(username),
	FOREIGN KEY(user2)    REFERENCES username_password(username),
	FOREIGN KEY(winner)   REFERENCES username_password(username),
	FOREIGN KEY(gamename) REFERENCES game_list(gamename)
);

-- Populate table with dummy values --

INSERT INTO availabilities (start_timestamp, end_timestamp, pet_count, caretaker_username)
VALUES ('2021-06-22 19:10:25-07','2022-06-22 19:10:25-07', 3, 'Sam')
RETURNING *;


INSERT INTO availabilities (start_timestamp, end_timestamp, pet_count, caretaker_username)
SELECT generate_series('2021-06-22 19:10:25-07', '2022-06-22 19:10:25-07', '10 day'::interval), generate_series('2022-06-22 19:10:25-07', '2023-06-22 19:10:25-07', '10 day'::interval), floor(random() * 5)
  , 'user_' || floor(random() * 100)
RETURNING *;

CREATE OR REPLACE FUNCTION update_user_status_from_plays() RETURNS trigger AS $ret$
	BEGIN
		UPDATE username_password
		SET status='Silver'
		WHERE (
			SELECT COUNT(*) FROM game_plays WHERE username=NEW.user1
		) > 10;
		UPDATE username_password
		SET status='Gold'
		WHERE (
			SELECT COUNT(*) FROM game_plays WHERE username=NEW.user1
		) > 20;
		UPDATE username_password
		SET status='Silver'
		WHERE (
			SELECT COUNT(*) FROM game_plays WHERE username=NEW.user2
		) > 10;
		UPDATE username_password
		SET status='Gold'
		WHERE (
			SELECT COUNT(*) FROM game_plays WHERE username=NEW.user2
		) > 20;
		RETURN NEW;
	END;
$ret$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION merge_availabilities() RETURNS trigger AS $ret$
	BEGIN
	    --Case 0: new availability period does not coincide with old availability period at all --
	    IF((SELECT COUNT(*) FROM availabilities A WHERE A.start_timestamp > NEW.start_timestamp OR A.end_timestamp < NEW.end_timestamp) <= 0)
	    THEN
	    RAISE NOTICE 'new availability does not coincide with old availability';
	    RETURN NEW;
	    END IF;

	    --Case 1: old availability period is part of  --
		UPDATE availabilities
		SET start_timestamp= NEW.start_timestamp, end_timestamp= NEW.end_timestamp
		WHERE (
			SELECT * FROM availabilities WHERE (caretaker_username = NEW.caretaker_username AND start_timestamp > NEW.start_timestamp AND end_timestamp < NEW.end_timestamp)
		);
		--Case 2: When new availability period coincide with old availability period on the left hand side --
		UPDATE availabilities
        		SET start_timestamp= NEW.start_timestamp
        		WHERE (
        			SELECT * FROM availabilities WHERE (caretaker_username = NEW.caretaker_username AND start_timestamp > NEW.start_timestamp AND start_timestamp <= NEW.end_timestamp AND end_timestamp >= NEW.end_timestamp)
        		);
      --Case 3: When new availability period coincide with old availability period on the right hand side --
      	UPDATE availabilities
              	SET end_timestamp= NEW.end_timestamp
              	WHERE (
              		SELECT * FROM availabilities WHERE (caretaker_username = NEW.caretaker_username AND start_timestamp <= NEW.start_timestamp AND start_timestamp <= NEW.end_timestamp AND end_timestamp >= NEW.end_timestamp)

             	);
		RETURN NULL;
	END;
$ret$ LANGUAGE plpgsql;

CREATE TRIGGER check_user_status_from_plays
	AFTER INSERT ON game_plays
	FOR EACH ROW
	EXECUTE PROCEDURE update_user_status_from_plays();

--Checks if new availability period coincides with existng availability. If so, merge them.--
CREATE TRIGGER check_coincide_availability_period
	BEFORE INSERT
	ON availabilities
	FOR EACH ROW
	EXECUTE PROCEDURE merge_availabilities();


