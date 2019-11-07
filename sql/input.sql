INSERT INTO cp_user VALUES ('daniels@gmail.com', '2019-11-03 00:00:00', '1990-12-23', 'm', 'Charlie', 'Daniels', '12345678');
INSERT INTO cp_user VALUES ('rico41@gmail.com', '2019-11-03 01:00:00', '1990-01-14', 'm', 'Sergio', 'Rico', '12345678');
INSERT INTO cp_user VALUES ('wilsontheKING@gmail.com', '2019-11-03 02:00:00', '1990-02-21', 'm', 'Callum', 'Wilson', '12345678');
INSERT INTO cp_user VALUES ('howecoach@gmail.com', '2019-11-03 03:00:00', '1990-09-21', 'm', 'Eddie', 'Howe', '12345678');

INSERT INTO cp_driver VALUES ('daniels@gmail.com');
INSERT INTO cp_driver VALUES ('wilsontheKING@gmail.com');
INSERT INTO cp_driver VALUES ('rico41@gmail.com');

INSERT INTO cp_passenger VALUES ('rico41@gmail.com');
INSERT INTO cp_passenger VALUES ('daniels@gmail.com');

INSERT INTO cp_driver_drives VALUES ('SJZ1234U', 'Audi R8', '3', 'daniels@gmail.com');
INSERT INTO cp_driver_drives VALUES ('SKL4321U', 'Honda Civic', '3', 'daniels@gmail.com');
INSERT INTO cp_driver_drives VALUES ('EK45I', 'Toyota Camry', '3', 'wilsontheKING@gmail.com');
INSERT INTO cp_driver_drives VALUES ('AAA', 'Toyota Camry', '3', 'rico41@gmail.com');


--INSERT INTO Advertised_Journey_Driver VALUES ('EK45I', 3, 'Chinatown', 'Woodlands', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 06:00:00', 'wilsontheKING@gmail.com');

INSERT INTO cp_advertised_journey VALUES ('SJZ1234U', 3, 'Woodlands', 'Chinatown', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 03:00:00', 'daniels@gmail.com'); 
INSERT INTO cp_advertised_journey VALUES ('SJZ1234U', 3, 'Chinatown', 'Woodlands', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 04:00:00', 'daniels@gmail.com');
INSERT INTO cp_advertised_journey VALUES ('EK45I', 3, 'Chinatown', 'Woodlands', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 06:00:00', 'wilsontheKING@gmail.com');
INSERT INTO cp_advertised_journey VALUES ('EK45I', 3, 'Chinatown', 'Woodlands', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 07:00:00', 'wilsontheKING@gmail.com');
INSERT INTO cp_advertised_journey VALUES ('AAA', 3, 'Chinatown', 'Woodlands', 5.5, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 07:15:00', 'rico41@gmail.com');


INSERT INTO cp_requested_journey VALUES (3, '23 Dover Road', '78 Ubi Lane', 20.0, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 05:00:00', 'daniels@gmail.com');
INSERT INTO cp_requested_journey VALUES (3, '23 Dover Road', '78 Ubi Lane', 20.0, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 06:00:00', 'daniels@gmail.com');
INSERT INTO cp_requested_journey VALUES (3, '23 Dover Road', '78 Ubi Lane', 20.0, '2019-12-03 00:00:00', '2019-12-03 01:00:00', '2019-12-03 07:00:00', 'rico41@gmail.com');


INSERT INTO cp_passenger_bid VALUES ('daniels@gmail.com', 'wilsontheKING@gmail.com', 'Chinatown', 'Woodlands', '23 Woodlands Ave 6', '86 Telok Ayer Street', '2019-12-03 01:00:00', '2019-12-03 06:00:00', 7);
INSERT INTO cp_passenger_bid VALUES ('daniels@gmail.com', 'wilsontheKING@gmail.com', 'Chinatown', 'Woodlands', '23 Woodlands Ave 6', '86 Telok Ayer Street', '2019-12-03 01:00:00', '2019-12-03 07:00:00', 7);
INSERT INTO cp_passenger_bid VALUES ('daniels@gmail.com', 'rico41@gmail.com', 'Chinatown', 'Woodlands', '23 Woodlands Ave 6', '86 Telok Ayer Street', '2019-12-03 01:00:00', '2019-12-03 07:15:00', 7);
