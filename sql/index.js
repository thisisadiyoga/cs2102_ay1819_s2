const sql = {}

sql.query = {
	add_owner: "CALL add_owner ($1, $3, $4, $2, $5, $6, $7, $8, $9, $10);",
	add_pet : "CALL add_pet ($1, $2, $3, $4, $5, $6, $7);", 

	get_user : "SELECT * FROM Users WHERE username = $1;",
	get_pet : "SELECT * FROM ownsPets WHERE username = $1 AND name = $2", 

	list_pets : "SELECT * FROM ownsPets WHERE username = $1;", 
	list_cats  : "SELECT * FROM Categories;", 
	search_caretaker : "SELECT username, first_name, last_name, postal_code, is_full_time, avg_rating, no_of_reviews FROM Caretakers WHERE username LIKE $1 OR first_name LIKE $1 OR last_name LIKE $1;", 

	//edit information
	update_pass: "UPDATE Owners SET password = $2 WHERE username = $1;",
	update_info: "UPDATE Owners SET email = $2 WHERE username = $1;",
	update_pet : "UPDATE ownsPets SET cat_name = $3, size = $4, description = $5, sociability = $6, special_req = $7 WHERE username = $1 AND name = $2;", 

	upload_userpic: "SELECT encode(profile_pic, 'base64') FROM Users where username = $1;", 

	//delete information
	del_owner : "DELETE FROM Owners WHERE username = $1;", 
	del_caretaker: "DELETE FROM Caretakers WHERE username = $1", 
	del_pet : "DELETE FROM ownsPets WHERE username = $1 AND name = $2;",
}

module.exports = sql