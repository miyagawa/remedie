$(document).bind('remedie-item-contextmenu', function(ev, args) {
  if (/nicovideo\.jp\/watch\/([a-z]{2}[0-9]+)/.test(args.item.props.link)) {
    var id = RegExp.$1;
    args.bindings['item_context_ext_nicovideo_download'] = function() {
      window.open("http://127.0.0.1/action/nph-download-proxy.cgi/" + id);
    };
    args.actions.push([ 'li', { id: 'item_context_ext_nicovideo_download' }, 'Download file via CGI' ]);
  }
});
