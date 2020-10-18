const sql_query = require('../sql');
const postgres_details = require('../config')
const passport = require('passport');
const bcrypt = require('bcrypt')
const postgres_details = require("../config.js");

// Postgre SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
	
	
	user: postgres_details.user,
	host: postgres_details.host,
	database: postgres_details.database,
	password: postgres_details.password,
	port: postgres_details.port,
	connectionString: process.env.DATABASE_URL,
	//ssl: true 
	user: postgres_details.user, 
	host: postgres_details.host,
	database: postgres_details.database, 
	password : postgres_details.password, 
	port : postgres_details.port,
});

const round = 10;
const salt  = bcrypt.genSaltSync(round);

function initRouter(app) {
	/* GET */
	app.get('/'      , index );
<<<<<<< HEAD
	app.get('/search', search);

=======
	
>>>>>>> master
	/* PROTECTED GET */
	app.get('/dashboard', passport.authMiddleware(), dashboard);
	app.get('/pets', passport.authMiddleware(), pets);
	app.get('/add_pets', passport.authMiddleware(), add_pets);

	app.get('/register' , passport.antiMiddleware(), register );
    app.get('/password' , passport.antiMiddleware(), retrieve );
	
	/* PROTECTED POST */
	app.post('/update_info', passport.authMiddleware(), update_info);
	app.post('/update_pass', passport.authMiddleware(), update_pass);
	app.post('/pets', passport.authMiddleware(), update_pet);
	
	app.post('/register'   , passport.antiMiddleware(), reg_user);
	app.post('/add_pets', passport.authMiddleware(), reg_pet);
	app.post('/edit_pet', passport.authMiddleware(), edit_pet);
	app.post('/del_pet', passport.authMiddleware(), del_pet);

	/* LOGIN */
	app.post('/login', passport.authenticate('local', {
		successRedirect: '/dashboard',
		failureRedirect: '/'
	}));
	
	/* LOGOUT */
	app.get('/logout', passport.authMiddleware(), logout);

	/*ADMIN*/
	app.get('/admin', admin);

}


// Render Function
function basic(req, res, page, other) {
	var info = {
		page: page,
		user: req.user.username,
	};
	if(other) {
		for(var fld in other) {
			info[fld] = other[fld];
		}
	}
	res.render(page, info);
}

function admin(req, res, next) {
	res.render('admin', { auth: false, page:'admin' });
}

function query(req, fld) {
	return req.query[fld] ? req.query[fld] : '';
}

function msg(req, fld, pass, fail) {
	var info = query(req, fld);
	return info ? (info=='pass' ? pass : fail) : '';
}

// GET
function index(req, res, next) {
    res.render('index', { page: 'index', auth: false });
}

function dashboard(req, res, next) {
	basic(req, res, 'dashboard', { info_msg: msg(req, 'info', 'Information updated successfully', 'Error in updating information'), pass_msg: msg(req, 'pass', 'Password updated successfully', 'Error in updating password'), auth: true });
}

function register(req, res, next) {
	res.render('register', { page: 'register', auth: false });
}
function retrieve(req, res, next) {
	res.render('retrieve', { page: 'retrieve', auth: false });
}

function pets (req, res, next) {
	var pet;

	pool.query(sql_query.query.list_pets, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			pet = [];
		} else {
			pet = data.rows;
		}

	basic(req, res, 'pets', { pet : pet, add_msg: msg(req, 'add', 'Pet added successfully', 'Error in adding pet'), auth: true });
	});
}

function add_pets(req, res, next) {
	var cat_list;
	pool.query(sql_query.query.list_cats, [], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			cat_list = [];
		} else {
			cat_list = data.rows;
		}

	basic(req, res, 'add_pets', { cat_list : cat_list, add_msg: msg(req, 'add', 'Pet added successfully', 'Error in adding pet'), auth: true });
	});
}

// POST 
function update_info(req, res, next) {
	var username  = req.user.username;
    var email = req.body.email;
	pool.query(sql_query.query.update_info, [username, email], (err, data) => {
		if(err) {
			console.error("Error in update info");
			res.redirect('/dashboard?info=fail');
		} else {
			res.redirect('/dashboard?info=pass');
		}
	});
}
function update_pass(req, res, next) {
	var username = req.user.username;
	var password = bcrypt.hashSync(req.body.password, salt);
	pool.query(sql_query.query.update_pass, [username, password], (err, data) => {
		if(err) {
			console.error("Error in update pass");
			res.redirect('/dashboard?pass=fail');
		} else {
			res.redirect('/dashboard?pass=pass');
		}
	});
}

