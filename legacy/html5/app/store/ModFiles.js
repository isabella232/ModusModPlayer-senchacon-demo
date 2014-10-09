Ext.define('Modify.store.ModFiles', {
    extend : 'Ext.data.Store',

    requires : 'Modify.model.ModFile',

    config: {
        model : 'Modify.model.ModFile',
        proxy : {
            type : 'memory'
        }
    }
});