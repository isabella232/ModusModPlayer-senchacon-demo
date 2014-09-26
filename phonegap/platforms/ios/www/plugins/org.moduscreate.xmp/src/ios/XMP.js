cordova.define("org.moduscreate.xmp.XMP", function(require, exports, module) { 


var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');


var XMP = {
	test : function() {
		console.log('JAVA SCRIPT TEST');
        

        var fileCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(function() { 
                // cordova.exec(null,null,'XMP','cdvPlayMod');
            }, null, 'XMP', 'cdvLoadMod', [data[0].path]);
        }



        var dirCallback = function(data) {
            console.log('dir success')
            console.log(data = JSON.parse(data));

            cordova.exec(fileCallback, null, 'XMP', 'cdvGetModFiles', [data[0].path]);
        }

		cordova.exec(dirCallback, null, 'XMP', 'cdvGetModPaths', []);
	}
};


module.exports = XMP;

});