function update_pet (req, res, next) {
	var username = req.user.username;
	var name = req.body.name;
	var cat_name = req.body.cat_name;
	var size = req.body.size;
	var description = req.body.description;
	var sociability = req.body.sociability;
	var special_req = req.body.special_req;

	pool.query(sql_query.query.update_pet, [username, name, cat_name, size, description, sociability, special_req], (err, data) => {
		if(err) {
			console.error("Error in updating pet");
			res.redirect('/pets?pass=fail');
		} else {
			res.redirect('/pets?pass=pass');
		}
	});
}

function edit_pet(req, res, next) {
	var cat_list;
	var pet;

	pool.query(sql_query.query.list_cats, [], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			cat_list = [];
		} else {
			cat_list = data.rows;
		}

		pool.query(sql_query.query.get_pet, [req.user.username, req.body.name], (err, data) => {
			if(err || !data.rows || data.rows.length == 0) {
				console.error("Pet not found");
				res.redirect('/pets');
			} else {
				pet = data.rows[0];
				basic(req, res, 'edit_pet', { cat_list : cat_list, pet : pet, add_msg: msg(req, 'edit', 'Pet edited successfully', 'Error in editing pet'), auth: true });
			}
		}
	)})
};

function del_pet (req, res, next) {
	console.log(req.body.name);
	pool.query(sql_query.query.del_pet, [req.user.username, req.body.name], (err, data) => {
		if(err) {
			console.error("Pet not found");
			res.redirect('/pets');
		} else {
			res.redirect('/pets');
		}
	});
}

function reg_user(req, res, next) {
	var username		= req.user.username;
	var firstname		= req.body.firstname;
	var lastname		= req.body.lastname;
	var password		= bcrypt.hashSync(req.body.password, salt);
	var email			= req.body.email;
	var dob				= req.body.dob;
	var credit_card_no	= req.body.credit_card_no;
	var unit_no			= req.body.unit_no;
	var postal_code 	= req.body.postal_code;
	pool.query(sql_query.query.add_owner, [username, password, firstname, lastname, email, dob, credit_card_no, unit_no, postal_code], (err, data) => {
		if(err) {
			console.error("Error in adding user", err);
			res.redirect('/register?reg=fail');
		} else {
			req.login({
				username    : username,
				passwordHash: password,
			}, function(err) {
				if(err) {
					return res.redirect('/register?reg=fail');
				} else {
					return res.redirect('/dashboard');
				}
			});
		}
	});
}

// function reg_admin(req, res, next) {
// 	var admin_username  = req.body.username;
// 	var password  = bcrypt.hashSync(req.body.password, salt);
// 	// var last_login_time = Date.now();
// 	var last_login_time = "2020-10-17 04:05:06";
// 	pool.query(sql_query.query.add_user, [username, password, last_login_time], (err, data) => {
// 		if(err) {
// 			console.error("Error in adding user", err);
// 			res.redirect('/admin?reg=fail');
// 		} else {
// 			req.login({
// 				username    : username,
// 				passwordHash: password,

// 			}, function(err) {
// 				if(err) {
// 					return res.redirect('/admin?reg=fail');
// 				} else {
// 					return res.redirect('/admin');
// 				}
// 			});
// 		}
// 	});
// }
function reg_pet(req, res, next) {
	var username		= req.user.username;
	var name			= req.body.name;
	var description		= req.body.description;
	var cat_name		= req.body.cat_name;
	var size			= req.body.size;
	var sociability		= req.body.sociability;
	var special_req		= req.body.special_req;
	
	pool.query(sql_query.query.add_pet, [username, name, description, cat_name, size, sociability, special_req], (err, data) => {
		if(err) {
			console.error("Error in adding pet", err);
			res.redirect('/pets?pet_reg=fail');
		} else {
			res.redirect('/pets?pet_reg=pass');
		}
	});
}


// LOGOUT
function logout(req, res, next) {
	req.session.destroy()
	req.logout()
	res.redirect('/')
}

module.exports = initRouter;