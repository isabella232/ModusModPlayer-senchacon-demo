cordova.define("org.moduscreate.modplyr.ModPlyr", function(require, exports, module) { 
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');


var ModPlyr = {
    test : function() {
        console.log('JAVA SCRIPT TEST');
        

        var fileCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(function() { 
                // cordova.exec(null,null,'ModPlyr','cdvPlayMod');
            }, null, 'ModPlyr', 'cordovaLoadMod', [data[0].path]);
        }



        var dirCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(fileCallback, null, 'ModPlyr', 'cordovaGetModFiles', [data[0].path]);
        }

        cordova.exec(dirCallback, null, 'ModPlyr', 'cordovaGetModPaths', []);
    }
};


module.exports = ModPlyr;

});
