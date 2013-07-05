Ext.define('MMP.view.ModPlayer', {
    extend : 'Ext.Container',

    config : {

        layout : 'vbox',
//        height : 120,

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
                style  : 'text-align:left; font-size: 15px; background-color: #E9E9E9;',
                itemId : 'stats',
                height : 200,
                tpl    : [
                    '<div><b>CPU: </b> {cpu}</div>',
                    '<div><b>Level: </b> {level}</div>',
                    '<div><b>Position: </b> {position}</div>',
                    '<div><b>Time: {time}</b></div>'
                ]
            },
            {
                xtype  : 'slider',
                itemId : 'slider'
            },
            {
                xtype       : 'container',
                height      : 40,
                layout      : {
                    type  : 'hbox',
                    align : 'stretch'
                },
                defaults : {
                    xtype : 'button',
                    flex : 1
                },
                items       : [
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
                    }
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
        }
    },

    initialize : function() {
        var data = this.getData();
        this.down('#fileName').setHtml(data.fileName);
        this.callParent();
    },

    onRewindBtnTap : function() {
        this.fireEvent('rewind', this);
    },

    onPlayBtnTap : function() {
        this.fireEvent('play', this);
    },

    onFastForwardButtonTap : function() {
        this.fireEvent('fastforward', this);
    },

    onStopBtnTap : function() {
        this.fireEvent('stop', this);
        this.setStats({});
    },

    updateSongData : function(songData) {
        console.log('SongData ::: ', songData);
    },

    setSongName : function(data) {
        this.down('#songName').setHtml(data.songName);
    },

    setStats : function(stats) {
//        debugger;

        /*
        buff: -0.03076172
        cpu: 0.01923458
        level: 132123416
        position: 0
        time: 0

         */

        this.down('#stats').setData(stats);
    }
});