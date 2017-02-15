/************************************************************************
 Product    : Home information and control
 Date       : 2016-06-21
 Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : MqttManager/main.js
 Version    : See below
 Author     : Bjorn Kjeholt
 *************************************************************************/

var managerClass = require("./Classes/managerClass");
var healthClass = require("./Classes/healthCheck");

var configInfo = {  config: {
                        name: process.env.DOCKER_CONTAINER_NAME,
                        rev:  process.env.DOCKER_IMAGE_TAG,
                        docker: {
                            image: process.env.DOCKER_IMAGE_NAME,
                            image_tag: process.env.DOCKER_IMAGE_TAG,
                            base_image: process.env.DOCKER_BASE_IMAGE_NAME,
                            base_image_tag: process.env.DOCKER_BASE_IMAGE_TAG,
                            container: process.env.DOCKER_CONTAINER_NAME } },
                    health_check: {
                         port_no: 3000,
                         check_functions: [] },
                    mysql: { 
                        ip_addr: (process.env.MYSQL_IP_ADDR !== undefined)? process.env.MYSQL_IP_ADDR : process.env.MYSQL_PORT_3306_TCP_ADDR,  // "192.168.1.10"
                        port_no: (process.env.MYSQL_PORT_NO !== undefined)? process.env.MYSQL_PORT_NO : process.env.MYSQL_PORT_3306_TCP_PORT,  // "3306"
                        user:    "root",
                        passw:   process.env.MYSQL_ENV_MYSQL_ROOT_PASSWORD,
                        scheme:  process.env.MYSQL_ENV_MYSQL_DATABASE, 
                        connected: false  },
                    mqtt: {
                        ip_addr: (process.env.MQTT_IP_ADDR !== undefined)? process.env.MQTT_IP_ADDR : process.env.MQTT_PORT_1883_TCP_ADDR,   // "192.168.1.10"
                        port_no: (process.env.MQTT_PORT_NO !== undefined)? process.env.MQTT_PORT_NO : process.env.MQTT_PORT_1883_TCP_PORT,   // "1883"
                        user:    (process.env.MQTT_USER !== undefined)? process.env.MQTT_USER : process.env.MQTT_ENV_MQTT_USER,      //"hic_nw",
                        passw:   (process.env.MQTT_PASSWORD !== undefined)? process.env.MQTT_PASSWORD : process.env.MQTT_ENV_MQTT_PASSWORD,  //"RtG75df-4Ge",
                        connected: false,
                        functions: {
                            message:    null },
                        subscribe: [
                                    { topic: "info/present/#", qos: 1 },
                                    { topic: "info/list", qos: 1 },
                                    { topic: "info/list/#", qos: 1 },
                                    { topic: "data/present/#", qos: 0 },
                                    { topic: "data/request/#", qos: 0 },
                                    { topic: "calc/store/#", qos: 1 },
                                    { topic: "calc/remove/#", qos: 1 },
                                    { topic: "calc/request/#", qos: 1 } ] }
                 };

var manager = managerClass.create(configInfo);
var healthObj = healthClass.create(configInfo)

