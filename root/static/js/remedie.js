Remedie.version = '0.2.0';

function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  modifier: 'ctrl+',
  channels: [],
  items:    [],
  unblockCallbacks: [],
  current_id: null,

  initialize: function() {
    if (!jQuery.browser.safari && !jQuery.browser.mozilla && !jQuery.browser.msie) {
      alert("Your browser " + navigator.userAgent + " is not supported.");
      return;
    }

    $().ajaxSend(function(event,xhr,options) {
      xhr.setRequestHeader('X-Remedie-Client', 'Remedie/' + Remedie.version);
    });
//    $().ajaxStop($.unblockUI); // XXX This might cause issues when AJAX calls are made during flash playback

    this.setupMenuActions();
    this.setupEventListeners();
    this.setupHotKeys();
    this.setupPluginDefaults();
 
    this.loadCollection( this.dispatchAction );
  },

  setupHotKeys: function() {
    // Emacs and KeyRemap4Macbook users have problems with ctrl+ modifier key because
    // ctrl+n for example is remapped to 'down' key. For now, hijack the cmd+ modifier
    // key if the userAgent is Mac. We may need to be careful not stealing frequently
    // used hotkeys like cmd+r
    if (/mac/i.test(navigator.userAgent))
      this.modifier = 'command+';

    this.installHotKey('n', this.newChannelDialog);
    this.installHotKey('shift+r', function(){
      if (remedie.currentChannel()) {
        remedie.manuallyRefreshChannel(remedie.currentChannel());
      } else {
        remedie.channels.forEach(function(channel) {
          remedie.refreshChannel(channel);
        });
      }
    });
    this.installHotKey('shift+d', function(){
      if (remedie.currentChannel())  remedie.removeChannel(remedie.currentChannel())
    });
    this.installHotKey('shift+u', function(){ remedie.toggleChannelView(false) });
  
    $(document).bind('keydown', 'esc', $.unblockUI);
  },

  setupPluginDefaults: function() {
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

    var preload = new Image(); preload.src = '/static/images/spinner.gif';
    $.blockUI.defaults.message   = '<img src="/static/images/spinner.gif" style="vertical-align:middle;margin-right:1em" />Loading...';
    $.blockUI.defaults.onUnblock = function(){ remedie.runUnblockCallbacks() };

    $.contextMenu.defaults({
      menuStyle:         Menu.context.menu_style,
      itemStyle:         Menu.context.item_style,
      itemHoverStyle:    Menu.context.item_hover_style,
      itemDisabledStyle: Menu.context.item_disabled_style,
      shadow:            true
    });

    $(".blockOverlay").livequery('click', $.unblockUI);
  },

  setupMenuActions: function() {
    $(".new-channel-menu").click(this.newChannelDialog);
    $(".channel-list-menu").click(function(){ remedie.toggleChannelView(false) });

    $("#new-channel-form").submit( function(e) { remedie.createNewChannel(e); return false; } );
    $(".cancel-dialog").click( $.unblockUI );

    $(".about-dialog-menu").click(function(){ remedie.showAboutDialog() });

    $("#import-opml").click(this.importDialog);
    $("#import-opml-upload").click(function(){ remedie.uploadOPMLFile() });
  },

  setupEventListeners: function() {
    $(document).bind('remedieChannelUpdated', function(ev, channel) {
      remedie.redrawChannel(channel);
      remedie.redrawUnwatchedCount(channel);
    });
    $(document).bind('remedieChannelDisplayed', function(ev, channel) {
      document.title = 'Remedie: ' + channel.name;
      remedie.current_id = channel.id;
    });
    $(document).bind('remedieChannelUndisplayed', function(ev, channel) {
      document.title = "Remedie Media Center";
      remedie.current_id = null;
      remedie.items = [];
    });
  },

  installHotKey: function(key, callback) {
    $(document).bind('keydown', this.modifier+key, function(){
      callback.call(this);
      return false;
    });
  },

  dispatchAction: function() {
    var args = [];
    args = location.hash.split('/');
    if (args[0] == '#channel') {
      if (this.channels[args[1]])
        this.showChannel( this.channels[args[1]] );
    }
  },

  currentChannel: function() {
    return this.channels[ this.current_id ];
  },

  runOnUnblock: function(callback) {
    this.unblockCallbacks.push(callback);
  },

  runUnblockCallbacks: function() {
    jQuery.each(this.unblockCallbacks, function() {
      this.call();
    });
    this.unblockCallbacks = [];
  },

  launchVideoPlayer: function(item, player, fullscreen, iframe) {
    var channel = this.channels[ item.channel_id ];
    if (iframe) {
      var form = $("<form></form>").attr("target", "upload-frame")
        .attr("method", "post").ajaxSubmit({
        url: "/rpc/player/play_inline",
        data: { url: item.ident, player: player, fullscreen: fullscreen },
        type: 'post',
        dataType: 'html',
        iframe: true
      });
    } else {
      $.ajax({
        url: "/rpc/player/play",
        data: { url: item.ident, player: player, fullscreen: fullscreen },
        type: 'post',
        dataType: 'json',
        success: function(r) {
          if (r.success) {
          } else {
            alert(r.error);
          }
        }
      });
    }

    this.markItemAsWatched(item); // TODO setTimeout?
  },

  playVideoInline: function(item, player) {
    var channel_id = item.channel_id;
    var id   = item.id;
    var url  = item.ident;

    var ratio;
    var offset = {};
    if (item.props.link && url.match(/nicovideo\.jp/)) {
      // XXX
      player = 'Web';
      ratio = 3/4;
      offset.height = 24;
    } else if (item.props.embed) {
      player = 'Web';
      if (item.props.embed.width && item.props.embed.height) {
        ratio  = item.props.embed.height / item.props.embed.width;
      } else {
        ratio = 3/4;
      }
    } else {
      ratio = 9/16; // TODO
      offset.height = 18;
    }

    var res    = RemedieUtil.calcWindowSize($(window).width()-100, $(window).height()-80, ratio);
    var width  = res.width;
    var height = res.height;

    if (!player)
      player = this.defaultPlayerFor(item.props.type);

    if (url.match(/nicovideo\.jp/)) {
      $.ajax({
        url: "/rpc/player/nicovideo",
        type: 'post',
        data: { url: url, width: width, height: height },
        async: false,
        dataType: 'json',
        success: function(r) {
          item.props.embed = { code: r.code };
        }
      });
    }

    var thumbnail;
    if (item.props.type && item.props.type.match(/audio/)) {
      var thumb = item.props.thumbnail || this.channels[item.channel_id].props.thumbnail;
      width  = parseInt(thumb.width  || 256);
      height = parseInt(thumb.height || 256);
      thumbnail = thumb.url;
    }

    if (offset.width)  width  += offset.width;
    if (offset.height) height += offset.height;

    if (player == 'Web') {
      if (item.props.embed.code) {
         $('head').append("<script>" + item.props.embed.code + "</script>");
      } else {
        var s1 = new SWFObject(item.props.embed.url, 'player-' + item.id, width, height, '9');
        s1.addParam('allowfullscreen','true');
        s1.addParam('allowscriptaccess','always');
        s1.addParam('flashvars', 'bitrate=700000'); // Hulu
        s1.write('embed-player');
      }
    } else if (player == 'QuickTime') {
        var s1 = new QTObject(url, 'player-' + id, width,  height);
        s1.addParam('scale', 'Aspect');
        s1.addParam('target', 'QuickTimePlayer');
        s1.write('embed-player');
    } else if (player == 'WMP') {
        var s1 = new MPObject(url, 'player-' + id, width,  height);
        s1.addParam("autostart", "1");
        s1.write('embed-player');
    } else if (player == 'Silverlight') {
        var elm = document.getElementById("embed-player");
        var ply = new jeroenwijering.Player(elm, '/static/js/wmvplayer/wmvplayer.xaml', {
          file: url,
          width: width,
          height: height,
          link: item.props.link
//          autostart: true
        });
        this.autoPlaySilverlight(ply);

        // space key to play and pause the video
        $(document).bind('keydown', 'space', function(){
          if (ply.view) ply.sendEvent("PLAY");
          return false;
        });
        this.runOnUnblock(function(){$(document).unbind('keydown', 'space', function(){})});
    } else if (player == 'Flash') {
        var flashvars = [];
        flashvars.push('autostart=true');
        flashvars.push('file=' + encodeURIComponent(url));
        if (thumbnail)
          flashvars.push('image=' + encodeURIComponent(thumbnail));
        if (item.props.link)
          flashvars.push('link=' + encodeURIComponent(item.props.link));
      
        var s1 = new SWFObject('/static/player.swf', 'player-' + id, width, height, '9');
        s1.addParam('allowfullscreen','true');
        s1.addParam('allowscriptaccess','always');
        s1.addParam('flashvars', flashvars.join('&'));
        s1.write('embed-player');

        // space key to play and pause the video
        $(document).bind('keydown', 'space', function(){
          document.getElementById('player-'+id).sendEvent("PLAY");
          return false;
        });
        this.runOnUnblock(function(){$(document).unbind('keydown', 'space', function(){})});
    }

    this.runOnUnblock(function(){
      $('#embed-player').children().remove();
      remedie.markItemAsWatched(item); // TODO setTimeout?
    });

    $.blockUI({
      message: $('#embed-player'),
      css: { top:  ($(window).height() - height) / 2 + 'px',
             left: ($(window).width()  - width) / 2 + 'px',
             width:  width + 'px', height: 'auto',
             opacity: 1, padding: 0, border: '1px solid #fff', backgroundColor: '#fff',
             '-webkit-border-radius': 0, '-moz-border-radius': 0 }
      });
  },

  defaultPlayerFor: function(type) {
    // ASF + Mac -> QuickTime (Flip4Mac)
    // WMV + Mac -> Silverlight
    // WMV + Win -> Windows Media Player
    if (type.match(/wmv|asf/)) {
      if (/mac/i.test(navigator.userAgent)) {
        if (type.match(/wmv/i)) {
          player = 'Silverlight';
        } else {
          player = 'QuickTime';
        }
      } else {
        player = 'WMP';
      }
    } else {
      player = 'Flash';
    }
    return player;
  },

  autoPlaySilverlight: function(ply) {
    if (ply.view) {
      ply.sendEvent('PLAY')
    } else {
      setTimeout(function(){remedie.autoPlaySilverlight(ply)}, 100)
    }
  },

  markAllAsWatched: function(channel, showChannelView) {
    this.updateStatus({ id: channel.id, status: 'watched' }, function() {
      if (showChannelView) remedie.showChannel(channel);
    });
  },

  markItemAsWatched: function(item, sync) {
    this.updateStatus({ item_id: item.id, status: 'watched', sync: sync }, function() {
      $('#channel-item-title-' + item.id).removeClass('channel-item-unwatched');
      remedie.items[item.id].is_unwatched = false;
    });
  },

  markItemAsUnwatched: function(item) {
    // XXX should be 'downloaded' if it has local file
    this.updateStatus({ item_id: item.id, status: 'new' }, function() {
      $('#channel-item-title-' + item.id).addClass('channel-item-unwatched');
      remedie.items[item.id].is_unwatched = true;
    });
  },

  redrawUnwatchedCount: function(channel) {
    var count = channel.unwatched_count || 0;
    $('.unwatched-count-' + channel.id).each(function(){
      $(this).text(count);
    });
    this.renderUnwatchedBadges();
  },

  updateStatus: function(obj, callback) {
    $.ajax({
      url: "/rpc/channel/update_status",
      data: obj,
      type: 'post',
      dataType: 'json',
      async: (obj.sync ? false : true),
      success: function(r) {
        if (r.success) {
          remedie.channels[r.channel.id] = r.channel;
          callback.call();
          $.event.trigger('remedieChannelUpdated', r.channel);
        } else {
          alert(r.error);
        }
      }
    });
  },

  newChannelDialog: function() {
    $.blockUI({
      message: $("#new-channel-dialog")
    });
    return false;
  },

  importDialog: function() {
    $.blockUI({
      message: $("#import-opml-dialog")
    });
    return false;
  },

  uploadOPMLFile: function() {
    $('#import-opml-form').ajaxSubmit({
      url: "/rpc/collection/import_opml",
      type: 'post',
      dataType: 'text', // iframe downloads JSON
      iframe: true,
      success: function(r) {
        remedie.loadCollection(function(){
          $(r).text().split(/,/).forEach(function(id) {
            if (remedie.channels[id])
              remedie.refreshChannel(remedie.channels[id]);
          })
        });
      }
    });
  },

  toggleChannelView: function(display) {
    if (display) {
      $("#collection").hide();
      $("#channel-pane").show();
    } else {
      $.event.trigger('remedieChannelUndisplayed');
      $("#collection").show();
      $("#channel-pane").hide();
    }
    $.scrollTo({top:0});
    return false;
  },

  createNewChannel: function(el) {
    $.blockUI({ message: "Fetching ..." });
    $.ajax({
      url: "/rpc/channel/create",
      data: { url: jQuery.trim( $("#new-channel-url").attr('value') ) },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        $.unblockUI();
        if (r.success) {
          $("#new-channel-url").attr('value', '');

          remedie.channels[r.channel.id] = r.channel;
          remedie.renderChannelList(r.channel, $("#collection"));
          remedie.refreshChannel(r.channel)
        } else {
          alert(r.error);
        }
      }
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
        $.event.trigger("remedieChannelDisplayed", channel);

        var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/images/feed_256x256.png";
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

        $.each(r.items, function(index, item) {
          remedie.items[item.id] = item;
          $("#channel-items").createAppend(
           'div', { className: 'channel-item channel-item-selectable', id: 'channel-item-' + item.id  }, [
             'div', { className: 'item-thumbnail' }, [
               'a', { className: 'channel-item-clickable', href: item.ident, id: "item-thumbnail-" + item.id }, [
                 'img', { id: 'item-thumbnail-image-' + item.id,
                          src: thumbnail, alt: item.name, style: 'width: 128px' }, null
               ]
             ],
             'div', { className: 'item-infobox', style: "width: " + ($(window).width()-220) + "px" }, [
               'div', { className: 'item-infobox-misc' }, [
                  'ul', { className: 'inline' }, [
                    'li', { className: 'first' }, "size: " + RemedieUtil.formatBytes(item.props.size),
                    'li', {}, "updated: " + RemedieUtil.mangleDate(item.props.updated),
                    'li', {}, [ "a", { href: item.props.link, target: "_blank" }, "Link" ]
                  ],
               ],
               'h3', { id: 'channel-item-title-' + item.id,
                       className: item.is_unwatched ? 'channel-item-unwatched' : '' }, item.name,
               'div', { className: 'item-infobox-description' }, item.props.description
             ],
             'div', { className: "clear" }, null
           ]
         );

         if (item.props.thumbnail) {
           var img = new Image();
           img.onload = function(){
             var height = 128 * this.height / this.width;
             var margin = (128 * 3/4 - height) / 2;
             if (margin < 0) margin = 0;
             $("#item-thumbnail-image-" + item.id).attr("src", this.src).css({ "margin-top": margin, "margin-bottom": margin });
           };
           img.src = item.props.thumbnail.url;
         }
       });

       $(".channel-header")
        .contextMenu("channel-context-menu", {
          bindings: {
            channel_context_refresh:      function(){ remedie.manuallyRefreshChannel(channel) },
            channel_context_clear_stale:  function(){ remedie.manuallyRefreshChannel(channel, true) },
            channel_context_mark_watched: function(){ remedie.markAllAsWatched(channel, true) },
            channel_context_remove:       function(){ remedie.removeChannel(channel) }
          }
        });

       var fullscreen = 1; // TODO make it channel preference
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
                item_context_open:      function(){remedie.markItemAsWatched(item, true);location.href=item.ident},
                item_context_watched:   function(){remedie.markItemAsWatched(item)},
                item_context_unwatched: function(){remedie.markItemAsUnwatched(item)},
                item_context_play_vlc:  function(){remedie.launchVideoPlayer(item, 'VLC', fullscreen)},
                item_context_play_qt:   function(){remedie.launchVideoPlayer(item, 'QTL', fullscreen, 1)},
                item_context_play_qt_embed: function(){remedie.playVideoInline(item, 'QuickTime')},
                item_context_play_wmp:  function(){remedie.playVideoInline(item, 'WMP')},
                item_context_play_sl:   function(){remedie.playVideoInline(item, 'Silverlight')}
              },
              onContextMenu: function(e, menu) {
                item = remedie.items[ item.id ]; // refresh the status
                var el = $('#channel-item-context-menu ul'); el.children().remove();
                el.createAppend('li', { id: 'item_context_play' }, 'Play');
                el.createAppend('li', { id: 'item_context_copy' }, 'Copy Item URL (' + RemedieUtil.fileType(item.ident, item.props.type) + ')');
                el.createAppend('li', { id: 'item_context_open' }, 'Open URL with browser');
                if (item.is_unwatched) {
                  el.createAppend('li', { id: 'item_context_watched' }, 'Mark as watched');
                } else {
                  el.createAppend('li', { id: 'item_context_unwatched' }, 'Mark as unwatched');
                }

                if (/video/i.test(item.props.type)) {
                  el.createAppend('li', { id: 'item_context_play_vlc' }, 'Launch VLC');
                  el.createAppend('li', { id: 'item_context_play_qt' }, 'Launch QuickTime');
                  el.createAppend('li', { id: 'item_context_play_qt_embed' }, 'Play inline with QuickTime');
                }

                if (/wmv|asf/i.test(item.props.type)) {
                  if (!/mac/i.test(navigator.userAgent))
                    el.createAppend('li', { id: 'item_context_play_wmp' }, 'Play inline with WMP');
                  el.createAppend('li', { id: 'item_context_play_sl' }, 'Play inline with Silverlight');
                }

                return true;
              }
           });
         });

         $(".channel-item-clickable").click(function(){
           remedie.playVideoInline( remedie.items[this.id.replace("item-thumbnail-", "")] );
         });
         $(".item-thumbnail")
          .hover(function(){
             $(this).prepend($("<div/>").attr('id', 'play-button-'+channel.id)
               .addClass("channel-item-play").corners("10px transparent").css({opacity:0.6})
               .append($("<a/>").text("PLAY").click(function(){$(this).parent().next().trigger('click')})))
          }, function(){
             $('.channel-item-play').remove();
          });

        remedie.toggleChannelView(true);
      },
      error: function(r) {
        alert("Can't load the channel");
      }
    });
  },

  manuallyRefreshChannel: function(channel, clearStaleItems) {
    $.blockUI();
    this.refreshChannel(channel, true, clearStaleItems);
  },

  refreshChannel : function(channel, refreshView, clearStaleItems) {
    if (!channel)
      return; // TODO error message?

    $("#channel-" + channel.id + " .channel-thumbnail").css({opacity:0.3});
    $("#channel-" + channel.id + " .channel-unwatched-hover").css({opacity:0.3});
    $("#channel-" + channel.id + " .channel-refresh-hover").show();
    $.ajax({
      url: "/rpc/channel/refresh",
      data: { id: channel.id, clear_stale: clearStaleItems ? 1 : 0 },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        $.unblockUI();
        if (r.success) {
          remedie.channels[r.channel.id] = r.channel;
          $.event.trigger('remedieChannelUpdated', r.channel);
          if (refreshView)
            remedie.showChannel(r.channel);
        } else {
          $.event.trigger('remedieChannelUpdated', channel); // Fake updated Event to cancel animation
          alert(r.error);
        }
      }
    });
  },

  removeChannel : function(channel) {
    if (!channel)
      return; // TODO error message?

    if (!window.confirm("Are you sure you want to delete " + channel.name + "?"))
      return;

    $.ajax({
      url: "/rpc/channel/remove",
      data: { id: channel.id },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          $('#channel-'+channel.id).remove();
          remedie.channels[channel.id] = null;
          remedie.toggleChannelView(false);
        } else {
          alert(r.error);
        }
      }
    });
  },

  loadCollection: function(callback) {
    $.blockUI();
    $.ajax({
      url: "/rpc/channel/load",
      type: 'get',
      dataType: 'json',
      success: function(r) {
        $("#collection").children().remove();
        $.each(r.channels, function(index, channel) {
          remedie.channels[channel.id] = channel;
          remedie.renderChannelList(channel, $("#collection"));
          remedie.redrawUnwatchedCount(channel);
        });
        $.unblockUI();
        if (callback)
          callback.call(remedie);
      },
      error: function(r) {
        alert("Can't load subscription");
      }
    });
  },

  renderChannelList: function(channel, container) {
    var thumbnail;
    var default_thumbnail;
    if (channel.props.thumbnail) {
      thumbnail = channel.props.thumbnail.url;
    } else if (channel.first_item && channel.first_item.props.thumbnail) {
      thumbnail = channel.first_item.props.thumbnail.url;
    } else {
      thumbnail = "/static/images/feed_256x256.png";
      default_thumbnail = 1;
    }

    container.createAppend(
      'div', { className: 'channel channel-clickable', id: 'channel-' + channel.id  }, [
        'a', { href: '#channel/' + channel.id }, [
          'div', { className: 'channel-thumbnail-wrapper' }, [
            'img', { id: "channel-thumbnail-image-" + channel.id,
                     src: "/static/images/feed_256x256.png", alt: channel.name, className: 'channel-thumbnail' }, null
          ],
          'div', { className: 'channel-unwatched-hover unwatched-count-' + channel.id },
                (channel.unwatched_count || 0) + '',
          'div', { className: 'channel-refresh-hover' }, [
            'img', { src: "/static/images/spinner.gif" }
          ],
          'div', { className: 'channel-title' }, channel.name.trimChars(24)
        ]
      ]
    );
    $("#channel-" + channel.id)
      .click( function(){ remedie.showChannel(channel) } )
      .hover( function(){ $(this).addClass("hover-channel") },
              function(){ $(this).removeClass("hover-channel") } )
      .contextMenu("channel-context-menu", {
        bindings: {
          channel_context_refresh:      function(){ remedie.refreshChannel(channel) },
          channel_context_mark_watched: function(){ remedie.markAllAsWatched(channel, false) },
          channel_context_remove:       function(){ remedie.removeChannel(channel) }
        }
      });

    if (!default_thumbnail) {
       var img = new Image();
       img.onload = function(){
         var height = 192 * this.height / this.width;
         var margin = (192  - height) / 2;
         if (margin < 0) margin = 0;
         $("#channel-thumbnail-image-" + channel.id).attr("src", this.src).css({ "margin-top": margin, "margin-bottom": margin });
       };
       img.src = thumbnail;
     }
  },

  redrawChannel: function(channel) {
    var id = "#channel-" + channel.id;

    $(id + " .channel-thumbnail").css({opacity:1});
    $(id + " .channel-unwatched-hover").css({opacity:1});
    $(id + " .channel-refresh-hover").hide();

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
  }
};
