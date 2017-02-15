/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-14
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/Classes/Support/mqttInfoMsg.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

exports.checkMsg = function(topic,body,db,mqtt) {
    var q = "";
    switch(topic.order) {
        case 'present' :
            if (topic.node === '---') {
                //
                // A new or updated agent description has been received
                // 
                q = "CALL `store_info_agent`( '" + topic.agent + "',"+
                                             "'" + body.rev + "')";
            } else {
                if (topic.device === '---') {
                    //
                    // A new of updated node description has been received
                    //
                    q = "CALL `store_info_node`( '" + topic.agent + "',"+
                                                "'" + topic.node + "',"+
                                                "'" + ((body.rev !== undefined)? body.rev : "---") + "',"+
                                                "'" + ((body.type !== undefined)? body.type : "undef") + "')";
                } else {
                    // 
                    // A new or update device and/or variable have been received
                    //
                    q = "CALL `store_info_variable`('" + topic.agent + "',"+
                                                    "'" + topic.node + "',"+
                                                    "'" + topic.device + "',"+
                                                    "'" + topic.variable + "',"+
                                                    "'" + ((body.datatype !== undefined)? body.datatype : "text") + "',"+
                                                    "'" + ((body.devicetype !== undefined)? body.devicetype : "dynamic") + "',"+
                                                    "'" + ((body.wraparound !== undefined)? body.wraparound : "0") + "',"+
                                                    "'" + ((body.datacoef !== undefined)? body.datacoef : "1.0") + "',"+
                                                    "'" + ((body.dataoffset !== undefined)? body.dataoffset : "0") + "',"+
                                                    "'" + ((body.outvar !== undefined)? body.outvar : "0") + "')";
                }
            }
            db.query(  q, 
                       function(err,rows) {
                            if (err) {
                                // TODO
                            } else {
                            
                            }
                        });
                        
            break;
        case 'request':
            
            break;
        default:
            break;
    }
};