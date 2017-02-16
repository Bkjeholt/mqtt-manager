/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-15
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : TBD.js
 Version    : 0.7.1
 Author     : Bjorn Kjeholt
 ---------------------------------------------------------
 
 ***************************************************************************/

var mqttHandler = require('./mqttHandler');
var databaseClass = require('./databaseClass');

var mqttData= require('./Support/mqttDataMsg');
var mqttInfo= require('./Support/mqttInfoMsg');
var mqttCalc= require('./Support/mqttCalcMsg');

managerClass = function(ci) {
    var self = this;
    this.ci = ci;
    this.mqtt = null;
    this.db = null;

    this.mqttSubscribedMessage = function(topicStr, messageStr, packet) {
        self.mqtt.parseSubscribedMessage(topicStr, messageStr, function(err,topic,body) {
            if (!err) {
                switch(topic.group) {
                    case 'data' : 
                        mqttData.checkMsg(topic,body,self.db,function(err,msg) {
                                if (!err) {
                                    self.mqtt.publish(msg.topic,msg.body);
                                } else {
                                    
                                }
                            });
                        break;
                    case 'info' : 
                        mqttInfo.checkMsg(topic,body,self.db,function(err,msg) {
                                if (!err) {
                                    self.mqtt.publish(msg.topic,msg.body);                                    
                                } else {
                                    
                                }
                            });
                        break;
                    case 'calc' : 
                        mqttCalc.checkMsg(topic,body,self.db, function(err,msg) {
                                if (!err) {
                                    self.mqtt.publish(msg.topic,msg.body);
                                } else {
                                    
                                }
                            });
                        break;
                    default:
                        break;
                }
            }
        });
    };
    
    this.healthCheck_db = function(callback) {
        if (self.db)
            if (self.db.connected()){
            callback(null);
        } else {
            callback({ error: "non-healthy",
                       info: "The database is not connected" });            
        }
    };
    
    this.healthCheck_mqtt = function(callback) {
        if (self.db)
            if (self.mqtt.connected()){
            callback(null);
        } else {
            callback({ error: "non-healthy",
                       info: "The mqtt broker is not connected" });            
        }
    };
    
    this.setup = function () {
        console.log("--------------------------------------------------------");
        console.log("Docker container name:  " + self.ci.config.name);
        console.log("Docker image name:      " + self.ci.config.docker.image);
        console.log("Docker image tag:       " + self.ci.config.docker.image_tag);
        console.log("Docker base image name: " + self.ci.config.docker.base_image);
        console.log("Docker base image tag:  " + self.ci.config.docker.base_image_tag);
        console.log("--------------------------------------------------------");        
        console.log("ManagerClass: Preparation");
        self.ci.mqtt.functions.message = self.mqttSubscribedMessage; 
        self.ci.health_check.check_functions.push(self.healthCheck_db);
        self.ci.health_check.check_functions.push(self.healthCheck_mqtt);
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: Initiate Database sub class");
        self.db = databaseClass.create(self.ci);
        
        (function dbSetupLoop(callback) {
                self.db.setup(function(err) {
                        if (err) {
                            console.log("Problem with connecting to the database, retry in a second", err);
    
                            setTimeout(function() {
                                    dbSetupLoop(callback);
                                },1000);

                        } else {
                            callback(null);
                        }
                    });
            })(function (err) {
                    if (!err) {
                        console.log("--------------------------------------------------------");
                        console.log("ManagerClass: Initiate MQTT sub class");
                        self.mqtt = mqttHandler.create(self.ci);
                        console.log("--------------------------------------------------------");
                        
                    }
                });
        
        
    };
            
    self.setup();    
    /*
     * Send a status mqtt message every 60 seconds 
     */
    
    setInterval(function() {
        var msgStatus = {
                            status: "I'm alive",
                            time: (Math.floor(new Date()/1000))
                        };
        
        self.mqtt.sendStatus(msgStatus.toString());
    },60000);
    
    /*
     * Check for data to be published every 1 second.
     */
    setInterval(function() {        
        if (self.db) 
            self.db.checkPublishData(function(err, msg) {
                if (!err) {
                    self.mqtt.publish(msg.topic,msg.body);
                } else {
                    self.mqtt.publish({ group: "error",
                                        order: "report",
                                        agent: "---" },
                                      { time: (Math.floor(new Date()/1000)),
                                        code: 1020,
                                        desc: "Fault during execution of db.checkPublishData",
                                        info: err });
                }
            });
    }, 1000);
};

exports.create = function(ci) {
    return new managerClass(ci);
};


