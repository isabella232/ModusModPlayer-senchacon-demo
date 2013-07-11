/*
 @class MMP.view.Spectrum
 Based off of the code from:

 SpectrumBox - A JavaScript spectral analyzer.
 Mohit Cheppudira - 0xfe.blogspot.com
 */

/**
 @constructor
 Create an n-point FFT based spectral analyzer.

 @param numPoints - Number of points for transform.
 @param numBins - Number of bins to show on canvas.
 @param canvas_id - Canvas element ID.
 @param audio_context - An AudioContext instance.
 */

Ext.define('MMP.view.Spectrum', {
    extend : 'Ext.Component',
    xtype  : 'spectrum',

    config : {
        numPoints    : 2048,
        numBins      : 500,
        type         : 2,

        Types : {
            FREQUENCY : 1,
            TIME      : 2
        },

        style : "border: 1px solid #F00;",

        tpl : '<canvas id="{id}" height="{height}" width="{width}" />'
    },

    initialize : function() {
        // TODO: Push to element config

        var me = this,
            thisEl = me.element,
            canvas;


        this.callParent();



        thisEl.on('painted', function() {
            var thisElWidth = thisEl.getWidth(),
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
            me.type         = me.getType();
            me.validPoints  = 500;

            me.canvas2dContext = canvas.getContext('2d');
            me.data = new Uint8Array();

            if (this.type == 1) {
                me.barSpacing = 3;
            }
            else {
                me.barSpacing = 1;
            }
        }, me)


    },



    /* Updates the canvas display. */
    updateCanvas      : function(dataItems) {
        var me              = this,
            numBins         = me.getNumBins(),
            canvasWidth     = me.canvasWidth,
            canvasHeight    = me.canvasHeight,
            canvas2dContext = me.canvas2dContext,
            barSpacing      = me.barSpacing;

        me.canvas2dContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

        Ext.each(dataItems, function(data, index) {

            if (index < 1) {
                canvas2dContext.fillStyle = "rgb(0, 0, 255)";
            }
            else {
                canvas2dContext.fillStyle = "rgb(255, 0, 0)";
            }
            // Get the frequency samples

            var length = data.length;
            if (me.validPoints > 0) {
                length = me.validPoints;
            }

            // Clear canvas then redraw graph.

            // Break the samples up into bins
            var bin_size = Math.floor(length / numBins);



            for (var i = 0; i < numBins; ++i) {
                var sum = 0;
                for (var j = 0; j < bin_size; ++j) {
                    sum += data[(i * bin_size) + j];
                }

                // Calculate the average frequency of the samples in the bin
                var average = sum / bin_size;

                // Draw the bars on the canvas
                var barWidth = canvasWidth / numBins,
                    scaledAvg = (average / 256) * canvasHeight;

                if (me.type == 1) {
    //                console.log(i, barWidth, canvasHeight, barSpacing, -scaledAvg);
                    canvas2dContext.fillRect(i * barWidth, canvasHeight, barWidth - barSpacing, -scaledAvg);
                }
                else {
    //                console.log('here')
                    canvas2dContext.fillRect(i * barWidth, canvasHeight - scaledAvg + 2, barWidth, -1);
                }
            }
        })
    }



});
