--
--
-- Initialize a demo SQLite3 db. usage: sqlite3 ../databases/sample < ./create.sql

-- CREATE TABLE IF NOT EXISTS ACCOUNTS (DM TEXT,EM TEXT,UN TEXT,PW TEXT,CM TEXT,PRIMARY KEY(DM, EM));
-- CREATE TABLE IF NOT EXISTS ACCOUNTS (ID INTEGER PRIMARY KEY, DM TEXT,EM TEXT,UN TEXT,PW TEXT,CM TEXT,UNIQUE(DM, EM)) WITHOUT ROWID;
CREATE TABLE ACCOUNTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, DM TEXT, EM TEXT, UN TEXT, PW TEXT, CM TEXT, UNIQUE(DM, EM));

INSERT INTO ACCOUNTS (DM,EM,UN,PW,CM) VALUES('https://facebook.com/','adummy@email.com' ,'emanresu','o6vA/*2HSt4a_h!]','foobuzzbar');
INSERT INTO ACCOUNTS (DM,EM,UN,PW,CM) VALUES('https://www.google.com/','mail@gmail.com','googleuser','LL2Pto!vR&d!Y&I@','fizzbuzzbar');
INSERT INTO ACCOUNTS (DM,EM,UN,PW,CM) VALUES('https://twitter.com/','tsirp@twitter.com','tsirpinator','I8;l[/D<Qf~lmad]','foobarbuzz');
INSERT INTO ACCOUNTS (DM,EM,UN,PW,CM) VALUES('https://instagram.com/','selfindulgence@isgreat.me','notjustabimbo','fINjf>%lxVI{1ict','memyselfni');
INSERT INTO ACCOUNTS (DM,EM,UN,PW,CM) VALUES('https://pinterest.com/','looking@pictures.jif','artzor','OBXpzhQvaC({UFGz','daliforprez');
