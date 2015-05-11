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
        'Patterns'  : 'pattern',
        'Spectrum'  : 'spectrum',
        'Note Dots' : 'notedots'
    },

    updateLoopModeDict : {
        pattern  : 'pattern',
        notedots : 'pattern',
        waveform : 'waveform'
    },

    launch: function() {
        var me = this;

        // Initialize the main view
        me.main = Ext.create('Modify.view.Main', {
            listeners : {
                scope     : me,
                back      : me.unbindGlobalUpdateMethod,
                vizselect : me.onMainVizSelect
            }
        });

        window.updatePlayerViewPattern = Ext.emptyFn;


        cordova.exec(
            Ext.emptyFn,
            Ext.emptyFn,
            'MCModPlayerInterface',
            'boot',
            ['']
        );


/*
    <feature name="MCKGMP">
        <param name="ios-package" value="MCModPlayerInterface" />
        <param name="ios-package" value="MCFsTool" />
    </feature>
*/

        Ext.Viewport.add(me.main);
        me.main.show();

        if (Ext.os.is.iOS && Ext.os.version.major >= 7) {
            Ext.select(".x-toolbar").applyStyles("height: 62px; padding-top: 15px;");
        }

        me.loadMask = Ext.Viewport.add({
            hidden  : true,
            xtype   : 'loadmask',
            message : 'Loading...'
        });
        // alert('open debugger');


        cordova.exec(
            Ext.Function.bind(me.onAfterGetDirectories, me),
            function errorHandler(err) {

            },
            'MCFsTool',
            'getDirectoriesAsJson',
            ['']
        );

    },

    unbindGlobalUpdateMethod : function() {
        window.updatePlayerViewPattern = Ext.emptyFn;
   
    },

    bindGlobalUpdateMethod : function() {
        var me = this;
        window.updatePlayerViewPattern = Ext.Function.bind(this.onPatternUpdate, this);
    },

    onPatternUpdate : function(order, pattern, row) {
        // console.log(this, order, pattern, row)
        if (this.player) {
            this.player.updatePatternView(order, pattern, row);
        }
        else {
            console.log("NO PLAYER!!")
        }
    },

    onAfterGetDirectories : function(directories) {
        directories = Ext.decode(directories);
        

        var me = this,
            dirStore = Ext.create('Modify.store.Directories', {
                data : directories
            }),
            dirList  = Ext.create('Ext.dataview.List', {
                itemTpl   : '{name}/',
                store     : dirStore,
                listeners : {
                    scope  : me,
                    select : me.onDirListItemSelect
                }
            });


        me.main.add(dirList);


        return;
        // TODO: Disable/remove after development
        Ext.Function.defer(function() {
            var r = dirList.getStore().getAt(0);
            me.onDirListItemSelect(dirList, r);

            Ext.Function.defer(function() {
                var fileList = me.main.down('#fileList');
                r = fileList.getStore().getAt(0);
                me.onFileListItemSelect(fileList, r);

                setTimeout(function() {
                    var player = Ext.ComponentQuery.query('player')[0];

                    me.onMainVizSelect();

                    setTimeout(function() {
                        var btn = me.actionSheet.getInnerItems()[2];
                        me.actionSheet.hide();
                        me.onVizChange(btn);
                    }, 250)

                }, 50)
            }, 300)

        }, 1);

    },

    onDirListItemSelect : function(list,  record) {
        var me = this;

        // Ext.Function.defer(function() {
        //     list.deselectAll();
        // }, 200);

        cordova.exec(
            Ext.Function.bind(me.onAfterGetModFiles, me),
            function errorHandler(err) {

            },
            'MCFsTool',
            'getDirectoriesAsJson',
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
                itemTpl   : '{name}',
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

        // Ext.Function.defer(function() {
        //     list.deselectAll();
        // }, 200);

        var player = me.player = Ext.create('Modify.view.ModPlayer', {
            data : record.data,

            listeners : {
                play : function(view) {
                    cordova.exec(
                        function callback(data) {
                            player.isPlaying = true;
                            me.startModPlayerUpdateLoop();
                        },
                        function errorHandler(err) {
                            callback('Nothing to echo');
                        },
                        'MCModPlayerInterface',
                        'resume',
                        []
                    );

                },
                pause : function() {
                    me.stopModPlayerUpdateLoop();
                    player.isPlaying = false;

                    cordova.exec(
                        Ext.emptyFn,
                        Ext.emptyFn,
                        'MCModPlayerInterface',
                        'pause',
                        []
                    );
                }
            }

        });


        // me.loadMask.show();

        // Load file
        cordova.exec(
            function callback(modInfo) {
                modInfo = JSON.parse(modInfo)[0];
                console.log(modInfo)

                // debugger;
                player.setSongName(modInfo);
                // me.getPatternData(modInfo.patterns);
                me.injectPatternView(modInfo);
                //

            },
            function errorHandler(err) {
                me.loadMask.hide();

            },
            'MCModPlayerInterface',
            'loadFile',
            [data.path]
        );


        this.main.addAndAnimateItem(this.player);
    },


    getPatternData : function(path) {
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
            'MCModPlayerInterface',
            'getAllPatterns',
            [path]
        )
    },

    startModPlayerUpdateLoop : function() {
        this.bindGlobalUpdateMethod();
        // if (! this.interval && this.vizMode) {
        //     console.log('startModPlayerUpdateLoop();');
        //     var boundTimerFunction = Ext.Function.bind(this.getSongStats, this);
        //     this.interval = setInterval(boundTimerFunction, 40);
        // }
    },

    stopModPlayerUpdateLoop : function() {
        this.unbindGlobalUpdateMethod();
        // if (this.interval) {
        //     clearInterval(this.interval);
        //     delete this.interval;
        // }
    },

    getSongStats : function() {

        var me        = this,
            player    = me.player,
            playerViz = player.getInnerAt(0);


        var dataType = me.updateLoopModeDict[me.vizMode],
            args;

        if (me.vizMode == 'spectrum') {
            var spectrumSize = playerViz.element.getSize(),
                spectrumMode = playerViz.getMode();

            args = [me.vizMode, spectrumSize.width, spectrumSize.height];
        }
        else if (me.vizMode == 'pattern' || me.vizMode == 'notedots') {
            args = ['pattern'];
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

    injectPatternView : function(modInfo) {
        this.stopModPlayerUpdateLoop();

        var xtype = 'patternview',
            player = this.player;


        player.removeInnerAt(0);
        delete this.vizMode;

        // Give time for the update loop to finish executing!
        this.vizMode = xtype;

        var item = player.add({
            xtype       : xtype,
            height      : '100%',
            patternData : modInfo.patterns
        });

        item.prevRowNum = -1;
        item.showPatternAndPosition(0, modInfo.currentPat, 0);
        // item.setPatternData(modInfo.patterns);
        // if (item.setPatternData) {
        //     item.setPatternData(player.patterns);
        // }

        this.startModPlayerUpdateLoop();

        window.vizItem = item;
        window.player  = player;
        player.vizItem = item;
    },

    onVizChange : function(btn) {
        var me     = this,
            player = me.main.down('player'),
            xtype;

        xtype = this.buttonTextToXtypeDict[btn.getText()];

        this.stopModPlayerUpdateLoop();

        player.removeInnerAt(0);
        delete me.vizMode;
        if (xtype) {
            // console.log('PLAYER adding ' + xtype);
            me.vizMode = xtype;

            var item = player.add({
                xtype  : xtype,
                height : '100%'
            });
            me.startModPlayerUpdateLoop();

            if (item.setPatternData) {
                item.setPatternData(player.patternData);
            }


            window.vizItem = item;
            window.player = player;
            player.vizItem = item;
        }

        me.actionSheet.hide();
    }

});