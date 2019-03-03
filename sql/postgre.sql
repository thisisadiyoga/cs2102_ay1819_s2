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

INSERT INTO username_password (username, password, status, first_name, last_name)
VALUES ('meeple', '$2b$10$13BWk/6YJ4JYlxPvkNTnqeT6J8zsPTe592QIen.Le7apc921uebUW', 'Bronze', 'Adi', 'Prabawa');
INSERT INTO username_password (username, password, status, first_name, last_name)
VALUES ('adi'   , '$2b$10$Pdcb3BDaN1wATBHyZ0Fymurw1Js01F9nv6xgff42NfOmTrdXT1A.i', 'Bronze', 'Mikal', 'Lim');
INSERT INTO username_password (username, password, status, first_name, last_name)
VALUES ('cs2102', '$2b$10$vS4KkX8uenTCNooir9vyUuAuX5gUhSGVql8yQdsDDD4TG8bSUjkt.', 'Bronze', 'Kueider', 'Ho');

INSERT INTO game_list (ranking, gamename, rating)
VALUES (1, 'Gloomhaven', 8.617);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (2, 'Pandemic Legacy: Season 1', 8.494);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (3, 'Through the Ages: A New Story of Civilization', 8.272);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (4, 'Terraforming Mars', 8.232);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (5, 'Twilight Struggle', 8.180);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (6, 'Star Wars: Rebellion', 8.164);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (7, 'Scythe', 8.121);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (8, 'Gaia Project', 8.116);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (9, 'Great Western Trail', 8.072);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (10, 'Terra Mystica', 8.058);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (11, 'Twilight Imperium (Fourth Edition)', 8.036);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (12, 'War of the Ring (Second Edition)', 8.016);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (13, 'The Castles of Burgundy', 8.011);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (14, '7 Wonders Duel', 7.998);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (15, 'The 7th Continent', 7.967);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (16, 'Spirit Island', 7.962);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (17, 'Puerto Rico', 7.929);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (18, 'Arkham Horror: The Card Game', 7.925);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (19, 'Viticulture Essential Edition', 7.923);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (20, 'Concordia', 7.920);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (21, 'Caverna: The Cave Farmers', 7.916);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (22, 'Brass: Birmingham', 7.908);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (23, 'Brass: Lancashire', 7.901);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (24, 'Agricola', 7.896);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (25, 'Mage Knight Board Game', 7.895);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (26, 'Mansions of Madness: Second Edition', 7.882);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (27, 'Orleans', 7.874);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (28, 'Blood Rage', 7.852);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (29, 'Food Chain Magnate', 7.852);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (30, 'A Feast for Odin', 7.846);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (31, 'Mechs vs. Minions', 7.826);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (32, 'Kingdom Death: Monster', 7.821);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (33, 'Pandemic Legacy: Season 2', 7.818);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (34, 'Star Wars: Imperial Assault', 7.817);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (35, 'Through the Ages: A Story of Civilization', 7.810);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (36, 'Power Grid', 7.807);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (37, 'Azul', 7.788);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (38, 'Eclipse', 7.784);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (39, 'Tzolkin: The Mayan Calendar', 7.780);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (40, 'Le Havre', 7.761);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (41, 'Robinson Crusoe: Adventures on the Cursed Island', 7.752);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (42, 'The Voyages of Marco Polo', 7.734);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (43, 'Android: Netrunner', 7.714);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (44, 'Clans of Caledonia', 7.706);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (45, '7 Wonders', 7.697);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (46, 'Keyflower', 7.683);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (47, 'Caylus', 7.668);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (48, 'Race for the Galaxy', 7.667);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (49, 'Dominant Species', 7.664);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (50, 'Rising Sun', 7.655);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (51, 'Fields of Arle', 7.652);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (52, 'Twilight Imperium (Third Edition)', 7.649);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (53, 'Lords of Waterdeep', 7.649);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (54, 'Five Tribes', 7.644);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (55, 'Eldritch Horror', 7.643);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (56, 'Codenames', 7.639);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (57, 'El Grande', 7.634);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (58, 'Anachrony', 7.631);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (59, 'Dominion: Intrigue', 7.615);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (60, 'Clank!: A Deck-Building Adventure', 7.613);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (61, 'Patchwork', 7.612);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (62, 'The Gallerist', 7.605);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (63, 'Mombasa', 7.602);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (64, 'T.I.M.E Stories', 7.596);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (65, 'Battlestar Galactica: The Board Game', 7.596);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (66, 'Roll for the Galaxy', 7.593);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (67, 'Troyes', 7.578);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (68, 'Sherlock Holmes Consulting Detective: The Thames Murders', 7.577);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (69, 'Russian Railroads', 7.568);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (70, 'Tigris & Euphrates', 7.564);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (71, 'Star Wars: X-Wing Miniatures Game', 7.560);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (72, 'Trajan', 7.554);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (73, 'Dead of Winter: A Crossroads Game', 7.552);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (74, 'Pandemic', 7.551);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (75, 'Dominion', 7.550);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (76, 'Kemet', 7.526);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (77, 'Crokinole', 7.525);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (78, 'Pandemic: Iberia', 7.516);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (79, 'Root', 7.514);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (80, 'Lisboa', 7.506);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (81, 'Descent: Journeys in the Dark (Second Edition)', 7.503);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (82, 'Stone Age', 7.502);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (83, 'Forbidden Stars', 7.499);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (84, 'Alchemists', 7.491);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (85, 'Santorini', 7.485);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (86, 'War of the Ring (First Edition)', 7.483);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (87, 'Legendary Encounters: An Alien Deck Building Game', 7.478);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (88, 'Star Realms', 7.477);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (89, 'Castles of Mad King Ludwig', 7.477);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (90, 'Agricola (Revised Edition)', 7.476);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (91, 'Yokohama', 7.474);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (92, 'A Game of Thrones: The Board Game (Second Edition)', 7.471);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (93, 'Istanbul', 7.471);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (94, 'Raiders of the North Sea', 7.467);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (95, 'The Resistance: Avalon', 7.466);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (96, 'Champions of Midgard', 7.456);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (97, 'Ticket to Ride: Europe', 7.451);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (98, 'Ora et Labora', 7.449);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (99, 'Grand Austria Hotel', 7.445);
INSERT INTO game_list (ranking, gamename, rating)
VALUES (100, 'Chaos in the Old World', 7.445);

INSERT INTO user_games (username, gamename)
VALUES ('meeple', 'Gloomhaven');
INSERT INTO user_games (username, gamename)
VALUES ('meeple', 'Gaia Project');

INSERT INTO user_games (username, gamename)
VALUES ('adi', 'Twilight Struggle');

INSERT INTO game_plays (user1, user2, gamename, winner)
VALUES ('meeple', 'adi', 'Scythe', 'adi');
INSERT INTO game_plays (user1, user2, gamename, winner)
VALUES ('meeple', 'adi', 'Scythe', 'meeple');
INSERT INTO game_plays (user1, user2, gamename, winner)
VALUES ('meeple', 'adi', 'Scythe', 'meeple');
INSERT INTO game_plays (user1, user2, gamename, winner)
VALUES ('adi', 'meeple', 'Scythe', 'adi');

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

CREATE TRIGGER check_user_status_from_plays
	AFTER INSERT ON game_plays
	FOR EACH ROW
	EXECUTE PROCEDURE update_user_status_from_plays();

