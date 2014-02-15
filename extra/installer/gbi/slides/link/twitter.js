/* requires jquery.tweet.js */

/* TODO: Fix tweet slideDown animation to actually slide down instead of changing height */

function escapeHTML(text) {
	return $('<div/>').text(text).html();
}

function spliceText(text, indices) {
	// Copyright 2010, Wade Simmons <https://gist.github.com/442463>
	// Licensed under the MIT license
	var result = "";
	var last_i = 0;
	var i = 0;
	
	for (i=0; i < text.length; ++i) {
		var ind = indices[i];
		if (ind) {
			var end = ind[0];
			var output = ind[1];
			if (i > last_i) {
				result += escapeHTML(text.substring(last_i, i));
			}
			result += output;
			i = end - 1;
			last_i = end;
		}
	}
	
	if (i > last_i) {
		result += escapeHTML(text.substring(last_i, i));
	}
	
	return result;
}

function Tweet(data) {
	var tweet = this;
	
	var innerData = data;
	if (data.retweeted_status) innerData = data.retweeted_status;
	
	var userID = innerData.from_user || innerData.user.id;
	var userRealName = innerData.from_user_name || innerData.user.name;
	var userScreenName = innerData.from_user || innerData.user.screen_name;
	
	var linkHashTag = function(hashTag) {
		return 'https://twitter.com/search?q='+encodeURIComponent('#'+hashTag);
	}
	
	var linkUser = function(userName) {
		return 'https://twitter.com/'+encodeURIComponent(userName);
	}
	
	var linkUserID = function(userID) {
		return 'https://twitter.com/account/redirect_by_id?id='+encodeURIComponent(userID);
	}
	
	var linkEntities = function(entities, text) {
		entityIndices = {};
		
		$.each(entities.media || [], function(i, entry) {
			var link = '<a class="twitter-url twitter-media" href="'+encodeURI(entry.media_url)+'">'+escapeHTML(entry.display_url || entry.url)+'</a>';
			entityIndices[entry.indices[0]] = [entry.indices[1], link];
		});
		
		$.each(entities.urls || [], function(i, entry) {
			var link = '<a class="twitter-url" href="'+encodeURI(entry.url)+'">'+escapeHTML(entry.display_url || entry.url)+'</a>';
			entityIndices[entry.indices[0]] = [entry.indices[1], link];
		});
		
		$.each(entities.hashtags || [], function(i, entry) {
			var link = '<a class="twitter-hashtag" href="'+linkHashTag(entry.text)+'">'+escapeHTML('#'+entry.text)+'</a>';
			entityIndices[entry.indices[0]] = [entry.indices[1], link];
		});
		
		$.each(entities.user_mentions || [], function(i, entry) {
			var link = '<a class="twitter-mention" href="'+linkUserID(entry.id)+'">'+escapeHTML('@'+entry.screen_name)+'</a>';
			entityIndices[entry.indices[0]] = [entry.indices[1], link];
		});
		
		return spliceText(text, entityIndices);
	}
	var linkedText = linkEntities(innerData.entities, innerData.text);
	
	this.getHtml = function() {
		var container = $('<div class="tweet">');
		
		var authorDetails = $('<a class="tweet-author-details">');
		authorDetails.attr('href', linkUserID(userID));
		
		var authorName = $('<span class="tweet-author-name">');
		authorName.text(userRealName);
		
		var authorID = $('<span class="tweet-author-id">');
		authorID.text(userScreenName);
		
		authorDetails.append(authorName, authorID);
		container.append(authorDetails);
		
		var text = $('<div class="tweet-text">');
		text.html(linkedText);
		container.append(text);
		
		return container;
	}
}

function TweetsList(container) {
	var tweetsList = this;
	
	container = $(container);
	var list = $('<ul class="tweets-list">');
	container.append(list);
	
	var cleanup = function() {
		var bottom = container.height();
		list.children().each(function(index, listItem) {
			if ($(listItem).position().top > bottom) {
				$(listItem).remove();
			}
		});
	}
	
	this.showTweet = function(tweet) {
		var listItem = $('<li>');
		listItem.html(tweet.getHtml());
		listItem.hide();
		listItem.css('opacity', '0');
		
		list.prepend(listItem);
		
		var expandTime = listItem.height() * 8;
		listItem.animate({
			'height': 'show',
			'opacity': '1'
		}, expandTime, 'linear', function() {
			cleanup();
		});
		
		/*listItem.slideDown(500);*/
	}
}

function TweetQuery(lang) {
	var tweetQuery = this;
	
	// request is tightly encapsulated because we might move that logic to a remote server
	
	var QUERY_URL = 'https://api.twitter.com/1/lists/statuses.json';
	var request = {
		'owner_screen_name' : 'hello_ubuntu',
		'slug' : 'installer-slideshow',
		'include_entities' : true,
		'include_rts' : true,
		'per_page' : 25
	}
	
	//var QUERY_URL = 'https://search.twitter.com/search.json';
	/*var request = {
		'q' : 'from:ubuntu OR from:ubuntudev OR from:planetubuntu OR from:ubuntul10n OR from:ubuntucloud OR from:ubuntuone OR from:ubuntudesigners OR from:ubuntuunity OR from:canonical',
		'lang' : 'all',
		'result_type' : 'recent',
		'rpp' : 25,
		'include_entities' : true
	}*/
	
	var lastUpdate = 0;
	
	/** Time since last update, in seconds */
	this.getTimeSinceUpdate = function() {
		var now = Date.now();
		return now - lastUpdate;
	}
	
	this.loadTweets = function(loadedCallback) {
		var newTweets = [];
		
		$.ajax({
			url: QUERY_URL,
			dataType: 'jsonp',
			data: request,
			timeout: 5000,
			success: function(data, status, xhr) {
				//var results = data.results || [];
				var results = data || [];
				if ('results' in results) results = results.results;
				$.each(results, function(index, tweetData) {
					var tweet = new Tweet(tweetData);
					newTweets.unshift(tweet);
				});
			},
			complete: function(xhr, status) {
				loadedCallback(newTweets);
			}
		});
		lastUpdate = Date.now();
	}
}

