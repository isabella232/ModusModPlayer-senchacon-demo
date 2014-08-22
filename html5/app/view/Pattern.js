Ext.define('Modizer.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'pattern',
    config : {
        style       : 'border: 1px solid #F00',
        patternData : null,
        data        : null,
        tpl         : [
            '<table style="border-bottom: 1px solid #00F;">',
                '<tpl for=".">',
                    '<tr>',
                    '<td>LULZ</td>',
//                        '<tpl for="{values}">',
//                            '<td>{.}</td>',
//                        '</tpl>',
                    '</tr>',
                '</tpl>',
            '</table>'
        ]
    },
//
    applyPatternData : function(patternData) {
        this.numChannels = patternData[0][0].length;


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
                    this.setData(pattern);
                    // Switch patterns
                }

                if (rowNum != this.prevRowNum) {
                    // Animate rows
                    console.log(patternNum, rowNum);

//                console.log('Found Pattern ' + patternNumber + ' Row ' + rowNum);
//                alert('debugger')
//                console.log('here')
//                debugger;
                }

                this.element.dom.innerHTML = patternNum  + ' --  ' +  rowNum;
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