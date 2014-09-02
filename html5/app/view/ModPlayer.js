Ext.define('Modify.view.ModPlayer', {
    extend : 'Ext.Container',

    xtype : 'player',

    config : {
        layout : 'auto',

        patternData : null,

        items  : [
            {
                xtype  : 'component',
                itemId : 'songStatus',
                style  : 'text-align:center;',
                height : 40,
                docked : 'top',
                tpl    : [
                    '<div style="font-size: 14px; font-weight: bold; text-align:center;">{songName}</div>',
                    '<div style="font-size: 12px;text-align:center;">{fileName}</div>'
                ]
            },
//            {
//                xtype : 'pattern',
//                height : '100%'
//            },
//            {
//                xtype  : 'component',
//                itemId : 'spectrum',
//                flex   : 1
//            },
            {
                xtype    : 'toolbar',
                docked   : 'bottom',
                defaults : {
                    xtype : 'button'
                },
                items    : [
                    { xtype : 'spacer' },
                    {
                        text   : '&lt;&lt;',
                        itemId : 'rewindbtn'
                    },
                    {
                        text   : 'Play',
                        itemId : 'playbtn',
                        ui     : 'confirm'
                    },
                    {
                        text   : '&gt;&gt;',
                        itemId : 'fastforwardbtn'
                    },
                    {
                        text   : 'STOP',
                        itemId : 'stopbtn',
                        ui     : 'decline'
                    },
                    { xtype : 'spacer' }
                ]
            }
        ],

        control : {
            '#rewindbtn' : {
                tap : 'onRewindBtnTap'
            },
            '#playbtn' : {
                tap : 'onPlayBtnTap'
            },
            '#fastforwardbtn' : {
                tap : 'onFastForwardBtnTap'
            },
            '#stopbtn' : {
                tap : 'onStopBtnTap'
            }
        },

        emptyStats : {
            cpu     : '--',
            order   : '--',
            pattern : '--',
            row     : '--'
        }
    },

    initialize : function() {
        var data = this.getData();
        this.down('#songStatus').setData(data.fileName);
//        this.spectrum = this.down('spectrum');
//        this.patternView = this.down('pattern');
        this.callParent();
    },

    onRewindBtnTap : function() {
        this.fireEvent('rewind', this);
    },

    onPlayBtnTap : function() {
        if (this.isPlaying) {
            return;
        }
        this.fireEvent('play', this);
    },

    onFastForwardButtonTap : function() {
        this.fireEvent('fastforward', this);
    },

    onStopBtnTap : function() {
        this.fireEvent('stop', this);
        this.setStats(this.getEmptyStats());
    },

    updateSongData : function(songData) {
        console.log('SongData ::: ', songData);
    },

    setSongName : function(songName) {
        var myData = this.getData();
        myData.songName = songName;
        this.setData(myData);
        this.down('#songStatus').setData(myData);

//        alert('open debuhhr');
//        console.log('here')
//        debugger;
//        this.down('#songName').setHtml(data.songName);
    },

    setPatternData : function(patternDataAsString) {
        this.setStats(this.getEmptyStats());

        if (! patternDataAsString) {
            return;
        }

        var patternData

        try {
            patternData = JSON.parse(patternDataAsString);
        }
        catch(e) {
            alert('Could not parse JSON pattern data! #HasSads');
            return;
        }

//        var keys     = Object.keys(patternData),
//            firstKey = keys[0],
//            firstPat = patternData[firstKey],
//            firstRow = firstPat[0],
//            rowSPlit = firstRow.split(' ');
//        if (this.patternView) {
//            this.patternView.setPatternData(patternData);
//
//        }
        this.patternData = patternData;

        console.log("SENCHA:: Got pattern data!");

        return patternData;
    },

    setStats : function(stats) {
//        console.log('player.setStats()')
//        debugger;
        this.songStats = stats;
//        stats.cpu = (! isNaN(stats.cpu)) ? stats.cpu.toFixed(2) : stats.cpu;
//        console.log(stats.cpu);

//        this.down('#stats').setData(stats);

        var vizItem = this.vizItem;
        if (vizItem) {
            // Todo: normalize methods for viz items
            if (vizItem.xtype == 'pattern')  {
                vizItem.showPatternAndPosition(stats.pattern, stats.row);
            }
            else if (vizItem.xtype == 'spectrum') {
                vizItem.updateCanvas(stats);
            }
            else {
                console.log('NO vizItem.xtype');
            }
        }
        else {
            console.log('NO VIZ ITEM!');
        }

    }
});