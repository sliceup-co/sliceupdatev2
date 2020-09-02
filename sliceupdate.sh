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






