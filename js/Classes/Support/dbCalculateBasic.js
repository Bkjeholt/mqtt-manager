/************************************************************************
 Product    : Home information and control
 Date       : 2017-03-16
 Copyright  : Copyright (C) 2017 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 -------------------------------------------------------------------------
 File       : mqtt-manager/js/Classes/Support/dbCalculateBasic.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

/*
 *  
 */
exports.calculate = function(varId,callback) {
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