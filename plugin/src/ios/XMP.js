var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');


var XMP = {
	test : function() {
		console.log('JAVA SCRIPT TEST');

		cordova.exec(null, null, 'XMP', 'test', []);
	}
};


module.exports = XMP;