function TweetBuffer() {
	var tweetBuffer = this;
	
	var query = new TweetQuery('all');
	
	var tweets = [];
	var nextTweetIndex = 0;
	
	var loadedCallback = function(newTweets) {
		if (newTweets.length > 0) {
			tweets = newTweets;
		}
		nextTweet = 0;
	}
	
	var getNextTweet = function(returnTweet) {
		if (nextTweetIndex < tweets.length) {
			returnTweet(tweets[nextTweetIndex]);
		} else {
			nextTweetIndex = 0;
			if (query.getTimeSinceUpdate() > 15 * 60 * 1000) {
				// load new tweets every 15 minutes
				query.loadTweets(function(newTweets) {
					loadedCallback(newTweets);
					returnTweet(tweets[nextTweetIndex]);
				});
			} else {
				returnTweet(tweets[nextTweetIndex]);
			}
		}
	}
	
	
	this.dataIsAvailable = function(response) {
		getNextTweet(function(tweet) {
			response ( (tweet !== undefined) );
		});
	}
	
	/* Loads (if necessary) the next tweet and sends it asynchronously to
	 * the tweetReceived(tweet) callback. The tweet parameter is undefined
	 * if no tweets are available.
	 */
	this.popTweet = function(tweetReceived) {
		getNextTweet(function(tweet) {
			nextTweetIndex += 1;
			tweetReceived(tweet);
		});
	}
}

function TwitterStream(streamContainer) {
	var twitterStream = this;
	
	var tweetsContainer = $(streamContainer).children('.twitter-stream-tweets');
	var tweetsList = new TweetsList(tweetsContainer);
	
	var tweetBuffer = new TweetBuffer();
	
	var showNextInterval = undefined;
	
	var showNextTweet = function() {
		tweetBuffer.popTweet(function(tweet) {
			if (tweet) {
				twitterStream.enable();
				tweetsList.showTweet(tweet);
			} else {
				// this isn't working, so we'll hide the stream
				twitterStream.disable();
			}
		});
	}
	
	var _enabled = false;
	this.isEnabled = function() {
		return _enabled;
	}
	this.enable = function(immediate) {
		if (_enabled) return;
		if (immediate) {
			$(streamContainer).show();
		} else {
			$(streamContainer).fadeIn(150);
		}
		_enabled = true;
	}
	this.disable = function(immediate) {
		if (! _enabled) return;
		if (immediate) {
			$(streamContainer).hide();
		} else {
			$(streamContainer).fadeOut(150);
		}
		_enabled = false;
		this.stop();
	}
	
	this.start = function() {
		this.stop();
		showNextInterval = window.setInterval(showNextTweet, 6000);
	}
	this.stop = function() {
		if (showNextInterval) window.clearInterval(showNextInterval);
	}
	
	var _init = function() {
		tweetBuffer.dataIsAvailable(function(available) {
			if (available) {
				twitterStream.enable(true);
				// make sure there is some content visible from the start
				showNextTweet();
			} else {
				twitterStream.disable(true);
			}
		});
	}
	_init();
}

/* Only show the Twitter stuff if the slideshow is supposed to be English */
if ('locale' in INSTANCE_OPTIONS) {
	var locale_data = parse_locale_code(INSTANCE_OPTIONS['locale']);
	var language = locale_data['language'];
} else {
	var language = 'C';
}

var twitterLanguages = ['en', 'C'];
if (twitterLanguages.indexOf(language) >= 0) {
	var doTwitter = true;
} else {
	var doTwitter = false;
}

// Turn off Twitter for security reason
doTwitter = false;

Signals.watch('slideshow-loaded', function() {
	if (doTwitter) {
		$('.twitter-stream').each(function(index, streamContainer) {
			var stream = new TwitterStream(streamContainer);
			$(streamContainer).data('stream-object', stream);
			// TODO: test connection, show immediately if connection is good
		});
	
		$('.twitter-post-status-link').each(function(index, linkContent) {
			// Twitter-post-status-link is a <div> to avoid being translated. We need to wrap it around an <a> tag
			var statusText = $(linkContent).children('.twitter-post-status-text').text();
			var link = $('<a>');
			link.attr('href', 'https://twitter.com/home?status='+encodeURIComponent(statusText));
			link.insertBefore(linkContent);
			$(linkContent).appendTo(link);
		});
	} else {
		$('.twitter-stream').hide();
		/* TODO: show something charming? */
	}
});

Signals.watch('slide-opened', function(slide) {
	if (! doTwitter) return;
	
	var streamContainers = $('.twitter-stream', slide);
	streamContainers.each(function(index, streamContainer) {
		var stream = $(streamContainer).data('stream-object');
		if (stream) {
			stream.start();
		}
	});
});

Signals.watch('slide-closing', function(slide) {
	if (! doTwitter) return;
	
	var streamContainers = $('.twitter-stream', slide);
	streamContainers.each(function(index, streamContainer) {
		var stream = $(streamContainer).data('stream-object');
		if (stream) {
			stream.stop();
		}
	});
});

