const sql_query = require('./sql');

const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');

const exphbs = require('express-handlebars')
const bodyParser = require('body-parser')
const session = require('express-session')
const passport = require('passport')
const fs = require('fs')

const app = express();

// Body Parser Config
app.use(bodyParser.urlencoded({
  extended: false
}));

// Authentication Setup
require('dotenv').load();
require('./auth').init(app);
app.use(session({
  secret: process.env.SECRET,
  resave: true,
  saveUninitialized: true
}))
app.use(passport.initialize())
app.use(passport.session())


// View Engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Router Setup
require('./routes').init(app);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

// Postgres SQL Connection
const { Pool } = require('pg');
const pool = new Pool({
	connectionString: process.env.DATABASE_URL,
  //ssl: true
});

console.log('Initializing Tables!')
// var drop_tables = fs.readFileSync('sql/drop_table.sql').toString();
// pool.query(drop_tables, function(err, result){
//     if(err){
//         console.log('error: ', err);
//         process.exit(1);
//     }
// });

var create_table = fs.readFileSync('sql/create_table.sql').toString();
pool.query(create_table, function(err, result){
    if(err){
        console.log('error: ', err);
        process.exit(1);
    }
});

module.exports = app;
