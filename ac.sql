-- bashpass/ac.sql
--
-- Initialize a demo SQLite3 db. usage: sqlite3 git.db3 < ac.sql

CREATE TABLE IF NOT EXISTS ac(dm varchar(100),em varchar(100),un varchar(100),pw varchar(256),cm varchar(100));

INSERT OR REPLACE INTO ac VALUES('https://facebook.com/','adummy@email.com' ,'emanresu','cccb31f4ba8aff46d409d60ab335672e3f014304125f57882595e5dbb5570030cbfba163c8ad381f9d8fbff8d53691c9305c38851ad64b019ad9bc33d30ba9d2','foobuzzbar');
INSERT OR REPLACE INTO ac VALUES('https://www.google.com/','mail@gmail.com','googleuser','6d1cb32a30be93d77987a10f814b74c5a347bce8d63fe8db50f2e200466d3bf083ab2ad3f2c70255da3bf802b96b50e82cd69f805211de1169a2d3035c15eb40','fizzbuzzbar');
INSERT OR REPLACE INTO ac VALUES('https://twitter.com/','tsirp@twitter.com','tsirpinator','600f981de85b722d86827025b85d1554ff7d72b611e81a79b3c75221c23547b89d54845f67cd9e2e03363c30e413f481063a2b2b2ba6e59e22a0777324442c27','foobarbuzz');
