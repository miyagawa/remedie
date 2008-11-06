/*
 * MPObject embed
 * http://blog.deconcept.com/2005/01/26/web-standards-compliant-javascript-quicktime-detect-and-embed/
 *
 * by Geoff Stearns (geoff@deconcept.com, http://www.deconcept.com/)
 *
 * v1.0.2 - 02-16-2005
 *
 * Embeds a Windows Media movie to the page, includes plugin detection
 *
 * Usage:
 *
 *	myMPObject = new MPObject("path/to/mov.wmv", "movid", "width", "height");
 *	myMPObject.altTxt = "Upgrade your Media Player!";	// optional
 *	myMPObject.addParam("autostart", "0");			// optional
 *	myMPObject.addParam("showstatusbar", "0");		// optional
 *	myMPObject.addParam("controller", "0");			// optional
 *	myMPObject.write();
 *
 */

MPObject = function(mov, id, w, h) {
	this.mov = mov;
	this.id = id;
	this.width = w;
	this.height = h;
	this.redirect = "";
	this.sq = document.location.search.split("?")[1] || "";
	this.altTxt = "This content requires the Windows Mediaplayer Plugin. <a href='http://www.microsoft.com/'>Download Media Player</a>.";
	this.bypassTxt = "<p>Already have Media Player? <a href='?detectmp=false&"+ this.sq +"'>Click here.</a></p>";
	this.params = new Object();
	this.doDetect = getQueryParamValue('detectmp');
}

MPObject.prototype.addParam = function(name, value) {
	this.params[name] = value;
}

MPObject.prototype.getParams = function() {
    return this.params;
}

MPObject.prototype.getParam = function(name) {
    return this.params[name];
}

MPObject.prototype.getParamTags = function() {
    var paramTags = "";
    for (var param in this.getParams()) {
        paramTags += '<param name="' + param + '" value="' + this.getParam(param) + '" />';
    }
    if (paramTags == "") {
        paramTags = null;
    }
    return paramTags;
}

MPObject.prototype.getHTML = function() {
    var mpHTML = "";
	if (navigator.plugins && navigator.plugins.length) { // not ie
        mpHTML += '<embed type="application/x-mplayer2" src="' + this.mov + '" width="' + this.width + '" height="' + this.height + '" id="' + this.id + '"';
        for (var param in this.getParams()) {
            mpHTML += ' ' + param + '="' + this.getParam(param) + '"';
        }
        mpHTML += '></embed>';
    }
    else { // pc ie
        mpHTML += '<object classid="clsid:05589FA1-C356-11CE-BF01-00AA0055595A" width="' + this.width + '" height="' + this.height + '" id="' + this.id + '">';
        this.addParam("src", this.mov);
        if (this.getParamTags() != null) {
            mpHTML += this.getParamTags();
        }
        mpHTML += '</object>';
    }
    return mpHTML;
}


MPObject.prototype.getVariablePairs = function() {
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

MPObject.prototype.write = function(elementId) {
	if(isMPInstalled() || this.doDetect=='false') {
		if (elementId) {
			document.getElementById(elementId).innerHTML = this.getHTML();
		} else {
			document.write(this.getHTML());
		}
	} else {
		if (this.redirect != "") {
			document.location.replace(this.redirect);
		} else {
			if (elementId) {
				document.getElementById(elementId).innerHTML = this.altTxt +""+ this.bypassTxt;
			} else {
				document.write(this.altTxt +""+ this.bypassTxt);
			}
		}
	}		
}

function isMPInstalled() {
	var mpInstalled = false;
	mpObj = false;
	if (navigator.plugins && navigator.plugins.length) {
		for (var i=0; i < navigator.plugins.length; i++ ) {
         var plugin = navigator.plugins[i];
         if (plugin.name.indexOf("Windows Media") > -1) {
			mpInstalled = true;
         }
      }
	} else {
		execScript('on error resume next: mpObj = IsObject(CreateObject("MediaPlayer.MediaPlayer.1"))','VBScript');
		mpInstalled = mpObj;
	}
	return mpInstalled;
}

/* get value of querystring param */
function getQueryParamValue(param) {
	var q = document.location.search;
	var detectIndex = q.indexOf(param);
	var endIndex = (q.indexOf("&", detectIndex) != -1) ? q.indexOf("&", detectIndex) : q.length;
	if(q.length > 1 && detectIndex != -1) {
		return q.substring(q.indexOf("=", detectIndex)+1, endIndex);
	} else {
		return "";
	}
}
