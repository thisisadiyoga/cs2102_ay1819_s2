
const sql_query = require('../sql');
const postgres_details = require('../config')
const passport = require('passport');
const bcrypt = require('bcrypt');
const multer = require("multer");
const upload = multer({dest: "../uploads"});
const fs = require('fs');
const flash = require('connect-flash');


// Postgre SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
	// ssl: true
	user: postgres_details.user,
    database: postgres_details.database,
    host: postgres_details.host,
    port: postgres_details.port,
    password: postgres_details.password,
      idleTimeoutMillis: 2000
});

const round = 10;
const salt  = bcrypt.genSaltSync(round);


function initRouter(app) {
	/* GET */
	app.get('/', index );

	/* PROTECTED GET */
	app.get('/dashboard', passport.authMiddleware(), dashboard);
	app.get('/pets', passport.authMiddleware(), pets);
	app.get('/add_pets', passport.authMiddleware(), add_pets);
	app.get('/caretaker' , passport.authMiddleware(), caretaker );
	app.get('/ctreviews' , passport.authMiddleware(), ctview_bids );
	app.get('/dailyprice' , passport.authMiddleware(), dailyprice );
	app.get('/edit_dailyprice' , passport.authMiddleware(), edit_dailyprice );

    app.get('/caretaker_calendar'   , passport.authMiddleware(), caretaker_calendar);
    app.get('/full_time_caretaker_calendar'   , passport.authMiddleware(), full_time_caretaker_calendar);
    app.get('/owner_calendar'   , passport.authMiddleware(), owner_calendar);

	/* admin pages*/
	app.get('/adminDashboard', passport.authMiddleware(), adminDashboard);
	app.post('/registerAdmin', passport.antiMiddleware(), reg_admin);
	app.get('/adminInformation', passport.authMiddleware(), adminInformation);
	app.get('/category', passport.authMiddleware(), category);
	app.post('/edit_cat', passport.authMiddleware(), edit_cat);
	app.post('/add_cat', passport.authMiddleware(), add_cat);
	app.post('/del_admin', del_admin);
	app.get('/adminStatistics', passport.authMiddleware(), adminStatistics)

	/*Registration*/
	app.get('/register' , passport.antiMiddleware(), register );
	app.get('/password' , passport.antiMiddleware(), retrieve );
	app.get('/ctregister' , passport.antiMiddleware(), ctregister );

	/*Search*/
	app.get('/rating.js', search_caretaker);
	app.get('/location', passport.authMiddleware(), location);

	/* PROTECTED POST */
	app.post('/update_info', passport.authMiddleware(), update_info);
	app.post('/update_pass', passport.authMiddleware(), update_pass);
	app.post('/update_avatar', [passport.authMiddleware(), upload.single('avatar')], update_avatar);
	app.post('/pets', [passport.authMiddleware(), upload.single('img')], update_pet);

	app.post('/register', [passport.antiMiddleware(), upload.single('avatar')], reg_user);
	app.post('/del_user', del_user);
	app.post('/add_pets', [passport.authMiddleware(), upload.single('img')], reg_pet);
	app.post('/edit_pet', passport.authMiddleware(), edit_pet);
	app.post('/del_pet', passport.authMiddleware(), del_pet);
	app.post('/display', passport.authMiddleware(), search_caretaker);
	app.post('/ctsignup', passport.authMiddleware(), ct_from_owner);
    app.post('/update_availability', passport.authMiddleware(), update_availability);
    app.post('/add_availability'   , passport.authMiddleware(), add_availability);
	app.post('/delete_availability' , passport.authMiddleware(), delete_availability);
	app.post('/take_leave' , passport.authMiddleware(), take_leave);
	app.post('/displayreview' , passport.authMiddleware(), displayreview);

	/*BIDS*/
	app.get('/rate_review', passport.authMiddleware(), rate_review_form);
	app.post('/ctregister', [passport.antiMiddleware(), upload.single('avatar')], reg_ct);
	app.post('/dailyprice', passport.authMiddleware(), set_dailyprice);
	app.post('/edit_dailyprice' , passport.authMiddleware(), change_dailyprice);

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

	/*BIDS*/
	app.get('/viewbids', passport.authMiddleware(), viewbids);
	app.post('/rate_review', passport.authMiddleware(), rate_review);
	app.get('/rate_review_form', passport.authMiddleware(), rate_review_form);
	app.get('/insert_transac', passport.authMiddleware(), view_transac);
	app.post('/insert_transac', passport.authMiddleware(), insert_transac);
	app.get('/newbid', passport.authMiddleware(), newbid);
	app.post('/insert_bid', passport.authMiddleware(), insert_bid);

	app.post('/delete_bid', passport.authMiddleware(), delete_bid);

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
		avatar : req.user.avatar,
		is_owner : req.user.is_owner,
		is_caretaker : req.user.is_caretaker,
        is_full_time: req.user.is_full_time == null? false: req.user.is_full_time
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
	if (typeof req.user == 'undefined') {
		res.render('index', {page: 'index', auth: false });
	} else {
		basic(req, res, 'index', { auth: true });
	}
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

function adminInformation(req, res, next) {
	basic(req, res, 'adminInformation', {
		auth: true
	});
}

function register(req, res, next) {
	res.render('register', { page: 'register', auth: false });
}

function retrieve(req, res, next) {
	res.render('retrieve', { page: 'retrieve', auth: false });
}

function ctregister(req, res, next) {
	res.render('ctregister', { page: 'ctregister', auth: false });
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

function dailyprice(req, res, next) {
	var cat_list;
	pool.query(sql_query.query.list_cats, [], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
		    console.log('Error adding pet: ', err);
			cat_list = [];
		} else {
			cat_list = data.rows;
		}

		basic(req, res, 'dailyprice', { cat_list : cat_list, add_msg: msg(req, 'add', 'Pet added successfully', 'Error in adding pet'), auth: true });
	});
}

