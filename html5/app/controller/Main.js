Ext.define('Modify.controller.Main', {
   extend : 'Ext.app.Controller',

    config : {
        views : [
            'Main',
            'ModPlayer',
            'Spectrum'
        ],

        stores : [
            'ModFiles',
            'Directories'
        ]
    },

    launch: function() {
        var me = this;


        // Initialize the main view
        me.main = Ext.create('Modify.view.Main', {
            listeners : {
                back : function() {
                    me.stopModPlayerUpdateLoop();
                }
            }
        });


        Ext.Viewport.add(me.main);
        me.main.show();

        if (Ext.os.is.iOS && Ext.os.version.major >= 7) {
            Ext.select(".x-toolbar").applyStyles("height: 62px; padding-top: 15px;");
        }

        me.loadMask = Ext.Viewport.add({
            hidden  : true,
            xtype   : 'loadmask',
            message : 'Loading patterns'
        });

        cordova.exec(
            Ext.Function.bind(me.onAfterGetDirectories, me),
//            function callback(directories) {
//                directories = Ext.decode(directories);
//                alert(directories[0].path);
//            },
            function errorHandler(err) {

            },
            'ModPlyr',
            'cordovaGetModPaths',
            ['']
        );
    },

    onAfterGetDirectories : function(directories) {
        directories = Ext.decode(directories);

        var dirStore = Ext.create('Modify.store.Directories', {
                data : directories
            }),
            dirList  = Ext.create('Ext.dataview.List', {
                itemTpl   : '{dirName}',
                store     : dirStore,
                listeners : {
                    scope   : this,
                    select : this.onDirListItemSelect
                }
            });

        this.main.add(dirList);

    },

    onDirListItemSelect : function(list,  record) {
        var me = this;

        Ext.Function.defer(function() {
            list.deselectAll();
        }, 200)

//        if (this.main.isAnimating) {
//            return;
//        }
//
//        this.main.isAnimating = true;

        cordova.exec(
            Ext.Function.bind(me.onAfterGetModFiles, me),
//            function callback(directories) {
//                directories = Ext.decode(directories);
//                alert(directories[0].path);
//            },
            function errorHandler(err) {

            },
            'ModPlyr',
            'cordovaGetModFiles',
            [record.data.path]
        );
    },

    onAfterGetModFiles : function(files) {
        files = Ext.decode(files);
        var me        = this,
            fileStore = Ext.create('Modify.store.ModFiles', {
                data : files
            }),
            fileList = Ext.create('Ext.dataview.List', {
                itemTpl   : '{fileName}',
                store     : fileStore,
                flex      : 1,
                listeners : {
                    scope  : me,
                    select : me.onFileListItemSelect
                }
            });

        me.main.addAndAnimateItem(fileList);
    },

    onFileListItemSelect : function(list, record) {
        var me   = this,
            data = record.data;

        Ext.Function.defer(function() {
            list.deselectAll();
        }, 200);

        var player = me.player = Ext.create('Modify.view.ModPlayer', {
            data : record.data,

            listeners : {
                play : function(view) {
                    cordova.exec(
                        function callback(data) {
//                            console.log(data);
                            player.isPlaying = true;
                            me.startModPlayerUpdateLoop();
                        },
                        function errorHandler(err) {
                            callback('Nothing to echo');
                        },
                        'ModPlyr',
                        'cordovaPlayMod',
                        []
                    );

                },
                stop : function() {
                    player.isPlaying = false;
                    me.stopModPlayerUpdateLoop();

                    cordova.exec(
                        Ext.Function.bind(me.onAfterGetModFiles, me),
            //            function callback(directories) {
            //                directories = Ext.decode(directories);
            //                alert(directories[0].path);
            //            },
                        function errorHandler(err) {

                        },
                        'ModPlyr',
                        'cordovaStopMusic',
                        []
                    );
                }
            }

        });


        me.loadMask.show();

        // Load file
        cordova.exec(
            function callback(data) {
                player.setSongName(data);

                me.getPatternData();

            },
            function errorHandler(err) {
                me.loadMask.hide();

            },
            'ModPlyr',
            'cordovaLoadMod',
            [data.path]
        );



        this.main.addAndAnimateItem(this.player);
    },


    getPatternData : function() {
        var me = this;
        cordova.exec(
            function callback(patternData) {
//                debugger;
                me.player.setPatternData(patternData);
                me.loadMask.hide();


            },
            function errorHandle(err) {
                if (err == "notready") {
                    Ext.Function.defer(me.getPatternData, 50, me);
                    return;
                }

                me.loadMask.hide();

                me.player.setPatternData('none');
            },
            'ModPlyr',
            'cordovaGetPatternData',
            []
        )
    },

    startModPlayerUpdateLoop : function() {
        if (! this.interval) {
            var boundTimerFunction = Ext.Function.bind(this.getSongStats, this);
            this.interval = setInterval(boundTimerFunction, 20);
        }
    },

    stopModPlayerUpdateLoop : function() {
        if (this.interval) {
            clearInterval(this.interval);
            delete this.interval;
        }
    },

    getSongStats : function() {

        var me           = this,
            player       = me.player;
//            spectrum     = player.spectrum
//            spectrumSize = spectrum.element.getSize(),
//            spectrumMode = spectrum.getMode();


//        if (spectrumMode == 0 || spectrumMode == 1) {
//            spectrumMode = 'wavform';
//        }
//        else if (spectrumMode == 2) {
//            spectrumMode = 'spectrum';
//        }

        cordova.exec(
            function callback(data) {

                player.setStats(data);
            },
            function errorHandler(err) {
                console.log('getSongStats error');
            },
            'ModPlyr',
            'cordovaGetStats',
            []
//            [spectrumMode, spectrumSize.width, spectrumSize.height]
        );

    }

});