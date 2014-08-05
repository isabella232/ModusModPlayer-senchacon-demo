Ext.define('Modify.store.Directories', {
    extend : 'Ext.data.Store',

    requires : 'Modify.model.Directory',

    config: {
        model : 'Modify.model.Directory',
        proxy : {
            type : 'memory'
        }
    }
});