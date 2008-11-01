/*

Life as Me: Flash Message jQuery Plugin
Copyright (c) 2008 Alice Dawn Bevan-McGregor. All Rights Reserved.

Permission is granted to use and modify this file as long as this original header remains intact.

For additional information on the site design used by Life as Me, please see the following website:

    http://www.lifeasme.com/corporate/site-design/

Changelog:

    1.0     Initial release.
    1.1     Updated to use setTimeout vs. the elem.animate() hack.
    
Upcoming features:

    - Multiple message support.  This requires creating a new flash div for each message and stacking them.

Sample CSS formatting:

    #flash { position: fixed; top: 0px; left: 0px; width: 100%; z-index: 1000; background-color: #569; color: white; background-image: url('/static/img/btn.png'); background-position: bottom; border-bottom: 1px solid #555; }
    #flash, #flash * { cursor: pointer; }
    #flash .yui-b { padding: 5px 0; }
    #flash .yui-b>* { font-size: 128%; }
    #flash label { display: block; text-align: right; font-weight: bold; text-transform: capitalize; }
    #flash label:after { content: ':'; }

    #flash.subtle { background-color: #444; color: white; }
    #flash.subtle:hover { background-color: #222; }
    #flash.warning { background-color: #ff0; color: black; }
    #flash.warning:hover { background-color: #ff8; }
    #flash.success { background-color: #595; }
    #flash.success:hover { background-color: #7b7; }
    #flash.failure, #flash.error { background-color: #800; }
    #flash.failure:hover, #flash.error:hover { background-color: #a00; }
    #flash.subtle, #flash.success, #flash.failure, #flash.error { text-shadow: black 2px 2px 2px; }

*/


jQuery.Flash = function(element){
    this.element = $(element);
    this.timeout = undefined;
    
    var content = $('<div class="yui-t1 doc4"></div>');
    
    content.append('<div class="yui-main"><div class="yui-b"><div></div></div></div>');
    content.append('<div class="yui-b"><label></label></div>');
    content.append('<div style="clear: both;"><!-- IE --></div>');
    
    this.element.hide()
        .click(function(){ jQuery.flash.hide(); })
        .hover(function(){ jQuery.flash.onOver(); }, function(){ jQuery.flash.onLeave(); })
        .append(content);
};

jQuery.Flash.version = 1.1;

jQuery.Flash.prototype.onOver = function() {
    this.element.addClass('over');
}

jQuery.Flash.prototype.onLeave = function() {
    this.element.removeClass('over');
    
    if ( this.element.hasClass('expired') ) this.hide();
}

jQuery.Flash.prototype.onTimeout = function() {
    this.element.addClass('expired');
    if ( ! this.element.hasClass('over') ) this.hide();
}

jQuery.Flash.prototype.show = function() {
    this.element.fadeIn(1000);
    
    if ( ! this.element.hasClass('error') )
        this.timeout = window.setTimeout(function(){ jQuery.flash.onTimeout() }, 15000);
}

jQuery.Flash.prototype.hide = function() {
    if ( this.timeout ) {
        clearTimeout(this.timeout);
        this.timeout = undefined;
    }
    
    this.element.fadeOut(1000).removeClass('expired').removeClass('over');
}

jQuery.Flash.prototype.message = function(klass, label, message) {
    this.element.removeClass('expired');
    
    if ( this.element.is(":visible") ) {
        if ( this.timeout ) {
            clearTimeout(this.timeout);
            this.timeout = undefined;
        }
        
        this.element.fadeOut(1000, function(){ jQuery.flash.message(klass, label, message); });
        return;
    }
    
    this.element.attr('class', klass);
    this.element.find('.yui-b div').text(message);
    this.element.find('.yui-b label').text(label);
    
    this.show();
}

jQuery.Flash.prototype.subtle = function(label, message) { this.message('subtle', label, message); }
jQuery.Flash.prototype.error = function(label, message) { this.message('error', label, message); }
jQuery.Flash.prototype.failure = function(label, message) { this.message('failure', label, message); }
jQuery.Flash.prototype.fail = function(label, message) { this.message('failure', label, message); }
jQuery.Flash.prototype.warning = function(label, message) { this.message('warning', label, message); }
jQuery.Flash.prototype.warn = function(label, message) { this.message('warning', label, message); }
jQuery.Flash.prototype.information = function(label, message) { this.message('information', label, message); }
jQuery.Flash.prototype.info = function(label, message) { this.message('information', label, message); }
jQuery.Flash.prototype.success = function(label, message) { this.message('success', label, message); }

$(function(){ jQuery.flash = new jQuery.Flash('#flash'); });