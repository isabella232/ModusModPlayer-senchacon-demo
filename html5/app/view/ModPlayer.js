Ext.define('Modify.view.ModPlayer', {
    extend : 'Ext.Container',

    config : {

        layout : 'vbox',
//        height : 120,

        patternData : null,

        items  : [
            {
                xtype  : 'component',
                itemId : 'songName',
                style  : 'text-align:center; font-size: 14px; font-weight: bold;',
                height : 20,
                html   : '...'
            },
            {
                xtype  : 'component',
                itemId : 'fileName',
                style  : 'text-align:center; font-size: 12px;',
                height : 20,
                html   : '...'
            },
            {
                xtype  : 'component',
                style  : 'text-align: left; font-size: 12px; background-color: #E9E9E9;',
                itemId : 'stats',
                height : 20,
                tpl    : [
                    '<div style="display: -webkit-flex; -webkit-flex-direction: row;">',
                            '<div style="-webkit-flex: 1 1;"><b>CPU: </b> {cpu}</div>',
                            '<div style="-webkit-flex: 1 1;"><b>Ord: </b> {order}</div>',
                            '<div style="-webkit-flex: 1 1;"><b>Pat: </b> {pattern}</div>',
                            '<div style="-webkit-flex: 1 1;"><b>Row:</b> {row}</div>',
                    '</div>'
                ]
            },
            {
                xtype : 'pattern',
                flex  : 1
            },
//            {
//                xtype  : 'component',
//                itemId : 'spectrum',
//                flex   : 1
//            },
            {
                xtype       : 'toolbar',
                defaults : {
                    xtype : 'button'
                },
                items       : [
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
        this.down('#fileName').setHtml(data.fileName);
//        this.spectrum = this.down('spectrum');
        this.patternView = this.down('pattern');
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

    setSongName : function(data) {
        this.down('#songName').setHtml(data.songName);
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
        this.patternView.setPatternData(patternData);

        console.log("SENCHA:: Got pattern data!");

        return patternData;
    },


    setStats : function(stats) {
//        debugger;
        this.songStats = stats;
        stats.cpu = (! isNaN(stats.cpu)) ? stats.cpu.toFixed(2) : stats.cpu;

        this.down('#stats').setData(stats);
        this.patternView.showPatternAndPosition(stats.pattern, stats.row);
//        this.spectrum.updateCanvas(stats.waveData);
    }
});