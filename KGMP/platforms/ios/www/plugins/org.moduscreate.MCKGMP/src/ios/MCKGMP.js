cordova.define("org.moduscreate.MCKGMP.MCKGMP", function(require, exports, module) { 
var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');


var MCKGMP = {
    test : function() {
        console.log('JAVA SCRIPT TEST');
        

        var fileCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(function() { 
                // cordova.exec(null,null,'MCKGMP','cdvPlayMod');
            }, null, 'MCKGMP', 'cdvLoadMod', [data[0].path]);
        }



        var dirCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(fileCallback, null, 'MCKGMP', 'cdvGetModFiles', [data[0].path]);
        }

        cordova.exec(dirCallback, null, 'MCKGMP', 'cdvGetModPaths', []);
    }
};


module.exports = MCKGMP;

});
