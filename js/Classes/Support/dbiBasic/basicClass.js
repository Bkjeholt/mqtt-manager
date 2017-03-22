/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-20
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : dbiClass/basicClass.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

// var waitForPort = require('wait-for-port');
var mysql = require('mysql');

var dbConnectInfo = null;
var dbConnection;
var dbConnected = false;
var dbConnecting = false;

function dbCreateConnection (callback) {
    if (!dbConnected) {
        if (!dbConnecting) {
            dbConnecting = true;
            dbConnection = mysql.createConnection({ host     : dbConnectInfo.ip_addr,
                                                    port     : dbConnectInfo.port_no,
                                                    user     : dbConnectInfo.user,
                                                    password : dbConnectInfo.passw,
                                                    database : dbConnectInfo.scheme });
            dbConnection.connect(function(err) {
                dbConnecting = false;
                if (!err) {
                    dbConnected = true;
                    callback(null);
                } else {
                    callback({ error: "DB failed connection",
                               info: err,
                               db_access: dbConnectInfo });
                }
            });
        } else {
            callback({ error: "DB connecting in progress",
                       info: {},
                       db_access: dbConnectInfo });
        } 
    } else {
        callback(null);
    }
};

dbConnection.on('error', function(err) {
        console.log("DB unhandled error has occured. err=",err); 
        dbConnected = false;
    });

function setup(mysqlInfo) {
    dbConnectInfo = mysqlInfo;
    dbCreateConnection(function(err) {
                            if (err) {
                                // ToDo
                            }
                        });
};

setInterval(function() {
        if (dbConnectInfo) {
            if (!dbConnected) {
                dbCreateConnection(function(err) {
                        if (err) {
                            // ToDo
                        }
                    });
            } else {
                dbConnection.ping(function (err) {
                        if (err) {
                            console.log("DB failed ping, mark the connection as down. err=",err);
                            dbConnected = false;

                        } else {
    //                        console.log('DB Server responded to ping');
                        }
                    });
            }
        } 
    },5000);
 
module.exports = setup;
module.exports = dbBasic;

function dbBasic () {
    var self = this;

    
    dbCreateConnection(function(err) {
            if (!err) {
            } else {
                console.log("dbBasic: Failing to connect to the database. err=",err);
            }
        });
};

dbBasic.prototype.query = function (query, callback) {
        if (dbConnected) {
            this.db.query(query, function(err,error, results, fields) {
                    if (!error) {
                        callback(null, results);
                    } else {
                        callback({ error: "DB query failing",
                                   ecode: 1,
                                   info: { err: error,
                                           results: results,
                                           fields: fields,
                                           query: query } },null);
                    }
                });
        } else {
            callback({ error: "DB not connected, query not executed",
                       ecode: 2,
                       info: { query: query } },null);
        }
    };

dbBasic.prototype.healthCheck = function(callback) {
        if (dbConnected) {
            dbConnection.ping(function (err) {
                    if (err) {
                        dbConnected = false;
                        callback({ error: "DB failed ping, the connection is unhealthy",
                                   info: err });
                    } else {
                        callback(null);
                    }
                });
        } else {
            callback({ error: "DB unconnected, the connection is unhealthy",
                       info: {} });
        }
    };
    
dbBasic.prototype.storeData = function(variableId, sampleTime, sampleData, callback) {
        var q;
        if (dbConnected) {
            q = "CALL `store_data_vid`('"+variableId+"','"+
                                          sampleTime+"','"+
                                          sampleData+"','"+
                                          "Key-"+variableId+"--"+sampleTime+"')";
            this.db.query(q, function(error,results,fields) {
                    if (!err) {
                        callback(null,results[0]);
                    } else {
                        callback({ error: "DB storeData failing",
                                   ecode: 1,
                                   info: { err: error,
                                           results: results,
                                           fields: fields,
                                           query: q } },null);
                    }
                });
        } else {
            callback({ error: "DB not connected, query not executed",
                       ecode: 2,
                       info: { query: query } },null);
            
        }
    };