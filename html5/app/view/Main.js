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
                    ui     : 'confirm',
                    itemId : 'stopbutton',
                    text   : 'TEST',
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


        var title = item.$className.split('.');
        title = title[title.length - 1];
        this.down('toolbar').setTitle(title)

    },

    showBackButton : function(title) {
        title = title || 'Back';

        var backButton = this.backButton || (this.backButton = this.down('#backbutton'));


        backButton.setText(title);
        backButton.setHidden(false);

    },
    onBackButton : function(btn) {
        var innerItems = [].concat(this.getInnerItems());

//        debugger;
        if (innerItems.length > 1) {
            var animateTo = innerItems[innerItems.length - 2];
            var currentItem = innerItems.pop();


            var title = animateTo.$className.split('.');
            title = title[title.length - 1];
            this.down('toolbar').setTitle(title)

            this.animateActiveItem(animateTo, {
                type      : 'slide',
                direction : 'right'
            });

            Ext.Function.defer(function() {
                this.remove(currentItem);
                if (this.getInnerItems().length == 1) {
                    btn.hide();
                }
            }, 300, this)

        }
        else {
            btn.hide();
        }



    },
    onStopButton : function() {
        this.fireEvent('stop', this);
    }

});
