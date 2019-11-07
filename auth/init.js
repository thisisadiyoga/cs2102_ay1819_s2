const sql_query = require('../sql');

const passport = require('passport');
const bcrypt = require('bcrypt');
const LocalStrategy = require('passport-local').Strategy;

const authMiddleware = require('./middleware');
const antiMiddleware = require('./antimiddle');

// Postgre SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  //ssl: true
});

function findUser(email, callback) {
	pool.query(sql_query.query.userpass, [email], (err, data) => {
		if(err) {
			console.error("Cannot find user");
			return callback(null);
		}
		
		if(data.rows.length == 0) {
			console.error("User does not exists?");
			return callback(null)
		} else if(data.rows.length == 1) {
      pool.query(sql_query.query.find_driver, [email], (err, data1) => {
        let is_driver = false;
        if (err || !data1.rows || data1.rows.length == 0) {

        } else {
          if (data1.rows.length == 1) {
            is_driver = true;
          }
        }
        pool.query(sql_query.query.find_passenger, [email], (err, data2) => {
          var is_passenger = false;
          if (err || !data2.rows || data2.rows.length == 0) {

          } else {
            if (data2.rows.length == 1) {
              is_passenger = true;
            }
          }
          return callback(null, {
            email       : data.rows[0].email,
            passwordHash: data.rows[0].password,
            firstname   : data.rows[0].firstname,
            lastname    : data.rows[0].lastname,
            age         : data.rows[0].age,
            gender      : data.rows[0].gender,
            is_driver   : is_driver,
            is_passenger: is_passenger,
          });
        });
      });
		} else {
			console.error("More than one user?");
			return callback(null);
		}
	});
}

passport.serializeUser(function (user, cb) {
  cb(null, user.email);
})

passport.deserializeUser(function (email, cb) {
  findUser(email, cb);
})

function initPassport() {
  passport.use(new LocalStrategy(
    (username, password, done) => {
      findUser(username, (err, user) => {
        if (err) {
          return done(err);
        }

        // User not found
        if (!user) {
          console.error('User not found');
          return done(null, false);
        }

        // Always use hashed passwords and fixed time comparison
        bcrypt.compare(password, user.passwordHash, (err, isValid) => {
          if (err) {
            return done(err);
          }
          if (!isValid) {
            return done(null, false);
          }
          return done(null, user);
        })
      })
    }
  ));

  passport.authMiddleware = authMiddleware;
  passport.antiMiddleware = antiMiddleware;
  passport.findUser = findUser;
}

module.exports = initPassport;