function edit_dailyprice(req, res, next) {
	var dailyprice;
	pool.query(sql_query.query.view_charges, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
		    console.log('Error adding charges: ', err);
			dailyprice = [];
		} else {
			dailyprice = data.rows;
		}

		basic(req, res, 'edit_dailyprice', { dailyprice : dailyprice, add_msg: msg(req, 'add', 'Charges added successfully', 'Error in adding charges'), auth: true });
	});
}

function change_dailyprice (req, res, next) {
	var username = req.user.username;
	var daily_price = req.body.daily_price;
	var cat_name = req.body.cat_name;

	pool.query(sql_query.query.update_charges, [daily_price, cat_name, username], (err, data) => {
		if(err) {
			console.error("Error in updating daily price");
			res.redirect('/edit_dailyprice?edit=fail');
		} else {
			res.redirect('/edit_dailyprice?edit=pass');
		}
	});
}

function adminStatistics (req, res, next) {
	var allInformation;

	pool.query(sql_query.query.list_caretakers, (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			allCaretakers = [];
		} else {
			allCaretakers = data.rows;
		}
		pool.query(sql_query.query.get_all_pets_in_month, (err,data) => {
			if(err || !data.rows || data.rows.length == 0) {
				allPets = [];
			} else {
				allPets = data.rows;
			}

			pool.query(sql_query.query.get_number_of_jobs_every_month, (err,data) => {
				if(err || !data.rows || data.rows.length == 0) {
					allJobs = [];
				} else {
					allJobs = data.rows;
				}

				pool.query(sql_query.query.get_all_caretaker_salaries, (err,data) => {
					if(err || !data.rows || data.rows.length == 0) {
						allSalary = [];
					} else {
						allSalary = data.rows;
					}

					pool.query(sql_query.query.get_all_underperforming_caretakers, (err,data) => {
						if(err || !data.rows || data.rows.length == 0) {
							allUnderperforming = [];
						} else {
							allUnderperforming = data.rows;
						}

						basic(req, res, 'adminStatistics', { caretakers : allCaretakers,
							allPets: allPets,
							allJobs: allJobs,
							allSalary: allSalary,
							allUnderperforming: allUnderperforming,
							auth: true });
					})
				})
			})
		})

	});
}

