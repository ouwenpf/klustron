#!/bin/bash

# Database name, username, and password
DATABASE="test_lvhuan"
USERNAME="root"
PASSWORD="123456"
PORT=3306
HOST='127.0.0.1'


# MySQL socket
# SOCKET="/data/mysql/mysql3306/tmp/mysql3306.sock"


# Connect to MySQL and get a list of views
#VIEWS=$(mysql -S $SOCKET -e "SHOW FULL TABLES IN test_lvhuan WHERE TABLE_TYPE LIKE 'VIEW';" -s --skip-column-names | awk '{print $1}')


VIEWS=$(mysql -u"$USERNAME" -p"$PASSWORD" -h"$HOST" -P"$PORT"  2>/dev/null -e "SHOW FULL TABLES IN $DATABASE WHERE TABLE_TYPE LIKE 'VIEW';" -s --skip-column-names | awk '{print $1}')

# Loop through each view and modify the DEFINER
for VIEW in $VIEWS; do
    # Get the CREATE VIEW statement
    # CREATE_VIEW=$(mysql -S $SOCKET -e "SHOW CREATE VIEW test_lvhuan.$VIEW;" -s --skip-column-names | awk -F'\t' '{print $2}')
	
	CREATE_VIEW=$(mysql -u"$USERNAME" -p"$PASSWORD" -h"$HOST" -P"$PORT" 2>/dev/null -e "SHOW CREATE VIEW test_lvhuan.$VIEW;" -s --skip-column-names | awk -F'\t' '{print $2}')
    
    # Modify the DEFINER and change CREATE to ALTER
    ALTER_VIEW=$(echo "$CREATE_VIEW" | sed -e 's/CREATE ALGORITHM=UNDEFINED DEFINER/ALTER ALGORITHM=UNDEFINED DEFINER/' -e 's/`root`@`%`/`root`@`localhost`/')
    
    # Execute the ALTER VIEW statement
    # mysql -S $SOCKET  $DATABASE -e "$ALTER_VIEW"
	
	mysql -u"$USERNAME" -p"$PASSWORD" -h"$HOST" -P"$PORT"  $DATABASE 2>/dev/null -e "$ALTER_VIEW"
	
	
    if [ $? -ne 0 ]; then
        echo "Failed to execute ALTER VIEW statement for $VIEW."
    else
        echo "Successfully executed ALTER VIEW statement for $VIEW."
    fi
	
done
