--
--
-- Initialize a demo SQLite3 db. usage: sqlite3 git.db3 < create.sql

CREATE TABLE IF NOT EXISTS ACCOUNTS(DM nchar(100) NOT NULL,EM nchar(100) NOT NULL,UN nchar(100) NOT NULL,PW nchar(256) NOT NULL,CM nchar(100), PRIMARY KEY(DM,EM));

INSERT OR REPLACE INTO ACCOUNTS VALUES('https://facebook.com/','adummy@email.com' ,'emanresu','o6vA\*2HSt4a_h!]','foobuzzbar');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://www.google.com/','mail@gmail.com','googleuser','LL2Pto!vR&d!Y&I@','fizzbuzzbar');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://twitter.com/','tsirp@twitter.com','tsirpinator','I8;l[\D<Qf~lmad]','foobarbuzz');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://instagram.com/','selfindulgence@isgreat.me','notjustabimbo','fINjf>%lxVI{1ict','memyselfni');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://pinterest.com/','looking@pictures.jif','artzor','OBXpzhQvaC({UFGz','daliforprez');
