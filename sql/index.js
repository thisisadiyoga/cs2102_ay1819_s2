const sql = {}

sql.query = {
	// Counting & Average
	count_play: 'SELECT COUNT(winner) FROM game_plays WHERE user1=$1 OR user2=$1',
	count_wins: 'SELECT COUNT(winner) FROM game_plays WHERE winner=$1',
	avg_rating: 'SELECT AVG(rating) FROM user_games INNER JOIN game_list ON user_games.gamename=game_list.gamename WHERE username=$1',

	// Information
	page_game: 'SELECT * FROM game_list WHERE ranking >= $1 AND ranking <= $2 ORDER BY ranking ASC',
	page_lims: 'SELECT * FROM game_list ORDER BY ranking ASC LIMIT 10 OFFSET $1',
	ctx_games: 'SELECT COUNT(*) FROM game_list',
	all_games: 'SELECT ranking,game_list.gamename AS game,rating FROM user_games INNER JOIN game_list ON user_games.gamename=game_list.gamename WHERE username=$1 ORDER BY ranking ASC',
	all_cars:  'SELECT * FROM cp_driver_drives WHERE email=$1',
	all_journeys: 'SELECT car_plate_no, max_passengers, pick_up_area, drop_off_area, min_bid, bid_start_time, bid_end_time, pick_up_time FROM cp_advertised_journey WHERE email=$1',
  valid_journeys: 'SELECT * FROM cp_advertised_journey NATURAL JOIN cp_driver_drives NATURAL JOIN cp_driver WHERE bid_end_time > NOW()::timestamp AND email=$1',
	all_available_journeys: 'SELECT email, car_model, car_plate_no, max_passengers, pick_up_area, drop_off_area, min_bid, bid_start_time, bid_end_time, to_char(pick_up_time, \'YYYY-MM-DD HH24:MI:SS\') AS pick_up_time FROM cp_advertised_journey NATURAL JOIN cp_driver_drives NATURAL JOIN cp_user WHERE bid_end_time > NOW()::timestamp',

	// Insertion
	add_car: 'INSERT INTO cp_driver_drives (car_plate_no, car_model, max_passengers, email) VALUES($1, $2, $3, $4)',
	advertise_journey: 'INSERT INTO cp_advertised_journey (email, car_plate_no, max_passengers, pick_up_area, drop_off_area, min_bid, bid_start_time, bid_end_time, pick_up_time) VALUES ($1, $2, $8, $3, $4, $9, $5, $6, $7)',
	add_user: 'INSERT INTO cp_user (email, account_creation_time, dob, gender, firstname, lastname, password) VALUES ($1, CURRENT_TIMESTAMP, $2, $3, $4, $5, $6)',
	add_driver:		'INSERT INTO cp_driver (email) VALUES ($1)',
 	add_passenger:	'INSERT INTO cp_passenger (email, home_address, work_address) VALUES ($1, \'\', \'\')',
	add_bid: 'INSERT INTO cp_passenger_bid (passenger_email, driver_email, car_plate_no, pick_up_time, pick_up_address, drop_off_address, bid_time, bid_price, number_of_passengers, bid_won) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NULL)',
	
	add_cash_payment: 'INSERT INTO cp_payment_method (have_card, email) VALUES (\'f\', $1)',

	// Login
	userpass: 'SELECT email, password, firstname, lastname FROM cp_user WHERE email=$1',
	find_driver:'SELECT * FROM cp_driver WHERE email=$1',
	find_passenger: 'SELECT * FROM cp_passenger WHERE email=$1',
	find_advertised_ride: 'SELECT email, firstname, lastname, gender, car_model, car_plate_no, max_passengers, pick_up_area, drop_off_area, min_bid, to_char(bid_end_time, \'YYYY-MM-DD HH24:MI:SS\') AS bid_end_time, to_char(pick_up_time, \'YYYY-MM-DD HH24:MI:SS\') AS pick_up_time FROM cp_advertised_journey NATURAL JOIN cp_user NATURAL JOIN cp_driver_drives WHERE email=$1 AND to_char(pick_up_time, \'YYYY-MM-DD HH24:MI:SS\')=$2 AND car_plate_no=$3',

	// Update
	update_info: 'UPDATE cp_user SET firstname=$2, lastname=$3 WHERE email=$1',
	update_pass: 'UPDATE cp_user SET password=$2 WHERE email=$1',
	update_car: 'UPDATE cp_driver_drives SET car_plate_no=$1, car_model=$2, max_passengers=$3 WHERE email=$4 AND car_plate_no=$5',
	add_payment: 'UPDATE cp_payment_method SET have_card=$1, cardholder_name=$2, cvv=$3, expiry_date=$4, card_number=$5, email=$6',
	add_driver_info: 'UPDATE cp_driver SET bank_account_no=$1, license_no=$2 WHERE email=$3',
	update_advertisement: '',
	update_bid: '',

	// Deletion
	del_car: 'DELETE FROM cp_driver_drives WHERE email=$1 AND car_plate_no=$2',
	del_journey: 'DELETE FROM cp_advertised_journey WHERE email=$1 AND car_plate_no=$2 AND pick_up_time=$3',

	// Search
	search_game: 'SELECT * FROM game_list WHERE lower(gamename) LIKE $1',


	//complex queries
	choose_best_bid: '',
	recommended_ride: '',

	// WITH highest_bid_price AS (
	// 	SELECT passenger_email, MAX(bid_price)
	// 	FROM cp_passenger_bid
	// 	WHERE driver_email = 'bbb@gmail.com'
	// 	AND pick_up_time = '2019-11-07 11:15:00'
	// 	GROUP BY passenger_email, driver_email, car_plate_no, pick_up_time
	// ),
	// highest_avg_rating AS (
	// 	SELECT d.passenger_email, AVG(rating)  
	// 	FROM (cp_driver_rates NATURAL JOIN cp_journey_occurs) d
	// 	WHERE 
	// 	EXISTS (
	// 		SELECT 1
	// 		FROM cp_passenger_bid a
	// 		WHERE a.passenger_email = d.passenger_email
	// 		AND a.driver_email = 'bbb@gmail.com'
	// 		AND a.pick_up_time = '2019-11-07 11:15:00'
	// 	)
	// 	GROUP BY d.passenger_email
	// )
	// SELECT *
	// FROM (
	// 	SELECT *,
	// 	CASE WHEN (SELECT COUNT(*) FROM highest_bid_price) > 1 THEN 1 END AS bid_price_tie
	// 	FROM cp_passenger_bid p
	// ) 
	// WHERE 


	
	//For our last complex query maybe we can do a recommendation of sorts for new journeys to the passenger based on old ride timings, destinations and drivers etc.
	WITH journey_info AS (
	SELECT pick_up_area, drop_off_area, pick_up_time, EXTRACT(HOUR FROM DATE_TRUNC('hour', pick_up_time + interval '30 minute')) AS hour
	FROM cp_journey_occurs NATURAL JOIN cp_passenger_bid NATURAL JOIN cp_advertised_journey
	),
	x AS (
		SELECT *,
		CASE WHEN (
			SELECT COUNT(*) FROM journey_info j
			WHERE j.pick_up_time > (CURRENT_TIMESTAMP - '1 week'::interval) 
			GROUP BY j.pick_up_area, j.drop_off_area, j.hour
			
			) >= 2 THEN 1 ELSE 0 END AS frequent_pick_up_area
		FROM journey_info
	)
	SELECT DISTINCT pick_up_area, drop_off_area, pick_up_time
	FROM x
	WHERE frequent_pick_up_area = 1;
	

	//

	



}

module.exports = sql
