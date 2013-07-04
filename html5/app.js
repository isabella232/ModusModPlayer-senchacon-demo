/*
    This file is generated and updated by Sencha Cmd. You can edit this file as
    needed for your application, but these edits will have to be merged by
    Sencha Cmd when it performs code generation tasks such as generating new
    models, controllers or views and when running "sencha app upgrade".

    Ideally changes to this file would be limited and most work would be done
    in other places (such as Controllers). If Sencha Cmd cannot merge your
    changes and its generated code, it will produce a "merge conflict" that you
    will need to resolve manually.
*/

// DO NOT DELETE - this directive is required for Sencha Cmd packages to work.
//@require @packageOverrides

//<debug>
Ext.Loader.setPath({
    'Ext': 'touch/src'
});
//</debug>

Ext.application({
    name: 'MMP',

    requires: [
        'Ext.MessageBox'
    ],

    views: [
        'Main'
    ],

    stores : [
        'ModFiles',
        'Directories'
    ],

    icon: {
        '57': 'resources/icons/Icon.png',
        '72': 'resources/icons/Icon~ipad.png',
        '114': 'resources/icons/Icon@2x.png',
        '144': 'resources/icons/Icon~ipad@2x.png'
    },

    isIconPrecomposed: true,

    startupImage: {
        '320x460': 'resources/startup/320x460.jpg',
        '640x920': 'resources/startup/640x920.png',
        '768x1004': 'resources/startup/768x1004.png',
        '748x1024': 'resources/startup/748x1024.png',
        '1536x2008': 'resources/startup/1536x2008.png',
        '1496x2048': 'resources/startup/1496x2048.png'
    },

    launch: function() {
        // Destroy the #appLoadingIndicator element
        Ext.fly('appLoadingIndicator').destroy();

        // Initialize the main view
        this.main = Ext.Viewport.add(Ext.create('MMP.view.Main'));


        cordova.exec(
            Ext.Function.bind(this.onAfterGetDirectories, this),
//            function callback(directories) {
//                directories = Ext.decode(directories);
//                alert(directories[0].path);
//            },
            function errorHandler(err) {
                callback('Nothing to echo');
            },
            'ModPlyr',
            'cordovaGetModPaths',
            ['']
        );
    },

    onAfterGetDirectories : function(directories) {
        directories = Ext.decode(directories);

        var dirStore = Ext.create('MMP.store.Directories', {
                data : directories
            }),
            dirList  = Ext.create('Ext.dataview.List', {
                itemTpl   : '{dirName}',
                store     : dirStore,
                listeners : {
                    scope   : this,
                    itemtap : this.onDirListItemTap
                }
            });

        this.main.add(dirList);

    },

    onDirListItemTap : function(list, index, listItem, record) {

        cordova.exec(
            Ext.Function.bind(this.onAfterGetModFiles, this),
//            function callback(directories) {
//                directories = Ext.decode(directories);
//                alert(directories[0].path);
//            },
            function errorHandler(err) {
                callback('Nothing to echo');
            },
            'ModPlyr',
            'cordovaGetModFiles',
            [record.data.path]
        );
    },

    onAfterGetModFiles : function(files) {
        files = Ext.decode(files);


         var fileStore = Ext.create('MMP.store.ModFiles', {
                data : files
            }),
            fileList  = Ext.create('Ext.dataview.List', {
                itemTpl   : '{fileName}',
                store     : fileStore,
                listeners : {
                    scope   : this,
                    itemtap : this.onFileListItemTap
                }
            });


        this.main.addAndAnimateItem(fileList);
//        this.main.animateActiveItem(fileList, {type:'slide', direction:'right'});
//        this.main.showBackButton();
    },

    onFileListItemTap : function(list, index, listItem, record) {
        debugger;

    },


    onUpdated: function() {
        Ext.Msg.confirm(
            "Application Update",
            "This application has just successfully been updated to the latest version. Reload now?",
            function(buttonId) {
                if (buttonId === 'yes') {
                    window.location.reload();
                }
            }
        );
    }
});
