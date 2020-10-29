const sql = {}

sql.query = {
	add_owner: "CALL add_owner ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);",
	add_pet : "INSERT INTO ownsPets VALUES ($1, $2, $3, $4, $5, $6, $7, $8);", 
	add_cat : "INSERT INTO Categories VALUES ($1, $2);", 
	add_admin : "INSERT INTO Administrators VALUES ($1, $2, $3);", 
	add_caretaker : "INSERT INTO Caretakers VALUES ($1, $2);", 

	view_bids: 'SELECT * FROM Bids WHERE owner_username = $1',
	rate_review: 'UPDATE Bids SET rating = $1, review = $2 WHERE owner_username = $3 AND pet_name = $4 AND p_start_date = $5 AND p_end_date = $6 AND caretaker_username = $7',
	insert_bid: 'CALL insert_bid($1, $2, $3, $4, $5, $6, $7, $8)',
	choose_bids: 'UPDATE Bids SET is_successful = (CASE WHEN random() < 0.5 THEN true ELSE false END) WHERE is_successful IS NULL;',
	set_transac_details: 'UPDATE Bids SET payment_method = $1, mode_of_transfer = $2 WHERE owner_username = $3 AND pet_name = $4 AND caretaker_username = $5 AND p_start_date = $6 AND p_end_date = $7',
	pay_bid: 'UPDATE Bids SET is_paid = true WHERE owner_username = $1 AND pet_name = $2 AND caretaker_username = $3 AND p_start_date = $4 AND p_end_date = $5',
	search_reviews: 'SELECT review FROM Bids WHERE caretaker_username = $1 AND review IS NOT NULL',
	search_avg_rating: 'SELECT AVG(rating) FROM Bids WHERE caretaker_username = $1',
	search_past_orders: 'SELECT pet_name, p_start_date, p_end_date, caretaker_username, rating, review, payment_method, mode_of_transfer, is_paid, total_price FROM Bids WHERE owner_username = $1 AND is_successful = true',
	search_petdays: 'SELECT SUM(duration) FROM (SELECT EXTRACT(DAY FROM AGE(p_end_date, p_start_date)) + 1 AS duration FROM Bids WHERE caretaker_username = $1 AND p_start_date >= $2 AND p_start_date <= $3 AND is_successful = true)',

	get_user : "SELECT * FROM Users WHERE username = $1;",
	get_pet : "SELECT * FROM ownsPets WHERE username = $1 AND name = $2;", 
	get_admin: "SELECT * FROM Administrators WHERE admin_id = $1;",
	get_caretaker : "SELECT * FROM Caretakers WHERE username = $1 AND NOT is_disabled;", 

	list_pets : "SELECT * FROM ownsPets WHERE username = $1;", 
	list_cats  : "SELECT * FROM Categories;", 
	list_caretakers: "SELECT username, first_name, last_name, is_full_time, avg_rating, no_of_pets_taken FROM caretakers NATURAL JOIN Users WHERE NOT is_disabled;",
	search_caretaker : "SELECT username, first_name, last_name, postal_code, is_full_time, avg_rating, no_of_reviews, avatar FROM Caretakers NATURAL JOIN Users WHERE username LIKE $1 OR first_name LIKE $1 OR last_name LIKE $1;", 

	//edit information
	update_pass: "UPDATE Users SET password = $2 WHERE username = $1;",
	update_info: "UPDATE Users SET email = $2 WHERE username = $1;",
	update_avatar: "UPDATE Users SET avatar = $2 WHERE username = $1;", 
	update_pet : "UPDATE ownsPets SET cat_name = $3, size = $4, description = $5, sociability = $6, special_req = $7 WHERE username = $1 AND name = $2;", 
	update_pet_pic : "UPDATE ownsPets SET img = $3 WHERE username = $1 AND name = $2;",
	update_cat : "UPDATE Categories SET base_price = $2 WHERE cat_name = $1;", 

	upload_userpic: "SELECT encode(profile_pic, 'base64') FROM Users where username = $1;", 

	//delete information
	del_user : "DELETE FROM Users WHERE username = $1", 
	del_owner : "DELETE FROM Owners WHERE username = $1;", 
	del_caretaker: "DELETE FROM Caretakers WHERE username = $1;", 
	del_pet : "DELETE FROM ownsPets WHERE username = $1 AND name = $2;",
	del_admin : "DELETE FROM Administrators WHERE admin_id = $1;", 

	get_area : "SELECT postal_code FROM Users WHERE username = $1;", 
	find_nearby : "SELECT * FROM Caretakers WHERE NOT is_disabled AND username IN (SELECT username FROM Users WHERE postal_code LIKE $2; AND username <> $1",  //where string is extract of first 2 digits of postal code + filter [00]____
}

module.exports = sql
