function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    $("#new-channel-menu").click(function(){
//      $("#new-channel-dialog").dialog({
//        modal: true,
//        overlay: { opacity: 0.8, background: "black" }
//      });
       $("#new-channel-dialog").toggle();
       $("#subscription").toggle();
    });
    $("#new-channel-form").submit( this.newChannel );
    $("#new-channel-cancel").click( function() {
       $("#new-channel-dialog").toggle();
       $("#subscription").toggle();
    });
    this.loadSubscription();
  },

  newChannel: function(self) {
    $.ajax({
      url: "/rpc/channel/create",
      data: { url: $("#new-channel-url").attr('value') },
      type: 'get',
      dataType: 'json',
      success: function(r) {
        if (r.success) {
          alert(r.channel.name + " was added to your subscription");
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

