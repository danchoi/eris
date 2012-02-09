
$(function() {
  _.templateSettings = { interpolate : /\{\{(.+?)\}\}/g };

  window.FeedItem = Backbone.Model.extend({ idAttribute: 'href' });
  window.FeedItemsList = Backbone.Collection.extend({
    url: function() {
      return ('/items?from_time=' + this.models[this.models.length-1].get("date"));
    },
    model: FeedItem,
    comparator: function(x) { return x.get('date'); }
  });
  window.FeedItems = new FeedItemsList();
  window.FeedItemView = Backbone.View.extend({
    tagName: "div",
    classNme: "feedItem",
    template: _.template( $('#feed-item-template').html() ),
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      return this;
    }
  });


  window.Tweet = Backbone.Model.extend({ idAttribute: 'href' });
  window.TweetsList = Backbone.Collection.extend({
    url: function() { return ; },
    model: Tweet,
    comparator: function(x) { return x.get('created_at'); }
  });
  window.Tweets = new TweetsList();
  window.TweetView = Backbone.View.extend({
    tagName: "div",
    classNme: "tweet",
    template: _.template( $('#tweet-template').html() ),
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      return this;
    }
  });

  window.AppView = Backbone.View.extend({
    initialize: function() {
      FeedItems.bind('add', this.addOneFeedItem, this);
      FeedItems.bind('reset', this.addAllFeedItems, this);
      FeedItems.bind('refresh', this.addAllFeedItems, this);

      Tweets.bind('add', this.addOneTweet, this);
      Tweets.bind('reset', this.addAllTweets, this);
      Tweets.bind('refresh', this.addAllTweets, this);
    },

    addOneFeedItem: function(x) {
      var feedItemView = new FeedItemView({model: x});
      if ((x.get('item_id') % 2) == 0) {
        $("#feedItems").prepend(feedItemView.render().el);
      } else {
        $("#feedItems-column-2").prepend(feedItemView.render().el);
      }
    },
    addAllFeedItems: function() { FeedItems.each(this.addOneFeedItem); },

    addOneTweet: function(x) {
      var tweetView = new TweetView({model: x});
      $("#tweets").prepend(tweetView.render().el);
    },
    addAllTweets: function() { Tweets.each(this.addOneTweet); }
  });

  window.App = new AppView;

});