function add_pets(req, res, next) {
	var cat_list;
	pool.query(sql_query.query.list_cats, [], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
		    console.log('Error adding pet: ', err);
			cat_list = [];
		} else {
			cat_list = data.rows;
		}

		basic(req, res, 'add_pets', { cat_list : cat_list, add_msg: msg(req, 'add', 'Pet added successfully', 'Error in adding pet'), auth: true });
	});
}

function location (req, res, next) {
	var user_list;
	var location;

	pool.query(sql_query.query.get_location, [req.user.username], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			console.error('User postal_code not found', err);
			res.redirect('/dashboard');
		} else {
			location = data.rows[0].postal_code;

			pool.query(sql_query.query.filter_location, [req.user.username, location.substr(0, 2) + "____"], (err, data) => {
				if (err || !data.rows || data.rows.length == 0) {
					console.error('No entries found');
					user_list = [];
				} else {
					user_list = data.rows;

				}
				basic(req, res, 'location', {user_list : user_list, auth: true});
			})
		}
	});
}

function owner_calendar(req, res, next) {
   console.log('In owner calendar method');
    var bids;
    var error_message, success_message;


    pool.query(sql_query.query.read_all_bids,[req.user.username], (err, data) => { //TODO req.user.username
            if(err || !data.rows || data.rows.length == 0) {
                        bids = [];
                        console.log('Error reading bids: ' + err);
            } else {
                        bids = data.rows;
            }
                      error_message = req.flash('error');
                      success_message = req.flash('success');
            basic(req, res, 'owner_calendar', { bids: bids, error_message: error_message, success_message: success_message, bids_msg: msg(req, 'add', 'Bids displayed successfully', 'Error in displaying all bids'), auth: true });

        });
}

function caretaker_calendar(req, res, next) {
    var availabilities, bids;
    var error_message, success_message;


    pool.query(sql_query.query.read_availabilities,[req.user.username], (err, data) => { //TODO req.user.username
            if(err || !data.rows || data.rows.length == 0) {
                        availabilities = [];
                        console.log('Error reading availabilities: ' + err);
            } else {
                        availabilities = data.rows;
                    }


    pool.query(sql_query.query.read_successful_bids, [req.user.username], (err, data) => {
           if(err || !data.rows || data.rows.length == 0) {
                          bids = [];
                           console.log('Error reading bids: ' + err);
          } else {
                    bids = data.rows;

          }
                    console.log('Bids read is  ' + bids);
                      error_message = req.flash('error');
                      success_message = req.flash('success');

            basic(req, res, 'caretaker_calendar', { bids: bids, availabilities: availabilities, error_message: error_message, success_message: success_message, availability_msg: msg(req, 'add', 'Availability period added successfully', 'Invalid parameters in availability period'), auth: true });
        })
        });
}

function full_time_caretaker_calendar(req, res, next) {
    var availabilities, bids;
    var error_message, success_message;


    pool.query(sql_query.query.read_availabilities,[req.user.username], (err, data) => { //TODO req.user.username
            if(err || !data.rows || data.rows.length == 0) {
                        availabilities = [];
                        console.log('Error reading availabilities: ' + err);
            } else {
                        availabilities = data.rows;
                    }


    pool.query(sql_query.query.read_successful_bids, [req.user.username], (err, data) => {
           if(err || !data.rows || data.rows.length == 0) {
                          bids = [];
                           console.log('Error reading bids: ' + err);
          } else {
                    bids = data.rows;
                    console.log('Bids is ' + bids);
          }

                      error_message = req.flash('error');
                      success_message = req.flash('success');

            basic(req, res, 'full_time_caretaker_calendar', { bids: bids, availabilities: availabilities, error_message: error_message, success_message: success_message, availability_msg: msg(req, 'add', 'Availability period added successfully', 'Invalid parameters in availability period'), auth: true });
        })
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
			res.redirect('/?reg=fail');
		} else {
		console.error("Successfully added owner");
			req.login({
				username    : username,
				passwordHash: password,
				isUser: true
			}, function(err) {
				if(err) {
					res.redirect('/?reg=fail');
				} else {
					res.redirect('/add_pets');
				}
			});
		}
	});
}

