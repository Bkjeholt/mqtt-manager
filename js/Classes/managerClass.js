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
 Mqtt format: topic: group/order/agent/node/device/variable
                        group       order           Comment
                        -------     ----------      --------------------------
                        data        present
                                    request
                        info        present
                                    list
                        status      alive

              message: // sub device data
                        { time: UnixTimeStamp,
                          data: Data information }
                       // agent information
                        { time: UnixTimeStamp,
                          name: AgentName,
                          rev:  AgentRevision }
                       // device information
                        { time: UnixTimeStamp,
                          name: DeviceName,
                          rev:  DeviceRevision }
                       // sub device information
                        { time: UnixTimeStamp,
                          name: SubDeviceName,
                          rev:  SubDeviceRevision,
                          det:  SubDeviceType, // I.e. dynamic, static, semistatic
                          dat:  SudDeviceDataType, // I.e. float, int, bool, text
                          wrap: WrapAroundValue    }

 **************************************************************************/

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
    
    this.mqttMessage = function(topicStr, messageStr, packet) {
        /*
         * topic {
         *      order   
         *      agent     AgentName
         *      device    DeviceName
         *      variable  VariableName
         *    }
         */
        var topic = self.mqtt.topicStrToJson(topicStr);
        var message = self.mqtt.msgStrToJson(messageStr);
        
        console.log("MQTT topic:   " + topicStr);
        console.log("MQTT message: " + messageStr);
        
        switch (topic.group) {
            case 'data':
                switch (topic.order) {
                    case 'present' :
                        self.db.query(  "CALL `store_data`('" + topic.agent + "',"+
                                                          "'" + topic.node + "',"+
                                                          "'" + topic.device + "',"+
                                                          "'" + topic.variable + "',"+
                                                          "'" + message.time + "',"+
                                                          "'" + message.data + "')", 
                                        function(err,rows) {
                                            if (err) {
                                                // TODO
                                            } else {
                            
                                            }
                                        });                        
                        break;
                    case 'request':
                        self.db.query("CALL `get_data`( '" + topic.agent+"',"+
                                                       "'" + topic.node + "',"+
                                                       "'" + topic.device + "',"+
                                                       "'" + topic.variable + "')", 
                                        function(err,rows) {
                                            var data_time;
                                            var data_value = "";
                                
                                            if (err) {
                                                // TODO
                                            } else {
                                                if (rows[0].length > 0) {
                                                    /*
                                                     * 
                                                     */

                                                    self.mqtt.publish({ order: "data",
                                                                        suborder: "set",
                                                                        agent: topic.agent,
                                                                        node: topic.node,
                                                                        device: topic.device,
                                                                        variable: topic.variable },
                                                                      rows[0][0].message_body );

                                                } else {
/*                                                    self.mqtt.publish({ order: "data",
                                                                        suborder: "resp",
                                                                        agent: topic.agent,
                                                                        node: topic.node,
                                                                        device: topic.device,
                                                                        subdevice: topic.subdevice },
                                                                      { error: "No data available" });
*/                                                    
                                                }
                                            }
                                        });
                            break;
                    default:
                        break;
                }
                
                break;
            case 'info':
                switch (topic.order) {
                    case 'present' :
                        var q = "";
                        if (topic.node === '---') {
                            //
                            // A new or updated agent description has been received
                            // 
                            q = "CALL `store_info_agent`('" + topic.agent + "',"+
                                                        "'" + message.rev + "')";
                        } else {
                            if (topic.device === '---') {
                                //
                                // A new of updated node description has been received
                                //
                                q = "CALL `store_info_node`('" + topic.agent + "',"+
                                                           "'" + topic.node + "',"+
                                                           "'" + ((message.rev !== undefined)? message.rev : "---") + "',"+
                                                           "'" + ((message.type !== undefined)? message.type : "undef") + "')";
                            } else {
                                // 
                                // A new or update device and/or variable have been received
                                //
                                
/*                              if (topic.variable === '---') {
                                    q = "CALL `store_info_device`('" + topic.agent + "',"+
                                                                 "'" + topic.node + "',"+
                                                                 "'" + topic.device + "',"+
                                                                 "'" + message.datatype + "',"+
                                                                 "'" + message.devicetype + "',"+
                                                                 "'" + message.wraparound + "',"+
                                                                 "'" + message.datacoef + "',"+
                                                                 "'" + message.dataoffset + "')";
                                } else { */
                                    q = "CALL `store_info_variable`('" + topic.agent + "',"+
                                                                   "'" + topic.node + "',"+
                                                                   "'" + topic.device + "',"+
                                                                   "'" + topic.variable + "',"+
                                                                   "'" + ((message.datatype !== undefined)? message.datatype : "text") + "',"+
                                                                   "'" + ((message.devicetype !== undefined)? message.devicetype : "dynamic") + "',"+
                                                                   "'" + ((message.wraparound !== undefined)? message.wraparound : "0") + "',"+
                                                                   "'" + ((message.datacoef !== undefined)? message.datacoef : "1.0") + "',"+
                                                                   "'" + ((message.dataoffset !== undefined)? message.dataoffset : "0") + "',"+
                                                                   "'" + ((message.outvar !== undefined)? message.outvar : "0") + "')";
//                                }
                            }
                        }
                        self.db.query(  q, 
                                        function(err,rows) {
                                            if (err) {
                                                // TODO
                                            } else {
                            
                                            }
                                        });                        
                        break;
                    default:
                        break;
                }
                break;
            case 'calc':
                switch (topic.order) {
                    case 'set':
                        
                        self.db.query("CALL `store_calc_active`('" + topic.agent + "',FALSE)",
                                      function(err,rows) {
                                          var query = "";
                                          var i;
                                          var numberOfOutstandingQueries = message.srcaddr.length + message.param.length + 1;
                                          
                                          if (err) {
                                              console.log("Error: StoreCalcActive");
                                          } else {
                                              query = "CALL `store_calc`('" + topic.agent + "'," +
                                                                        "'" + message.type +"'," +
                                                                        "'" + message.dstaddr.agent +"'," +
                                                                        "'" + message.dstaddr.node +"'," +
                                                                        "'" + message.dstaddr.device +"'," +
                                                                        "'" + message.dstaddr.variable + "')";
                                              self.db.query(query,
                                                            function (err,rows) {
                                                                var query = "";
                                                                
                                                                if (err) {
                                                                    console.log("Error: StoreCalcActive");
                                                                } else {
                                                                    numberOfOutstandingQueries = numberOfOutstandingQueries-1;
                                                                }
                                              });
                                              
                                              for (i=0; i < message.srcaddr.length; i=i+1) {
                                                  query = "CALL `store_calc_input`('" + topic.agent + "'," +
                                                                                  "'" + message.type +"'," +
                                                                                  "'" + message.srcaddr[i].agent +"'," +
                                                                                  "'" + message.srcaddr[i].node +"'," +
                                                                                  "'" + message.srcaddr[i].device +"'," +
                                                                                  "'" + message.srcaddr[i].variable + "')";
                                                  self.db.query(query, function(err,rows){
                                                      if (err) {
                                                          console.log("Error: ");
                                                      } else {
                                                          numberOfOutstandingQueries = numberOfOutstandingQueries-1;
                                                      }
                                                  });
                                              }
                                              
                                              for (i=0; i < message.param.length; i=i+1) {
                                                  query = "CALL `store_calc_param`('" + topic.agent + "'," +
                                                                                  "'" + message.param[i].name +"'," +
                                                                                  "'" + message.param[i].value +"')";
                                                  self.db.query(query, function(err,rows){
                                                      if (err) {
                                                          console.log("Error: ");
                                                      } else {
                                                          numberOfOutstandingQueries = numberOfOutstandingQueries-1;
                                                      }
                                                  });
                                              }
                                              
                                              self.db.query("CALL `store_calc_active`('" + topic.agent + "',TRUE)", 
                                                            function(err,rows) {
                                                                if (err) {
                                                                    console.log("Error: ");
                                                                } else {
                                                                    numberOfOutstandingQueries = numberOfOutstandingQueries-1;
                                                                } 
                                                            });
                                             
                                          }
                                      });
                        break;
                    case 'clear':
                        break;
                    case 'request':
                        self.db.query("SELECT `get_calc_list`()",
                                      function(err,rows) {
                                            if (err){
                                                console.log("Error: Not possible to execute db query 'get_calc_list'");
                                            } else {
                                                console.log("get_calc_list -> " + JSON.stringify(rows[0]));
                                            }
                                      });
                        break;
                    
                    default:
                        break;
                }
                break;
            default:
                break;
        };
    };
    
    (function setup () {
        console.log("--------------------------------------------------------");
        console.log("Package name:    " + self.ci.config.name);
        console.log("Package version: " + self.ci.config.rev);
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: ci=",self.ci);
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: Preparation");
        self.ci.mqtt.functions.message = self.mqttMessage;        
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: Initiate MQTT sub class");
        self.mqtt = mqttHandler.create(self.ci);
        console.log("--------------------------------------------------------");
        console.log("ManagerClass: Initiate Database sub class");
        self.db = databaseClass.create(self.ci);
        console.log("--------------------------------------------------------");
        
    }());
    
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


