--
--
-- Initialize a demo SQLite3 db. usage: sqlite3 git.db3 < create.sql

CREATE TABLE IF NOT EXISTS ACCOUNTS(DOMAIN varchar(100) NOT NULL,EMAIL varchar(100) NOT NULL,USERNAME varchar(100) NOT NULL,PASSWORD varchar(256) NOT NULL,COMMENT varchar(100), PRIMARY KEY(DOMAIN,EMAIL));

INSERT OR REPLACE INTO ACCOUNTS VALUES('https://facebook.com/','adummy@email.com' ,'emanresu','o6vA\*2HSt4a_h!]','foobuzzbar');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://www.google.com/','mail@gmail.com','googleuser','LL2Pto!vR&d!Y&I@','fizzbuzzbar');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://twitter.com/','tsirp@twitter.com','tsirpinator','I8;l[\D<Qf~lmad]','foobarbuzz');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://instagram.com/','selfindulgence@isgreat.me','notjustabimbo','fINjf>%lxVI{1ict','memyselfni');
INSERT OR REPLACE INTO ACCOUNTS VALUES('https://pinterest.com/','looking@pictures.jif','artzor','OBXpzhQvaC({UFGz','daliforprez');