function reg_ct(req, res, next) {
	var username  = req.body.username;
	var first_name  = req.body.firstname;
	var last_name  = req.body.lastname;
	var password  = bcrypt.hashSync(req.body.password, salt);
	var email   = req.body.email;
	var dob    = req.body.dob;
	var credit_card_no = req.body.credit_card_no;
	var unit_no   = req.body.unit_no;
	var postal_code  = req.body.postal_code;
	var avatar   = fs.readFileSync(req.file.path).toString('base64');
	var is_full_time  = req.body.is_full_time;

	console.log(username, is_full_time);

	pool.query(sql_query.query.add_ct, [username, first_name, last_name, password, email, dob, credit_card_no, unit_no, postal_code, avatar, is_full_time], (err, data) => {
	 if(err) {
		console.error("Error in adding caretaker", err);
		return res.redirect('/');
	 } else {
		req.login({
			username    : username,
			passwordHash: password,
			isUser: true
		   }, function(err) {
			if(err) {
			 res.redirect('/register?reg=fail');
			} else {
				return res.redirect('/dashboard');
			}
		});
	}
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
	pool.query(sql_query.query.add_admin, [admin_username, admin_password], (err, data) => {
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

function set_dailyprice(req, res, next) {
	var cat_name = req.body.cat_name;
	var caretaker_username = req.user.username;
	var daily_price = req.body.daily_price;

	pool.query(sql_query.query.insert_charges, [daily_price, cat_name, caretaker_username], (err, data) => {
		if(err) {
			console.error("Unable to insert daily price", err);
			res.redirect('/dailyprice?add=fail');
		} else {
			res.redirect('/dailyprice?add=pass');
		}
	});
}

function del_user (req, res, next) {
	var username = req.user.username;

	req.session.destroy()
	req.logout()

	pool.query(sql_query.query.del_user, [username], (err, data) => {
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

function del_admin (req, res, next) {
	var admin_username = req.user.admin_username;

	req.session.destroy()
	req.logout()

	pool.query(sql_query.query.del_admin, [admin_username], (err, data) => {
		if(err) {
			console.error("Error in deleting admin account", err);
		} else {
			console.log("Admin deleted");
			res.redirect('/?del=pass')
		}
	});
}

// POST
function update_availability(req, res, next) {
    var old_start_timestamp = req.body.old_start_timestamp;
    var old_end_timestamp = req.body.old_end_timestamp;
    var start_timestamp = req.body.start_timestamp;
    var end_timestamp  = req.body.end_timestamp;

    pool.query(sql_query.query.update_availability, [start_timestamp, end_timestamp, old_start_timestamp, req.user.username], (err, data) => { //TODO: username
        if(err) {
              req.flash('error', 'The period cannot be updated. Check that there are no scheduled pet-care jobs that are outside of the new period.');

             res.redirect('/caretaker_calendar?update=fail');
        } else {
              req.flash('success', 'The period is successfully updated.');
             res.redirect('/caretaker_calendar?update=pass');
        }
    });
}

function add_availability(req, res, next) {

    var start_timestamp = req.body.start_timestamp ;
    var end_timestamp = req.body.end_timestamp;



    pool.query(sql_query.query.add_availability, [start_timestamp, end_timestamp, req.user.username], (err, data) => {
        if(err) {

               req.flash('error', 'The new period cannot be added.');
                res.redirect('/caretaker_calendar?add=fail');

        } else {
            req.flash('success', 'The period is successfully added. It may merge with existing availability schedule.');
             res.redirect('/caretaker_calendar?add=pass');
        }
    });
}

function delete_availability(req, res, next) {
    var start_timestamp = req.body.old_start_timestamp;
    var end_timestamp = req.body.old_end_timestamp;

    pool.query(sql_query.query.delete_availability, [start_timestamp, req.user.username], (err, data) => {
        if(err) {

        console.log("Error deleting availability: " + err);

            req.flash('error', 'The period cannot be deleted as there is a scheduled pet-care job within that period.');

             res.redirect('/caretaker_calendar?delete=fail');


        } else {
        req.flash('success', 'The period is successfully deleted.');
             res.redirect('/caretaker_calendar?delete=pass');
        }
    });
}

function take_leave(req, res, next) {
    var leave_start_timestamp = req.body.leave_start_timestamp;
    var leave_end_timestamp = req.body.leave_end_timestamp;

    pool.query(sql_query.query.take_leave, [leave_start_timestamp, leave_end_timestamp, req.user.username], (err, data) => { //TODO: username
        if(err) {
              req.flash('error', 'Leave cannot be applied. You must work at least 2 X 150 consecutive days per year. Also, Check that there are no scheduled pet-care jobs within the leave period.');
              console.log("Cannot apply leave. " + err);

             res.redirect('/full_time_caretaker_calendar?update=fail');
        } else {
              req.flash('success', 'Leave is successfully applied.');
             res.redirect('/full_time_caretaker_calendar?update=pass');
        }
    });
}

function search_caretaker (req, res, next) {
	var caretaker;
	pool.query(sql_query.query.search_caretaker, [req.user.username, "%" + req.body.name + "%"], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			caretaker = [];
		} else {
			caretaker = data.rows;
		}
		basic(req, res, 'display', { caretaker : caretaker, add_msg: msg(req, 'search', 'Match found', 'No match found'), auth: true });
	});
}

function caretaker (req, res, next) {
	var caretaker;
	var pet_days = [];
	var firstday = "2020-11-01 00:00:01";
	var lastday = "2020-11-30 23:59:59";

	pool.query(sql_query.query.get_caretaker, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			caretaker = [];
		} else {
			caretaker = data.rows;
			
			pool.query(sql_query.query.search_petdays, [req.user.username, firstday, lastday], (err, data) => {
				if (err || !data.rows || data.rows.length == 0) {
					pet_days = [];
					console.log("Unable to calculate pet_days");
				} else {
					pet_days = data.rows;

				}
			})
		}
		basic(req, res, 'caretaker', { caretaker : caretaker, pet_days : pet_days, add_msg: msg(req, 'add', 'Caretaker added successfully', 'Error in adding caretaker'), auth: true });
	});
}

function viewbids (req, res, next) {
	var owner = req.user.username;
	console.log(owner);
	var bids;
	pool.query(sql_query.query.view_bids, [owner], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			bids = [];
		} else {
			bids = data.rows;
		}
		basic(req, res, 'viewbids', {data: bids, auth : true});
	});
}

function ctview_bids (req, res, next) {
	var bids;
	pool.query(sql_query.query.ctview_bids, [req.user.username], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			bids = [];
		} else {
			bids = data.rows;
		}
		basic(req, res, 'ctreviews', {bids: bids, auth : true});
	});
}

