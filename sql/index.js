const sql = {}

sql.query = {
	
	insert_bid: 'SELECT insert_bid($1, $2, $3, $4, $5, $6, $7, $8)',

	choose_bids: 'SELECT choose_bids()',

	rate_or_review: 'SELECT rate_or_review($1, $2, $3, $4, $5, $6, $7)',

	set_transac_details: 'SELECT set_transac_details($1, $2, $3, $4, $5, $6, $7)',

	pay_bid: 'SELECT pay_bid($1, $2, $3, $4, $5)',

	search_reviews: 'SELECT review FROM Bids WHERE username = $1 AND review IS NOT NULL',

	search_avg_rating: 'SELECT AVG(rating) FROM Bids WHERE username = $1',

	search_past_orders: 'SELECT pet_name, p_start_date, p_end_date, username, rating, review, payment_method, mode_of_transfer, is_paid, total_price FROM Bids WHERE owner_username = $1 AND is_successful = true',

	search_petdays: 'SELECT SUM(duration) FROM (SELECT p_end_date - p_start_date + 1 AS duration FROM Bids WHERE username = $1 AND p_start_date >= $2 AND p_start_date <= $3 AND is_successful = true)',
}

module.exports = sql
