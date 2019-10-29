# Carpooling
Carpooling Application

# Setting up
- Install npm `npm install`
- Run client `npm start`

- If you encounter problems during npm install, try to manually install bcrypt module by `npm install bcrypt`
- If your encounter problems during npm start:
    - Error `include secret as option`: caused by process.env.SECRET not set. You need to set your own SECRET variable. 
    Removing commenting for the statement above, create `.env` file in the root directory and add the following into the file.
    Edit `DATABASE_URL` to match your psql login info.
        ```text
          SECRET=ndsvn2g8dnsb9hsg
          DEBUG=true
          DEBUGLEVEL=5
          DATABASE_URL='postgres://someuser:somepassword@somehost:381/somedatabase'
        ```

# Acknowledgements
- `CS2102 Database Systems: Introduction to Web Application Development` project created by `thisisadiyoga` at https://github.com/thisisadiyoga/cs2102_ay1819_s2