/*
 @class MMP.view.Spectrum
 Based off of the code from:

 SpectrumBox - A JavaScript spectral analyzer.
 Mohit Cheppudira - 0xfe.blogspot.com
 */

Ext.define('MMP.view.Spectrum', {
    extend : 'Ext.Component',
    xtype  : 'spectrum',

    config : {
        numPoints    : 2048,
        binMax       : 500,
        binMin       : 10,
        numBins      : 500,
        mode         : 2,
        barSpacing   : 0,

        spectrumY    : 0,

        modes : [
            1, // wave
            2, // bars,
            3  // spectrum
        ],

        style : "border: 1px solid #F00;",

        tpl : '<canvas id="{id}" height="{height}" width="{width}" />'
    },

    initialize : function() {
        // TODO: Push to element config

        var me = this,
            thisEl = me.element,
            canvas;

        this.callParent();

        thisEl.on({
            scope : this,
            tap   : 'onElTapSwitchMode',
            dragstart  : 'onElDragStart',
            dragend    : 'onElDragEnd',
            drag       : 'onElDrag'
        });

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
            me.validPoints  = 500;

            me.canvas2dContext = canvas.getContext('2d');
            me.data = new Uint8Array();

        }, me);


    },

    onElTapSwitchMode : function() {
        this.setMode((this.getMode() + 1) % this.getModes().length);

    },




    onElDragStart : function(evtObj) {

        this.isDragging = true;
        this.prevDragX = evtObj.getXY()[0];
    },




    onElDrag : function(event) {
        var me     = this,
            currX  = event.getXY()[0],
            prevX  = me.prevX || currX,
            deltaX = currX - prevX,
            initX  = me.initialDragX,
            curBin = me.getNumBins(),
            binMax = me.getBinMax(),
            binMin = me.getBinMin(),
            binChange;

        me.prevX = currX;

        // Horizontal Dragging
        if (Math.abs(deltaX) >= 2) {
            if (! initX) {
                me.initialDragX = currX;
            }

            if (currX < initX) {
//                me.dragDirection = 'left';
                binChange = currX - initX;
            }
            else if (currX > initX) {
//                me.dragDirection = 'right';
                binChange = Math.abs(currX - initX);
            }

            if (binChange == undefined) {
                return;
            }

            binChange = binChange + curBin;

            if (binChange > binMax) {
                binChange = binMax;
            }
            else if (binChange < binMin) {
                binChange = binMin;
            }

            this.setNumBins(binChange);
        }


    },


    onElDragEnd : function() {
        delete this.prevX;
        delete this.initialDragX;
    },


    updateCanvas      : function(dataItems) {
        var me = this;



        var  currentMode = me.getMode();
        if (currentMode == 1 || currentMode == 2) {
            me.drawWaveForms(dataItems);
        }
        else {
            me.drawSpectrum(dataItems);
        }
    },

    /* Updates the canvas display. */

    drawWaveForms : function(dataItems) {
        var me              = this,
            elHeight        = me.element.getHeight(),
            numBins         = me.getNumBins(),
            canvasWidth     = me.canvasWidth,
            canvasHeight    = me.canvasHeight,
            canvas2dContext = me.canvas2dContext,
            barSpacing      = me.getBarSpacing(),
            one             = 1,
            currentMode     = me.getMode();

        console.log("NUM BINS >>>> ", numBins);

        me.canvas2dContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

        Ext.each(dataItems, function(data, index) {

            if (index < one) {
                canvas2dContext.fillStyle = "rgba(0, 20, 177, .5)";
            }
            else {
                canvas2dContext.fillStyle = "rgba(177, 20, 0, .5)";
            }
            // Get the frequency samples

            var length = data.length;
            if (me.validPoints > 0) {
                length = me.validPoints;
            }

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
                    scaledAvg = (average / elHeight) * canvasHeight;


                if (currentMode == one) {
                    canvas2dContext.fillRect(i * barWidth, canvasHeight, barWidth - barSpacing, -scaledAvg);
                }
                else {
                    canvas2dContext.fillRect(i * barWidth, canvasHeight - scaledAvg + 2, barWidth, -1);
                }
            }
        });
    },

    drawSpectrum : function() {
        this.y = this.y || 0;
    }




});
