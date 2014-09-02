Ext.define('Modify.view.Main', {
    extend : 'Ext.Container',
    xtype  : 'main',

    requires: [
        'Ext.TitleBar',
        'Ext.dataview.List',
        'Modify.view.Pattern',
        'Modify.view.Spectrum'
    ],
    config: {
        layout : {
            type : 'card'
        },
        items : {
            xtype  : 'toolbar',
            itemId : 'titlebar',
            cls    : 'main-toolbar',
            docked : 'top',
            title  : 'MODify',
            items : [
                {
                    xtype  : 'button',
//                    ui     : 'back',
                    itemId : 'backbutton',
                    text   : 'Back',
                    hidden : true
                },
                {xtype:'spacer'},
                {
                    xtype  : 'button',
//                    ui     : 'confirm',
                    itemId : 'vizbutton',
                    text   : 'Viz',
                    hidden : true
                }
            ]
        },
        control : {
            '#backbutton' :{
                tap : 'onBackButton'
            },
            '#vizbutton' :{
                tap : 'onVizButton'
            }
        }
    },

    addAndAnimateItem : function(item) {
        var me = this;
//            title;


        me.add(item);

        me.animateActiveItem(item, { type : 'slide', direction : 'left' });
        me.showBackButton();


        if (item.xtype == 'player') {
            me.down('#vizbutton').show();

        }
//
//        title = item.$className.split('.');
//        title = title[title.length - 1];
//        me.down('toolbar').setTitle('MODify')

    },

    showBackButton : function(title) {
        title = title || 'Back';

        var backButton = this.backButton || (this.backButton = this.down('#backbutton'));


        backButton.setText(title);
        backButton.setHidden(false);
    },

    onBackButton : function(backButton) {
        var me         = this,
            innerItems = [].concat(me.getInnerItems());

        me.fireEvent('back', me);
//        debugger;

        if (innerItems.length > 1) {
            var animateTo   = innerItems[innerItems.length - 2],
                currentItem = innerItems.pop();

            if (currentItem.xtype == 'player') {
                me.down('#vizbutton').hide();

            }

            var numItems = me.getInnerItems().length;

            if (numItems == 2) {
                backButton.hide();
            }

//                title       = animateTo.$className.split('.');

//            title = title[title.length - 1];
//            me.down('toolbar').setTitle(title);

            me.animateActiveItem(animateTo, {
                type      : 'slide',
                direction : 'right'
            });

            Ext.Function.defer(function() {
                me.remove(currentItem);
            }, 300);

        }
        else {
            backButton.hide();
        }
    },

    onVizButton : function() {
        this.fireEvent('vizselect', this);
    }

});
