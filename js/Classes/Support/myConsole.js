/************************************************************************
 Product    : Home information and control
 Date       : 2017-02-17
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : Support/myConsole.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/
'use strict';

var debug = false;

var myConsole = Object.setPrototypeOf({
  log(message, ...args) {
    
  }
}, console);

module.exports = myConsole;
function doSomething() {
    
}

// Functions which will be available to external callers
exports.doSomething = doSomething;
