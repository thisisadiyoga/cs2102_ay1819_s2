const sql_query = require('../sql');
const passport = require('passport');
const bcrypt = require('bcrypt')
const flash = require('connect-flash');
const postgres_details = require("../config.js");

// Postgre SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    //ssl: true
     user: postgres_details.user,
    database: postgres_details.database,
    idleTimeoutMillis: 2000
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

    app.get('/register' , passport.antiMiddleware(), register );
    app.get('/password' , passport.antiMiddleware(), retrieve );

    app.get('/calendar'   , passport.authMiddleware(), calendar);

    app.get('/register' , passport.antiMiddleware(), register );
    app.get('/password' , passport.antiMiddleware(), retrieve );

    /* PROTECTED POST */
    app.post('/update_availability', passport.authMiddleware(), update_availability);
    app.post('/add_availability'   , passport.authMiddleware(), add_availability);
    app.post('/delete_availability' , passport.authMiddleware(), delete_availability);

    app.post('/update_info', passport.authMiddleware(), update_info);
    app.post('/update_pass', passport.authMiddleware(), update_pass);
    app.post('/pets', passport.authMiddleware(), update_pet);

    app.post('/register', passport.antiMiddleware(), reg_user);
    app.post('/del_user', del_user);
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
}


// Render Function
function basic(req, res, page, other) {
    var info = {
        page: page,
        //user: req.user.username,
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
   // res.render('register', { page: 'register', auth: false });
   res.render('register', { page: 'register', auth: false });

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

function calendar(req, res, next) {
    var availabilities, bids;
    var error_message, success_message;


    pool.query(sql_query.query.read_availabilities,[req.user.username], (err, data) => { //TODO req.user.username
            if(err || !data.rows || data.rows.length == 0) {
                        availabilities = [];
                        console.log('Error reading availabilities: ' + err);
            } else {
                        availabilities = data.rows;
                    }


    pool.query(sql_query.query.read_bids, [req.user.username], (err, data) => {
           if(err || !data.rows || data.rows.length == 0) {
                          bids = [];
                           console.log('Error reading bids: ' + err);
          } else {
                    bids = data.rows;
          }

                      error_message = req.flash('error');
                      success_message = req.flash('success');

            basic(req, res, 'calendar', { bids: bids, availabilities: availabilities, error_message: error_message, success_message: success_message, availability_msg: msg(req, 'add', 'Availability period added successfully', 'Invalid parameters in availability period'), auth: true });
        })
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
              req.flash('error', 'The period cannot be updated. Check that there are scheduled pet-care jobs that are outside of the new period.');

             res.redirect('/availabilities?update=fail');
        } else {
              req.flash('success', 'The period is successfully updated.');
             res.redirect('/availabilities?update=pass');
        }
    });
}

function add_availability(req, res, next) {

    var start_timestamp = req.body.start_timestamp ;
    var end_timestamp = req.body.end_timestamp;



    pool.query(sql_query.query.add_availability, [start_timestamp, end_timestamp, req.user.username], (err, data) => {
        if(err) {

               req.flash('error', 'The new period cannot be added.');
                res.redirect('/availabilities?add=fail');

        } else {
            req.flash('success', 'The period is successfully added. It may merge with existing availability schedule.');
             res.redirect('/availabilities?add=pass');
        }
    });
}

function delete_availability(req, res, next) {
    var start_timestamp = req.body.old_start_timestamp;
    var end_timestamp = req.body.old_end_timestamp;

    pool.query(sql_query.query.delete_availability, [start_timestamp, req.user.username], (err, data) => {
        if(err) {

            req.flash('error', 'The period cannot be deleted as there is a scheduled pet-care job within that period.');

             res.redirect('/availabilities?delete=fail');


        } else {
        req.flash('success', 'The period is successfully deleted.');
             res.redirect('/availabilities?delete=pass');
        }
    });
}

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
    var username		= req.body.username;
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
                    return res.redirect('/add_pets');
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

    pool.query(sql_query.query.add_pet, [username, name, description, cat_name, size, sociability, special_req], (err, data) => {
        if(err) {
            console.error("Error in adding pet", err);
            res.redirect('/pets?pet_reg=fail');
        } else {
            res.redirect('/pets?pet_reg=pass');
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
                    res.redirect('/')
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