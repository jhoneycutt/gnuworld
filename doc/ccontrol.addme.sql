-- "$Id: ccontrol.addme.sql,v 1.6 2002/08/30 10:15:12 nighty Exp $"
-- 2001-03-29 :  |MrBean|
-- This script will add the first user to ccontrol
-- it will create a user with a coder access by the handle of Admin
-- with pass : temPass
-- the host that will be added is *!*@* , this is a security risk, and should be changed along with the password
-- Note: this script should be run only once , and when the database got no other opers

INSERT INTO OPERS (user_name,password,access,saccess,last_updated,isCODER) VALUES ('jotun','password9dbb300e28bc21c8dab41b01883918eb',2147483647,2147483647,date_part('epoch', CURRENT_TIMESTAMP)::int,'t');
INSERT INTO HOSTS (user_id,host) VALUES (1,'*!*@*');

