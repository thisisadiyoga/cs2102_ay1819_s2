const sql = {}

sql.query = {
	add_owner: "CALL add_owner ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);",
	add_pet : "INSERT INTO ownsPets VALUES ($1, $2, $3, $4, $5, $6, $7, $8);", 
	add_cat : "INSERT INTO Categories VALUES ($1, $2);", 
	add_admin : "INSERT INTO Administrators VALUES ($1, $2);", 
	//BIDS
	//Information
	read_all_bids: 'SELECT bid_start_timestamp AS start, bid_end_timestamp AS end, \'Caretaker: \' || caretaker_username AS title, total_price, rating, review, is_paid, is_successful, caretaker_username, pet_name, avail_start_timestamp, avail_end_timestamp, type_of_service, mode_of_transfer FROM bids WHERE owner_username = $1', //TODO: cast $2 to 12am of the day
	read_successful_bids: 'SELECT bid_start_timestamp AS start, bid_end_timestamp AS end, \'Pet Owner: \' || owner_username AS title, total_price, rating, review, is_paid, is_successful, pet_name, avail_start_timestamp, avail_end_timestamp, type_of_service, mode_of_transfer FROM bids WHERE caretaker_username = $1', //TODO: cast $2 to 12am of the day

    //Deletion
    delete_bid: 'DELETE FROM bids WHERE bid_start_timestamp = $1::timestamp AT TIME ZONE \'UTC\' AND avail_start_timestamp = $2::timestamp AT TIME ZONE \'UTC\' AND caretaker_username = $3 AND pet_name = $4',
    // Update
   update_bids: 'UPDATE bids SET bid_start_timestamp = $7::timestamp AT TIME ZONE \'UTC\', bid_end_timestamp = $8::timestamp AT TIME ZONE \'UTC\', avail_start_timestamp = $9::timestamp AT TIME ZONE \'UTC\', avail_end_timestamp = $10::timestamp AT TIME ZONE \'UTC\', caretaker_username = $11, pet_name = $12, type_of_service = $13 WHERE bid_start_timestamp = $1::timestamp AT TIME ZONE \'UTC\' AND avail_start_timestamp = $2::timestamp AT TIME ZONE \'UTC\' AND caretaker_username = $4 AND owner_username = $5 AND pet_name = $6',


	add_caretaker : "INSERT INTO Caretakers VALUES ($1, $2);", 
	add_ct : "CALL add_ct ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);",

	insert_bids: 'CALL insert_bids($1, $2, $3::timestamp AT TIME ZONE \'UTC\', $4::timestamp AT TIME ZONE \'UTC\', $5, $6);',
	
	view_bids: 'SELECT * FROM Bids WHERE is_successful;',
	ctview_bids: 'SELECT * FROM Bids WHERE caretaker_username = $1',
	rate_review: 'UPDATE Bids SET rating = $1, review = $2 WHERE owner_username = $3 AND pet_name = $4 AND bid_start_timestamp = $5 AND bid_end_timestamp = $6 AND caretaker_username = $7',
	rate_review_updatect: 'UPDATE Caretakers SET avg_rating = ((avg_rating*no_of_reviews)+$1)/(no_of_reviews+1) , no_of_reviews = no_of_reviews + 1 WHERE username = $2;',
	choose_bids: 'UPDATE Bids SET is_successful = (CASE WHEN random() < 0.5 THEN true ELSE false END) WHERE is_successful IS NULL;',
	set_transac_details: 'UPDATE Bids SET payment_method = $1, mode_of_transfer = $2, is_paid = true WHERE owner_username = $3 AND pet_name = $4 AND caretaker_username = $5 AND bid_start_timestamp = $6 AND bid_end_timestamp = $7',
    pay_bid: 'UPDATE Bids SET is_paid = true WHERE owner_username = $1 AND pet_name = $2 AND caretaker_username = $3 AND bid_start_timestamp = $4 AND bid_end_timestamp = $5',
    search_reviews: 'SELECT review FROM Bids WHERE caretaker_username = $1 AND review IS NOT NULL',
	search_avg_rating: 'SELECT AVG(rating) FROM Bids WHERE caretaker_username = $1',
	search_past_orders: 'SELECT pet_name, bid_start_timestamp, bid_end_timestamp, caretaker_username, rating, review, payment_method, mode_of_transfer, is_paid, total_price FROM Bids WHERE owner_username = $1 AND is_successful = true',
	search_petdays: 'SELECT SUM(duration) FROM (SELECT EXTRACT(DAY FROM AGE(bid_start_timestamp, bid_end_timestamp)) + 1 AS duration FROM Bids WHERE caretaker_username = $1 AND bid_start_timestamp >= $2 AND bid_start_timestamp <= $3 AND is_successful = true)',
	insert_charges: 'INSERT INTO Charges VALUES ($1, $2, $3);',
	update_charges: 'UPDATE Charges SET daily_price = $1 WHERE caretaker_username = $3 AND cat_name = $2',
	view_charges: 'SELECT * FROM Charges WHERE caretaker_username = $1',

	get_user_old : "SELECT * FROM Users WHERE username = $1;",
	get_user : "SELECT username, password, avatar, is_owner, is_caretaker, (SELECT is_full_time FROM Caretakers WHERE username = $1) FROM Users WHERE username = $1;",
	get_pet : "SELECT * FROM ownsPets WHERE username = $1 AND name = $2;", 
	get_admin: "SELECT * FROM Administrators WHERE admin_username = $1;",
	get_caretaker : "SELECT * FROM Caretakers WHERE username = $1 AND NOT is_disabled;", 
	get_location : "SELECT postal_code FROM Users WHERE username = $1;", 

	list_users: "SELECT * FROM Users;", 
	list_pets : "SELECT * FROM ownsPets WHERE username = $1;", 
	list_cats  : "SELECT * FROM Categories;", 
	list_caretakers: "SELECT username, first_name, last_name, is_full_time, avg_rating, no_of_pets_taken FROM caretakers NATURAL JOIN Uers WHERE NOT is_disabled;",
	search_caretaker : "SELECT username, first_name, last_name, postal_code, is_full_time, avg_rating, no_of_reviews, avatar FROM Caretakers NATURAL JOIN Users WHERE username <> $1 AND (username LIKE $2 OR first_name LIKE $2 OR last_name LIKE $2);", 

	filter_location:"SELECT * FROM Users WHERE postal_code LIKE $2 AND username <> $1;", 

	//edit information
	update_pass: "UPDATE Users SET password = $2 WHERE username = $1;",
	update_info: "UPDATE Users SET email = $2 WHERE username = $1;",
	update_avatar: "UPDATE Users SET avatar = $2 WHERE username = $1;", 
	update_pet : "UPDATE ownsPets SET cat_name = $3, size = $4, description = $5, sociability = $6, special_req = $7 WHERE username = $1 AND name = $2;", 
	update_pet_pic : "UPDATE ownsPets SET img = $3 WHERE username = $1 AND name = $2;",
	update_cat : "UPDATE Categories SET base_price = $2 WHERE cat_name = $1;", 

	upload_userpic: "SELECT encode(profile_pic, 'base64') FROM Users where username = $1;", 

	//summary information 
	get_all_pets_in_month: "SELECT extract(year from bid_start_timestamp) as year, to_char(bid_start_timestamp,'Mon') as month, count(pet_name) as count_of_pets FROM Bids WHERE is_successful AND bid_start_timestamp>= '2020-01-01' GROUP BY year, month; ",
	get_caretaker_salary_every_month: "SELECT extract(year from B2.bid_start_timestamp) as year, extract (month from B2.bid_start_timestamp) as month, B2.caretaker_username, SUM(DATE_PART('day', b2.bid_end_timestamp - b2.bid_start_timestamp)) as pet_days,	CASE WHEN c.is_full_time AND SUM(DATE_PART('day', b2.bid_end_timestamp - b2.bid_start_timestamp)) > 60 THEN 3000 + SUM (total_price)*0.8 WHEN c.is_full_time AND SUM(DATE_PART('day', b2.bid_end_timestamp - b2.bid_start_timestamp)) <= 60 THEN 3000 ELSE SUM (total_price)* 0.75 END AS salary FROM bids B2 INNER JOIN caretakers C on C.username = B2.caretaker_username WHERE B2.is_successful GROUP BY year, month, c.is_full_time, caretaker_username ORDER BY year DESC, month DESC, caretaker_username ASC;",
  
	// underperforming: caretakers with less than 2 distinct pets
	get_all_underperforming_caretakers: "",
	get_number_of_jobs_every_month: " SELECT extract(year from bid_start_timestamp) as year, to_char(bid_start_timestamp,'Mon') as month, count(*) as count_of_jobs FROM Bids WHERE is_successful GROUP BY year, month;",

	//delete information
	del_user : "DELETE FROM Users WHERE username = $1;", 
	del_owner : "DELETE FROM Owners WHERE username = $1;", 
	del_caretaker: "DELETE FROM Caretakers WHERE username = $1;", 
	del_pet : "DELETE FROM ownsPets WHERE username = $1 AND name = $2;",
	del_admin : "DELETE FROM Administrators WHERE admin_username = $1;",	

	get_all_caretaker_salaries: " SELECT 	extract(year from bid_start_timestamp) as year,	extract(month from bid_start_timestamp) as month, B1.caretaker_username, total_price * 0.75 as salary FROM bids B1 WHERE EXISTS (SELECT 1 From Caretakers c WHERE c.username = B1.caretaker_username AND NOT c.is_full_time) AND is_successful AND bid_start_timestamp>= '2020-01-01' AND bid_start_timestamp <= '2050-12-31' UNION	SELECT 	extract(year from B2.bid_start_timestamp) as year, extract (month from B2.bid_start_timestamp) as month, B2.caretaker_username, 3000 as salary FROM bids B2 WHERE EXISTS (SELECT 1 From Caretakers c WHERE c.username = B2.caretaker_username AND c.is_full_time) AND B2.is_successful GROUP BY year, month, caretaker_username ORDER BY year DESC, month DESC, caretaker_username ASC;",

	//AVAILABILITIES
	// Information
	read_availabilities: 'SELECT start_timestamp AS start, end_timestamp AS end FROM declares_availabilities WHERE caretaker_username = $1', //TODO: cast $2 to 12am of the day
	// Insertion
	add_availability: 'INSERT INTO declares_availabilities (start_timestamp, end_timestamp, caretaker_username) VALUES($1::timestamp AT TIME ZONE \'UTC\',$2::timestamp AT TIME ZONE \'UTC\',$3)',

	// Update
	update_availability: 'UPDATE declares_availabilities SET start_timestamp = $1::timestamp AT TIME ZONE \'UTC\', end_timestamp = $2::timestamp AT TIME ZONE \'UTC\' WHERE start_timestamp = $3::timestamp AT TIME ZONE \'UTC\' AND caretaker_username = $4',

	//Deletion
	delete_availability: 'CALL delete_availability($2,  $1::timestamp AT TIME ZONE \'UTC\' )',

	//Take leave
	take_leave: 'CALL take_leave($1::timestamp AT TIME ZONE \'UTC\', $2::timestamp AT TIME ZONE \'UTC\', $3)',


	get_area : "SELECT postal_code FROM Users WHERE username = $1;", 
	find_nearby : "SELECT * FROM Caretakers WHERE NOT is_disabled AND username IN (SELECT username FROM Users WHERE postal_code LIKE $2; AND username <> $1);",  //where string is extract of first 2 digits of postal code + filter [00]____
}

module.exports = sql
