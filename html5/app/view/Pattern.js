Ext.define('Modizer.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'pattern',
    config : {
        html        : 'PATTERN VIEW HERE',
        style       : 'border: 1px solid #F00',
        patternData : null
    },

    setPatternData : function(patternData) {

//        alert('open debugger');
        console.log(patternData);
        debugger;

    }

});