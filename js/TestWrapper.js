/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-15
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/TestWrapper.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

    process.env.DOCKER_CONTAINER_NAME = "hic-manager";
    process.env.DOCKER_IMAGE_NAME = "mqtt-manager";
    process.env.DOCKER_IMAGE_TAG = "0.7.0";
    
    process.env.MYSQL_IP_ADDR = "127.0.0.1";
    process.env.MYSQL_PORT_NO = "3306";
    process.env.MYSQL_ENV_MYSQL_ROOT_PASSWORD = "hic";
    process.env.MYSQL_ENV_MYSQL_DATABASE = "hic";
    process.env.
            
    process.env.MQTT_IP_ADDR = "192.168.1.10";
    process.env.MQTT_PORT_NO = "1883";
    process.env.MQTT_USER = "NA";
    process.env.MQTT_PASSWORD = "NA";
    process.env.npm_package_name = "hic-agent-onewire";
    process.env.npm_package_version = "testenv-0.1.1";

require("./main.js");
   