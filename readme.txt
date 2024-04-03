For more details about the project visit: https://drive.google.com/drive/folders/1XIRxjA5J395H2O17Jib_AJfVQ-Xgg2sW?usp=sharing 

Please execute the SQL files in the follwing order
🔒Database Init
🔒Database Cleaning 
🔒Database Querying


Please note:
🔒In the 'Database Cleaning.sql' file we have a query that converts 'lastlogin' and 'timestamp' columns from text to timestamp.
🔒 This query is based on the format of the system's time. We have written it according to the format on our local machine and it might not work on every machine 
🔒Please change these two lines in the query according to the local machine's time format
SET TempLastLogin = STR_TO_DATE(`LastLogin`, '%Y-%m-%d');
SET TempTimestamp = STR_TO_DATE(`Timestamp`, '%Y-%m-%d %H:%i:%s');
