/************************************************************************
 Product    : Home information and control
 Date       : 2016-12-01
 Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : agent_body.js
 Version    : 0.2.1
 Author     : Bjorn Kjeholt
 *************************************************************************/

var mysql = require('mysql');

databaseClass = function (ci) {
    var self = this;
    this.ci = ci;
    
    var dbConnected = false;
    var dbPopulated = false;
    
    this.db = mysql.createConnection({ host     : self.ci.mysql.ip_addr,
                                       user     :  self.ci.mysql.user,
                                       password :  self.ci.mysql.passw,
                                       database :  self.ci.mysql.scheme });

    self.db.on('error', function(err) {
            console.log("Database create connection: An error has occured ",err); // 'ER_BAD_DB_ERROR' 
            dbConnected = false;
        });
  
//    console.log("DB ci",self.ci);
        
    this.query = function(query, callback) {
//        console.log("DB query: " + query);

        self.db.query(query, function(err,rows) {
                if (!err) {
                    callback(null, rows);
                } else {
                    callback(err,null);
                }
            });
    };
    
    this.store_info_variable = function(header,body,callback) {
        var queryGetDeviceId = "SELECT `device`.`id` AS `device_id` " +
                                    "FROM `device`, `node`, `agent` " +
                                    "WHERE " +
                                        "(`agent`.`name` = '" + header.agent + "') AND " +
                                        "(`node`.`name` = '" + header.node + "') AND " +
                                        "(`device`.`name` = '" + header.device + "') AND " +
                                        "(`agent`.`id` = `node`.`agent_id`) AND " +
                                        "(`node`.`id` = `device`.`node_id`) " +
                                    "ORDER BY `device`.`id` DESC " +
                                    "LIMIT 1";
        self.db.query(queryGetDeviceId, function(err,rows) {
                var queryGetVariableId = "";
                var deviceId = 0;
                
                if (!err) {
                    deviceId = rows[0][0].device_id;
                    queryGetVariableId = "SELECT `id` " +
                                            "FROM `variable`" +
                                            "WHERE " +
                                                "(`name` = '" + header.variable + "') AND " +
                                                "(`device_id` = '" + deviceId + "') " +
                                            "ORDER BY `id` DESC " +
                                            "LIMIT 1";
                                    
                    self.db.query(queryGetVariableId, function(err,rows) {
                            var queryInsertVariable = "";
                            var variableId = 0;
                            
                            if (!err) {
                                queryInsertVariable = "INSERT INTO `variable`";
                            }
                    });
                }
                
                                            
            });
        
    };
    
    this.store_data = function(topic,msg) {
        
    };
    
    this.connected = function() {
        return dbConnected;
    };
    
    this.checkPublishData = function (callback) {
        var query = "SELECT `DataPublishId`,\
                            `DataTime`,\
                            FROM_UNIXTIME(`DataTime`) AS `FullTime`,\
                            `DataValue`,\
                            `TopicAddress` FROM `list_all_unpublished_data`";
        
        if (self.connected()) {
            self.db.query(query, function(err, rows) {
                    var rowIndex = 0;
                    var queryDeleteMessage = "";
            
                    var topicJson;
  
                    var msgString= "";
  //                var msgPayloadJson = {};
            
                    if (!err) {
                        for (rowIndex = 0; rowIndex < rows.length; rowIndex = rowIndex + 1) {
                            topicArray = rows[rowIndex].TopicAddress.split("/");

                            callback(null,{topic: { group: "data",
                                                    order: "set",
                                                    agent: topicArray[0],
                                                    node: topicArray[1],
                                                    device: topicArray[2],
                                                    variable: topicArray[3] },
                                            body: { time: rows[rowIndex].DataTime,
                                                    date: rows[rowIndex].FullTime,
                                                    data: rows[rowIndex].DataValue}});
                            
                            queryDeleteMessage = "DELETE FROM `data_publish` WHERE `id`='" + rows[rowIndex].DataPublishId + "'";
                            self.db.query(queryDeleteMessage, function(err,rows) {
                                    if (err) {
                                        console.log("Not possible to remove row with index ="+ rows[rowIndex].DataPublishId + " from table data_publish");
                                    } 
                                });
                        }
                    } else {
                        console.log("ERROR db access", query);
                        callback(null, { topic: { group: "error",
                                                  order: "report",
                                                  agent: "mqtt-manager",
                                                  node: "sev-error" },
                                         body: { time: (Math.floor(new Date()/1000)),
                                                 code: 1010,
                                                 desc: "Error during Database query",
                                                 info: err }});
                    }
                });
        } else {
            // DB not connected
            callback(null, { topic: { group: "error",
                                      order: "report",
                                      agent: "mqtt-manager",
                                      node: "sev-warning" },
                             body: { time: (Math.floor(new Date()/1000)),
                                     code: 1020,
                                     desc: "Database not connected",
                                     info: err }});
        }
    };
    
    this.setup = function(callback) {
        self.db.connect(function(err) {
                if (err) {
                    console.error('error connecting: ' + err.stack);
                    callback(err);
                } else {
                    console.log('connected as id ' + self.db.threadId);
                    dbConnected = true;
                    callback(null);
                }
        });
    };
    
    setInterval(function() {
        if (dbConnected) {
            self.db.ping(function (err) {
                if (err) {
                    console.log("Error during ping of db server",err);
                    dbConnected = false;
                  
                } else {
                    console.log('Server responded to ping');
                }
            });
        }
    },30000);
};

exports.create = function (ci) {
    return new databaseClass(ci);
};