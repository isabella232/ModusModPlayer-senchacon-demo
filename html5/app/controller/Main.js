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

    buttonTextToXtypeDict : {
        'Patterns' : 'pattern',
        'Spectrum' : 'spectrum'
    },

    updateLoopModeDict : {
        pattern  : 'pattern',
        waveform : 'waveform'
    },

    launch: function() {
        var me = this;


        // Initialize the main view
        me.main = Ext.create('Modify.view.Main', {
            listeners : {
                scope     : me,
                back      : me.stopModPlayerUpdateLoop,
                vizselect : me.onMainVizSelect
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
            function errorHandler(err) {

            },
            'ModPlyr',
            'cordovaGetModPaths',
            ['']
        );

    },

    onAfterGetDirectories : function(directories) {
        directories = Ext.decode(directories);
        var me = this;

        var dirStore = Ext.create('Modify.store.Directories', {
                data : directories
            }),
            dirList  = Ext.create('Ext.dataview.List', {
                itemTpl   : '{dirName}',
                store     : dirStore,
                listeners : {
                    scope   : me,
                    select : me.onDirListItemSelect
                }
            });

        me.main.add(dirList);


        return;
        // TODO: Disable/remove after development
        Ext.Function.defer(function() {
            var r = dirList.getStore().getAt(4);
            me.onDirListItemSelect(dirList, r);
//
            Ext.Function.defer(function() {
                var fileList = me.main.down('#fileList');
                r = fileList.getStore().getAt(1);
                me.onFileListItemSelect(fileList, r);

                setTimeout(function() {
                    var player = Ext.ComponentQuery.query('player')[0];
                    player.fireEvent('play', player);

                    me.onMainVizSelect();

                    setTimeout(function() {
                        var btn = me.actionSheet.getInnerItems()[1];
                        me.actionSheet.hide();
                        me.onVizChange(btn);
                    }, 250)

                }, 50)
            }, 300)

        }, 1);

    },

    onDirListItemSelect : function(list,  record) {
        var me = this;

        Ext.Function.defer(function() {
            list.deselectAll();
        }, 200);


        cordova.exec(
            Ext.Function.bind(me.onAfterGetModFiles, me),
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
                itemId    : 'fileList',
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
                player.setSongName(data.songName);

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

//                me.player.patternView.showPatternAndPosition(0, 0);

//                setTimeout(function(){
//                    me.player.patternView.prevRowNum = me.player.patternView.prevPatternNum -1;
//                    me.player.patternView.showPatternAndPosition(0, 0);
//
                    me.loadMask.hide();
//                }, 150);

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
        if (! this.interval && this.vizMode) {
            console.log('startModPlayerUpdateLoop();');
            var boundTimerFunction = Ext.Function.bind(this.getSongStats, this);
            this.interval = setInterval(boundTimerFunction, 10);
        }
    },

    stopModPlayerUpdateLoop : function() {
        if (this.interval) {
            clearInterval(this.interval);
            delete this.interval;
        }
    },

    getSongStats : function() {

        var me        = this,
            player    = me.player,
            playerViz = player.getInnerAt(0);


//        if (spectrumMode == 0 || spectrumMode == 1) {
//            spectrumMode = 'wavform';
//        }
//        else if (spectrumMode == 2) {
//            spectrumMode = 'spectrum';
//        }


        var dataType = me.updateLoopModeDict[me.vizMode],
            args;

        if (me.vizMode == 'spectrum') {
            var spectrumSize = playerViz.element.getSize(),
                spectrumMode = playerViz.getMode();

            args = [me.vizMode, spectrumSize.width, spectrumSize.height];
        }
        else if (me.vizMode == 'pattern') {
            args = [me.vizMode];
        }
        else {
            args = [];
        }

        cordova.exec(
            function callback(data) {
                player.setStats(data);
            },
            function errorHandler(err) {
                console.log('getSongStats error');
            },
            'ModPlyr',
            'cordovaGetStats',
            args
        );

    },

    onMainVizSelect : function(view) {
        var me = this;

        if (! this.actionSheet) {

            this.actionSheet = Ext.create('Ext.ActionSheet', {
                items : [
                    {
                        text    : 'Patterns',
                        scope   : me,
                        handler : me.onVizChange
                    },
                    {
                        text    : 'Spectrum',
                        scope   : me,
                        handler : me.onVizChange
                    },
                    {
                        text     : 'Note Dots',
                        scope    : me,
                        disabled : true,
                        handler  : me.onVizChange
                    },
                    {
                        text    : 'None',
                        scope   : me,
                        handler : me.onVizChange
                    }
                ]
            });

            Ext.Viewport.add(this.actionSheet);

        }

        this.actionSheet.show();
    },




    onVizChange : function(btn) {
        var me = this,
            player = me.main.down('player'),
            xtype;

        xtype = this.buttonTextToXtypeDict[btn.getText()];

        this.stopModPlayerUpdateLoop();

        player.removeInnerAt(0);
        delete me.vizMode;
//        me.player

        // Give time for the update loop to finish executing!
        Ext.Function.defer(function() {
            if (xtype) {
                console.log('PLAYER adding ' + xtype);
                me.vizMode = xtype;

                var item = player.add({
                    xtype  : xtype,
                    height : '100%'
                });
                me.startModPlayerUpdateLoop();

                if (item.xtype == 'pattern') {
                    item.setPatternData(player.patternData);
                }

                window.vizItem = item;
                window.player = player;
                player.vizItem = item;
            }

            me.actionSheet.hide();
        }, 50);

    }

});