const sql_query = require('../sql');
const passport = require('passport');
const bcrypt = require('bcrypt')

// Postgre SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL,
  //ssl: true
});

const round = 10;
const salt  = bcrypt.genSaltSync(round);

function initRouter(app) {
	/* GET */
	app.get('/'      , index );
	app.get('/search', search);
	
	/* PROTECTED GET */
	app.get('/weekly_availabilities'   , weekly_availabilities);//TODO: passport.authMiddleware()
    app.get('/monthly_availabilities'    , passport.authMiddleware(), monthly_availabilities); //TODO: passport.authMiddleware()
	
	app.get('/register' , passport.antiMiddleware(), register );
	app.get('/password' , passport.antiMiddleware(), retrieve );
	
	/* PROTECTED POST */
	app.post('/update_availability', passport.authMiddleware(), update_availability);
	app.post('/add_availability'   , add_availability   ); //TODO: passport.authMiddleware()
	app.post('/delete_availability'   , passport.authMiddleware(), delete_availability);
	
	app.post('/reg_user'   , passport.antiMiddleware(), reg_user   );

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
		//user: req.user.username, //TODO usernmae

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
	res.redirect('weekly_availabilities');
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

function weekly_availabilities(req, res, next) {
	var now = new Date();
    var startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    var current_timestamp = startOfDay / 1000;
    var periods;
	pool.query(sql_query.query.read_weekly_availabilities, [ current_timestamp], (err, data) => { //TODO req.user.username
            if(err || !data.rows || data.rows.length == 0) {
            			periods = [];
            		} else {
            			periods = data.rows;
            		}

			basic(req, res, 'weekly_availabilities', { tbl: periods, availability_msg: msg(req, 'add', 'Availability period added successfully', 'Invalid parameters in availability period'), auth: true });
		});
}


function monthly_availabilities(req, res, next) {
	var now = new Date();
    var startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
   var current_timestamp = startOfDay / 1000;
	pool.query(sql_query.query.read_monthly_availabilities, [req.user.username, current_timestamp], (err, data) => {

	basic(req, res, 'monthly_availabilities', { tbl: data.rows, availability_msg: msg(req, 'add', 'Availability period added successfully', 'Invalid parameters in availability period'), auth: true });
		});
}

function register(req, res, next) {
	res.render('register', { page: 'register', auth: false });
}
function retrieve(req, res, next) {
	res.render('retrieve', { page: 'retrieve', auth: false });
}


// POST 
function update_availability(req, res, next) {
	var username  = req.user.username;
	var start_timestamp = req.body.start_timestamp;
	var end_timestamp  = req.body.end_timestamp;
	var mode = req.body.mode;
	pool.query(sql_query.query.update_availability, [start_timestamp, end_timestamp, username], (err, data) => {
		if(err) {
			console.error("Error in updating availability");
			if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?update=fail');
			else
			 res.redirect('/weekly_availabilities?update=fail');
		} else {
            if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?update=pass');
			else
			 res.redirect('/weekly_availabilities?update=pass');
		}
	});
}

function add_availability(req, res, next) {
	//var username = req.user.username; //TODO username
	var start_timestamp = req.body.start_timestamp;
	var end_timestamp = req.body.end_timestamp;

	pool.query(sql_query.query.add_availability, [start_timestamp, end_timestamp, 'jane'], (err, data) => {
        if(err) {
			console.error("Error in adding availability");
			if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?add=fail');
			else
			 res.redirect('/weekly_availabilities?add=fail');
		} else {
            if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?add=pass');
			else
			 res.redirect('/weekly_availabilities?add=pass');
		}
	});
}

function delete_availability(req, res, next) {
	var username = req.user.username;
	var start_timestamp = req.body.start_timestamp;
	var end_timestamp = req.body.end_timestamp;

	pool.query(sql_query.query.delete_availability, [start_timestamp, end_timestamp, username], (err, data) => {
        if(err) {
			console.error("Error in deleting info");
			if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?delete=fail');
			else
			 res.redirect('/weekly_availabilities?delete=fail');
		} else {
            if(mode = 'weekly')
			    res.redirect('/weekly_availabilities?delete=pass');
			else
			 res.redirect('/weekly_availabilities?delete=pass');
		}
	});
}

function reg_user(req, res, next) {
	var username  = req.body.username;
	var password  = bcrypt.hashSync(req.body.password, salt);
	var firstname = req.body.firstname;
	var lastname  = req.body.lastname;
	pool.query(sql_query.query.add_user, [username,password,firstname,lastname], (err, data) => {
		if(err) {
			console.error("Error in adding user", err);
			res.redirect('/register?reg=fail');
		} else {
			req.login({
				username    : username,
				passwordHash: password,
				firstname   : firstname,
				lastname    : lastname,
				status      : 'Bronze'
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