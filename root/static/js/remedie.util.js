function RemedieUtil() { }
RemedieUtil.prototype = { };
RemedieUtil.calcWindowSize = function(width, height, ratio) {
  width  += 16 - Math.ceil(width % 16);
  height += 9  - Math.ceil(height % 9);

  if (ratio * width > height) {
    width = height / ratio;
  } else {
    height = width * ratio;
  }

  return { width: width, height: height };
};

RemedieUtil.formatBytes = function(bytes) {
  if (typeof bytes == 'undefined' || bytes <= 0) return '-';
  var units = [ 'bytes', 'KB', 'MB', 'GB', 'TB' ];
  var i = 0;
  while (bytes > 1024) {
    bytes = bytes / 1024;
    i++;
    if (!units[i]) break;
  }

  return $.sprintf('%.1f %s', bytes, units[i]);    
};

RemedieUtil.encodeFlashVars = function(string) {
  return string.replace(/&/g, '%3F').replace(/=/g, '%3D').replace(/&/g, '%26');
};

RemedieUtil.mangleDate = function(date) {
  // TODO should localize the date as well
  if (!date) return "(Unknown)";
  return date.replace(/^(\d{4}-\d{2}-\d{2})T\d\d:\d\d.*$/i, "$1");
};

RemedieUtil.fileType = function(url, mime) {
  if (/\.(\w{2,4})$/.test(url))
    return "." + RegExp.$1;

  if (mime) {
    var t = mime.split('/');
    if (t.length == 2)
      return t[1];
  }

  return 'Unknown';
};

String.prototype.trimChars = function(length, append) {
  var string = this;
  if (string.length > length) {
    string = string.substring(0, length);
    string += append ? append : "..";
  }
  return string + '';
};

RemedieUtil.layoutImage = function(elem, src, width, height) {
  var img = new Image();
  img.onload = function(){
    var size;
    var margin;
    if (this.height > this.width * height / width) {
       size = height * this.width / this.height;
       margin = (width - size) / 2; 
    } else {
       size = width * this.height / this.width;
       margin = (height - size) / 2;
    }
    if (margin < 0) margin = 0;
    var el = elem.attr("src", this.src);
    if (this.height > this.width * height / width)
       el.css({ height: height, width: size, "margin-left": margin, "margin-right": margin });
    else
       el.css({ widht: width, height: size, "margin-top": margin, "margin-bottom": margin });
    };
    img.src = src;
};

RemedieUtil.mangleURI = function(url) {
  var uri = new URI(url);
  if (uri.authority != null && uri.authority.indexOf('@') > -1) {
    var host = uri.authority.split('@')[1];
    if (host) uri.authority = host;
  }
  return decodeURIComponent(uri.toString());
};

