function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    var self = this;

    $(".new-channel-menu").click(function(){ self.toggleNewChannel(true) });
    $(".channel-list-menu").click(function(){ self.toggleChannelView(false) });

    $("#new-channel-form").submit( function(e) { self.newChannel(e); return false; } );
    $("#new-channel-cancel").click( function() { self.toggleNewChannel(false) } );

    $(".about-dialog-menu").click(function(){ self.showAboutDialog(true) });

    $().ajaxStop($.unblockUI);

// I just don't know but livequery SOMETIMES doesn't work with Safari on my Mac mini
//    $(".channel-clickable").livequery('click', function(){
//      self.showChannel(this.href.replace(/.*#channel-/, ""));
//      return false;
//    });
//    $(".item-thumbnail-clickable").livequery('click', function(){
//      self.playVideo(this.href, this.id.replace("item-thumbanil-", ""));
//      return false;
//    });

    this.loadCollection();
  },

  channels: [],
  items:    [],

  playVideo: function(item) {
    var self = this;
    // TODO this only works when you're browsing from Local machine
    // If you're from remote, we should serve files from HTTP and run local
    // QuickTime/VLC to stream from the proxy
    var config = { player: 'Flash' }; // or VLC
    var channel = this.channels[ item.channel_id ];
    if (config.player == 'Flash') {
      this.playVideoInline(item.ident, item.id, false, channel.id);
    } else if (config.player == 'QTEmbed') {
      this.playVideoInline(item.ident, item.id, true, channel.id);
    } else if (config.player == 'VLC' || config.player == 'QuickTime') {
      $.ajax({
        url: "/rpc/player/play",
        data: { url: item.ident, player: config.player },
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
    }
  },

  playVideoInline: function(url, id, useQTEmbed, channel_id) {
    var self = this;

    var wh = RemedieUtil.calcWindowSize($(window).width());
    var width  = wh[0];
    var height = wh[1] + 20; // slider and buttons

    if (useQTEmbed) {
        var s1 = new QTObject(url, 'player-' + id, width,  height);
        s1.addParam('scale', 'Aspect');
        s1.addParam('target', 'QuickTimePlayer');
        s1.write('flash-player');
    } else {
        var s1 = new SWFObject('/static/player.swf', 'player-' + id, width, height, '9');
        s1.addParam('allowfullscreen','true');
        s1.addParam('allowscriptaccess','always');
        s1.addParam('flashvars','autostart=true&file=' + url);
        s1.write('flash-player');
    }

    $('#flash-player').createAppend(
     'div', { className: 'close-button' }, [
        'a', {}, "Click here to close the Player"
      ]
    ).click(function() {
      $.unblockUI();
      self.markItemAsWatched(channel_id, id);
    });

    $.blockUI({
      message: $('#flash-player'),
      css: { top:  ($(window).height() - height) / 2 - 6 + 'px',
             left: ($(window).width()  - width) / 2 + 'px',
             width:  wh[0] + 'px' }
    });
  },

  markItemAsWatched: function(channel_id, id) {
    this.updateStatus({ item_id: id, status: 'watched' });
    $('#channel-item-title-' + id).removeClass('channel-item-unwatched');
    var count = $('#unwatched-count-' + channel_id);
    if (count.text()) 
      count.text( count.text() - 1 );
  },

  updateStatus: function(obj) {
    $.ajax({
      url: "/rpc/channel/update_status",
      data: obj,
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {

        } else {
          alert(r.error);
        }
      },
    });
  },

  toggleNewChannel: function(display) {
    if (display) {
      $.blockUI({
        message: $("#new-channel-dialog"),
        css: {
            border: 'none',
            padding: '15px',
            backgroundColor: '#222',
            '-webkit-border-radius': '10px',
            '-moz-border-radius': '10px',
            opacity: '.8',
            color: '#fff'
        },
      });
    } else {
      $.unblockUI();
    }
    return false;
  },

  toggleChannelView: function(display) {
    if (display) {
      $("#subscription").hide();
      $("#channel-pane").show();
    } else {
      $("#subscription").show();
      $("#channel-pane").hide();
    }
    return false;
  },

  newChannel: function(el) {
    var self = this;
    $.blockUI({ css: {   border: 'none',
            padding: '15px',
            backgroundColor: '#222',
            '-webkit-border-radius': '10px',
            '-moz-border-radius': '10px',
            opacity: '.8',
            color: '#fff' } });
    $.ajax({
      url: "/rpc/channel/create",
      data: { url: jQuery.trim( $("#new-channel-url").attr('value') ) },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          $("#new-channel-url").attr('value', '');
          self.toggleNewChannel(false);
          self.renderChannel(r.channel, $("#subscription"));
          self.refreshChannel(r.channel, true)
        } else {
          alert(r.error);
        }
      },
    });
    return false;
  },

  showChannel: function(channel) {
    var self = this;
    $("#channel-pane").children().remove();
    $.ajax({
      url: "/rpc/channel/show",
      type: 'get',
      data: { id: channel.id },
      dataType: 'json',
      success: function(r) {
        var channel = r.channel;
        var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/images/feed_128x128.png";
        $("#channel-pane").createAppend(
         'div', { className: 'channel-header', id: 'channel-header-' + channel.id  }, [
           'div', { className: 'channel-header-thumbnail' }, [
             'img', { src: thumbnail, alt: channel.name }, null
           ],
           'div', { className: 'channel-header-infobox', style: 'width: ' + ($(window).width()-220) + 'px' }, [
              'h2', {}, [ 'a', { href: channel.props.link, target: "_blank" }, channel.name ],
              'p', { className: 'channel-header-data' }, r.items.length + ' items, ' +
                  (channel.unwatched_count ? channel.unwatched_count : 0) + ' unwatched',
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
          self.items[item.id] = item;
          var item_thumb = item.props.thumbnail ? item.props.thumbnail.url : null;
          $("#channel-items").createAppend(
           'div', { className: 'channel-item channel-item-clickable', id: 'channel-item-' + item.id  }, [
             'div', { className: 'item-thumbnail' }, [
               'a', { href: item.ident, id: "item-thumbnail-" + item.id }, [
                 // TODO load placeholder default image and replace later with new Image + onload
                 'img', { src: item_thumb || thumbnail, alt: item.name, style: 'width: 128px',
                          onload: "r.resizeThumb(this)" }, null
               ]
             ],
             'div', { className: 'item-infobox', style: "width: " + ($(window).width()-220) + "px" }, [
               'div', { className: 'item-infobox-misc' }, [
                  'ul', { className: 'inline' }, [
                    'li', { className: 'first' }, "size: " + RemedieUtil.formatBytes(item.props.size),
                    'li', {}, "updated: " + item.props.updated,
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

        $(".channel-item-clickable")
          .click(function(){ self.playVideo( self.items[this.id.replace("channel-item-", "")] ) })
          .hover(function(){ $(this).addClass("hover-channel-item")}, function(){ $(this).removeClass("hover-channel-item")});

        self.toggleChannelView(true);
      },
      error: function(r) {
        alert("Can't load the channel");
      }
    });
  },

  refreshChannel : function(channel, first_time) {
    var self = this;
    // TODO animated icon on top of thumbnail
    $.ajax({
      url: "/rpc/channel/refresh",
      data: { id: channel.id },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          // TODO remove nimated icon
          if (first_time) 
            self.redrawChannel(r.channel);
        } else {
          alert(r.error);
        }
      },
    });

  },

  loadCollection: function() {
    var self = this;
    $.ajax({
      url: "/rpc/channel/load",
      type: 'get',
      dataType: 'json',
      success: function(r) {
        for (i = 0; i < r.channels.length; i++) {
          var channel = r.channels[i];
          self.channels[channel.id] = channel;
          self.renderChannel(channel, $("#subscription"));
        }
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
        'a', { href: '#channel-' + channel.id }, [
          'img', { src: thumbnail, alt: channel.name, className: 'channel-thumbnail' }, [],
          'div', { className: 'channel-title' },
                 channel.unwatched_count ? channel.name + ' (<span id="unwatched-count-' + channel.id + '">' + channel.unwatched_count + '</span>)' : channel.name
        ]
      ]
    );
    $("#channel-" + channel.id)
      .click( function(){ r.showChannel(channel) } )
      .hover( function(){ $(this).addClass("hover-channel") },
              function(){ $(this).removeClass("hover-channel") } );
  },

  redrawChannel: function(channel) {
    var id = "#channel-" + channel.id;
    if ($(id).size() == 0)
       return this.renderChannel(channel, $("#subscription"));

    if (channel.props.thumbnail) 
      $(id + " .channel-thumbnail").attr('src', channel.props.thumbnail.url);

    if (channel.name) 
      $(id + " .channel-title").text(channel.name);

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
              'h2', {}, 'Remedie Media Center',
              'p', {}, [
                  'a', { href: "http://code.google.com/p/remedie/", target: "_blank" }, 'Source code'
              ],
              'a', { className: 'command-unblock' }, 'Close this window'
          ])
      message.children("a.command-unblock").click($.unblockUI);
      $.blockUI({
        message: message,
        css: {
            border: 'none',
            padding: '15px',
            backgroundColor: '#222',
            '-webkit-border-radius': '10px',
            '-moz-border-radius': '10px',
            opacity: '.8',
            color: '#fff'
        },
      });
      return false;
  },

};
