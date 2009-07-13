;(function($) {
  $.extend({
    ajaxComet: function(options) {
      var callback = options.success;
      $.ajax({
        url: options.url,
        data: options.data,
        type: options.type,
        dataType: options.dataType,
        success: function(events) {
          $.each(events, function(index, id) {
            $.ev.handlers[id] = function(ev) {
              callback(ev);
              delete $.ev.handlers[id];
            };
          });
        }
      });
    }
  });
})(jQuery);
