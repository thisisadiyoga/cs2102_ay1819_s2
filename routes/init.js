const sql_query = require('../sql');
const postgres_details = require('../config')
const passport = require('passport');
const bcrypt = require('bcrypt');
const multer = require("multer");
const upload = multer({dest: "../uploads"});
const fs = require('fs');

// Postgre SQL Connection
const { Pool } = require('pg');
const { RSA_NO_PADDING } = require('constants');
const { allowedNodeEnvironmentFlags } = require('process');
const pool = new Pool({
	
	user: postgres_details.user,
	host: postgres_details.host,
	database: postgres_details.database,
	password: postgres_details.password,
	port: postgres_details.port,
	connectionString: process.env.DATABASE_URL,
	//ssl: true 
});

const round = 10;
const salt  = bcrypt.genSaltSync(round);

function initRouter(app) {
	/* GET */
	app.get('/'      , index );
	
	/* PROTECTED GET */
	app.get('/dashboard', passport.authMiddleware(), dashboard);
	app.get('/pets', passport.authMiddleware(), pets);
	app.get('/add_pets', passport.authMiddleware(), add_pets);

	/* admin pages*/
	app.get('/adminDashboard', passport.authMiddleware(), adminDashboard);
	app.post('/registerAdmin', passport.antiMiddleware(), reg_admin);
	app.get('/adminInformation', passport.authMiddleware(), adminInformation);
	app.get('/category', passport.authMiddleware(), category);
	app.post('/edit_cat', passport.authMiddleware(), edit_cat);
	app.post('/add_cat', passport.authMiddleware(), add_cat);

	/*Registration*/ 
	app.get('/register' , passport.antiMiddleware(), register );
	app.get('/password' , passport.antiMiddleware(), retrieve );

	/*Search*/
	app.get('/rating.js', search_caretaker);

	/* PROTECTED POST */
	app.post('/update_info', passport.authMiddleware(), update_info);
	app.post('/update_pass', passport.authMiddleware(), update_pass);
	app.post('/update_avatar', [passport.authMiddleware(), upload.single('avatar')], update_avatar);
	app.post('/pets', [passport.authMiddleware(), upload.single('img')], update_pet);

	app.post('/register', [passport.antiMiddleware(), upload.single('avatar')], reg_user);
	app.post('/del_user', del_user,);
	app.post('/add_pets', [passport.authMiddleware(), upload.single('img')], reg_pet);
	app.post('/edit_pet', passport.authMiddleware(), edit_pet);
	app.post('/del_pet', passport.authMiddleware(), del_pet);
	app.post('/display', passport.authMiddleware(), search_caretaker);
	app.post('/ctsignup', passport.authMiddleware(), ct_from_owner)

	/* LOGIN */
	app.post('/login', passport.authenticate('user', {
		successRedirect: '/dashboard',
		failureRedirect: '/'
	}));

	/* LOGIN */
	app.post('/loginAdmin', passport.authenticate('admin', {
		successRedirect: '/adminDashboard',
		failureRedirect: '/admin?login=failed'
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

	pool.query(sql_query.query.get_user, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			user = [];
		} else {
			user = data.rows[0];
		}
	basic(req, res, 'dashboard', { user : user, info_msg: msg(req, 'info', 'Email updated successfully', 'Error in updating information'), pass_msg: msg(req, 'pass', 'Password updated successfully', 'Error in updating password'), avatar_msg : msg(req, 'avatar', 'Profile Picture Updated', 'Error in updating picture'), join_msg : msg(req, 'join', 'Welcome to caretakers', 'Error in joining caretakers'), auth: true });
	});
}

function adminDashboard(req, res, next) {
	basic(req, res, 'adminDashboard', { 
		auth: true });
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

		basic(req, res, 'pets', { pet : pet, add_msg: msg(req, 'add', 'Pet added successfully', 'Error in adding pet'), edit_msg: msg(req, 'edit', 'Pet edited successfully', 'Error in editing pet'), del_msg: msg(req, 'del', 'Pet deleted successfully', 'Error in deleting pet'), auth: true });
	});
}

