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
  if (typeof bytes == 'undefined' || bytes <= 0) return '(Unknown)';
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
  return date.replace(/^(.*\w{3} \d{4}) \d\d:\d\d.*$/i, "$1");
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

