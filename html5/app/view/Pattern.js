Ext.define('Modizer.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'pattern',
    id     : 'pattern',
    config : {
        patternData : null,
        scrollable  : {
            direction  : 'both',
            indicators : false
        },
        items : {
            xtype  : 'component',
            style  : 'border: 1px solid #F00',
            itemId : 'pattern',
            data   : null,
            tpl    : [
                '<table style="width: 100%; font-family: monospace; font-size: 10px;">',
                    '<tpl for=".">',
                        '<tr style="background-color: {[xindex % 2 === 0 ? "#EFEFEF;" : "#FFF;"]}">',
                            '<td style="border-right: 1px solid #F00;">{#}</td>',
                            '<tpl for=".">',
                                '<td style="padding: 0 5px 0 5px; border-right: 1px solid #F00;">{.}</td>',
                            '</tpl>',
                        '</tr>',
                    '</tpl>',
                '</table>'
            ]
        }
    },
//
    applyPatternData : function(patternData) {
        this.numChannels = patternData[0][0].length;

        this.down('#pattern').setWidth((this.numChannels * 95) + 50);


        this.prevPatternNum = this.prevRowNum = -1;

//        alert('open debugger');
//        console.log(patternData);
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

//            debugger;

            if (row) {
                if (patternNum != this.prevPatternNum) {
                    console.log(' >>>> PATTERN ' + patternNum);

                    this.down('#pattern').setData(pattern);
                    // Switch patterns
                }

                if (rowNum != this.prevRowNum) {
                    // Animate rows
//                    console.log(patternNum, rowNum);

//                console.log('Found Pattern ' + patternNumber + ' Row ' + rowNum);
//                alert('debugger')
//                console.log('here')
//                debugger;
                }

//                this.element.dom.innerHTML = patternNum  + ' --  ' +  rowNum;
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