/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-16
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : mqtt-manager/js/Classes/healthCheck.js
 Version    : 0.2.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

var healthCheckWeb = require('http');

var healthCheck = function (configInfo) {
    var self = this;
    this.ci = configInfo;
    
    var checkAllHealthyFunctions = function (callback) {
        
        self.ci.health_check.status = "Test in progress";
        
        (function healthCheckLoop(index,callbackLoop) {
                if (index > 0) {
                    console.log("Health check number " + (index-1));
                    
                    (self.ci.health_check.check_functions[index-1])(function(err) {
                            if (!err) {
                                healthCheckLoop(index-1,callbackLoop);
                            } else {
                                callbackLoop({ error:"non-healthy",
                                               test_number:index-1,
                                               info: err });
                            }
                        });
                    
                } else {
                    callbackLoop(null);
                }
            })(self.ci.health_check.check_functions.length,
               function(err) {
                   if (!err) {
                       self.ci.health_check.status = "ok";
                       callback(null);
                   } else {
                       self.ci.health_check.status = "Failing! In test number " + err.test_number;
                       callback(err);
                   }
               });
        
    };
    
    var server = healthCheckWeb.createServer(function(request,response) {
        console.log("HC received:", self.ci.health_check);
        checkAllHealthyFunctions(function(err) {
                if (!err) {
                    response.writeHead(200,{"Content-Type": "text/plain"});
                    response.end("Health status is OK\n");
                } else {
                    response.writeHead(500,{"Content-Type": "text/plain"});
                    response.end("Health status is not OK\n" +
                                 "Test number " + err.test_number + " failed\n" +
                                 "Error info " + JSON.stringify(err) + "");                       
                }
            });
    });
        
    server.listen(self.ci.health_check.port_no);
    
    this.check = function(callback) {
        callback(null);
    };
    
    (function setup() {
            self.ci.health_check.check_functions.push(self.check);
    })();
};

exports.create = function(ci){
    return new healthCheck(ci);
};
