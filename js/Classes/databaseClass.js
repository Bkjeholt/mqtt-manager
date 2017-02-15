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
            console.log(err.code); // 'ER_BAD_DB_ERROR' 
            dbConnected = false;
        });
  
//    console.log("DB ci",self.ci);
        
    this.query = function(query, callback) {
//        console.log("DB query: " + query);
        (function WaitForDbConnect() {
            if (!dbConnected) {
                self.db.connect(function(err) {
                    if (err) {
                        console.error('error connecting: ' + err.stack);
                        setTimeout(function() {
                            WaitForDbConnect();
                        },1000);
                    } else {
                        console.log('connected as id ' + self.db.threadId);
                        dbConnected = true;
                        WaitForDbConnect();
                    }
                });
            } else {
                self.db.query(query, function(err,rows) {
                    if (!err) {
                        callback(null, rows);
                    } else {
                        callback(err,null);
                    }
                });
            }
        })();
        
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