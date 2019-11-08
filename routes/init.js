const sql_query = require('../sql');
const passport = require('passport');
const bcrypt = require('bcrypt')
const fs = require('fs')

// Postgres SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL,
  //ssl: true
});

const round = 10;
const salt  = bcrypt.genSaltSync(round);

function initRouter(app) {
	/*
	Routes needed:
	- profile page (update)
	- advertised rides (Create, Read, Update?, Delete)
	- requested rides (Create, Read, Update?, Delete)
	- confirmed rides (Read, Update?, Delete)
	- completed rides (Read)
	- individual ride page (Create, Read, Update?, Delete)
	 */

	/* GET */
	app.get('/'      , index );
	app.get('/search', search);

	/* PROTECTED GET */
	app.get('/dashboard', passport.authMiddleware(), dashboard);
	app.get('/cars'    	, passport.authMiddleware(), cars);
	app.get('/journeys'    , passport.authMiddleware(), journeys);
	app.get('/payment'    	, passport.authMiddleware(), payment);
	app.get('/bids'    	, passport.authMiddleware(), bids);

	app.get('/register' , passport.antiMiddleware(), register );
	app.get('/login'		, passport.antiMiddleware(), login);
	app.get('/password' , passport.antiMiddleware(), retrieve );

	/* PROTECTED POST */
	app.post('/update_info', passport.authMiddleware(), update_info);
	app.post('/update_pass', passport.authMiddleware(), update_pass);
	app.post('/add_car'    , passport.authMiddleware(), add_car);
	app.post('/add_journey', passport.authMiddleware(), add_journey);
	app.post('/del_car'    , passport.authMiddleware(), del_car);

	app.post('/reg_user'   , passport.antiMiddleware(), reg_user);

	/* LOGIN */
	app.post('/login', passport.authenticate('local', {
		successRedirect: '/dashboard',
		failureRedirect: '/'
	}));

	/* LOGOUT */
	app.get('/logout', passport.authMiddleware(), logout);
}

// Render Function
function basic(req, res, page, other) {
	var info = {
		page: page,
		user: req.user.email,
		firstname: req.user.firstname,
		lastname : req.user.lastname,
		age			 : req.user.age,
		gender   : req.user.gender,
		is_driver: req.user.is_driver,
		is_passenger: req.user.is_passenger,
		dob			 : req.user.dob,
		gender	 : req.user.gender
	};
	if(other) {
		for(var fld in other) {
			info[fld] = other[fld];
		}
	}
	res.render(page, info);
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
	var ctx = 0, idx = 0, tbl, total;
	if(Object.keys(req.query).length > 0 && req.query.p) {
		idx = req.query.p-1;
	}
	pool.query(sql_query.query.page_lims, [idx*10], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			tbl = [];
		} else {
			tbl = data.rows;
		}
		pool.query(sql_query.query.ctx_games, (err, data) => {
			if(err || !data.rows || data.rows.length == 0) {
				ctx = 0;
			} else {
				ctx = data.rows[0].count;
			}
			total = ctx%10 == 0 ? ctx/10 : (ctx - (ctx%10))/10 + 1;
			console.log(idx*10, idx*10+10, total);
			if(!req.isAuthenticated()) {
				res.render('index', { page: '', auth: false, tbl: tbl, ctx: ctx, p: idx+1, t: total });
			} else {
				basic(req, res, 'index', { page: '', auth: true, tbl: tbl, ctx: ctx, p: idx+1, t: total });
			}
		});
	});
}

function login(req, res, next) {
	res.render('login', { page: 'login', auth: false });
}

function payment(req, res, next) {
	res.render('payment_info', { page: 'payment', auth: false });
}

function bids(req, res, next) {
	res.render('bids', { page: 'bids', auth: false });
}

function search(req, res, next) {
	var ctx  = 0, avg = 0, tbl;
	var game = "%" + req.query.gamename.toLowerCase() + "%";
	pool.query(sql_query.query.search_game, [game], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			ctx = 0;
			tbl = [];
		} else {
			ctx = data.rows.length;
			tbl = data.rows;
		}
		if(!req.isAuthenticated()) {
			res.render('search', { page: 'search', auth: false, tbl: tbl, ctx: ctx });
		} else {
			basic(req, res, 'search', { page: 'search', auth: true, tbl: tbl, ctx: ctx });
		}
	});
}

function dashboard(req, res, next) {
	basic(req, res, 'dashboard', { info_msg: msg(req, 'info', 'Information updated successfully', 'Error in updating information'), pass_msg: msg(req, 'pass', 'Password updated successfully', 'Error in updating password'), auth: true });
}

function cars(req, res, next) {
	var ctx = 0, avg = 0, tbl;
	pool.query(sql_query.query.avg_rating, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			avg = 0;
		} else {
			avg = data.rows[0].avg;
		}
		pool.query(sql_query.query.all_cars, [req.user.email], (err, data) => {
			if(err || !data.rows || data.rows.length == 0) {
				ctx = 0;
				tbl = [];
			} else {
				ctx = data.rows.length;
				tbl = data.rows;
			}
			basic(req, res, 'cars', { ctx: ctx, avg: avg, tbl: tbl, car_msg: msg(req, 'add', 'Car added successfully', 'Car does not exist'), auth: true });
		});
	});
}

function update_car(req, res, next) {
	let carplate = req.body.car
	var ctx = 0, avg = 0, tbl = [];



}

