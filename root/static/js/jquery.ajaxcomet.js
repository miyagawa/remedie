;(function($) {
  $.extend({
    ajaxComet: function(options) {
      var callback = options.success;
      $.ajax({
        url: options.url,
        data: options.data,
        type: options.type,
        dataType: options.dataType,
        success: function(r) {
          $.ev.handlers[r.id] = function(ev) {
            callback(ev);
            delete $.ev.handlers[r.id];
          };
        }
      });
    }
  });
})(jQuery);
