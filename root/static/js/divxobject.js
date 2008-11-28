/*
 * DivXObject embed based on qtobject.js
 *
 * Embeds a DivX web player to the page
 *
 * Usage:
 *
 *	d = new DivXObject("path/to/mov.divx", "movid", "width", "height");
 *	d.addParam("autoplay", "true");			// optional
 *	d.addParam("controller", "false");		// optional
 *	d.addParam("loop", "false");			// optional
 *	d.write(id);
 */

DivXObject = function(mov, id, w, h) {
	this.mov = mov;
	this.id = id;
	this.width = w;
	this.height = h;
	this.params = new Object();
}

DivXObject.prototype.addParam = function(name, value) {
	this.params[name] = value;
}

DivXObject.prototype.getParams = function() {
    return this.params;
}

DivXObject.prototype.getParam = function(name) {
    return this.params[name];
}

DivXObject.prototype.getParamTags = function() {
    var paramTags = "";
    for (var param in this.getParams()) {
        paramTags += '<param name="' + param + '" value="' + this.getParam(param) + '" />';
    }
    if (paramTags == "") {
        paramTags = null;
    }
    return paramTags;
}

DivXObject.prototype.getHTML = function() {
    var HTML = '<object classid="clsid:67DABFBF-D0AB-41fa-9C46-CC0F21721616" codebase="http://go.divx.com/plugin/DivXBrowserPlugin.cab" width="' + this.width + '" height="' + this.height + '" id="' + this.id + '">';
    this.addParam("custommode", "none");
    this.addParam("src", this.mov);
    if (this.getParamTags() != null) {
        HTML += this.getParamTags();
    }
    HTML += '<embed type="video/divx" width="' +this.width+ '" height="' +this.height+ '"';
    for (var param in this.getParams()) {
        HTML += ' ' + param + '="' + this.getParam(param) + '"';
    }
    HTML += ' pluginspage="http://go.divx.com/plugin/download/"></embed></object>';
    return HTML;
}

DivXObject.prototype.getVariablePairs = function() {
    var variablePairs = new Array();
    for (var name in this.getVariables()) {
        variablePairs.push(name + "=" + escape(this.getVariable(name)));
    }
    if (variablePairs.length > 0) {
        return variablePairs.join("&");
    }
    else {
        return null;
    }
}

DivXObject.prototype.write = function(elementId) {
    if (elementId) {
       document.getElementById(elementId).innerHTML = this.getHTML();
    } else {
       document.write(this.getHTML());
    }
}
