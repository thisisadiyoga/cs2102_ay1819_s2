INSERT INTO cp_user VALUES ('aaa@gmail.com', '2019-11-07 00:00:00', '2000-01-01','m', 'bob', 'jones', '1234');
INSERT INTO cp_user VALUES ('bbb@gmail.com', '2019-11-07 00:00:00', '2000-01-01','m', 'bob', 'jones', '1234');
INSERT INTO cp_user VALUES ('ccc@gmail.com', '2019-11-07 00:00:00', '2000-01-01','m', 'bob', 'jones', '1234');
INSERT INTO cp_user VALUES ('ddd@gmail.com', '2019-11-07 00:00:00', '2000-01-01','m', 'bob', 'jones', '1234');

INSERT INTO cp_driver VALUES ('aaa@gmail.com', '0123456789', 'license01');
INSERT INTO cp_driver VALUES ('bbb@gmail.com', '0123456789', 'license02');

INSERT INTO cp_driver_drives VALUES ('A123A', 'Audi R8', 3, 'aaa@gmail.com');
INSERT INTO cp_driver_drives VALUES ('B123B', 'Audi R8', 3, 'aaa@gmail.com');
INSERT INTO cp_driver_drives VALUES ('C123C', 'Audi R8', 3, 'aaa@gmail.com');
INSERT INTO cp_driver_drives VALUES ('A123A', 'Audi R8', 3, 'bbb@gmail.com');

INSERT INTO cp_passenger VALUES ('aaa@gmail.com', NULL, NULL);
INSERT INTO cp_passenger VALUES ('ccc@gmail.com', NULL, NULL);
INSERT INTO cp_passenger VALUES ('ddd@gmail.com', NULL, NULL);

INSERT INTO cp_payment_method VALUES ('f', NULL, NULL, NULL, NULL, 'aaa@gmail.com');
INSERT INTO cp_payment_method VALUES ('f', NULL, NULL, NULL, NULL, 'ccc@gmail.com');
INSERT INTO cp_payment_method VALUES ('t', 'bob', '111', '2022-11-11', '000000000', 'ddd@gmail.com');


INSERT INTO cp_advertised_journey VALUES ('aaa@gmail.com', 'A123A', 3, 'clementi', 'orchard', 10, '2019-11-07 06:00:00', '2019-11-07 06:15:00', '2019-11-07 07:00:00');
INSERT INTO cp_advertised_journey VALUES ('aaa@gmail.com', 'A123A', 3, 'clementi', 'orchard', 10, '2019-11-07 06:00:00', '2019-11-07 06:15:00', '2019-11-07 07:45:00');
INSERT INTO cp_advertised_journey VALUES ('bbb@gmail.com', 'A123A', 3, 'clementi', 'orchard', 10, '2019-11-07 10:00:00', '2019-11-07 10:15:00', '2019-11-07 11:15:00');
INSERT INTO cp_advertised_journey VALUES ('aaa@gmail.com', 'A123A', 3, 'clementi', 'orchard', 10, '2019-11-07 06:00:00', '2019-11-07 06:15:00', '2019-11-07 12:30:00');

INSERT INTO cp_passenger_bid VALUES ('ccc@gmail.com', 'bbb@gmail.com', 'A123A', '2019-11-07 11:15:00', 'pickupAddress', 'dropoffAddress', '2019-11-07 10:10:00', 15, 3, NULL);
INSERT INTO cp_passenger_bid VALUES ('aaa@gmail.com', 'bbb@gmail.com', 'A123A', '2019-11-07 11:15:00', 'pickupAddress', 'dropoffAddress', '2019-11-07 10:10:00', 15, 2, NULL);

UPDATE cp_passenger_bid SET bid_won = TRUE WHERE passenger_email = 'ccc@gmail.com';

INSERT INTO cp_journey_occurs VALUES ('ccc@gmail.com', 'bbb@gmail.com', 'A123A', '2019-11-07 11:15:00', '2019-11-07 10:10:00', NULL, NULL);

UPDATE cp_journey_occurs SET journey_end_time = '2019-11-07 11:10:00' WHERE passenger_email = 'ccc@gmail.com';

INSERT INTO cp_driver_rates VALUES ('2019-11-07 10:10:00', 'bbb@gmail.com', 3);

INSERT INTO cp_passenger_rates VALUES ('2019-11-07 10:10:00', 'ccc@gmail.com', 3);

INSERT INTO cp_payment VALUES ('2019-11-07 10:10:00', 'ccc@gmail.com', 'f', 'cash');