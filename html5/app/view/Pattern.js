Ext.define('Modify.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'patternview',

    config : {
        patternData : null,
        style  : 'background-color: #000;',

        // scrollable  : {
        //     direction  : 'vertical',
        //     indicators : false
        // },
        items : {
            xtype  : 'component',
            // style  : 'border: 1px solid #F00',
            itemId : 'pattern',
            data   : [],
            style  : 'background-color: #000; position: absolute; overflow:hidden;',
            tpl    : Ext.create('Ext.XTemplate', 
                // '<tpl for=".">',
                //     '<div style="font-family: monospace; font-size: 10px;">',
                //         '<span> '
                //     '{.}</div>',
                // '</tpl>',
                // {


                // }
                '<table style="width: 100%; font-family: monospace; font-size: 10px; color: #FFF; background-color: #000;">',
                    '<tpl for=".">',
                        // '<tr style="background-color: {[xindex % 2 === 0 ? "#EFEFEF;" : "#FFF;"]}">',
                        '<tr style="background-color: #000;">',
                            '<td style="width: 17px; color: #0F0;">{#}</td>',
                            '<td style="padding: 0 5px 0 5px; border-right: 1px solid #AFAFAF; overflow: hidden; color: #FFF;">{.}</td>',
                        '</tr>',
                    '</tpl>',
                '</table>'
            )
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
            ie.style.cssText = 'position: absolute; height: 11px; width: 100%; top: 50%;  border-top: 1px solid #F00;   border-bottom: 1px solid #F00;';

            thisElement.appendChild(this.indicatorEl);

            window.ie = this.indicatorEl;
        }

        // this.numChannels = patternData[0][0].length;

        this.down('#pattern').setWidth(3000);

        this.prevPatternNum = this.prevRowNum = -1;

        this.patternData = patternData;

        return patternData;
    },

    showPatternAndPosition : function(order, patternNum, rowNum) {
        // console.log('showPatternAndPosition', order, patternNum, rowNum)
        var patternData = this.getPatternData();


        window.item = this;

        if (! patternData || patternNum == '--' || rowNum == this.prevRowNum) {
            return;
        }


        var pattern       = patternData[patternNum],
            elementCenter = this.element.getHeight() / -2,
            patternView   = this.down('#pattern'),
            // scroller      = this.getScrollable().getScroller(),
            row,
            scrollTo;




        if (pattern) {
            row = pattern[rowNum];

            if (row) {
                // Switch pattern
                if (patternNum != this.prevPatternNum) {
                    // console.log(' --- NEW PATTERN --- ', patternNum);
                    // console.log(pattern);


                    patternView.setData(pattern);
                    
                    // this.table      = this.element.query('table')[0];
                    // this.tBodyNodes = this.table.childNodes[0].childNodes;
                    
                    scrollTo = elementCenter;
                    // setTimeout(function() {
                    //     scroller.scrollTo(0, scrollTo);
                    // }, 75)

                }

                // Set scroll to new row
                if (rowNum != this.prevRowNum) {
                    scrollTo = (elementCenter * -1) - (11 * rowNum);
                }

                console.log('scrollTo ' + scrollTo + 'px', elementCenter, (11 * rowNum))

                patternView.element.applyStyles({
                    top : scrollTo + 'px'
                });

                // scroller.scrollTo(0, scrollTo);
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