function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    $("#menu-new-channel").click( this.newChannel );
    this.loadSubscription();
  },

  newChannel: function() {
    var self = this;
    // TODO look at clipboard
    var input = window.prompt('Enter URL', '');
    if (!input) return;
    $.ajax({
      url: "/rpc/channel/create",
      data: { url: input },
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
         'img', { src: thumbnail, height: 120 }, [],
         'div', { className: 'channel-item-title' }, channel.name,
      ]
    );
  },
};

