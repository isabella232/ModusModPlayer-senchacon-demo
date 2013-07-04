Ext.define('MMP.store.Directories', {
    extend : 'Ext.data.Store',

    requires : 'MMP.model.Directory',

    config: {
        model : 'MMP.model.Directory',
        proxy : {
            type : 'memory'
        }
    }
});