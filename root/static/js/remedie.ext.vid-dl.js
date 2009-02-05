$(document).bind('remedie-item-contextmenu', function(ev, args) {
  if (args.item.type == 3) { // TODO change this 3 to something else
    args.bindings['item_context_ext_vid_dl'] = function() {
      window.open("http://www.vid-dl.net/?url=" + encodeURIComponent(args.item.props.link));
    };
    args.actions.push([ 'item_context_ext_vid_dl', 'Download with Vid-DL' ]);
  }
});
