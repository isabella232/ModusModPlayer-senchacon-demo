Ext.define('MMP.store.ModFiles', {
    extend : 'Ext.data.Store',

    requires : 'MMP.model.ModFile',

    config: {
        model : 'MMP.model.ModFile',
        proxy : {
            type : 'memory'
        }
    }
});