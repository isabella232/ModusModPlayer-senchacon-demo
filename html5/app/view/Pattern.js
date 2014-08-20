Ext.define('Modizer.view.Pattern', {
    extend : 'Ext.Container',
    xtype  : 'pattern',
    config : {
        html        : 'PATTERN VIEW HERE',
        style       : 'border: 1px solid #F00',
        patternData : null
    },
//
//    setPatternData : function(patternData) {
//
////        alert('open debugger');
//        console.log(patternData);
//        this.patternData = patternData;
////        debugger;
//    },
    showPatternAndPosition : function(patternNumber, rowNum) {
        if (patternNumber == '--') {
            return;
        }
        var patternData = this.getPatternData(),
            pattern     = patternData[patternNumber],
            row;


        if (pattern) {
            row = pattern[rowNum];

            debugger;

            if (row) {
                console.log('Found Pattern ' + patternNumber + ' Row ' + rowNum);
//                alert('debugger')
//                console.log('here')
//                debugger;
                this.element.dom.innerHTML = row;
            }
            else {
                console.warn('I don\'t have pattern #' + pattern + ' Row #' + rowNum);
            }


        }
        else {
            console.warn('I don\'t have pattern #' + pattern);
        }


        console.log(patternNumber, row);



    }
});