function del_car(req, res, next) {
	let carplate = req.body.car
	var ctx = 0, avg = 0, tbl = [];
	// pool.query(sql_query.query.avg_rating, [req.user.username], (err, data) => {
	// 	if(err || !data.rows || data.rows.length == 0) {
	// 		avg = 0;
	// 	} else {
	// 		avg = data.rows[0].avg;
	// 	}
		pool.query(sql_query.query.del_car, [req.user.email, carplate], (err, data) => {
			if(err) {
				console.log(err)
			} else {
				console.log('Success!')
				pool.query(sql_query.query.all_cars, [req.user.email], (err, data) => {
					if(err || !data.rows || data.rows.length == 0) {
						console.log(err)
						ctx = 0;
						tbl = [];
					} else {
						ctx = data.rows.length;
						tbl = data.rows;
						}
					basic(req, res, 'cars', { ctx: ctx, avg: avg, tbl: tbl, car_msg: msg(req, 'delete', 'Car deleted successfully', 'Car does not exist'), auth: true });
				});
			}
	});
}

function journeys(req, res, next) {
	var win = 0, avg = 0, ctx = 0, tbl, ctx_cars = 0, cars;
	pool.query(sql_query.query.count_wins, [req.user.username], (err, data) => {
		if(err || !data.rows || data.rows.length == 0) {
			win = 0;
		} else {
			win = data.rows[0].count;
		}
		pool.query(sql_query.query.all_plays, [req.user.username], (err, data) => {
			if(err || !data.rows || data.rows.length == 0) {
				ctx = 0;
				avg = 0;
				tbl = [];
			} else {
				ctx = data.rows.length;
				avg = win == 0 ? 0 : win/ctx;
				tbl = data.rows;
			}
			pool.query(sql_query.query.all_cars, [req.user.email], (err, data) => {
				if(err || !data.rows || data.rows.length == 0) {
					ctx_cars = 0;
					cars = [];
				} else {
					ctx_cars = data.rows.length;
					cars = data.rows;
				}
				basic(req, res, 'journeys', { win: win, ctx: ctx, avg: avg, tbl: tbl, ctx_cars: ctx_cars, cars: cars, journey_msg: msg(req, 'add', 'Journey added successfully', 'Invalid parameter in journey'), auth: true });
			});
		});
	});
}

function register(req, res, next) {
	res.render('register', { page: 'register', auth: false });
}
function retrieve(req, res, next) {
	res.render('retrieve', { page: 'retrieve', auth: false });
}


// POST
function update_info(req, res, next) {
	var email  = req.user.email;
	var firstname = req.body.firstname;
	var lastname  = req.body.lastname;
	pool.query(sql_query.query.update_info, [email, firstname, lastname], (err, data) => {
		if(err) {
			console.error("Error in update info");
			res.redirect('/dashboard?info=fail');
		} else {
			res.redirect('/dashboard?info=pass');
		}
	});
}
function update_pass(req, res, next) {
	var email = req.user.email;
	var password = bcrypt.hashSync(req.body.password, salt);
	pool.query(sql_query.query.update_pass, [email, password], (err, data) => {
		if(err) {
			console.error("Error in update pass");
			res.redirect('/dashboard?pass=fail');
		} else {
			res.redirect('/dashboard?pass=pass');
		}
	});
}

function add_car(req, res, next) {
	var email = req.user.email;
	var carplate = req.body.carplate;
	var car_model = req.body.carmodel;
	var max_pass = req.body.carmaxpass;

	pool.query(sql_query.query.add_car, [carplate, car_model, max_pass, email], (err, data) => {
		if(err) {
			console.error("Error in adding car");
			res.redirect('/cars?add=fail');
		} else {
			res.redirect('/cars?add=pass');
		}
	});
}

function add_journey(req, res, next) {
	var email = req.user.email;
	var carplate = req.body.carname.split("-")[1].trim();
	var maxPassengers = req.body.carmaxpass;
	var pickupArea  = req.body.pickuparea;
	var dropoffArea  = req.body.dropoffarea;
	var pickuptime = req.body.pickuptime;
	var dropofftime   = req.body.dropofftime;
	var bidStart = req.body.bidstart;
	var bidEnd = req.body.bidend;

	if (bidEnd < bidStart || dropofftime < pickuptime) {
		res.redirect('/jouruneys?add=fail');
	}

	pool.query(sql_query.query.advertise_journey, [email, carplate, maxPassengers, pickupArea, dropoffArea, 0, bidStart, bidEnd], (err, data) => {
		if(err) {
			console.error("Error in adding journey");
			res.redirect('/jouruneys?add=fail');
		} else {
			res.redirect('/journeys?add=pass');
		}
	});
}

function reg_user(req, res, next) {
	var email  = req.body.email;
	var password  = bcrypt.hashSync(req.body.password, salt);
	var firstname = req.body.firstname;
	var lastname  = req.body.lastname;
	var dob = req.body.dob;
	console.log(req.body.user_type)
	var gender = req.body.gender === "2" ? 'f' : 'm';
	console.log(gender, dob)
	pool.query(sql_query.query.add_user, [email, dob, gender, firstname, lastname, password], (err, data) => {
		if(err) {
			console.error("Error in adding user", err);
			res.redirect('/register?reg=fail');
		} else {
			console.log(req.body.user_type)
			if (req.body.user_type == "1" || req.body.user_type == "3") {
				pool.query(sql_query.query.add_driver, [email], (err, data) => {
					if(err) {
						console.log(err)
					} else {
						console.log('Added as driver')
					}
				});
			}

			if (req.body.user_type == "2" || req.body.user_type == "3") {
				pool.query(sql_query.query.add_passenger, [email], (err, data) => {});
			}

			req.login({
				email       : email,
				passwordHash: password,
				firstname   : firstname,
				lastname    : lastname,
				dob 				: dob,
				gender			: gender
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


// LOGOUT
function logout(req, res, next) {
	req.session.destroy()
	req.logout()
	res.redirect('/')
}

module.exports = initRouter;
