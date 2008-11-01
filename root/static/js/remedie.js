function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    var self = this;
    $("#new-channel-menu").click(function(){
//      $("#new-channel-dialog").dialog({
//        modal: true,
//        overlay: { opacity: 0.8, background: "black" }
//      });
       self.toggleNewChannel();
    });
    $("#new-channel-form").submit( function(e) { self.newChannel(e); return false; } );
    $("#new-channel-cancel").click( this.toggleNewChannel );
    this.loadSubscription();

    $().ajaxStop($.unblockUI);
  },

  toggleNewChannel: function() {
    $("#new-channel-dialog").toggle();
    $("#subscription").toggle();
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
      data: { url: $("#new-channel-url").attr('value') },
      type: 'post',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          alert(r.channel.name + " was added to your subscription");
          self.toggleNewChannel();
          self.renderChannel(r.channel, $("#subscription"));
        } else {
          alert(r.error);
        }
      },
    });
    return false;
  },

  loadSubscription: function() {
    var self = this;
    $.ajax({
      url: "/rpc/channel/load",
      type: 'get',
      dataType: 'json',
      success: function(r) {
        for (i = 0; i < r.channels.length; i++) {
          self.renderChannel(r.channels[i], $("#subscription"));
        }
      },
      error: function(r) {
        alert("Can't load subscription");
      }
    });
  },

  renderChannel: function(channel, container) {
   var thumbnail = channel.props.thumbnail ? channel.props.thumbnail.url : "/static/default_channel.png";
    container.createAppend(
      'div', { className: 'channel-item' }, [
         'img', { src: thumbnail, className: 'channel-thumbnail' }, [],
         'div', { className: 'channel-item-title' }, channel.name,
      ]
    );
  },
};

