/************************************************************************
 Product    : Home information and control
 Date       : 2016-03-02
 Copyright  : Copyright (C) 2016 Kjeholt Engineering. All rights reserved.
 Contact    : dev@kjeholt.se
 Url        : http://www-dev.kjeholt.se
 Licence    : ---
 ---------------------------------------------------------
 File       : SupportClasses/mqttHandler.js
 Version    : 0.1.0
 Author     : Bjorn Kjeholt
 *************************************************************************/

var mqtt = require('mqtt');

mqttHandler = function(ci) {
    var self = this;
    this.ci = ci;

    console.log("  MqttHandlerClass MqttInfo:",self.ci.mqtt);
    
    var mqttClient = mqtt.connect("mqtt://"+ci.mqtt.ip_addr,
                                  { connectTimeout: 5000 });
    this.ci = ci;

    console.log("MQTT connect :");

    mqttClient.on('connect',function(connack) {
        console.log("MQTT connected :",connack);
        self.subscribe();        
    });
    
    mqttClient.on('error',function(error) {
        console.log("MQTT error :",error);        
    });

    this.topicStrToJson = function (str) {
        var t = str.split("/");
        var result = {group: t[0],
                       order: t[1],
                       agent: '---',
                       node: '---',
                       device: '---',
                       variable: '---' };
        
        if (t[2] !== undefined) { 
            result.agent = t[2];
        
            if (t[3] !== undefined) {
                result.node = t[3];
        
                if (t[4] !== undefined) { 
                    result.device = t[4];
        
                    if (t[5] !== undefined) 
                        result.variable = t[5];
                }
            }
        }
        
        return result;
    };
    
    this.msgStrToJson = function (str) {
        var m = JSON.parse(str);
 
        if (m.time === undefined) 
            m.time = Math.floor((new Date())/1000);
        
        return m;
    };
    
    this.topicJsonToStr = function (topic) {
        var result = "" + topic.order + "/" + topic.suborder;
        switch(topic.order) {
            case 'calc':
                result = result + "/" + topic.calcname;
                break;
            default:
                if (topic.agent !== undefined) {
                    result = result + "/" + topic.agent;
                   
                    if (topic.node !== undefined) {
                        result = result + "/" + topic.node;

                        if (topic.device !== undefined) {
                            result = result + "/" + topic.device;

                            if (topic.variable !== undefined)
                                result = result + "/" + topic.variable;
                        }
                    }
                }

                break;
            }

        return result;
    };
    
    this.publishRaw = function(topicStr,msgStr,qualityOfService,retainMessage) {
        console.log("Publish raw: \nTopic: >>"+ topicStr +"<<\nMessage: >>"+ msgStr + "<<");
        
        mqttClient.publish(topicStr,
                           msgStr,
                           { qos: qualityOfService,
                             retain: retainMessage});
    };
    
    this.publish = function(topic,msgJson) {
        console.log("Publish mqtt message: \n\tTopic:>> "+ self.topicJsonToStr(topic) + "<<\n\tMessage: >>" + JSON.stringify(msgJson) + "<<");
        mqttClient.publish(self.topicJsonToStr(topic),
                              ((msgJson !== undefined)? JSON.stringify(msgJson) : ""),
                              { qos: 0,
                                retain: 0 });
    };
    
    this.sendStatus = function(statusStr) {
        mqttClient.publish("status/alive/---",
                           JSON.stringify({ time: Math.floor((new Date())/1000),
                                            type: statusStr }));
    };
    
    this.subscribe = function() {
        var i = 0;
        
        for (i=0; i < self.ci.mqtt.subscribe.length; i=i+1) {
//            console.log("MQTT subscribe: ", self.ci.mqtt.subscribe[i]);
            mqttClient.subscribe(self.ci.mqtt.subscribe[i].topic);
        }
    };
    
    this.connect = function(connack) {
        self.ci.mqtt.connected = true;
        self.sendStatus("reconnected");
        
        console.log("MQTT connected :",connack);
        self.subscribe();
    };
    
    this.disconnect = function () {
        self.ci.mqtt.connected = false;

        self.mqttClient = mqtt.connect("mqtt://"+ci.mqtt.ip_addr,
                                       { connectTimeout: 5000 });

    };
    
    (function() {
        mqttClient.on('close',(self.disconnect));
        mqttClient.on('message',(self.ci.mqtt.functions.message));
    }());
};

exports.create_mqtt = function (ci) {
    return new mqttHandler(ci);
};




