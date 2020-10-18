const sql = {}

sql.query = {
		// Counting & Average
    	count_play: 'SELECT COUNT(winner) FROM game_plays WHERE user1=$1 OR user2=$1',
    	count_wins: 'SELECT COUNT(winner) FROM game_plays WHERE winner=$1',
    	avg_rating: 'SELECT AVG(rating) FROM user_games INNER JOIN game_list ON user_games.gamename=game_list.gamename WHERE username=$1',

    	// Information
    	read_weekly_availabilities: 'SELECT start_date, end_date FROM declares_availabilities WHERE caretaker_username = $1 AND (start_timestamp >= $2 AND start_timestamp <= interval \'1 week\' ) ORDER BY start_timestamp ASC', //TODO: cast $2 to 12am of the day
    	read_monthly_availabilities: 'SELECT start_date, end_date FROM declares_availabilities WHERE caretaker_username = $1 AND  (start_timestamp >= $2 AND start_timestamp <= interval \'1  month\' ) ORDER BY start_timestamp ASC', //TODO: cast $2 to 12am of the day
    	read_yearly_availabilities: 'SELECT start_date, end_date FROM declares_availabilities WHERE caretaker_username = $1 AND  (start_timestamp >= $2 AND start_timestamp <= interval \'1  year\' ) ORDER BY start_timestamp ASC', //TODO: cast $2 to 12am of the day

    	// Insertion
    	add_availability: 'INSERT INTO declares_availabilities (start_timestamp, end_timestamp, caretaker_username) VALUES($1,$2,$3)',

    	// Login
    	userpass: 'SELECT * FROM username_password WHERE username=$1',

    	// Update
    	update_availability: 'UPDATE declares_availability SET start_timestamp = $2, end_timestamp = $3 WHERE caretaker_username=$1',

    	//Deletion
    	delete_availability: 'DELETE FROM declares_availability WHERE start_timestamp = $1 AND end_timestamp = $2 AND caretaker_username = $4',

    	// Search
    	search_game: 'SELECT * FROM game_list WHERE lower(gamename) LIKE $1',
}

module.exports = sql