/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-15
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : dbiCalculate/main.js
 Version    : 0.7.1
 Author     : Bjorn Kjeholt
 ---------------------------------------------------------
 
 ***************************************************************************/

var mqttHandler = require('./mqttHandler');
var databaseClass = require('./databaseClass');

var exec = require('child_process').exec;

var mqttData= require('./Support/mqttDataMsg');
var mqttInfo= require('./Support/mqttInfoMsg');
var mqttCalc= require('./Support/mqttCalcMsg');

module.exports = dbiCalculate;

function dbiCalculate(dbiBasicObj) {

    this.dbiCalc = new dbiBasicObj();
};

setInterval(function() {
        // Get list of calculations with at least one modified input.
        
    },5000);
    
    
    var self = this;
    this.ci = ci;
    this.mqtt = null;
    this.db = null;
    
    this.healthCheck_db = function(callback) {
        if (self.db) {
            if (self.db.connected()){
                callback(null);
            } else {
                callback({ error: "non-healthy",
                           info: "The database is not connected" });            
            }
        } else {
            callback({ error: "non-healthy",
                       info: "The database object is available" });            
            
        }
    };
    
    
    this.setup = function () {
        console.log("--------------------------------------------------------");
        console.log("dbiCalculate/mainClass: Preparation");
        self.ci.health_check.check_functions.push(self.healthCheck_db);
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: Initiate Database sub class");
        self.db = databaseClass.create(self.ci);
        
        (function dbSetupLoop(callback) {
                self.db.setup(function(err) {
                        var dbSetupCommand = "";
                        if (err) {
                            console.log("Problem with connecting to the database, retry in five seconds");
    
                            setTimeout(function() {
                                    dbSetupLoop(callback);
                                },5000);

                        } else {
                            dbSetupCommand = "/usr/src/app/script/mysql-setup.sh " + 
                                             self.ci.mysql.ip_addr + " " +
                                             self.ci.mysql.port_no + " " +
                                             self.ci.mysql.user + " " +
                                             self.ci.mysql.passw + " " +
                                             self.ci.mysql.scheme;
                            console.log("Database connected, execute script: " + dbSetupCommand);
                            exec(dbSetupCommand,function(err,stdout,stderr) {
                                if (!err) {
                                    console.log("Database tables,views and stored procedures are updated");
                                    console.log("Stdout:",stdout);
                                    console.log("-----------------------------------------");
                                    console.log("stderr:",stderr);
                                    console.log("-----------------------------------------");
                                    callback(null);
                                } else {
                                    console.error("Failing running the mysql-setups script err" ,err);
                                    callback(err);
                                }
                            });                            
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
        
        if (self.mqtt) self.mqtt.sendStatus(msgStatus.toString());
    },60000);
    
    /*
     * Check for data to be published every 1 second.
     */
    setInterval(function() {        
        if ((self.db) && (self.mqtt)) 
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
    return new mainClass(ci);
};


