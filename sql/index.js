const sql = {}

sql.query = {
	add_owner: "CALL add_owner ($1, $3, $4, $2, $5, $6, $7, $8, $9);",
	add_pet : "CALL add_pet ($1, $2, $3, $4, $5, $6, $7);", 

	get_user : "SELECT * FROM Users WHERE username = $1;",
	get_pet : "SELECT * FROM ownsPets WHERE username = $1 AND name = $2", 

	list_pets : "SELECT * FROM ownsPets WHERE username = $1;", 
	list_cats  : "SELECT * FROM Categories;", 

	//edit information
	update_pass: "UPDATE Owners SET password = $2 WHERE username = $1;",
	update_info: "UPDATE Owners SET email = $2 WHERE username = $1;",
	update_pet : "UPDATE ownsPets SET cat_name = $3, size = $4, description = $5, sociability = $6, special_req = $7 WHERE username = $1 AND name = $2;", 

	//delete information
	del_owner : "DELETE FROM Owners WHERE username = $1;", 
	del_caretaker: "DELETE FROM Caretakers WHERE username = $1", 
	del_pet : "DELETE FROM ownsPets WHERE username = $1 AND name = $2;",

	// Information
	read_availabilities: 'SELECT start_timestamp AS start, end_timestamp AS end FROM declares_availabilities WHERE caretaker_username = $1', //TODO: cast $2 to 12am of the day
	read_monthly_availabilities: 'SELECT start_date, end_date FROM declares_availabilities WHERE caretaker_username = $1 AND  (start_timestamp >= $2 AND start_timestamp <= interval \'1  month\' ) ORDER BY start_timestamp ASC', //TODO: cast $2 to 12am of the day
	read_yearly_availabilities: 'SELECT start_date, end_date FROM declares_availabilities WHERE caretaker_username = $1 AND  (start_timestamp >= $2 AND start_timestamp <= interval \'1  year\' ) ORDER BY start_timestamp ASC', //TODO: cast $2 to 12am of the day

	// Insertion
	add_availability: 'INSERT INTO declares_availabilities (start_timestamp, end_timestamp, caretaker_username) VALUES($1::timestamp AT TIME ZONE \'UTC\',$2::timestamp AT TIME ZONE \'UTC\',$3)',

	// Update
	update_availability: 'UPDATE declares_availabilities SET start_timestamp = $1::timestamp AT TIME ZONE \'UTC\', end_timestamp = $2::timestamp AT TIME ZONE \'UTC\' WHERE start_timestamp = $3::timestamp AT TIME ZONE \'UTC\' AND caretaker_username = $4',

	//Deletion
	delete_availability: 'DELETE FROM declares_availabilities WHERE start_timestamp = $1::timestamp AT TIME ZONE \'UTC\' AND caretaker_username = $2',


}

module.exports = sql