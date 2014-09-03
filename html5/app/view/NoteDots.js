Ext.define('Modify.view.NoteDots', {
    extend : 'Ext.Container',
    xtype  : 'notedots',

    config : {
        patternData : null,
//        style  : 'border: 1px solid #F00',
        tpl    : '<canvas id="{id}" height="{height}" width="{width}" />'

    },
//
     initialize : function() {
        // TODO: Push to element config

        var me = this,
            thisEl = me.element,
            canvas;

        this.callParent();
//
//        thisEl.on({
//            scope     : this,
//            tap       : 'onElTapSwitchMode',
//            dragstart : 'onElDragStart',
//            dragend   : 'onElDragEnd',
//            drag      : 'onElDrag'
//        });

        thisEl.on('painted', function() {
            console.log('thisEl painted')
            var thisElWidth  = thisEl.getWidth(),
                thisElHeight = thisEl.getHeight();

            me.setData({
                id     : 'canvas-' + me.getId(),
                width  : thisElWidth,
                height : thisElHeight
            });

            canvas = me.canvas = me.element.down('canvas').dom;

            // These are for backwards compatibility.
            me.canvasWidth  = thisElWidth;

            me.canvasHeight = thisElHeight;
            me.validPoints  = 1000;

            me.canvas2dContext = canvas.getContext('2d');
        }, me);
    },



    clearCanvas : function() {
        var me = this;
        me.canvas2dContext.clearRect(0, 0, me.canvasWidth, me.canvasHeight);

    },

    applyPatternData : function(patternData) {
        this.numChannels = patternData[0][0].length;
        this.patternData = patternData;
        return patternData;
    },

    showPatternAndPosition : function(patternNum, rowNum) {
        var patternData = this.getPatternData();

        if (! patternData || patternNum == '--' || rowNum == this.prevRowNum) {
            return;
        }

        var pattern = patternData[patternNum],
            row;

        if (pattern) {
            row = pattern[rowNum];

            if (row) {
                this.updateCanvas(row);

                this.prevRowNum = rowNum;
            }
            else {
                console.warn('Not Found ::' + patternNum + ' Row #' + rowNum);
            }

        }
        else {
            console.warn('Not Found ::' + patternNum);
        }


    },

    notes : {

        'C-' : 1,
        'C#' : 2,
        'D-' : 3,
        'D#' : 4,
        'E-' : 5,
        'F-' : 6,
        'F#' : 7,
        'G-' : 8,
        'G#' : 9,
        'A-' : 10,
        'A#' : 11,
        'B'  : 12
    },


    /*
        row example:
        [
            "C-4 01 .. . ..",
            "C-6 02 09 . ..",
            "C-3 03 30 L 0A",
            "... .. 0A . ..",
            "F-5 03 0A . ..",
            "... .. 0A . ..",
            "C-7 .. .. . ..",
            "D#6 .. .. . .."
        ]

     */
    updateCanvas      : function(row) {
        var me = this;
        window.item = this;

        me.clearCanvas();

//        stackBlurCanvasRGBA(me.canvas.id, 0, 0, this.canvasWidth, this.canvasHeight, 1);

        //grid width and height
        var canvasWidth  = me.canvasWidth,
            canvasHeight = me.canvasHeight,
            context      = me.canvas2dContext;

        var notesPerScale= 12,
            numScales    = 6,
            boxesPerRow  = notesPerScale * numScales,
            boxWidth     = canvasWidth / boxesPerRow,
            boxHeight    = canvasHeight / this.numChannels,
            radius       = boxHeight / 4,
            arcVal       = 2 * Math.PI;




        context.fillStyle = "rgba(80, 80, 255, 1)";
        Ext.each(row, function(channel, channelNum) {
            var note           = channel.substr(0,2),
                octave         = channel.substr(2,1),
                noteMultiplier = me.notes[note],
                x              = (boxWidth * noteMultiplier) * +octave,
                y              = boxHeight * channelNum;


//            context.fillRect(x, y, boxWidth, boxHeight);

            context.beginPath();
            context.arc(x, y + radius + 20, radius, 0, arcVal, false);
            context.fill();
//            context.stroke();

        });



//        me.drawWaveForms(dataItems);
    }

});