function displayreviewautomatic (caretaker, req, res) {
	var username = caretaker;
	var bids;
	pool.query(sql_query.query.ctview_bids, [username], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			bids = [];
		} else {
			bids = data.rows;
		}
		basic(req, res, 'ctreviews', {bids: bids, auth : true});
	});
}

function displayreview (req, res, next) {
	var username = req.body.username;
	var bids;
	pool.query(sql_query.query.ctview_bids, [username], (err, data) => {
		if (err || !data.rows || data.rows.length == 0) {
			bids = [];
		} else {
			bids = data.rows;
		}
		basic(req, res, 'ctreviews', {bids: bids, auth : true});
	});
}


function rate_review_form (req, res, next) {
	res.render('rate_review_form', {auth:true});
}

function rate_review (req, res, next) {
    var owner = req.user.username;
    var pet = req.body.petname;
    var start = req.body.startdate;
    var end = req.body.enddate;
    var caretaker = req.body.caretakername;
    var rating = req.body.rating;
	var review = req.body.review;
	pool.query(sql_query.query.rate_review, [rating, review, owner, pet, start, end, caretaker], (err, data) => {
		if (err) {
			console.error("Error in creating rating/review", err);
		} else {
			pool.query(sql_query.query.rate_review_updatect, [rating, caretaker], (err, data) => {
				if (err) {
					console.error("Error in updating caretaker avg_rating and no_of_reviews", err);
				} else {
					// res.redirect('/viewbids');
					displayreviewautomatic(caretaker, req, res);
				}
			});

			//res.redirect('/viewbids');
		}
	});
}

