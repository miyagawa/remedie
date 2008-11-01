function Remedie() {
  this.initialize();
}

Remedie.prototype = {
  initialize: function() {
    $("#menu-new-channel").click( this.newChannel );
    this.loadSubscription();
  },

  newChannel: function() {
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
          var el = self.renderChannel(r.channel);
          $("#subscription .channels-list").append(el);
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
          var el = self.renderChannel(r.channels[i]);
          $("#subscription").append(el);
        }
      },
      error: function(r) {
        alert("Can't load subscription");
      }
    });
  },

  renderChannel: function(channel) {
    var el = $("<div>");
    el.attr('class', 'channel-item');
    el.text( channel.name );
    return el;
  },
};

