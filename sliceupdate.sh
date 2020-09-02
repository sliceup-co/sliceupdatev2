#!/bin/bash

#update Grafana dashboardsd
    echo "Do Not run this script with sudo. The script will invoke sudo when required"
    echo "Press Enter to continue"
    read y
    cuser=$(whoami)    
    sudo cp newdashboards/*.* /opt/sliceup/dashboards/

    sudo grafana-cli plugins install magnesium-wordcloud-panel
    sleep 3
    echo "Restarting Grafana Now"
    sudo service grafana-server restart
    sleep 3
    sudo /bin/systemctl stop grafana-server
    sleep 5
    sudo /bin/systemctl start grafana-server
    sudo chmod g+w /opt/sliceup/dashboards/*.*
    sudo chown $cuser /opt/sliceup/dashboards/*.*
    sudo chgrp $cuser /opt/sliceup/dashboards/*.*

    echo "New dashboards installed"



	sudo systemctl stop slicemaster.service
	sudo cp files/sourcedb.sql /opt/sliceup/executables/db_migration/sourcedb.sql
	sudo -i -u postgres psql -c "DROP DATABASE sliceup"
	sudo -i -u postgres psql -c "CREATE DATABASE sliceup"
	sudo -i -u postgres psql sliceup < /opt/sliceup/executables/db_migration/sourcedb.sql
	sudo rm /opt/sliceup/executables/log-lines-proc-1.0.jar /opt/sliceup/executables/db-cleaner.jar
	sudo cp files/log-lines-proc-1.0.jar files/db-cleaner.jar files/user-client-1.0.jar /opt/sliceup/executables/
	sudo systemctl start slicemaster.service
	
	echo "Update complete."