function view_transac (req, res, next) {
	res.render('insert_transac', {auth:true});
}

function insert_transac (req, res, next) {
	var owner = req.user.username;
	var pet = req.body.petname;
	var start = req.body.startdate;
	var end = req.body.enddate;
	var caretaker = req.body.caretakername;
	var payment = req.body.paymentmethod;
	var mot = req.body.modeoftransfer;
	console.log(owner + pet + start + end + caretaker + payment + mot);
	pool.query(sql_query.query.set_transac_details, [payment, mot, owner, pet, caretaker, start, end], (err, data) => {
		if (err) {
			console.error("Error in setting transaction details", err);
		} else {
			res.redirect('/owner_calendar?error_message=pass');
		}
	})
}

function newbid (req, res, next) {
   basic(req, res, 'newbid', {auth:true});
}

function insert_bid (req, res, next) {
	var owner = req.user.username;
	var pet = req.body.petname;
	var p_start = req.body.pstartdate;
	var p_end = req.body.penddate;
	var caretaker = req.body.caretakername;
	var service = req.body.servicetype;
	console.log(p_start);
	console.log(p_end);
	console.log("calling insert bid query  with start and end timestamp " + p_start + " " + p_end);
	pool.query(sql_query.query.insert_bids, [owner, pet, p_start, p_end, caretaker, service], (err, data) => {
		if (err) {
		  req.flash('error', 'Error creating bids. Check the bid start and end time is within the start and end time of caretaker\'s availability');
			console.error("Error in creating bid", err);
		} else {
			res.redirect('/owner_calendar?insert=pass');

		}
	});
}


function delete_bid(req, res, next) {
    var old_bid_start_timestamp = req.body.old_bid_start_timestamp;
    var old_avail_start_timestamp = req.body.old_avail_start_timestamp;
    var old_caretaker_username = req.body.old_caretaker_username;
    var old_pet_name = req.body.old_pet_name;

    console.log("bids and avail start timestamp is " + old_bid_start_timestamp + old_avail_start_timestamp);


    var owner_username = req.user.username;

    console.log("caretaker and pet_name and pet-owner name is " + old_caretaker_username + old_pet_name + owner_username);


    pool.query(sql_query.query.delete_bid, [old_bid_start_timestamp, old_avail_start_timestamp, old_caretaker_username, old_pet_name], (err, data) => {
        if(err) {

            req.flash('error', 'The bid cannot be deleted');


             res.redirect('/owner_calendar?delete=fail');


        } else {
        console.log("delete the bid: " + data.rows[0]);
        req.flash('success', 'The bid is successfully deleted.');
              res.redirect('/owner_calendar?delete=pass');
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
