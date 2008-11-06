Remedie.version = '0.1.0';

function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    $(".new-channel-menu").click(this.displayNewChannel);
    $(".channel-list-menu").click(function(){ remedie.toggleChannelView(false) });

    $("#new-channel-form").submit( function(e) { remedie.newChannel(e); return false; } );
    $("#new-channel-cancel").click( $.unblockUI );

    $(".about-dialog-menu").click(function(){ remedie.showAboutDialog(true) });

    $().ajaxSend(function(event,xhr,options) {
      xhr.setRequestHeader('X-Remedie-Client', 'Remedie Media Center/' + Remedie.version);
    });
    $().ajaxStop($.unblockUI); // XXX This might cause issues when AJAX calls are made during flash playback

    // Emacs and KeyRemap4Macbook users have problems with ctrl+ modifier key because
    // ctrl+n for example is remapped to 'down' key. For now, hijack the cmd+ modifier
    // key if the userAgent is Mac. We may need to be careful not stealing frequently
    // used hotkeys like cmd+r
    if (/mac/i.test(navigator.userAgent))
      this.modifier = 'command+';

    $(document).bind('keydown', this.modifier+'n', this.displayNewChannel);
    $(document).bind('keydown', 'esc', $.unblockUI);

    $.blockUI.defaults.css = {
      padding:        '15px',
      margin:         0,
      width:          '30%',
      top:            '40%',
      left:           '35%',
      textAlign:      'center',
      color:          '#fff',
      border:         'none',
      backgroundColor:'#222',
      cursor:         'wait',
      opacity:        '.8',
      '-webkit-border-radius': '10px',
      '-moz-border-radius': '10px'
    };

    $.blockUI.defaults.message   = '<img src="/static/images/spinner.gif" style="vertical-align:middle;margin-right:1em" />Loading...';
    $.blockUI.defaults.onUnblock = function(){ remedie.runUnblockCallbacks() };

    this.loadCollection();
  },

  modifier: 'ctrl+',
  channels: [],
  items:    [],
  unblockCallbacks: [],

  runOnUnblock: function(callback) {
    this.unblockCallbacks.push(callback);
  },

  runUnblockCallbacks: function() {
    jQuery.each(this.unblockCallbacks, function() {
      this.call();
    });
    this.unblockCallbacks = [];
  },

  launchVideoPlayer: function(item, player) {
    var channel = this.channels[ item.channel_id ];
    $.ajax({
      url: "/rpc/player/play",
      data: { url: item.ident, player: player },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
        } else {
          alert(r.error);
        }
      },
    });
    this.markItemAsWatched(channel.id, item.id);
  },

  playVideoInline: function(item, player) {
    var channel_id = item.channel_id;
    var id   = item.id;
    var url  = item.ident;

    var wh = RemedieUtil.calcWindowSize($(window).width());
    var width  = wh[0];
    var height = wh[1] + 20; // slider and buttons

    if (player == 'QTEmbed') {
        var s1 = new QTObject(url, 'player-' + id, width,  height);
        s1.addParam('scale', 'Aspect');
        s1.addParam('target', 'QuickTimePlayer');
        s1.write('flash-player');
    } else if (player == 'Silverlight') {
        var elm = document.getElementById("flash-player");
        var ply = new jeroenwijering.Player(elm, '/static/js/wmvplayer/wmvplayer.xaml', {
          file: url,
          width: width,
          height: height,
//          autostart: true
        });
        this.autoPlaySilverlight(ply);

        // space key to play and pause the video
        $(document).bind('keydown', 'space', function(){
          if (ply.view) ply.sendEvent("PLAY");
          return false;
        });
        this.runOnUnblock(function(){$(document).unbind('keydown', 'space', function(){})});
    } else {
        var s1 = new SWFObject('/static/player.swf', 'player-' + id, width, height, '9');
        s1.addParam('allowfullscreen','true');
        s1.addParam('allowscriptaccess','always');
        s1.addParam('flashvars','autostart=true&file=' + url);
        s1.write('flash-player');

        // space key to play and pause the video
        $(document).bind('keydown', 'space', function(){
          document.getElementById('player-'+id).sendEvent("PLAY");
          return false;
        });
        this.runOnUnblock(function(){$(document).unbind('keydown', 'space', function(){})});
    }

    $('#flash-player').createAppend(
     'div', { className: 'close-button' }, [
        'a', {}, "Click here to close the Player"
      ]
    ).click($.unblockUI);

    this.runOnUnblock(function(){
      $('#flash-player').children().remove();
      remedie.markItemAsWatched(channel_id, id);
    });

    $.blockUI({
      message: $('#flash-player'),
      css: { top:  ($(window).height() - height) / 2 - 6 + 'px',
             left: ($(window).width()  - width) / 2 + 'px',
             width:  wh[0] + 'px',
             opacity: 1, padding: 0, border: '1px solid #fff', backgroundColor: '#fff',
             '-webkit-border-radius': 0, '-moz-border-radius': 0 }
      });
  },

  autoPlaySilverlight: function(ply) {
    if (ply.view) {
      ply.sendEvent('PLAY')
    } else {
      setTimeout(function(){remedie.autoPlaySilverlight(ply)}, 100)
    }
  },

  markItemAsWatched: function(channel_id, id) {
    this.updateStatus({ item_id: id, status: 'watched' });
    $('#channel-item-title-' + id).removeClass('channel-item-unwatched');
  },

  markItemAsUnwatched: function(channel_id, id) {
    this.updateStatus({ item_id: id, status: 'new' }); // # XXX should be 'downloaded' if it has local file
    $('#channel-item-title-' + id).addClass('channel-item-unwatched');
  },

  redrawUnwatchedCount: function(channel_id) {
    var count = remedie.channels[channel_id].unwatched_count || 0;
    $('.unwatched-count-' + channel_id).each(function(){
      $(this).text(count);
    });
    this.renderUnwatchedBadges();
  },

  updateStatus: function(obj) {
    $.ajax({
      url: "/rpc/channel/update_status",
      data: obj,
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          remedie.channels[r.channel.id] = r.channel;
          remedie.redrawUnwatchedCount(r.channel.id);
        } else {
          alert(r.error);
        }
      },
    });
  },

  displayNewChannel: function() {
    $.blockUI({
      message: $("#new-channel-dialog"),
    });
    return false;
  },

  toggleChannelView: function(display) {
    if (display) {
      $("#subscription").hide();
      $("#channel-pane").show();
    } else {
      // Ugh, shouldn't be here
      document.title = "Remedie Media Center";
      $("#subscription").show();
      $("#channel-pane").hide();
    }
    return false;
  },

  newChannel: function(el) {
    $.blockUI({ message: "Fetching ..." });
    $.ajax({
      url: "/rpc/channel/create",
      data: { url: jQuery.trim( $("#new-channel-url").attr('value') ) },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          $("#new-channel-url").attr('value', '');
          $.unblockUI();
          remedie.channels[r.channel.id] = r.channel;
          remedie.renderChannel(r.channel, $("#subscription"));
          remedie.renderUnwatchedBadges();
          remedie.refreshChannel(r.channel)
        } else {
          alert(r.error);
        }
      },
    });
    return false;
  },

  showChannel: function(channel) {
    $.ajax({
      url: "/rpc/channel/show",
      type: 'get',
      data: { id: channel.id },
      dataType: 'json',
      success: function(r) {
        $("#channel-pane").children().remove();
        var channel = r.channel;
        document.title = "Remedie: " + channel.name;
        var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/images/feed_128x128.png";
        $("#channel-pane").createAppend(
         'div', { className: 'channel-header', id: 'channel-header-' + channel.id  }, [
           'div', { className: 'channel-header-thumbnail' }, [
             'img', { src: thumbnail, alt: channel.name }, null
           ],
           'div', { className: 'channel-header-infobox', style: 'width: ' + ($(window).width()-220) + 'px' }, [
              'h2', { className: 'channel-header-title' }, [ 'a', { href: channel.props.link, target: "_blank" }, channel.name ],
              'div', { className: 'channel-header-data' }, [
                'a', { href: channel.ident, target: "_blank" }, channel.ident.trimChars(100),
                'br', {}, null,
                'span', {}, r.items.length + ' items, ' +
                  '<span class="unwatched-count-' + channel.id + '">' + 
                  (channel.unwatched_count ? channel.unwatched_count : 0) + '</span> unwatched'
              ],
              'p', { className: 'channel-header-description' }, channel.props.description
            ],
            'div', { className: "claer" }, null
          ]
        );

        $("#channel-pane").createAppend(
          'div', { id: 'channel-items', className: "clear" }, null
        );

        for (i = 0; i < r.items.length; i++) {
          var item = r.items[i];
          remedie.items[item.id] = item;
          var item_thumb = item.props.thumbnail ? item.props.thumbnail.url : null;
          $("#channel-items").createAppend(
           'div', { className: 'channel-item channel-item-selectable', id: 'channel-item-' + item.id  }, [
             'div', { className: 'item-thumbnail' }, [
               'a', { className: 'channel-item-clickable', href: item.ident, id: "item-thumbnail-" + item.id }, [
                 // TODO load placeholder default image and replace later with new Image + onload
                 'img', { src: item_thumb || thumbnail, alt: item.name, style: 'width: 128px',
                          onload: "remedie.resizeThumb(this)" }, null
               ]
             ],
             'div', { className: 'item-infobox', style: "width: " + ($(window).width()-220) + "px" }, [
               'div', { className: 'item-infobox-misc' }, [
                  'ul', { className: 'inline' }, [
                    'li', { className: 'first' }, "size: " + RemedieUtil.formatBytes(item.props.size),
                    'li', {}, "updated: " + RemedieUtil.mangleDate(item.props.updated),
                  ],
               ],
               'h3', { id: 'channel-item-title-' + item.id,
                       className: item.is_unwatched ? 'channel-item-unwatched' : '' }, item.name,
               'p', { className: 'item-infobox-description' }, item.props.description
             ],
             'div', { className: "clear" }, null
           ]
         );
       }

       $(".channel-item-selectable")
         .hover(function(){
           $(this).addClass("hover-channel-item");
           $(this).css('opacity',0.8)},
         function(){
           $(this).removeClass("hover-channel-item");
           $(this).css('opacity',1)})
         .each(function() {
            var item = remedie.items[ this.id.replace("channel-item-", "") ];
            $(this).contextMenu("channel-item-context-menu", {
              bindings: {
                item_context_play:      function(){remedie.playVideoInline(item)},
                item_context_copy:      function(){$.copy(item.ident)},
                item_context_watched:   function(){remedie.markItemAsWatched(item.channel_id, item.id)},
                item_context_unwatched: function(){remedie.markItemAsUnwatched(item.channel_id, item.id)},
                item_context_play_vlc:  function(){remedie.launchVideoPlayer(item, 'VLC')},
                item_context_play_qt:   function(){remedie.launchVideoPlayer(item, 'QuickTime')},
                item_context_play_qt_embed: function(){remedie.playVideoInline(item, 'QTEmbed')},
                item_context_play_sl:   function(){remedie.playVideoInline(item, 'Silverlight')}
              },
              menuStyle:         Menu.context.menu_style,
              itemStyle:         Menu.context.item_style,
              itemHoverStyle:    Menu.context.item_hover_style,
              itemDisabledStyle: Menu.context.item_disabled_style,
              shadow:            false,
           });
         });

        $(".channel-item-clickable")
          .click(function(){
            remedie.playVideoInline( remedie.items[this.id.replace("item-thumbnail-", "")], 'Flash' ) });

// TODO Should be unbound when this view is gone
//        $(document).bind('keydown', remedie.modifier+'shift+r', function(){
//          remedie.refreshChannel(channel, true);
//        });

        remedie.toggleChannelView(true);
      },
      error: function(r) {
        alert("Can't load the channel");
      }
    });
  },

  refreshChannel : function(channel, refreshView) {
    // TODO animated icon on top of thumbnail
    $.ajax({
      url: "/rpc/channel/refresh",
      data: { id: channel.id },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          // TODO remove animated icon
          remedie.redrawChannel(r.channel);
          if (refreshView)
            remedie.showChannel(r.channel);
        } else {
          alert(r.error);
        }
      },
    });

  },

  loadCollection: function() {
    $.blockUI();
    $.ajax({
      url: "/rpc/channel/load",
      type: 'get',
      dataType: 'json',
      success: function(r) {
        for (i = 0; i < r.channels.length; i++) {
          var channel = r.channels[i];
          remedie.channels[channel.id] = channel;
          remedie.renderChannel(channel, $("#subscription"));
        }
        remedie.renderUnwatchedBadges();
      },
      error: function(r) {
        alert("Can't load subscription");
      }
    });
  },

  renderChannel: function(channel, container) {
    var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/images/feed_256x256.png";
    container.createAppend(
      'div', { className: 'channel channel-clickable', id: 'channel-' + channel.id  }, [
        'img', { src: thumbnail, alt: channel.name, className: 'channel-thumbnail' }, null,
        'div', { className: 'channel-unwatched-hover unwatched-count-' + channel.id },
              (channel.unwatched_count || 0) + '',
        'div', { className: 'channel-title' }, channel.name.trimChars(24)
      ]
    );
    $("#channel-" + channel.id)
      .click( function(){ remedie.showChannel(channel) } )
      .hover( function(){ $(this).addClass("hover-channel") },
              function(){ $(this).removeClass("hover-channel") } );
  },

  redrawChannel: function(channel) {
    var id = "#channel-" + channel.id;
//    if ($(id).size() == 0)
//       return this.renderChannel(channel, $("#subscription"));

    if (channel.props.thumbnail) 
      $(id + " .channel-thumbnail").attr('src', channel.props.thumbnail.url);

    if (channel.name) 
      $(id + " .channel-title").text(channel.name);

  },

  renderUnwatchedBadges: function() {
    $(".channel-unwatched-hover").each(function(){
      var count = parseInt($(this).text());
      if (count > 0) {
        $(this).show();
        $(this).corners("10px transparent");
      } else {
        $(this).hide();
      }
     });
  },

  resizeThumb: function(el) {
    el.style.width = 128;
    if (el.height > el.width) {
      el.style.height = 128;
    } else {
      el.style.height = 128 * el.height / el.width;
    }
  },

  showAboutDialog: function() {
      var message = $('<div/>').createAppend(
           'div', { id: "about-dialog" }, [
              'h2', {}, 'Remedie Media Center ' + Remedie.version,
              'p', {}, [
                  'a', { href: "http://code.google.com/p/remedie/", target: "_blank" }, 'Source code'
              ],
              'a', { className: 'command-unblock' }, 'Close this window'
          ])
      message.children("a.command-unblock").click($.unblockUI);
      $.blockUI({ message: message });
      return false;
  },

};
