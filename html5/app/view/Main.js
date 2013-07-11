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
        var me = this,
            title;

        me.add(item);

        me.animateActiveItem(item, { type : 'slide', direction : 'left' });
        me.showBackButton();

        title = item.$className.split('.');
        title = title[title.length - 1];
        me.down('toolbar').setTitle(title)

    },

    showBackButton : function(title) {
        title = title || 'Back';

        var backButton = this.backButton || (this.backButton = this.down('#backbutton'));


        backButton.setText(title);
        backButton.setHidden(false);
    },

    onBackButton : function(btn) {
        var me         = this,
            innerItems = [].concat(me.getInnerItems());

        me.fireEvent('back', me);
//        debugger;

        if (innerItems.length > 1) {
            var animateTo   = innerItems[innerItems.length - 2],
                currentItem = innerItems.pop(),
                title       = animateTo.$className.split('.');

            title = title[title.length - 1];
            me.down('toolbar').setTitle(title);

            me.animateActiveItem(animateTo, {
                type      : 'slide',
                direction : 'right'
            });

            Ext.Function.defer(function() {
                me.remove(currentItem);
                if (me.getInnerItems().length == 1) {
                    btn.hide();
                }
            }, 300);

        }
        else {
            btn.hide();
        }
    },
    onStopButton : function() {
        this.fireEvent('stop', this);
    }

});
