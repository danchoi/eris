
$(function() {
  _.templateSettings = { interpolate : /\{\{(.+?)\}\}/g };

  window.BlogPost = Backbone.Model.extend({ idAttribute: 'href' });
  window.BlogPostsList = Backbone.Collection.extend({
    url: function() {
      return ('/blog_posts?from_time=' + this.models[this.models.length-1].get("date"));
    },
    model: BlogPost,
    comparator: function(x) { return x.get('date'); }
  });
  window.BlogPosts = new BlogPostsList();
  window.BlogPostView = Backbone.View.extend({
    tagName: "div",
    classNme: "blogpost",
    template: _.template( $('#blogpost-template').html() ),
    render: function() {
      $(this.el).html(this.template(this.model.toJSON()));
      return this;
    }
  });


  window.Tweet = Backbone.Model.extend({ idAttribute: 'href' });
  window.TweetsList = Backbone.Collection.extend({
    url: function() {
      return ('/tweets?from_time=' + this.models[this.models.length-1].get("created_at"));
    },
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
      BlogPosts.bind('add', this.addOneBlogPost, this);
      BlogPosts.bind('reset', this.addAllBlogPosts, this);
      BlogPosts.bind('refresh', this.addAllBlogPosts, this);

      Tweets.bind('add', this.addOneTweet, this);
      Tweets.bind('reset', this.addAllTweets, this);
      Tweets.bind('refresh', this.addAllTweets, this);
    },

    addOneBlogPost: function(x) {
      var blogpostView = new BlogPostView({model: x});
      if ((x.get('blog_post_id') % 2) == 0) {
        $("#blogposts").prepend(blogpostView.render().el);
      } else {
        $("#blogposts-column-2").prepend(blogpostView.render().el);
      }
    },
    addAllBlogPosts: function() { BlogPosts.each(this.addOneBlogPost); },

    addOneTweet: function(x) {
      var tweetView = new TweetView({model: x});
      $("#tweets").prepend(tweetView.render().el);
    },
    addAllTweets: function() { Tweets.each(this.addOneTweet); }
  });

  window.App = new AppView;

});
