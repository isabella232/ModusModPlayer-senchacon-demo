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
                    '<div style="font-size: 14px; font-weight: bold; text-align:center;">{name}</div>',
                    '<div style="font-size: 12px;text-align:center;">{niceName}</div>'
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
                        itemId : 'prevbtn'
                    },
                    {
                        text   : 'Play',
                        itemId : 'playbtn',
                        ui     : 'confirm'
                    },
                    {
                        text   : '&gt;&gt;',
                        itemId : 'nextbtn'
                    },
                    // {
                    //     text   : 'STOP',
                    //     itemId : 'stopbtn',
                    //     ui     : 'decline'
                    // },
                    { xtype : 'spacer' }
                ]
            }
        ],

        control : {
            '#prevbtn' : {
                tap : 'onPrevBtnTap'
            },
            '#playbtn' : {
                tap : 'onPlayBtnTap'
            },
            '#nextbtn' : {
                tap : 'onNextBtnTap'
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
        this.down('#songStatus').setData(data);
//        this.spectrum = this.down('spectrum');
//        this.patternView = this.down('pattern');
        this.callParent();
    },

    onPrevBtnTap : function() {
        this.fireEvent('previous', this);
    },

    onPlayBtnTap : function() {
        if (this.isPlaying) {
            this.fireEvent('pause', this);
            this.setPlayMode();
            return;
        }
        this.fireEvent('play', this);
        this.setPauseMode();
    },

    onNextBtnTap : function() {
        this.fireEvent('next', this);
    },


    updateSongData : function(songData) {
        console.log('SongData ::: ', songData);
    },

    setSongName : function(modInfo) {

        this.setData(modInfo);
        this.down('#songStatus').setData(modInfo);

//        alert('open debuhhr');
//        console.log('here')
//        debugger;
//        this.down('#songName').setHtml(data.songName);
    },

    setPlayMode : function() {
        this.down('#playbtn').setText('Play ');
    },
    setPauseMode : function() {
        this.down('#playbtn').setText('Pause');

    },

    updatePatternView : function(order, pattern, row) {
        this.down('patternview').showPatternAndPosition(order, pattern, row);
    },

    setPatternData : function(patternData) {
        this.patternData = patternData;
        return;
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
            if (vizItem.showPatternAndPosition)  {
                vizItem.showPatternAndPosition(stats.pattern, stats.row);
            }
            else if (vizItem.updateCanvas) {
                vizItem.updateCanvas(stats.waveData);
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