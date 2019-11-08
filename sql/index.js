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
	all_plays: 'SELECT gamename AS game, user1, user2, winner FROM game_plays WHERE user1=$1 OR user2=$1',

	// Insertion
	add_car: 'INSERT INTO cp_driver_drives (car_plate_no, car_model, max_passengers, email) VALUES($1, $2, $3, $4)',
	advertise_journey: 'INSERT INTO cp_advertised_journey (email, car_plate_no, max_passengers, pick_up_area, drop_off_area, min_bid, bid_start_time, bid_end_time) VALUES($1,$2,$3,$4,$5,%6,$7,$8,$9)',
	add_user: 'INSERT INTO cp_user (email, account_creation_time, dob, gender, firstname, lastname, password) VALUES ($1, CURRENT_TIMESTAMP, $2, $3, $4, $5, $6)',
	add_driver:		'INSERT INTO cp_driver (email) VALUES ($1)',
 	add_passenger:	'INSERT INTO cp_passenger (email, home_address, work_address) VALUES ($1, \'\', \'\')',
	add_bid: '',

	// Login
	userpass: 'SELECT email, password, firstname, lastname FROM cp_user WHERE email=$1',
	find_driver:'SELECT * FROM cp_driver WHERE email=$1',
	find_passenger: 'SELECT * FROM cp_passenger WHERE email=$1',

	// Update
	update_info: 'UPDATE cp_user SET firstname=$2, lastname=$3 WHERE email=$1',
	update_pass: 'UPDATE cp_user SET password=$2 WHERE email=$1',
	update_car: 'UPDATE cp_driver_drives SET car_plate_no=$1, car_model=$2, max_passengers=$3 WHERE email=$4 AND car_plate_no=$5',
	update_advertisement: '',
	update_bid: '',

	// Deletion
	del_car: 'DELETE FROM cp_driver_drives WHERE email=$1 AND car_plate_no=$2',

	// Search
	search_game: 'SELECT * FROM game_list WHERE lower(gamename) LIKE $1',
}

module.exports = sql
