/************************************************************************
 Product    : Home information and control
 Date       : 2017-03-17
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/Classes/Support/calcMin.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

module.exports = calculate;

function calculate(dbi, calcId, sampleTime, callback){
    var query = "SELECT `calc`.`variable_id` AS `DstVariableId` " + 
                    "FROM `calc` " +
                    "WHERE (`calc`.`id` = '" + calcId + "'); " + 
                "SELECT `calc_input`.`variable_id` AS `SrcVariableId`," + 
                       "`get_data_time`(`calc_input`.`variable_id`,'" + sampleTime + "') AS `SrcDataString` " +
                    "FROM `calc_input` " +
                    "WHERE (`calc_input`.`calc_id` = '" + calcId + "') " +
                    "ORDER BY `calc_input`.`id` ASC;" +
                "SELECT `calc_param`.`name` AS `ParamName`, " +
                       "`calc_param`.`value` AS `ParamValue` " +
                    "FROM `calc_param` " +
                    "WHERE (`calc_param`.`calc_id` = '" + calcId + "'); " +
                    "ORDER BY `calc_param`.`id` ASC";
    dbi.query(query, function(err, results) {
            if (!err) {
                
                (function loop(i, value, callback) {
                    var srcData;
                    if (i > 0) {
                        srcData = Number(results[1][i-1].SrcDataString);
                        if (value === null)
                            loop(i-1, 
                                 srcData, 
                                 callback);
                        else 
                            loop(i-1, 
                                 (srcData < value)? srcData : value, 
                                 callback);
                    } else {
                        callback(null,value);
                    }
                })( results[1].length, 
                    null, 
                    function(err,data) {
                        if (!err) {
                            callback(null, { time: sampleTime,
                                             variableid: results[0][0].DstVariableId, 
                                             data: data });
                        } else {
                            callback(err,null);
                            //ToDo
                        }
                        });
            } else {
                callback({ error: "CalcMin initial query failing",
                           info: { err: err,
                                   results: results,
                                   query: query } }, null);
            }
        });
};
