Remedie.version = '0.3.0';

function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  channels: [],
  items:    [],
  unblockCallbacks: [],
  current_id: null,
  hotkeys: [],
  onPlaybackComplete: null,

  initialize: function() {
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
    this.installHotKey('shift+n', 'New channel', function(){ remedie.newChannelDialog() });
    this.installHotKey('r', 'Reload (all) channel', function(){
      if (remedie.currentChannel())
        remedie.showChannel(remedie.currentChannel());
      else
        remedie.loadCollection();
    });
    this.installHotKey('shift+r', 'Update (all) channel', function(){
      if (remedie.currentChannel()) {
        remedie.manuallyRefreshChannel(remedie.currentChannel());
      } else {
        remedie.channels.forEach(function(channel) {
          remedie.refreshChannel(channel);
        });
      }
    });
    this.installHotKey('del', 'Unsubscribe channel', function(){
      if (remedie.currentChannel())  remedie.removeChannel(remedie.currentChannel())
    });
    this.installHotKey('u', 'Back to channel view', function(){
      if (remedie.current_id) {
        remedie.toggleChannelView(false);
        location.href = "#menu";
      }
    });
    this.installHotKey('shift+u', 'Mark all as watched', function(){
      if (remedie.current_id) remedie.markAllAsWatched(remedie.currentChannel(), true)
    });

    // vi like keyborad shortcut.
    this.installHotKey('h', 'Move to the right (next) channel', function(){
      if (remedie.current_id)
        location.href = $("#channel-pane .prev-channel").click().attr('href');
      else
        remedie.moveCursorPrev();
    });
    this.installHotKey('l', 'Move to the left (previous) channel', function(){
      if (remedie.current_id)
        location.href = $("#channel-pane .next-channel").click().attr('href');
      else
        remedie.moveCursorNext();
    });
    this.installHotKey('j', 'Move to the next (down) channel (or item)', function(){
      if (remedie.current_id)
        remedie.moveCursorNext()
      else
        remedie.moveCursorDown()
    });
    this.installHotKey('k', 'Move to the previous (up) channel (or item)', function(){
      if (remedie.current_id)
        remedie.moveCursorPrev()
      else
        remedie.moveCursorUp()
    });

    this.installHotKey('left', 'Move to the left channel / rewind to the previous video (in playback)', function(){
      if (!remedie.current_id) remedie.moveCursorPrev();
    });
    this.installHotKey('right', 'Move to the right channel / fast forward to the next video (in playback)', function(){
      if (!remedie.current_id)    remedie.moveCursorNext();
    });
    this.installHotKey('up',   'Move to the previous item (up)', function(){
      if (remedie.current_id) remedie.moveCursorPrev();
      else                    remedie.moveCursorUp();
    });
    this.installHotKey('down', 'Move up the next item (down)', function(){
      if (remedie.current_id) remedie.moveCursorNext();
      else                    remedie.moveCursorDown();
    });

    this.installHotKey('o', 'Open channel (or play/close item)', function(){
      if (remedie.current_id) {
        if ( remedie.isPlayingVideo ) {
          Shadowbox.close();
          return false;
        } else {
          var items = $('.channel-item');
          if (items) remedie.playVideoInline(remedie.items[items[remedie.cursorPos].id.replace("channel-item-", "")]);
          return false;
        }
      } else {
        var channels = $('.channel');
        if (channels) {
          var channel_id = channels[remedie.cursorPos].id.replace("channel-", "");
          remedie.showChannel(remedie.channels[channel_id]);
        }
        return false;
      }
    });
    this.installHotKey('esc', 'Close embed player (or dialog)', $.unblockUI, true);
    this.installHotKey('shift+h', 'Show this help', function() {
      var message = $('<div/>').createAppend(
           'div', { id: "keyboard-shortcut-help-dialog" }, [
              'h2', {}, 'Keyboard shortcuts',
              'hr', {}, null,
              'div', { className: 'keyboard-shortcuts', style: 'text-align: left' }, null,
              'br', {}, null
          ]);
      var container = $("div.keyboard-shortcuts", message);
      $.each(remedie.hotkeys, function(index, info) {
         var key = info.key;
         if (key.match(/shift\+/)) {
           key = key.replace(/shift\+/, '').toUpperCase() + " (" + key + ")";
         }
         container.append('<em>' + key + '</em>: ' + info.desc + '<br/>');
      });
      $.blockUI({
        message: message,
        css: { top: '50px' }
      });
    });
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
      opacity:        '.8',
      cursor:         'auto',
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

    $.jGrowl.defaults.closer = false;
    $.jGrowl.defaults.speed  = 1000;

    $(".blockOverlay").live('click', $.unblockUI);
    $("#shadowbox_overlay").live('dblclick', Shadowbox.close);
    $(".show-all-items").live('click', function() {
      $.blockUI();
      remedie.showChannel(remedie.currentChannel(), { all: true });
    });
    $(".show-unwatched-items").live('click', function() {
      remedie.showChannel(remedie.currentChannel(), { unwatched: true, all: true });
    });
  },

  setupMenuActions: function() {
    $(".new-channel-menu").click(function(){ remedie.newChannelDialog() });
    $(".channel-list-menu").click(function(){ remedie.toggleChannelView(false) });

    $("#new-channel-form").submit( function(e) { remedie.createNewChannel(e); return false; } );
    $(".cancel-dialog").click( $.unblockUI );

    $(".about-dialog-menu").click(function(){ remedie.showAboutDialog() });

    $("#import-opml").click(this.importDialog);
    $("#import-opml-upload").click(function(){ remedie.uploadOPMLFile() });
  },

  setupEventListeners: function() {
    $(document).bind('remedie-channel-updated', function(ev, args) {
      remedie.redrawChannel(args.channel);
      remedie.redrawUnwatchedCount(args.channel);
      remedie.renderUnwatchedBadges();
      if (!args.skip_notification)
        remedie.notifyNewItems(args.channel, args.prev);
    });
    $(document).bind('remedie-channel-ondisplay', function(ev, channel) {
      document.title = 'Remedie: ' + channel.name;
      if (channel.unwatched_count) document.title += " (" + channel.unwatched_count + ")";

      // RSS auto discovery
      var baseURL = location.href.replace(/^(http:\/\/.*?\/).*$/, "$1");
      $('head link[rel="alternate"]').remove();
      $('head').append(
        $("<link/>").attr("rel", "alternate").attr("type", "application/rss+xml").attr("title", "Media RSS")
          .attr("href", baseURL + "rpc/channel/rss?id=" + channel.id).attr("id", "gallery")
      );

      remedie.current_id = channel.id;
    });
    $(document).bind('remedie-channel-onhidden', function(ev, channel) {
      document.title = "Remedie Media Center";
      remedie.current_id = null;
      remedie.items = [];
    });
    $(document).bind('remedie-item-loaded', function(ev, args) {
      var item = args.item;
      if (item.is_unwatched)
        remedie.markItemAsWatched(item);

      remedie.isPlayingVideo  = true;
      remedie.lastPlayedVideo = item;
      remedie.cursorPos = $('.channel-item').index($('#channel-item-' + item.id));

      // make Shadowbox title header a link to the item page
      if (item.props.link) {
        var title = $('#shadowbox_title_inner').html();
        $('#shadowbox_title_inner').empty().createAppend(
          'a', { href: item.props.link, target: '_blank' }, title
        );
      }
    });
  },

  installHotKey: function(key, description, callback, always) {
    this.hotkeys.push({key:key, desc:description});
    $(document).bind('keydown', key, function(ev){
      if (always || !/INPUT|TEXTAREA/i.test((ev.srcElement || ev.target).nodeName)) {
        callback.call(this);
        return false;
      }
    });
  },

  dispatchAction: function() {
    var args = [];
    args = location.hash.split('/');
    if (args[0] == '#channel') {
      if (this.channels[args[1]])
        var opts = {};
        if (args[2] == 'all')       opts.all = 1;
        if (args[2] == 'unwatched') opts.unwatched = 1;
        this.showChannel( this.channels[args[1]], opts );
    } else if (args[0] == '#subscribe') {
      this.newChannelDialog(decodeURIComponent(args[1]));
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

  // TODO: eventually this notification should be triggered on the server side and broadcast over comet
  notifyNewItems: function(channel, prev) {
    var diff = channel.unwatched_count - prev.unwatched_count;
    if (prev != undefined && diff > 0) {
      var item = channel.first_item;
      if (item) {
        var icon;
        var thumb = item.props.thumbnail || channel.props.thumbnail;
        if (thumb != null && thumb.url)
          icon = thumb.url;
        var msg = item.name;
        if (diff > 1) msg += " (" + (diff - 1) + " more)";
        $.jGrowl(msg, { icon: icon, header: channel.name, life: 5000 });
      }
    }
  },

  launchVideoPlayer: function(item, player, fullscreen, iframe) {
    var channel = this.channels[ item.channel_id ];
    var url;
    if (item.props.download_path) {
      url = item.props.download_path;
    } else {
      url = item.ident;
    }

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
        data: { url: url, player: player, fullscreen: fullscreen },
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

  isPlayingVideo: false,
  lastPlayedVideo: null,

  playVideoInline: function(item, player, opts) {
    if (!opts) opts = {};

    // callback to upgrade {id:id} to the full gallery item for Shadowbox
    var loadGalleryItem = function(gallery) {
      var item = remedie.items[gallery.id]
      var nextItem = remedie.getShadowboxGallery(item, player, opts);
      var callback;
      if (perItemCallback = nextItem.onFinish) {
        callback = function(args) {
          $.event.trigger('remedie-item-loaded', { item: item });
          perItemCallback.call(args);
        };
      } else {
        callback = function() { $.event.trigger('remedie-item-loaded', { item: item }) };
      }
      $.extend(gallery, nextItem);
      Shadowbox.applyOptions({ onFinish: callback });
    };

    if (opts.thisItemOnly || !item.is_unwatched) {
      this.onPlaybackComplete = Shadowbox.close;
      Shadowbox.open({ id: item.id }, {
        gallery: 'gallery' + item.channel_id,
        onOpen:  loadGalleryItem
      });
    } else {
      this.onPlaybackComplete = function() { setTimeout(function(){ Shadowbox.next() }, 100) };
      var items = $('.channel-item-unwatched');
      var curr  = items.index($("#channel-item-title-" + item.id));
      items = items.slice(curr, items.length);
      var galleryItems = $.map(items, function(n, i) { return { id: n.id.replace('channel-item-title-', '') } });
      Shadowbox.open(galleryItems, {
        gallery:  'gallery' + item.channel_id,
        onChange: loadGalleryItem,
        onOpen:   loadGalleryItem
      });
    }

    Shadowbox.applyOptions({
      onClose: function() {
        remedie.isPlayingVideo = false;
        // Hmm, need to call this twice to make it completely reset
        Shadowbox.applyOptions({ onFinish: null, onOpen: null, onChange: null });
        Shadowbox.applyOptions({ onFinish: null, onOpen: null, onChange: null });
      }
    });
  },

  getShadowboxGallery: function(item, player, opts) {
    if (!opts) opts = {};
    var channel_id = item.channel_id;
    var id   = item.id;
    var url  = item.ident;

    var ratio;
    var thumbnail;
    if (item.props.link && url.match(/nicovideo\.jp/)) {
      // XXX
      player = 'Web';
      ratio = 3/4;
    } else if (item.props.embed) {
      if (/shockwave/i.test(item.props.type)) {
        player = 'Web';
      } else if (/x?html/.test(item.props.type)) {
        player = 'iframe';
      }
      if (item.props.embed.width && item.props.embed.height) {
        ratio  = item.props.embed.height / item.props.embed.width;
      } else {
        ratio = 9/16; // TODO configurable
      }
    } else {
      if (item.props.type && item.props.type.match(/audio/)) {
        var thumb = item.props.thumbnail || this.channels[item.channel_id].props.thumbnail;
        ratio = parseInt(thumb.height  || 256) / parseInt(thumb.width || 256);
        thumbnail = thumb ? thumb.url : undefined;
      } else {
        ratio = (item.props.height && item.props.width)
          ? (item.props.height / item.props.width) : 9/16; // TODO
      }
    }

    var res    = RemedieUtil.calcWindowSize($(window).width()-100, $(window).height()-94, ratio);
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
          if (r.code) {
            item.props.embed = { script: r.code };
          } else if (r.error) {
            throw r.error;
          }
        }
      });
    }

    if (player == 'Web') {
      if (item.props.embed.script) {
        return {
          player:  'html',
          title:   item.name,
          height:  height,
          width:   width,
          content: '<div id="embed-player"></div>',
          onFinish: function() {
            $('head').append("<script>" + item.props.embed.script + "</script>");
          }
        };
      } else {
        return {
          player:  'html',
          title:   item.name,
          height:  height,
          width:   width,
          content: '<div id="embed-player"></div>',
          onFinish: function() {
            var s1 = new SWFObject(item.props.embed.url, 'player-' + item.id, width, height, '9');
            s1.addParam('allowfullscreen','true');
            s1.addParam('allowscriptaccess','always');
            s1.write('embed-player');

            // TODO: This might be better pluggable
            // Handle YouTube callback
            // http://code.google.com/apis/youtube/js_api_reference.html
            $(document).bind('remedie-player-ready-youtube', function(ev, id){ // id is undefined for some reason
              var player = document.getElementById('player-'+item.id);
              player.addEventListener('onStateChange', 'function(newstate){if(newstate==0) remedie.onPlaybackComplete()}');
              $(document).unbind('remedie-player-ready-youtube');
            });
          }
        };
      }
    } else if (player == 'iframe') {
      return {
        player:  'iframe',
        title:   item.name,
        height:  height,
        width:   width,
        content: item.props.embed.url
      };
    } else if (player == 'QuickTime') {
      return {
        player:  'qt',
        title:   item.name,
        height:  height,
        width:   width,
        content: url,
        onFinish: function() {
          document.getElementById('shadowbox_content').addEventListener('qt_ended', remedie.onPlaybackComplete, false);
        }
      };
    } else if (player == 'WMP') {
      return {
        player:  'html', // TODO make it 'wmp' for Shadowbox
        title:   item.name,
        height:  height,
        width:   width,
        content: '<div id="embed-player"></div>',
        onFinish: function() {
          var s1 = new MPObject(url, 'player-' + id, width,  height);
          s1.addParam("autostart", "1");
          s1.write('embed-player');
        }
      };
    } else if (player == 'DivX') {
      return {
        player:  'html',
        title:   item.name,
        height:  height,
        width:   width,
        content: '<div id="embed-player"></div>',
        onFinish: function() {
          var s1 = new DivXObject(url, 'player-' + id, width,  height);
          s1.addParam("autostart", "true");
          s1.addParam("controller", "true");
          s1.write('embed-player');
        }
      };
    } else if (player == 'Silverlight') {
      return {
        player:  'html',
        title:   item.name,
        height:  height,
        width:   width,
        content: '<div id="embed-player"></div>',
        onFinish: function() {
          var elm = document.getElementById("embed-player");
          var ply = new jeroenwijering.Player(elm, '/static/js/wmvplayer/wmvplayer.xaml', {
            file: url,
            width: width,
            height: height - 18,
            link: item.props.link
          });
          (function(ply) {
            if (ply.view) {
              ply.addListener('STATE', function(ost,nst){if (nst == 'Completed') remedie.onPlaybackComplete()});
              ply.sendEvent('PLAY');
            } else {
              // not ready yet
              var _this = arguments.callee;
              setTimeout(function(){_this(ply)}, 100)
            }
          })(ply);
        }
      };
    } else if (player == 'Flash') {
      var file, streamer;
      if (url.match(/^rtmp[ts]?:/)) {
        var urls = url.split('/');
        file = encodeURIComponent(urls.pop());
        streamer = encodeURIComponent(urls.join('/'));
      } else {
        file = encodeURIComponent(url);
      }
      return {
        player:   'flv',
        title:    item.name,
        height:   height,
        width:    width,
        content:  file,
        streamer: streamer,
        link:     item.props.link,
        image:    thumbnail,
        onFinish: function() {
          $(document).bind('remedie-player-ready', function(ev, id){
            var player = document.getElementById(id);
            // JW player needs a string representatin for callbacks
            player.addViewListener('STOP', 'Shadowbox.close');
            player.addModelListener('STATE', 'function(ev){if (ev.newstate=="COMPLETED") remedie.onPlaybackComplete()}');
            $(document).unbind('remedie-player-ready');
          });
        }
      };
    }
  },

  defaultPlayerFor: function(type) {
    // ASF + Mac -> QuickTime (Flip4Mac)
    // WMV + Mac -> Silverlight
    // WMV + Win -> Windows Media Player
    if (type.match(/wmv|asf|wvx/)) {
      if (/mac/i.test(navigator.userAgent)) {
        if (type.match(/wmv/i)) {
          player = 'Silverlight';
        } else {
          player = 'QuickTime'; // TODO make it 'f4m' for Shadowbox
        }
      } else {
        player = 'WMP';
      }
    } else if (type.match(/quicktime/i)) {
      player = 'QuickTime';
    } else if (type.match(/divx/i)) {
      player = 'DivX';
    } else {
      player = 'Flash';
    }
    return player;
  },

  setupSilverlightPlayer: function(ply) {
    if (ply.view) {
      ply.addListener('STATE', function(ost,nst){if (nst == 'Completed') $.unblockUI()});
      ply.sendEvent('PLAY');
    } else {
      // not ready yet
      setTimeout(function(){remedie.setupSilverlightPlayer(ply)}, 100)
    }
  },

  startDownload: function(item, app) {
    if (!app) app = this.defaultDownloaderFor(item);

    $.ajax({
      url: "/rpc/item/download",
      data: { id: item.id, app: app },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          $.event.trigger('remedie-item-updated', r.item);
          remedie.items[r.item.id] = r.item;
          remedie.startTrackStatus(r.item);
        } else {
          alert(r.error);
        }
      }
    });
  },

  defaultDownloaderFor: function(item) {
     if (/x-ms-asf/i.test(item.props.type) || item.ident.match(/rtsp:\/\//) || item.ident.match(/mms:\/\//)) {
       return 'Mplayer';
     } else {
       return 'Wget';
     }
  },

  cancelDownload: function(item) {
    $.ajax({
      url: "/rpc/item/cancel_download",
      data: { id: item.id },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          $.event.trigger('remedie-item-updated', r.item);
          remedie.items[r.item.id] = r.item;
          $("#progressbar-" + item.id).remove();
        } else {
          alert(r.error);
        }
      }
    });
  },

  startTrackStatus: function(item) {
    var pb = $("<span/>").attr('id', 'progressbar-' + item.id);
    pb.progressBar({
      showText: false,
      increment: 1,
      speed: 100,
      boxImage: "/static/images/progressbar.gif",
      barImage: "/static/images/progressbg_green.gif"
    });
    $("#channel-item-" + item.id + " .item-thumbnail").prepend(
      $("<div/>").addClass("item-progressbar").append(pb)
    );
    this.trackStatus(item);
  },

  trackStatus: function(item) {
    $.ajax({
      url: "/rpc/item/track_status",
      type: 'get',
      data: { id: item.id },
      dataType: 'json',
      success: function(r) {
        var el = $("#progressbar-" + item.id);
        if (r.status.percentage != undefined) {
          if (r.status.percentage < 100) {
            el.progressBar(r.status.percentage);
            setTimeout(function(){remedie.trackStatus(item)}, 1000);
          } else {
            // TODO send events
            remedie.items[r.item.id] = r.item;
            el.remove();
          }
        } else if (r.status.error) {
          alert(r.status.error)
          remedie.cancelDownload(item);
        } else {
          setTimeout(function(){remedie.trackStatus(item)}, 1000);
        }
      },
      error: function(r) {
        alert(r.responseText);
      }
    })
  },

  embedCooliris: function(channel) {
    var res    = RemedieUtil.calcWindowSize($(window).width()-100, $(window).height()-80, 9/16);
    var width  = res.width;
    var height = res.height;

    Shadowbox.open({
      player:  'html',
      height:  height,
      width:   width,
      content: '<div id="embed-player"></div>'
    }, {
      onFinish: function() {
        var embed = new SWFObject("http://apps.cooliris.com/embed/cooliris.swf", 'cooliris-' + channel.id, width, height, '9');
        embed.addParam('allowfullscreen', 'true');
        embed.addParam('allowscriptaccess', 'always');
        embed.addVariable('feed', $("#gallery").attr('href'));
        embed.write('embed-player');
      }
    });
  },

  markAllAsWatched: function(channel, showChannelView) {
    this.updateStatus({ id: channel.id, status: 'watched' }, function() {
      if (showChannelView && remedie.current_id == channel.id)
        remedie.showChannel(channel);
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
    if (this.current_id) {
      document.title = 'Remedie: ' + channel.name;
      if (channel.unwatched_count) document.title += " (" + channel.unwatched_count + ")";
    }
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
          var o = remedie.channels[r.channel.id];
          remedie.channels[r.channel.id] = r.channel;
          callback.call();
          $.event.trigger('remedie-channel-updated', { channel: r.channel, prev: o, skip_notification: true });
        } else {
          alert(r.error);
        }
      }
    });
  },

  newChannelDialog: function(url) {
    if (url) $("#new-channel-url").attr('value', url);

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
      $("body").scrollTo({ top: 0 });
      remedie.resetCursorPos();
    } else {
      var channel_id = this.current_id;
      $.event.trigger('remedie-channel-onhidden');
      $("#collection").show();
      $("#channel-pane").hide();
      remedie.resetCursorPos(channel_id);
    }
    return false;
  },

  createNewChannel: function(el) {
    $.blockUI({ message: "Fetching ..." });
    $.ajax({
      url: "/rpc/channel/create",
      data: {
        url: $.trim($("#new-channel-url").attr('value')),
        no_discovery: $("#no-discovery").attr("checked") ? 1 : 0
      },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        $.unblockUI();
        if (r.success) {
          $("#new-channel-url").attr('value', '');

          remedie.channels[r.channel.id] = r.channel;
          remedie.renderChannelList(r.channel, $("#collection"));
          $(document).bind('remedie-channel-ondisplay', function(){
            remedie.manuallyRefreshChannel(r.channel);
            remedie.resetCursorPos();
            $(document).unbind('remedie-channel-ondisplay', arguments.callee);
          });
          remedie.showChannel(r.channel);
        } else {
          alert(r.error);
        }
      }
    });
    return false;
  },

  findChannel: function(channel, offset) {
    var array = new Array;
    var want;
    $.each(this.channels, function(idx, c) {
      if (c != undefined) {
        array.push(c);
        if (c.id == channel.id)
          want = array.length - 1 + offset;
      }
    });

    if (want && want > array.length - 1) want = 0;
    if (want < 0) want = array.length - 1;
    return array[want];
  },

  showChannel: function(channel, opts) {
    if (!opts) opts = {};
    var currentStateURI = "#channel/" + channel.id;
    if (opts.unwatched) currentStateURI += '/unwatched';
    else if (opts.all)  currentStateURI += '/all'; // unwatched includes all
    location.href = currentStateURI;
    $.ajax({
      url: "/rpc/channel/show",
      type: 'get',
      data: { id: channel.id, limit: (opts.all ? 0 : 50), status: (opts.unwatched ? [ 'new', 'downloaded' ] : 0) },
      dataType: 'json',
      success: function(r) {
        $.unblockUI();
        $("#channel-pane").children().remove();
        var channel = r.channel;
        $.event.trigger("remedie-channel-ondisplay", channel);

        var prevChannel = remedie.findChannel(channel, -1);
        var nextChannel = remedie.findChannel(channel, 1);

        var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/images/feed_256x256.png";
        $("#channel-pane").createAppend(
          'div', { className: 'channel-header', id: 'channel-header-' + channel.id  }, [
            'div', { className: 'channel-header-thumbnail' }, [
              'img', { src: "/static/images/feed_256x256.png", alt: channel.name }, null
            ],
            'div', { className: 'channel-header-infobox', style: 'width: ' + ($(window).width()-220) + 'px' }, [
              'div', { className: 'channel-header-nextprev' }, [
                'ul', { className: 'inline' }, [
                  'li', { className: 'first' }, [
                     'a', { href: "#channel/" + prevChannel.id,  className: "prev-channel" },
                        "&laquo; " + prevChannel.name.trimChars(12)
                  ],
                  'li', {}, [
                     'a', { href: "#channel/" + nextChannel.id,  className: "next-channel" },
                        nextChannel.name.trimChars(12) + " &raquo;"
                  ],
                ],
              ],
              'h2', { className: 'channel-header-title' }, [ 'a', { href: channel.props.link, target: "_blank" }, channel.name ],
              'div', { className: 'channel-header-data' }, [
                'a', { href: channel.ident, target: "_blank" }, RemedieUtil.mangleURI(channel.ident).trimChars(100),
                'br', {}, null,
                'span', {}, '<a class="show-all-items">' + r.channel.total + ' items' + '</a>' +
                  ', ' +
                  '<a class="show-unwatched-items"><span class="unwatched-count-' + channel.id + '">' + 
                  (channel.unwatched_count ? channel.unwatched_count : 0) + '</span> unwatched</a>'
              ],
              'p', { className: 'channel-header-description' }, channel.props.description
            ],
            'div', { className: "clear" }, null
          ]
        );

        if (channel.props.thumbnail)
          RemedieUtil.layoutImage($("#channel-pane .channel-header-thumbnail img"), channel.props.thumbnail.url, 128, 96);

        $("#channel-pane .prev-channel").click(function(){remedie.showChannel(prevChannel)});
        $("#channel-pane .next-channel").click(function(){remedie.showChannel(nextChannel)});

        $("#channel-pane").createAppend(
          'div', { id: 'channel-items', className: "clear" }, null
        );

        $.each(r.items, function(index, item) {
          remedie.items[item.id] = item;
          $("#channel-items").createAppend(
           'div', { className: 'channel-item channel-item-selectable', id: 'channel-item-' + item.id  }, [
             'div', { className: 'item-thumbnail' }, [
               'a', { className: 'channel-item-clickable', href: item.ident, id: "item-thumbnail-" + item.id, rel: "shadowbox[gallery" + item.channel_id + "]" }, [
                 'img', { id: 'item-thumbnail-image-' + item.id,
                          src: thumbnail, alt: item.name, style: 'width: 128px' }, null
               ]
             ],
             'div', { className: 'item-infobox', style: "width: " + ($(window).width()-220) + "px" }, [
               'div', { className: 'item-infobox-misc' }, [
                  'ul', { className: 'inline' }, [
                    'li', { className: 'first' }, [
                      "a", { href: item.ident }, "size: " + RemedieUtil.formatBytes(item.props.size)
                    ],
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

         if (item.props.thumbnail)
           RemedieUtil.layoutImage($("#item-thumbnail-image-" + item.id), item.props.thumbnail.url, 128, 96);
       });

//       Shadowbox.setup();

       $(".channel-header")
        .contextMenu("channel-context-menu", {
          bindings: {
            channel_context_refresh:      function(){ remedie.manuallyRefreshChannel(channel) },
            channel_context_clear_stale:  function(){ remedie.manuallyRefreshChannel(channel, true) },
            channel_context_mark_watched: function(){ remedie.markAllAsWatched(channel, true) },
            channel_context_cooliris:     function(){ PicLensLite.start() },
            channel_context_cooliris_swf: function(){ remedie.embedCooliris(channel) },
            channel_context_remove:       function(){ remedie.removeChannel(channel) }
          }
        });

       var fullscreen = 1; // TODO make it channel preference
       $(".channel-item-selectable")
         .hover(function(){ $(this).addClass("hover-channel-item").css('opacity',0.8) },
                function(){ $(this).removeClass("hover-channel-item").css('opacity',1) });
       $(".item-thumbnail").each(function() {
           var item = remedie.items[ $(this).parent().get(0).id.replace("channel-item-", "") ];
           $(this).contextMenu("channel-item-context-menu", {
           bindings: {
             item_context_play:      function(){remedie.playVideoInline(item)},
             item_context_play_only:  function(){remedie.playVideoInline(item, null, { thisItemOnly: 1 })},
             item_context_copy:      function(){$.copy(item.ident)},
             item_context_open:      function(){remedie.markItemAsWatched(item, true);location.href=item.ident},
             item_context_watched:   function(){remedie.markItemAsWatched(item)},
             item_context_unwatched: function(){remedie.markItemAsUnwatched(item)},
             item_context_download:  function(){remedie.startDownload(item)},
             item_context_download_sd:  function(){remedie.startDownload(item, 'SpeedDownload')},
             item_context_cancel_download:  function(){remedie.cancelDownload(item)},
             item_context_reveal:    function(){remedie.launchVideoPlayer(item, 'Finder')},
             item_context_play_vlc:  function(){remedie.launchVideoPlayer(item, 'VLC', fullscreen)},
//                item_context_play_qt:   function(){remedie.launchVideoPlayer(item, 'QTL', fullscreen, 1)},
             item_context_play_qt:   function(){remedie.launchVideoPlayer(item, 'QuickTime', fullscreen)},
             item_context_play_qt_embed: function(){remedie.playVideoInline(item, 'QuickTime')},
             item_context_play_wmp:  function(){remedie.playVideoInline(item, 'WMP')},
             item_context_play_sl:   function(){remedie.playVideoInline(item, 'Silverlight')},
             item_context_play_divx: function(){remedie.playVideoInline(item, 'DivX')}
           },
           onContextMenu: function(e, menu) {
             item = remedie.items[ item.id ]; // refresh the status
             var el = $('#channel-item-context-menu ul'); el.children().remove();
             el.createAppend('li', { id: 'item_context_play' }, 'Play');
             el.createAppend('li', { id: 'item_context_play_only' }, 'Play only this item');
             el.createAppend('li', { id: 'item_context_copy' }, 'Copy Item URL (' + RemedieUtil.fileType(item.ident, item.props.type) + ')');
             el.createAppend('li', { id: 'item_context_open' }, 'Open URL with browser');

             // TODO check if it's downloadable
             if (!item.props.track_id && !item.props.download_path) {
               el.createAppend('li', { id: 'item_context_download' }, 'Download file');
               if (navigator.userAgent.match(/mac/i))
                 el.createAppend('li', { id: 'item_context_download_sd' }, 'Download with Speed Download');
             } else if (item.props.track_id) {
               el.createAppend('li', { id: 'item_context_cancel_download' }, 'Cancel download');
             }

             if (item.props.download_path || item.ident.match(/^file:/)) {
               if (navigator.userAgent.match(/mac/i))
                 el.createAppend('li', { id: 'item_context_reveal' }, 'Reveal in Finder');
               if (item.props.download_path && !item.props.track_id)
                 el.createAppend('li', { id: 'item_context_cancel_download' }, 'Remove downloaded file');
             }

             if (item.is_unwatched) {
               el.createAppend('li', { id: 'item_context_watched' }, 'Mark as watched');
             } else {
               el.createAppend('li', { id: 'item_context_unwatched' }, 'Mark as unwatched');
             }

             if (/divx/i.test(item.props.type)) {
               el.createAppend('li', { id: 'item_context_play_divx' }, 'Play inilne with DivX player');
             } else if (/video/i.test(item.props.type)) {
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

         if (item.props.track_id) {
           remedie.startTrackStatus(item);
         }

         $(this)
          .hover(function(){
            if (!remedie.items[item.id].props.track_id) {
              $(this).prepend($("<div/>").attr('id', 'play-button-'+item.id)
                .addClass("channel-item-play")
                .append($("<a/>").attr("href", "javascript:void 0").text("PLAY").click(function(){$(this).parent().next().trigger('click')}))
                .corners("10px transparent").css({opacity:0.6}));
            }
          }, function(){
            $('.channel-item-play').remove();
          });
        });

        $(".channel-item-clickable").click(function(){
          try{
            remedie.playVideoInline( remedie.items[this.id.replace("item-thumbnail-", "")] );
          } catch(e) { alert(e) };
          return false;
        });

        if (channel.total > r.items.length) {
          $("#channel-items").createAppend('div', { className: 'show-more-items' }, [
            'a', { className: 'show-all-items' }, 'Showing only ' + r.items.length + ' items. Click here to show all items'
          ]);
        }

        remedie.toggleChannelView(true);
      },
      error: function(r) {
        alert("Can't load the channel: " + r.responseText);
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
    $("#channel-" + channel.id + " .channel-unwatched-hover").addClass("channel-unwatched-hover-gray");
    $("#channel-" + channel.id + " .channel-refresh-hover").show();
    $.ajax({
      url: "/rpc/channel/refresh",
      data: { id: channel.id, clear_stale: clearStaleItems ? 1 : 0 },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        $.unblockUI();
        if (r.success) {
          var o = remedie.channels[r.channel.id];
          remedie.channels[r.channel.id] = r.channel;
          $.event.trigger('remedie-channel-updated', { channel: r.channel, prev: o });
          if (refreshView)
            remedie.showChannel(r.channel);
        } else {
          $.event.trigger('remedie-channel-updated', { channel: channel }); // Fake updated Event to cancel animation
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
        remedie.renderUnwatchedBadges();
        remedie.resetCursorPos();
        $.unblockUI();
        if (callback)
          callback.call(remedie);
      },
      error: function(r) {
        alert("Can't load subscription: " + r.responseText);
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

    // TODO Do NOT display items that are not bound to the event: e.g. Cooliris
    var gridEvents = [];
    $("#channel-" + channel.id)
      .bind( 'click', function(){ remedie.showChannel(channel) } )
      .hover( function(){
                $(this).addClass("hover-channel");
                if (!$(this).data('gridEventsInstalled')) {
                  var _this = this;
                  var id = setTimeout(function(){
                    remedie.installGridEvents($(_this), channel.id);
                  }, 1000);
                  gridEvents.push(id);
                }
              },
              function(){
                $.each(gridEvents, function(idx, id) { clearTimeout(id) });
                $(this).removeClass("hover-channel");
                if (!default_thumbnail)
                  RemedieUtil.layoutImage($("#channel-thumbnail-image-" + channel.id), thumbnail, 192, 192);
              } )
      .contextMenu("channel-context-menu", {
        bindings: {
          channel_context_refresh:      function(){ remedie.refreshChannel(channel) },
          channel_context_clear_stale:  function(){ remedie.refreshChannel(channel, false, true) },
          channel_context_mark_watched: function(){ remedie.markAllAsWatched(channel, false) },
          channel_context_remove:       function(){ remedie.removeChannel(channel) }
        }
      });

    if (!default_thumbnail)
      RemedieUtil.layoutImage($("#channel-thumbnail-image-" + channel.id), thumbnail, 192, 192);
  },

  installGridEvents: function(element, id) {
    $.ajax({
      url: "/rpc/channel/show",
      type: 'get',
      data: { id: id },
      dataType: 'json',
      success: function(r) {
        element.data('gridEventsInstalled', true);
        var images = [];
        var width = element.width();
        $.each(r.items, function(index, item) {
          if (item.props.thumbnail && item.props.thumbnail.url) {
            images.push(item.props.thumbnail.url);
          }
        });

        if (images.length > 0) {
          var d = 192 / images.length;
          element.bind('mousemove', function(event) {
            var offset = $(this).offset({ scroll: false });
            var x = event.pageX - offset.left;
            var image = images[parseInt(x / d)];
            if (image) {
              RemedieUtil.layoutImage($('#channel-thumbnail-image-' + id), image, 192, 192);
            }
          });
        }
      }
    });
  },

  cursorPos: -1,

  moveCursor: function(index) {
    if (index < -1) return false;
    if (index == -1) {
      if (remedie.current_id)
        $(".channel-item-selectable").removeClass("hover-channel-item");
      else
        $(".channel-clickable").removeClass("hover-channel");
      $("body").scrollTo({ top: 0 });
      return true;
    }

    if (remedie.current_id) {
      var items = $('.channel-item');
      if (!items) {
        return false;
      }
      var target = items[index];
      if (!target) return false;
      $("body").scrollTo(target, 100);
      $(".channel-item-selectable").removeClass("hover-channel-item");
      $(target).addClass("hover-channel-item");
      return true;
    } else {
      var channels = $('.channel');
      if (!channels) {
        return false;
      }
      var target = channels[index];
      if (!target) return false;
      $("body").scrollTo(target, 100);
      $(".channel-clickable").removeClass("hover-channel");
      $(target).addClass("hover-channel");
      return true;
    }
  },

  getElementPosition: function(e) {
    var pos = {x:0, y:0};
    if (document.documentElement.getBoundingClientRect) { // IE 
      var box = e.getBoundingClientRect();
      var owner = e.ownerDocument;
      pos.x = box.left + Math.max(owner.documentElement.scrollLeft, owner.body.scrollLeft) - 2;
      pos.y = box.top  + Math.max(owner.documentElement.scrollTop,  owner.body.scrollTop) - 2;
    } else if(document.getBoxObjectFor) { //Firefox
      pos.x = document.getBoxObjectFor(e).x;
      pos.y = document.getBoxObjectFor(e).y;
    } else {
      do {
        pos.x += e.offsetLeft;
        pos.y += e.offsetTop;
      } while (e = e.offsetParent);
    }
    return pos;
  },

  moveCursorUp: function() {
    if (remedie.current_id) {
      if (this.moveCursor(remedie.cursorPos - 1)) remedie.cursorPos -= 1;
    } else {
      var channels = $('.channel');
      if (!channels) {
        return false;
      }
      var target, cursor = remedie.cursorPos;
      if (cursor > 0) {
        var opos = this.getElementPosition(channels[cursor]);
        while ((target = channels[--cursor])) {
          var npos = this.getElementPosition(target);
          if (opos.x == npos.x) break;
        }
      }
      if (!target) cursor = -1;
      if (this.moveCursor(cursor)) remedie.cursorPos = cursor;
    }
  },

  moveCursorDown: function() {
    if (remedie.current_id) {
      if (this.moveCursor(remedie.cursorPos + 1)) remedie.cursorPos += 1;
    } else {
      var channels = $('.channel');
      if (!channels) {
        return false;
      }
      var target, cursor = remedie.cursorPos;
      if (cursor < 0) {
        cursor = 0;
      } else {
        var opos = this.getElementPosition(channels[cursor]);
        while ((target = channels[++cursor])) {
          var npos = this.getElementPosition(target);
          if (opos.x == npos.x) break;
        }
      }
      if (this.moveCursor(cursor)) remedie.cursorPos = cursor;
    }
  },

  moveCursorNext: function() {
    if (this.moveCursor(remedie.cursorPos + 1)) remedie.cursorPos += 1;
  },

  moveCursorPrev: function() {
    if (this.moveCursor(remedie.cursorPos - 1)) remedie.cursorPos -= 1;
  },

  resetCursorPos: function(channel_id) {
    if (channel_id) {
      remedie.cursorPos = $('.channel').index($('#channel-' + channel_id));
      this.moveCursor(remedie.cursorPos);
    } else
      remedie.cursorPos = -1;
  },

  redrawChannel: function(channel) {
    var id = "#channel-" + channel.id;

    $(id + " .channel-thumbnail").css({opacity:1});
    $(id + " .channel-unwatched-hover").removeClass("channel-unwatched-hover-gray");
    $(id + " .channel-refresh-hover").hide();

    var thumbnail;
    if (channel.props.thumbnail)
      thumbnail = channel.props.thumbnail;
    else if (channel.first_item && channel.first_item.props.thumbnail)
      thumbnail = channel.first_item.props.thumbnail;

    if (thumbnail)
      RemedieUtil.layoutImage($(id + " .channel-thumbnail"), thumbnail.url, 192, 192);

    if (channel.name) 
      $(id + " .channel-title").text(channel.name.trimChars(24));
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
                  'a', { href: "http://remediecode.org/", target: "_blank" }, 'Get source code'
              ]
          ]);
      $.blockUI({ message: message });
      return false;
  }
};

function playerReady(obj) {
  $.event.trigger('remedie-player-ready', obj.id);
}

function onYouTubePlayerReady(id) {
  $.event.trigger('remedie-player-ready-youtube', id);
}
