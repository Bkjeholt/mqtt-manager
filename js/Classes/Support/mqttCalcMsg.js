/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-14
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/Classes/Support/mqttCalcMsg.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

var checkCalcSet = function (calcName, body, db, callback) {
    db.query("CALL `store_calc_active`('" + calcName + "',FALSE)",
            function(err,rows) {
                var query = "";
                var i;
                                          
                if (err) {
                    console.log("Error: StoreCalcActive");
                } else {
                    db.query("CALL `store_calc`( '" + calcName + "'," +
                                               "'" + body.order +"'," +
                                                               "'" + body.output.agent +"'," +
                                                               "'" + body.output.node +"'," +
                                                               "'" + body.output.device +"'," +
                                                               "'" + body.output.variable + "')", function (err,rows) {
                            var query = "";
                                                                
                            if (err) {
                                                console.log("Error: StoreCalcActive");
                            } else {
                                                numberOfOutstandingQueries = numberOfOutstandingQueries-1;
                            }
                        });
                                    
                                    (function storeCalcInputLoop(i,callback) {
                                            var query = "";
                                            if (i > 0) {
                                                query = "CALL `store_calc_input`( '" + calcName + "'," +
                                                                                 "'" + body.inputs[i-1].agent +"'," +
                                                                                 "'" + body.inputs[i-1].node +"'," +
                                                                                 "'" + body.inputs[i-1].device +"'," +
                                                                                 "'" + body.inputs[i-1].variable + "')";
                                                db.query(query, function(err,rows){
                                                      if (err) {
                                                          console.log("Store calc input Error: ",err);
                                                          callback(err);
                                                      } else {
                                                          storeCalcInputLoop(i-1,callback);
                                                      }
                                                  });
                                            } else {
                                                callback(null);
                                            }

                                        })(body.inputs.length,
                                            function (err) {
                                                // All calc inputs are stored in the database
                                                if (!err) {
                                                    (function storeCalcParamLoop(i, callback) {
                                                            var query = "";
                                                            if (i > 0) {
                                                                query = "CALL `store_calc_param`('" + calcName + "'," +
                                                                                                "'" + body.params[i-1].name +"'," +
                                                                                                "'" + body.params[i-1].value +"')";
                                                                db.query(query, function(err,rows){
                                                                        if (err) {
                                                                            callback(err);
                                                                            console.log("Error: ");
                                                                        } else {
                                                                            storeCalcParamLoop(i-1,callback);
                                                                        }
                                                                    });
                                                            } else {
                                                                callback(null);
                                                            }
                                                    })(body.params.length, 
                                                        function(err) {
                                                            if (!err) {
                                                                db.query("CALL `store_calc_active`('" + calcName + "',TRUE)", 
                                                                        function(err,rows) {
                                                                                if (err) {
                                                                                    console.log("Error: ");
                                                                                } else {
                                                                                } 
                                                                            });

                                                            }
                                                       });
                                                }
                                            });
                                              
                                             
                                          }
                                      });

};

var checkCalcRequest = function (calcName, db, callback) {
    db.query("SELECT `get_calc_list`('" + calcName + "')",
             function(err,rows) {
                    var resultJson = [];
                    if (err){
                        console.log("Error: Not possible to execute db query 'get_calc_list'");
                        
                        callback(err,[{topic: {},body:{}}]);
                    } else {
                        /*
                         * The query resulted in a response string according 
                         * to (without Whitespaces):
                         * [ { name: CalcName,
                         *     type: CalcOrder,
                         *     active: 1,
                         *     dst: { agent:AgentName,
                         *            node:NodeName,
                         *            device: DeviceName,
                         *            variable: VariableName },
                         *     srcs: [ { agent:AgentName,
                         *               node:NodeName,
                         *               device: DeviceName,
                         *               variable: VariableName },
                         *           ] }
                         *   }
                         * ]
                         */ 
                        
                        try {
                            resultJson = JSON.parse(rows[0]);
                        } catch (e) {
                            err = {
                                        error: "Malformatted message",
                                        calcname: ">>>"+calcName+"<<<",
                                        body: ">>>"+body+"<<<",
                                        query: "SELECT `get_calc_list`('" + calcName + "')"
                                    };
                            resultJson = [{error: "Malformatted calc list from mysql (" + rows[0] + ")"}];
                        };
                        
                        (function sendMqttMsg (i) {
                            if (i > 0) {
                                callback(null,{
                                                topic: {
                                                    group: "calc",
                                                    order: "list",
                                                    agent: (calcName !== '---')? calcName : undefined },
                                                body: resultJson[i-1] });
                                sendMqttMsg(i-1);
                            }
                        })(resultJson.length);
                        
                        console.log("get_calc_list -> " + JSON.stringify(resultJson));
                    }
                });
    
};

exports.checkMsg = function(topic,body,db,callback) {
    topic.calcname = (topic.agent !== '---')? topic.agent : 'undefined';
    switch(topic.order) {
        case 'set':
            if (topic.calcname !== 'undefined') {
                //
                checkCalcSet(topic.calcname, body, db, callback);
            }
            break;
        case 'clear':
            break;
        case 'request':
            checkCalcRequest(topic.calcname, db, callback);
            break;
                    
        default:
            break;
    }
};