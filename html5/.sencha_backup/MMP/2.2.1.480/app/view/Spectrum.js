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
        mode         : 0,
        barSpacing   : 0,

        spectrumY    : 0,

        modes : [
            0, // wave
            1, // bars,
            2  // spectrum
        ],

        modeMethodMap : {
            0 : 'drawWaveForms',
            1 : 'drawWaveBars',
            2 : 'drawSpectrum'
        },

        waveEchoLimit : 3,
        waveEchoBuffer : [],

        style : "background-color: #000;",

        tpl : '<canvas id="{id}" height="{height}" width="{width}" />'
    },

    initialize : function() {
        // TODO: Push to element config

        var me = this,
            thisEl = me.element,
            canvas;

        this.callParent();

        thisEl.on({
            scope      : this,
            tap        : 'onElTapSwitchMode',
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
        var me = this;
        me.setMode((me.getMode() + 1) % me.getModes().length);

        me.y = 0;
        this.clearCanvas();
    },


    clearCanvas : function() {
        var me = this;
        me.canvas2dContext.clearRect(0, 0, me.canvasWidth, me.canvasHeight);

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
        var me = this,
            currentMode = me.getMode();
        console.log(dataItems)
//        debugger;
        me[me.getModeMethodMap()[currentMode]](dataItems);
    },



    drawWaveBars : function(dataItems) {
         if (! dataItems) {
            this.clearCanvas();
            return;
        }

        var me              = this,
            elHeight        = me.element.getHeight(),
            numBins         = me.getNumBins(),
            canvasWidth     = me.canvasWidth,
            canvasHeight    = me.canvasHeight,
            canvas2dContext = me.canvas2dContext,
            barSpacing      = me.getBarSpacing(),
            one             = 1;

        me.canvas2dContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

        Ext.each(dataItems, function(data, index) {

            if (index < one) {
                canvas2dContext.fillStyle = "rgba(255, 80, 20, 1)";
            }
            else {
                canvas2dContext.fillStyle = "rgba(80, 255, 20, 1)";
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


                if (index < one) {
                    scaledAvg += 50;
                }

                canvas2dContext.fillRect(
                    i * barWidth,
                    canvasHeight,
                    barWidth - barSpacing,
                    -scaledAvg
                );
            }
        });
    },

    drawWaveForms : function(dataItems) {
        if (! dataItems) {
            this.clearCanvas();
            return;
        }

        var me              = this,
            elHeight        = me.element.getHeight(),
            numBins         = me.getNumBins(),
            canvasWidth     = me.canvasWidth,
            canvasHeight    = me.canvasHeight,
            canvas2dContext = me.canvas2dContext,
            one             = 1;


        me.canvas2dContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);


        Ext.each(dataItems, function(data, index) {

            if (index < one) {
                canvas2dContext.fillStyle = "rgba(255, 80, 20, 1)";
            }
            else {
                canvas2dContext.fillStyle = "rgba(80, 255, 20, 1)";
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


                var offset;
                if (index < one) {
                    offset = -100;
                }
                else {
                    offset = 20;
                }

                canvas2dContext.fillRect(i * barWidth, (canvasHeight - scaledAvg + 2) + offset, barWidth, 5);
            }
        });
    },

    drawSpectrum : function(spectrumData) {
        if (! spectrumData) {
            this.clearCanvas();

            return;
        }
        var  y = this.y = this.y || 0;

        if (y > this.element.getWidth()) {
            y = this.y = 0;
        }

        var x = 0,
            height = this.element.getHeight(),
            canvas2dContext = this.canvas2dContext,
            yPlusOne = y + 5;

        for (; x < height; x++) {
            canvas2dContext.fillStyle = "#00FF00";
            canvas2dContext.fillRect();
            canvas2dContext.fillRect(yPlusOne,x,1,1);
        }

        var base     = 32,
            rgbStart = 'rgb(',
            rgbEnd   = ')',
            value;

        for (x = 0; x < height; x++) {
            value = base + spectrumData[x];
            canvas2dContext.fillStyle = rgbStart + value + ',' + value + ',' + value + rgbEnd;
            canvas2dContext.fillRect(y, x, 5, 1);
        }

        this.y++;
    }




});
