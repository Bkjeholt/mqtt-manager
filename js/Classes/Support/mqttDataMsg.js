/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-14
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/Classes/Support/mqttDataMsg.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

var calculate = function()
exports.checkMsg = function(topic,body,db,callback) {
    switch(topic.order) {
        case 'present' :
            if (body.data !== undefined) {
                db.query(  "CALL `store_data`('" + topic.agent + "',"+
                                            "'" + topic.node + "',"+
                                            "'" + topic.device + "',"+
                                            "'" + topic.variable + "',"+
                                            "'" + body.time + "',"+
                                            "'" + body.data + "')", 
                    function(err,rows) {
                            if (err) {
                                                // TODO
                            } else {
                            
                            }
                        });
            } else {
                // Missing data field in the body
            }
            break;
        case 'request':
            db.query("CALL `get_data`( '" + topic.agent+"',"+
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
                                                    callback(null, { topic: { group: "data",
                                                                              order: "set",
                                                                              agent: topic.agent,
                                                                              node: topic.node,
                                                                              device: topic.device,
                                                                              variable: topic.variable },
                                                                     body: rows[0][0].message_body });

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
};