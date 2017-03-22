/************************************************************************
 Product    : Home information and control
 Date       : 2017-03-16
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : dbiCalculate.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 ---------------------------------------------------------
 
 ***************************************************************************/

var dbiCalc = null;
var calculationInProgress = false;
var calculationTime = { start: 0,
                        stop: 0,
                        duration: 0 };

module.exports = dbiCalculate;

function getCurrentTime() {
    return Math.floor(new Date()/1000);
};

function dbiCalculate(dbiBasicObj) {

    dbiCalc = new dbiBasicObj();
};

setInterval(function() {
        var query;
    
        if (dbiCalc !== null) {
            // Get list of calculations with at least one modified input.
        
            query = "CALL `calculate_modified_data`()";
           
            calculationInProgress = true;
            calculationTime.start = getCurrentTime();
            
            this.dbiCalc.query(query,function(err,results) {
                    calculationInProgress = false;
                    calculationTime.duration = getCurrentTime() - calculationTime.start;
                    if (!err) {
                    } else {
                    }
                });
            }
    },2000);
        
    this.healthCheck_db = function(callback) {
        if (dbiCalc !== null ) {
            if (dbiCalc.healthCheck()){
                callback(null);
            } else {
                callback({ error: "non-healthy",
                           info: "dbiCalc: The database is not available" });            
            }
        } else {
            callback({ error: "non-healthy",
                       info: "dbiCalc: The database object is  not connected" });            
            
        }
    };
    
