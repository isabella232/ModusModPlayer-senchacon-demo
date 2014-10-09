Ext.define('Modify.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'pattern',

    config : {
        patternData : null,
        scrollable  : {
            direction  : 'both',
            indicators : false
        },
        items : {
            xtype  : 'component',
//            style  : 'border: 1px solid #F00',
            itemId : 'pattern',
            data   : [],
            tpl    : [
                '<table style="width: 100%; font-family: monospace; font-size: 10px;">',
                    '<tpl for=".">',
                        '<tr style="background-color: {[xindex % 2 === 0 ? "#EFEFEF;" : "#FFF;"]}">',
                            '<td style="border-right: 1px solid #AFAFAF;">{#}</td>',
                            '<tpl for=".">',
                                '<td style="padding: 0 5px 0 5px; border-right: 1px solid #AFAFAF;">{.}</td>',
                            '</tpl>',
                        '</tr>',
                    '</tpl>',
                '</table>'
            ]
        }
    },
//
    applyPatternData : function(patternData) {
        if (! this.indicatorEl) {

            var thisElement = this.element,
                height      = thisElement.getHeight();

            var ie = this.indicatorEl = document.createElement('div');

            this.indicatorEl.id = 'indicator';

            //
            ie.style.cssText = 'position: absolute; height: 12px; width: 100%; top: 50%; background: rgba(168,197,255, .4); border: 1px solid rgba(168,197,255, .4);';

            thisElement.appendChild(this.indicatorEl);

            window.ie = this.indicatorEl;
        }

        this.numChannels = patternData[0][0].length;

        this.down('#pattern').setWidth((this.numChannels * 95) + 50);

        this.prevPatternNum = this.prevRowNum = -1;

        this.patternData = patternData;

        return patternData;
    },
    showPatternAndPosition : function(patternNum, rowNum) {
        var patternData = this.getPatternData();

        window.item = this;

        if (! patternData || patternNum == '--' || rowNum == this.prevRowNum) {
            return;
        }

        var pattern       = patternData[patternNum],
            elementCenter = this.element.getHeight() / -2,
            scroller      = this.getScrollable().getScroller(),
            row,
            scrollTo;


        if (pattern) {
            row = pattern[rowNum];

            if (row) {
                // Switch pattern
                if (patternNum != this.prevPatternNum) {
                    this.down('#pattern').setData(pattern);
                    this.table      = this.element.query('table')[0];
                    this.tBodyNodes = this.table.childNodes[0].childNodes;
                    scrollTo = elementCenter;
                }

                // Set scroll to new row
                if (rowNum != this.prevRowNum) {
                    scrollTo = elementCenter + (11 * rowNum);
                }

                scroller.scrollTo(0, scrollTo);
                this.prevPatternNum = patternNum;
                this.prevRowNum = rowNum;
            }
            else {
                console.warn('Not Found ::' + patternNum + ' Row #' + rowNum);
            }


        }
        else {
            console.warn('Not Found ::' + patternNum);
        }


    }
});