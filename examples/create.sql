--
-- Initialize a demo SQLite3 db. usage: sqlite3 git.db3 < create.sql

CREATE TABLE IF NOT EXISTS ac(dm varchar(100),em varchar(100),un varchar(100),pw varchar(256),cm varchar(100));

INSERT OR REPLACE INTO ac VALUES('https://facebook.com/','adummy@email.com' ,'emanresu','o6vA\*2HSt4a_h!]','foobuzzbar');
INSERT OR REPLACE INTO ac VALUES('https://www.google.com/','mail@gmail.com','googleuser','LL2Pto!vR&d!Y&I@','fizzbuzzbar');
INSERT OR REPLACE INTO ac VALUES('https://twitter.com/','tsirp@twitter.com','tsirpinator','I8;l[\D<Qf~lmad]','foobarbuzz');
INSERT OR REPLACE INTO ac VALUES('https://instagram.com/','selfindulgence@isgreat.me','notjustabimbo','fINjf>%lxVI{1ict','memyselfni');
INSERT OR REPLACE INTO ac VALUES('https://pinterest.com/','looking@pictures.jif','artzor','OBXpzhQvaC({UFGz','daliforprez');
