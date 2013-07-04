Ext.define('MMP.view.Main', {
    extend: 'Ext.Container',
    xtype: 'main',

    requires: [
        'Ext.TitleBar',
        'Ext.dataview.List'
    ],
    config: {
        layout : {
            type : 'card'
        },
        items : {
            xtype  : 'toolbar',
            itemId : 'titlebar',
            docked : 'top',
            title  : 'Prototype',
            items : [
                {
                    xtype  : 'button',
                    ui     : 'back',
                    itemId : 'backbutton',
                    text   : 'Back',
                    hidden : true
                },
                {xtype:'spacer'},
                {
                    xtype  : 'button',
                    ui     : 'decline',
                    itemId : 'stopbutton',
                    text   : 'STOP',
                    hidden : false
                }

            ]
        },
        control : {
            '#backbutton' :{
                tap : 'onBackButton'
            },
            '#stopbutton' :{
                tap : 'onStopButton'
            }
        }
    },

    addAndAnimateItem : function(item) {
        this.add(item);

        this.animateActiveItem(item, { type : 'slide', direction : 'left' });
        this.showBackButton();
    },

    showBackButton : function(title) {
        title = title || 'Back';

        var backButton = this.backButton || (this.backButton = this.down('#backbutton'));


        backButton.setText(title);
        backButton.setHidden(false);
        this.down('#stopbutton').show();

    },
    onBackButton : function(btn) {
        var innerItems = [].concat(this.getInnerItems());

        if (innerItems.length > 1) {
            var animateTo = innerItems[innerItems.length - 2];
            var currentItem = innerItems.pop();

            this.animateActiveItem(animateTo, {
                type      : 'slide',
                direction : 'right'
            });

            Ext.Function.defer(function() {
                this.remove(currentItem);
                if (this.getInnerItems().length == 1) {
                    btn.hide();
                    this.down('#stopbutton').hide();
                }
            }, 300, this)







        }
        else {
            btn.hide();
        }



    },
    onStopButton : function() {
        this.fireEvent('stop');
    }

});
