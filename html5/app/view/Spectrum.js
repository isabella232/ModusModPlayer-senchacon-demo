/*
 @class MMP.view.Spectrum
 Based off of the code from:

 SpectrumBox - A JavaScript spectral analyzer.
 Mohit Cheppudira - 0xfe.blogspot.com
 */

/**
 @constructor
 Create an n-point FFT based spectral analyzer.

 @param num_points - Number of points for transform.
 @param num_bins - Number of bins to show on canvas.
 @param canvas_id - Canvas element ID.
 @param audio_context - An AudioContext instance.
 */

Ext.define('MMP.view.Spectrum', {
    extend : 'Ext.Component',
    xtype  : 'spectrum',

    config : {
        num_points    : 0,
        num_bins      : 0,
        audio_context : null,
        type          : 1,

        Types : {
            FREQUENCY : 1,
            TIME      : 2
        },

        style : "border: 1px solid #F00;"
    },

    initialize : function() {
        // TODO: Push to element config
        this.setHtml('<canvas id="' + this.getId() + '">');
        this.callParent();
        var canvas = this.canvas = this.element.down('canvas');
        canvas.fillStyle = "rgb(150, 150, 150)";
    },


    shitNit          : function(num_points, num_bins, canvas_id, audio_context, type) {
        this.num_bins = num_bins;
        this.num_points = num_points;
        this.update_rate_ms = 50;
        this.smoothing = 0.75;
        this.type = type || this.getTypes().FREQUENCY;

        // Number of points we actually want to display. If zero, display all points.
        this.valid_points = 0;

        // Determine the boundaries of the canvas.
        this.canvas = document.getElementById(canvas_id);
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        if (this.type == SpectrumBox.Types.FREQUENCY) {
            this.bar_spacing = 3;
        }
        else {
            this.bar_spacing = 1;
        }

        this.ctx = this.canvas.getContext('2d');
        this.actx = audio_context;

        // Create the spectral analyzer
        this.fft = this.actx.createAnalyser();
        this.fft.fftSize = this.num_points;
        this.data = new Uint8Array(this.fft.frequencyBinCount);
    },

    /* Returns the AudioNode of the FFT. You can route signals into this. */
    getAudioNode     : function() {
        return this.fft;
    },

    /* Returns the canvas' 2D context. Use this to configure the look
     of the display. */
    getCanvasContext : function() {
        return this.ctx;
    },

    /* Set the number of points to work with. */
    setValidPoints   : function(points) {
        this.valid_points = points;
        return this;
    },

    /* Set the domain type for the graph (TIME / FREQUENCY. */
    setType          : function(type) {
        this.type = type;
        return this;
    },

    /* Enable the analyzer. Starts drawing stuff on the canvas. */
    enable           : function() {
        var that = this;
        if (!this.intervalId) {
            this.intervalId = window.setInterval(
                function() {
                    that.updateCanvas();
                }, this.update_rate_ms);
        }
        return this;
    },

    /* Disable the analyzer. Stops drawing stuff on the canvas. */
    disable          : function() {
        if (this.intervalId) {
            window.clearInterval(this.intervalId);
            this.intervalId = undefined;
        }
        return this;
    },

    /* Updates the canvas display. */
    updateCanvas      : function() {
        // Get the frequency samples
        debugger;
        data = this.data;
        if (this.type == SpectrumBox.Types.FREQUENCY) {
            this.fft.smoothingTimeConstant = this.smoothing;
            this.fft.getByteFrequencyData(data);
        }
        else {
            this.fft.smoothingTimeConstant = 0;
            this.fft.getByteFrequencyData(data);
            this.fft.getByteTimeDomainData(data);
        }

        var length = data.length;
        if (this.valid_points > 0) {
            length = this.valid_points;
        }

        // Clear canvas then redraw graph.
        this.ctx.clearRect(0, 0, this.width, this.height);

        // Break the samples up into bins
        var bin_size = Math.floor(length / this.num_bins);
        for (var i = 0; i < this.num_bins; ++i) {
            var sum = 0;
            for (var j = 0; j < bin_size; ++j) {
                sum += data[(i * bin_size) + j];
            }

            // Calculate the average frequency of the samples in the bin
            var average = sum / bin_size;

            // Draw the bars on the canvas
            var bar_width = this.width / this.num_bins;
            var scaled_average = (average / 256) * this.height;

            if (this.type == SpectrumBox.Types.FREQUENCY) {
                this.ctx.fillRect(
                    i * bar_width, this.height,
                    bar_width - this.bar_spacing, -scaled_average);
            }
            else {
                this.ctx.fillRect(
                    i * bar_width, this.height - scaled_average + 2,
                    bar_width - this.bar_spacing, -1);
            }
        }
    }



});