function adminInformation (req, res, next) {
	var allInformation;

	pool.query(sql_query.query.list_caretakers, (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			allInformation = [];
		} else {
			allInformation = data.rows;
		}
		console.log(allInformation);

	basic(req, res, 'adminInformation', { caretakers : allInformation, auth: true });
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

function ct_from_owner (req, res, next) {
	var is_full_time = req.body.is_full_time;

	pool.query(sql_query.query.add_caretaker, [req.user.username, is_full_time], (err, data) => {
		if(err) {
			console.error("Error in update info", err);
			res.redirect('/dashboard?join=fail');
		} else {
			res.redirect('/dashboard?join=pass');
		}
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

function update_avatar(req, res, next) {
	var username = req.user.username;
	var avatar = fs.readFileSync(req.file.path).toString('base64');
	pool.query(sql_query.query.update_avatar, [username, avatar], (err, data) => {
		if(err) {
			console.error("Error in update profile picture");
			res.redirect('/dashboard?avatar=fail');
		} else {
			res.redirect('/dashboard?avatar=pass');
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
			res.redirect('/pets?edit=fail');
		} else {
			if (typeof req.file !== 'undefined')
			{
				var img = fs.readFileSync(req.file.path).toString('base64');
				pool.query(sql_query.query.update_pet_pic, [username, name, img], (err, data) => {
					if (err) {
						console.error("Error in updating image");
						res.redirect('/pets?edit=fail');
					} else {
						res.redirect('/pets?edit=pass')
					}
				});
			} else 
			{
				res.redirect('/pets?edit=pass');
			}
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
				res.redirect('/pets?edit=fail');
			} else {
				pet = data.rows[0];
				basic(req, res, 'edit_pet', { cat_list : cat_list, pet : pet, add_msg: msg(req, 'edit', 'Pet edited successfully', 'Error in editing pet'), auth: true });
			}
		}
	)});
}

function del_pet (req, res, next) {
	console.log(req.body.name);
	pool.query(sql_query.query.del_pet, [req.user.username, req.body.name], (err, data) => {
		if(err) {
			console.error("Pet not found");
			res.redirect('/pets?del=fail');
		} else {
			res.redirect('/pets?del=pass');
		}
	});
}

function reg_user(req, res, next) {
	var username		= req.body.username;
	var first_name		= req.body.firstname;
	var last_name		= req.body.lastname;
	var password		= bcrypt.hashSync(req.body.password, salt);
	var email			= req.body.email;
	var dob				= req.body.dob;
	var credit_card_no	= req.body.credit_card_no;
	var unit_no			= req.body.unit_no;
	var postal_code 	= req.body.postal_code;
	var avatar			= fs.readFileSync(req.file.path).toString('base64');

	pool.query(sql_query.query.add_owner, [username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar], (err, data) => {
		if(err) {
			console.error("Error in adding user", err);
			res.redirect('/register?reg=fail');
		} else {
			req.login({
				username    : username,
				passwordHash: password,
				isUser: true
			}, function(err) {
				if(err) {
					return res.redirect('/register?reg=fail');
				} else {
					return res.redirect('/add_pets');
				}
			});
		}
	});
}

function category (req, res, next) {
	var category;

	pool.query(sql_query.query.list_cats, [], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			category = [];
		} else {
			category = data.rows;
		}

		basic(req, res, 'category', { category : category, add_msg: msg(req, 'add', 'Category added successfully', 'Error in adding category'), edit_msg: msg(req, 'edit', 'Category edited successfully', 'Error in editing category'), del_msg: msg(req, 'del', 'Category deleted successfully', 'Error in deleting category'), auth: true });
	});
}

function edit_cat(req, res, next) {
	var cat_name = req.body.cat_name;
	var base_price = req.body.base_price;

	pool.query(sql_query.query.update_cat, [cat_name, base_price], (err, data) => {
		if(err) {
			console.error("Category not found", err);
			res.redirect('/category?edit=fail');
		} else {
			res.redirect('/category?edit=pass');
		}
	});
}

function add_cat(req, res, next) {
	var cat_name = req.body.cat_name;
	var base_price = req.body.base_price;

	pool.query(sql_query.query.add_cat, [cat_name, base_price], (err, data) => {
		if (err) {
			console.error("Category add failed", err);
			res.redirect('/category?add=fail');
		} else {
			res.redirect('/category?add=pass');
		}
	});
}


function reg_admin(req, res, next) {
	// console.log(req.body);
	var admin_username  = req.body.admin_username;
	var admin_password  = bcrypt.hashSync(req.body.admin_password, salt);
	// var last_login_time = Date.now();
	var last_login_time = "2020-10-17 04:05:06";
	pool.query(sql_query.query.add_admin, [admin_username, admin_password, last_login_time], (err, data) => {
		if(err) {
			console.error("Error in adding admin", err);
			res.redirect('/admin?reg=fail');
		} else {
			req.login({
				admin_username: admin_username,
				passwordHash: admin_password,
				isUser: false

			}, function(err) {
				if(err) {
					console.log(err);
					return res.redirect('/admin?reg=fail');
				} else {
					return res.redirect('/adminDashboard');
				}
			});
		}
	});
}

function reg_pet(req, res, next) {
	var username		= req.user.username;
	var name			= req.body.name;
	var description		= req.body.description;
	var cat_name		= req.body.cat_name;
	var size			= req.body.size;
	var sociability		= req.body.sociability;
	var special_req		= req.body.special_req;
	var img				= fs.readFileSync(req.file.path).toString('base64');
	
	pool.query(sql_query.query.add_pet, [username, name, description, cat_name, size, sociability, special_req, img], (err, data) => {
		if(err) {
			console.error("Error in adding pet", err);
			res.redirect('/pets?add=fail');
		} else {
			res.redirect('/pets?add=pass');
		}
	});
}

function del_user (req, res, next) {
	var username = req.user.username;
	
	req.session.destroy()
	req.logout()

	pool.query(sql_query.query.del_owner, [username], (err, data) => {
		if(err) {
			console.error("Error in deleting account", err);
		} else {
			pool.query(sql_query.query.del_caretaker, [username], (err, data) => {
				if(err) {
					console.error("Error in deleting account", err);
				} else {
					console.log("User deleted");
					res.redirect('/?del=pass')
				}
			});
		}
	});
}

function search_caretaker (req, res, next) {
	var caretaker;
	pool.query(sql_query.query.search_caretaker, ["%" + req.body.name + "%"], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			caretaker = [];
		} else {
			caretaker = data.rows;
		}

		basic(req, res, 'display', { caretaker : caretaker, add_msg: msg(req, 'search', 'Match found', 'No match found'), auth: true });
	});
}



// LOGOUT
function logout(req, res, next) {
	req.session.destroy()
	req.logout()
	res.redirect('/')
}

module.exports = initRouter;







/*function search_nearby (req, res, next) {
	var username = req.user.username;
	var filter;
	var nearby;

	console.log(username);
	
	pool.query(sql_query.query.get_area, [username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			filter = [];
			console.error("postal code not found");
			res.redirect("/display");
		} else {
			filter = data.rows[0].postal_code

			pool.query(sql_query.query.find_nearby, [username, filter[0, 2] + "____"], (err, data) => {
				if(err) {
					console.error("Error in deleting account", err);
					res.redirect("/display?found=pass")
				} else if (!data.rows || data.rows.length == 0){
					console.info("No nearby caretaker found");
					nearby = []
					
					basic(req, res, 'display', { category : category, search_msg: msg(req, 'search', 'No nearby caretaker found', 'Error in searching caretaker'), auth: true });
				} else {
					console.log("Caretaker found");
					nearby = data.rows
					basic(req, res, 'display', { category : category, search_msg: msg(req, 'search', 'Caretakers found', 'Error in searching caretaker'), auth: true });
				}
			});
		}
	});
}*/