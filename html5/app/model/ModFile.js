(function() {
var splitter = ' - ';

Ext.define("Modify.model.ModFile", {
    extend : 'Ext.data.Model',
    config : {
        fields : [
            'path',
            {
                name : 'name',
                convert : function(v) {
                   return v ? v.split(splitter)[1] :'';
                }
            }
        ]
    }
});

})();