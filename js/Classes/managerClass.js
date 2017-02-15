/************************************************************************
 Product    : Home information and control
 Date       : 2016-11-11
 Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : TBD.js
 Version    : 0.2.1
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
                                    mqtt.publish(msg.topic,msg.body);
                                } else {
                                    
                                }
                            });
                        break;
                    case 'info' : 
                        mqttInfo.checkMsg(topic,body,self.db,function(err,msg) {
                                if (!err) {
                                    mqtt.publish(msg.topic,msg.body);                                    
                                } else {
                                    
                                }
                            });
                        break;
                    case 'calc' : 
                        mqttCalc.checkMsg(topic,body,self.db, function(err,msg) {
                                if (!err) {
                                    mqtt.publish(msg.topic,msg.body);
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
     * Check for data to be published
     */
    setInterval(function() {
        var query = "SELECT `DataPublishId`,\
                            `DataTime`,\
                            FROM_UNIXTIME(`DataTime`) AS `FullTime`,\
                            `DataValue`,\
                            `TopicAddress` FROM `list_all_unpublished_data`";
        
        if (self.db) 
            if (self.db.connected())
        self.db.query(query, function(err, rows) {
            var rowIndex = 0;
            var queryDeleteMessage = "";
            
            var topicJson;;
  
            var msgString= "";
  //          var msgPayloadJson = {};
            
            if (!err) {
                for (rowIndex = 0; rowIndex < rows.length; rowIndex = rowIndex + 1) {
                    topicArray = rows[rowIndex].TopicAddress.split("/");

                    self.mqtt.publish({ order: "data",
                                        suborder: "set",
                                        agent: topicArray[0],
                                        node: topicArray[1],
                                        device: topicArray[2],
                                        variable: topicArray[3] },
                                      { time: rows[rowIndex].DataTime,
                                        date: rows[rowIndex].FullTime,
                                        data: rows[rowIndex].DataValue });
                    
                    queryDeleteMessage = "DELETE FROM `data_publish` WHERE `id`='" + rows[rowIndex].DataPublishId + "'";
                    self.db.query(queryDeleteMessage, function(err,rows) {
                        if (err) {
                            console.log("Not possible to remove row with index ="+ rows[rowIndex].DataPublishId + " from table data_publish");
                        } 
                   });
                   
               }
           } else {
               console.log("ERROR db access", query);
           }
        });
    }, 2000);
};

exports.create = function(ci) {
    return new managerClass(ci);
};


