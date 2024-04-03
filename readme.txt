Our client, a prominent figure in the financial landscape, renowned for its extensive banking
services and comprehensive credit card operations, serves a diverse customer base and maintains
a wide network of merchant partnerships. This position underscores their pivotal role in facilitating
economic transactions and growth. However, the digital era has introduced sophisticated financial
frauds, posing significant risks to customer trust and the institution's stability. The urgency to
combat these threats has become paramount, necessitating innovative and robust security
measures.

In response, our client has embarked on a strategic initiative to develop a state-of-the-art, SQL-
based real-time fraud detection system. This project is aimed at harnessing the power of real-time

data analytics, to identify and neutralize fraudulent activities efficiently. The commitment to this
project reflects the client's dedication to upholding security, restoring customer confidence, and
establishing new benchmarks for fraud prevention in the financial sector.

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
