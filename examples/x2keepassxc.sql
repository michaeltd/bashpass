-- Export to KeePassXC like so: sqlite3 ${db} < x2keepassxc.sql

.mode csv
.header on
.output x2keepassxc.csv
SELECT DM AS Title, EM || ' ' || UN as Username, PW as Password, DM as URL, CM as Notes from ACCOUNTS;
