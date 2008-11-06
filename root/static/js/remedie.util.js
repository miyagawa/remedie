function RemedieUtil() { }
RemedieUtil.prototype = { };
RemedieUtil.calcWindowSize = function(window_width) {
  var widths = [ 1920, 1280, 1024, 704 ];
  var i = 0;
  while (window_width < widths[i]) {
    i++;
    if (!widths[i]) {
      i--; break;
    }
  }
  return [ widths[i], widths[i] * 9/16 ];
};

RemedieUtil.formatBytes = function(bytes) {
  if (bytes <= 0) return '(Unknown)';
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

String.prototype.trimChars = function(length, append) {
  var string = this;
  if (string.length > length) {
    string = string.substring(0, length);
    string += append ? append : "..";
  }
  return string + '';
};

