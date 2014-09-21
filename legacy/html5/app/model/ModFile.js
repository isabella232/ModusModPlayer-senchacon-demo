Ext.define("Modify.model.ModFile", {
    extend : 'Ext.data.Model',
    config : {
        fields : [
            'path',
            {
                name : 'fileName'
//                convert : function(v) {
//                    return v.split(' - ')[1];
//                }
            }
        ]
    }
});