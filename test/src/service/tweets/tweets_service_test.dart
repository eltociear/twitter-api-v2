// Copyright 2022 Kato Shinya. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided the conditions.

// Package imports:
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:twitter_api_v2/src/client/client_context.dart';
import 'package:twitter_api_v2/src/client/user_context.dart';
import 'package:twitter_api_v2/src/exception/rate_limit_exceeded_exception.dart';
import 'package:twitter_api_v2/src/exception/twitter_exception.dart';
import 'package:twitter_api_v2/src/service/filtered_stream_response.dart';
import 'package:twitter_api_v2/src/service/tweets/exclude_tweet_type.dart';
import 'package:twitter_api_v2/src/service/tweets/filtering_rule_data.dart';
import 'package:twitter_api_v2/src/service/tweets/filtering_rule_meta.dart';
import 'package:twitter_api_v2/src/service/tweets/filtering_rule_param.dart';
import 'package:twitter_api_v2/src/service/tweets/matching_rule.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_count_data.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_count_meta.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_data.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_expansion.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_field.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_geo_param.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_media_param.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_meta.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_poll_param.dart';
import 'package:twitter_api_v2/src/service/tweets/tweet_reply_param.dart';
import 'package:twitter_api_v2/src/service/tweets/tweets_service.dart';
import 'package:twitter_api_v2/src/service/twitter_response.dart';
import 'package:twitter_api_v2/src/service/users/user_data.dart';
import 'package:twitter_api_v2/src/service/users/user_meta.dart';
import '../../../mocks/client_context_stubs.dart' as context;

void main() {
  group('.createTweet', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildPostStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets',
          'test/src/service/tweets/data/create_tweet.json',
        ),
      );

      final response = await tweetsService.createTweet(
        text: 'Hello, World!',
        media: TweetMediaParam(mediaIds: [], taggedUserIds: []),
        geo: TweetGeoParam(placeId: ''),
        poll: TweetPollParam(duration: Duration(days: 7), options: []),
        reply: TweetReplyParam(inReplyToTweetId: '', excludeReplyUserIds: []),
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1445880548472328192');
      expect(response.data.text, 'Hello, World!');
    });

    test('throws TwitterException', () async {
      final tweetsService = TweetsService(
        context: ClientContext(
          bearerToken: '',
          timeout: const Duration(seconds: 10),
        ),
      );

      expect(
        () async =>
            await tweetsService.createTweet(text: 'Throw TwitterException'),
        throwsA(
          allOf(isA<TwitterException>(),
              predicate((e) => e.toString().isNotEmpty)),
        ),
      );
    });

    test('throws TwitterException due to no data', () async {
      final tweetsService = TweetsService(
        context: context.buildPostStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets',
          'test/src/service/tweets/data/no_data.json',
        ),
      );

      expect(
        () async =>
            await tweetsService.createTweet(text: 'Throw TwitterException'),
        throwsA(
          allOf(isA<TwitterException>(),
              predicate((e) => e.toString().isNotEmpty)),
        ),
      );
    });

    test('throws RateLimitExceededException', () async {
      final tweetsService = TweetsService(
        context: context.buildPostStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets',
          'test/src/service/tweets/data/rate_limit_exceeded_error.json',
        ),
      );

      expect(
        () async => await tweetsService.createTweet(
            text: 'Throw RateLimitExceededException'),
        throwsA(
          allOf(
            isA<RateLimitExceededException>(),
            predicate(
              (e) =>
                  e.toString() ==
                  'RateLimitExceededException: Rate limit exceeded',
            ),
          ),
        ),
      );
    });

    test('with OAuth1.0a', () async {
      final clientContext = context.buildPostStub(
        UserContext.oauth2OrOAuth1,
        '/2/tweets',
        'test/src/service/tweets/data/create_tweet.json',
      );

      when(clientContext.hasOAuth1Client).thenReturn(true);

      final tweetsService = TweetsService(context: clientContext);
      final response = await tweetsService.createTweet(text: 'Hello, World!');

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1445880548472328192');
      expect(response.data.text, 'Hello, World!');
    });
  });

  group('.destroyTweet', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildDeleteStub(
          '/2/tweets/1111',
          'test/src/service/tweets/data/destroy_tweet.json',
        ),
      );

      final response = await tweetsService.destroyTweet(tweetId: '1111');

      expect(response, isA<bool>());
      expect(response, isTrue);
    });

    test('with OAuth1.0a', () async {
      final clientContext = context.buildDeleteStub(
        '/2/tweets/1111',
        'test/src/service/tweets/data/destroy_tweet.json',
      );

      when(clientContext.hasOAuth1Client).thenReturn(true);

      final tweetsService = TweetsService(context: clientContext);
      final response = await tweetsService.destroyTweet(tweetId: '1111');

      expect(response, isA<bool>());
      expect(response, isTrue);
    });
  });

  test('.createLike', () async {
    final tweetsService = TweetsService(
      context: context.buildPostStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/likes',
        'test/src/service/tweets/data/create_like.json',
      ),
    );

    final response = await tweetsService.createLike(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.destroyLike', () async {
    final tweetsService = TweetsService(
      context: context.buildDeleteStub(
        '/2/users/0000/likes/1111',
        'test/src/service/tweets/data/destroy_like.json',
      ),
    );

    final response = await tweetsService.destroyLike(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.createRetweet', () async {
    final tweetsService = TweetsService(
      context: context.buildPostStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/retweets',
        'test/src/service/tweets/data/create_retweet.json',
      ),
    );

    final response = await tweetsService.createRetweet(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.destroyRetweet', () async {
    final tweetsService = TweetsService(
      context: context.buildDeleteStub(
        '/2/users/0000/retweets/1111',
        'test/src/service/tweets/data/destroy_retweet.json',
      ),
    );

    final response = await tweetsService.destroyRetweet(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.lookupLikingUsers', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/tweets/1111/liking_users',
        'test/src/service/tweets/data/lookup_liking_users.json',
        {},
      ),
    );

    final response = await tweetsService.lookupLikingUsers(
      tweetId: '1111',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<UserData>>());
    expect(response.meta, isA<UserMeta>());
    expect(response.data.length, 5);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 5);
  });

  test('.lookupLikedTweets', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/liked_tweets',
        'test/src/service/tweets/data/lookup_liked_tweets.json',
        {},
      ),
    );

    final response = await tweetsService.lookupLikedTweets(
      userId: '0000',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 5);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 5);
  });

  test('.lookupRetweetedUsers', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/tweets/1111/retweeted_by',
        'test/src/service/tweets/data/lookup_retweeted_users.json',
        {},
      ),
    );

    final response = await tweetsService.lookupRetweetedUsers(
      tweetId: '1111',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<UserData>>());
    expect(response.meta, isA<UserMeta>());
    expect(response.data.length, 3);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 3);
  });

  test('.lookupQuoteTweets', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/tweets/1111/quote_tweets',
        'test/src/service/tweets/data/lookup_quote_tweets.json',
        {},
      ),
    );

    final response = await tweetsService.lookupQuoteTweets(
      tweetId: '1111',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 10);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 10);
  });

  group('.searchRecent', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2Only,
          '/2/tweets/search/recent',
          'test/src/service/tweets/data/search_recent.json',
          {'query': 'hello'},
        ),
      );

      final response = await tweetsService.searchRecent(
        query: 'hello',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 6);
      expect(response.meta, isNotNull);
      expect(response.meta!.resultCount, 6);
    });

    test('with various fields', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2Only,
          '/2/tweets/search/recent',
          'test/src/service/tweets/data/search_recent_with_various_fields.json',
          {'query': 'hello'},
        ),
      );

      final response = await tweetsService.searchRecent(
        query: 'hello',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 6);
      expect(response.meta, isNotNull);
      expect(response.meta!.resultCount, 6);
    });
  });

  test('.searchAll', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2Only,
        '/2/tweets/search/all',
        'test/src/service/tweets/data/search_all.json',
        {'query': 'hello'},
      ),
    );

    final response = await tweetsService.searchAll(
      query: 'hello',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 6);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 6);
  });

  group('.lookupById', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id.json',
          {},
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with expansions', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id.json',
          {
            'expansions': 'author_id',
          },
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
        expansions: [TweetExpansion.authorId],
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with multiple expansions', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id.json',
          {
            'expansions': 'author_id,attachments.media_keys',
          },
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
        expansions: [
          TweetExpansion.authorId,
          TweetExpansion.attachmentsMediaKeys
        ],
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with fields', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id.json',
          {
            'tweet.fields': 'attachments',
          },
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
        tweetFields: [TweetField.attachments],
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with multiple fields', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id.json',
          {
            'tweet.fields': 'attachments,author_id',
          },
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
        tweetFields: [
          TweetField.attachments,
          TweetField.authorId,
        ],
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with media', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id_with_media.json',
          {},
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with polls', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id_with_polls.json',
          {},
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });

    test('with places', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/tweets/1111',
          'test/src/service/tweets/data/lookup_by_id_with_places.json',
          {},
        ),
      );

      final response = await tweetsService.lookupById(
        tweetId: '1111',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<TweetData>());
      expect(response.data.id, '1067094924124872705');
    });
  });

  test('.lookupByIds', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/tweets',
        'test/src/service/tweets/data/lookup_by_ids.json',
        {'ids': '1261326399320715264,1278347468690915330'},
      ),
    );

    final response = await tweetsService.lookupByIds(
      tweetIds: ['1261326399320715264', '1278347468690915330'],
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.data.length, 2);
  });

  test('.countRecent', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2Only,
        '/2/tweets/counts/recent',
        'test/src/service/tweets/data/counts_recent.json',
        {
          'query': 'hello',
          'since_id': '1111',
          'until_id': '2222',
        },
      ),
    );

    final response = await tweetsService.countRecent(
      query: 'hello',
      sinceTweetId: '1111',
      untilTweetId: '2222',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetCountData>>());
    expect(response.meta, isA<TweetCountMeta>());
    expect(response.meta!.total, 744364);
  });

  test('.countAll', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2Only,
        '/2/tweets/counts/all',
        'test/src/service/tweets/data/counts_all.json',
        {
          'query': 'hello',
          'since_id': '1111',
          'until_id': '2222',
        },
      ),
    );

    final response = await tweetsService.countAll(
      query: 'hello',
      sinceTweetId: '1111',
      untilTweetId: '2222',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetCountData>>());
    expect(response.meta, isA<TweetCountMeta>());
    expect(response.meta!.total, 744364);
  });

  test('.createBookmark', () async {
    final tweetsService = TweetsService(
      context: context.buildPostStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/bookmarks',
        'test/src/service/tweets/data/create_bookmark.json',
      ),
    );

    final response = await tweetsService.createBookmark(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.destroyBookmark', () async {
    final tweetsService = TweetsService(
      context: context.buildDeleteStub(
        '/2/users/0000/bookmarks/1111',
        'test/src/service/tweets/data/destroy_bookmark.json',
      ),
    );

    final response = await tweetsService.destroyBookmark(
      userId: '0000',
      tweetId: '1111',
    );

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.lookupBookmarks', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2Only,
        '/2/users/0000/bookmarks',
        'test/src/service/tweets/data/lookup_bookmarks.json',
        {},
      ),
    );

    final response = await tweetsService.lookupBookmarks(userId: '0000');

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 5);
    expect(response.meta, isNotNull);
    expect(response.meta!.resultCount, 5);
  });

  test('.createHiddenReply', () async {
    final tweetsService = TweetsService(
      context: context.buildPutStub(
        '/2/tweets/0000/hidden',
        'test/src/service/tweets/data/create_hidden_reply.json',
      ),
    );

    final response = await tweetsService.createHiddenReply(tweetId: '0000');

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.destroyHiddenReply', () async {
    final tweetsService = TweetsService(
      context: context.buildPutStub(
        '/2/tweets/0000/hidden',
        'test/src/service/tweets/data/destroy_hidden_reply.json',
      ),
    );

    final response = await tweetsService.destroyHiddenReply(tweetId: '0000');

    expect(response, isA<bool>());
    expect(response, isTrue);
  });

  test('.lookupMentions', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/mentions',
        'test/src/service/tweets/data/lookup_mentions.json',
        {
          'max_results': '10',
          'pagination_token': 'TOKEN',
        },
      ),
    );

    final response = await tweetsService.lookupMentions(
      userId: '0000',
      maxResults: 10,
      paginationToken: 'TOKEN',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 5);
    expect(response.meta!.resultCount, 5);
  });

  group('.lookupTweets', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/users/0000/tweets',
          'test/src/service/tweets/data/lookup_tweets.json',
          {
            'max_results': '10',
            'pagination_token': 'TOKEN',
          },
        ),
      );

      final response = await tweetsService.lookupTweets(
        userId: '0000',
        maxResults: 10,
        paginationToken: 'TOKEN',
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 10);
      expect(response.meta!.resultCount, 10);
    });

    test('with exclude', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/users/0000/tweets',
          'test/src/service/tweets/data/lookup_tweets.json',
          {
            'max_results': '10',
            'pagination_token': 'TOKEN',
            'exclude': 'replies',
          },
        ),
      );

      final response = await tweetsService.lookupTweets(
        userId: '0000',
        maxResults: 10,
        paginationToken: 'TOKEN',
        excludes: [ExcludeTweetType.replies],
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 10);
      expect(response.meta!.resultCount, 10);
    });

    test('with excludes', () async {
      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/users/0000/tweets',
          'test/src/service/tweets/data/lookup_tweets.json',
          {
            'max_results': '10',
            'pagination_token': 'TOKEN',
            'exclude': 'retweets,replies',
          },
        ),
      );

      final response = await tweetsService.lookupTweets(
        userId: '0000',
        maxResults: 10,
        paginationToken: 'TOKEN',
        excludes: ExcludeTweetType.values,
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 10);
      expect(response.meta!.resultCount, 10);
    });

    test('with date time in ISO format', () async {
      final now = DateTime.now();

      final tweetsService = TweetsService(
        context: context.buildGetStub(
          UserContext.oauth2OrOAuth1,
          '/2/users/0000/tweets',
          'test/src/service/tweets/data/lookup_tweets.json',
          {
            'max_results': '10',
            'pagination_token': 'TOKEN',
            'start_time': now.toUtc().toIso8601String(),
          },
        ),
      );

      final response = await tweetsService.lookupTweets(
        userId: '0000',
        maxResults: 10,
        paginationToken: 'TOKEN',
        startTime: now,
      );

      expect(response, isA<TwitterResponse>());
      expect(response.data, isA<List<TweetData>>());
      expect(response.meta, isA<TweetMeta>());
      expect(response.data.length, 10);
      expect(response.meta!.resultCount, 10);
    });
  });

  test('.lookupHomeTimeline', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2OrOAuth1,
        '/2/users/0000/timelines/reverse_chronological',
        'test/src/service/tweets/data/lookup_home_timeline.json',
        {
          'max_results': '5',
          'pagination_token': 'TOKEN',
        },
      ),
    );

    final response = await tweetsService.lookupHomeTimeline(
      userId: '0000',
      maxResults: 5,
      paginationToken: 'TOKEN',
    );

    expect(response, isA<TwitterResponse>());
    expect(response.data, isA<List<TweetData>>());
    expect(response.meta, isA<TweetMeta>());
    expect(response.data.length, 5);
    expect(response.meta!.resultCount, 5);
  });

  group('.connectVolumeStream', () {
    test('normal case', () async {
      final tweetsService = TweetsService(
        context: context.buildSendStub(
          UserContext.oauth2Only,
          'test/src/service/tweets/data/connect_volume_stream.json',
          const {'backfill_minutes': '5'},
        ),
      );

      final response = await tweetsService.connectVolumeStream(
        backfillMinutes: 5,
      );

      final data = await response.toList();

      expect(response, isA<Stream<TwitterResponse<TweetData, void>>>());
      expect(data, isA<List<TwitterResponse<TweetData, void>>>());
      expect(data.length, 70);
    });

    test('with error', () async {
      final tweetsService = TweetsService(
        context: context.buildSendStub(
          UserContext.oauth2Only,
          'test/src/service/tweets/data/connect_volume_stream_with_error.json',
          const {'backfill_minutes': '5'},
        ),
      );

      final response = await tweetsService.connectVolumeStream(
        backfillMinutes: 5,
      );

      final data = <TwitterResponse<TweetData, void>>[];
      final errors = <dynamic>[];

      await for (final event in response.handleError(errors.add)) {
        data.add(event);
      }

      expect(data.length, 5);
      expect(errors.length, 1);
      expect(errors.single, isA<TwitterException>());
    });
  });

  test('.connectFilteredStream', () async {
    final tweetsService = TweetsService(
      context: context.buildSendStub(
        UserContext.oauth2Only,
        'test/src/service/tweets/data/connect_filtered_stream.json',
        const {'backfill_minutes': '5'},
      ),
    );

    final response = await tweetsService.connectFilteredStream(
      backfillMinutes: 5,
    );

    final data = await response.toList();

    expect(response, isA<Stream<FilteredStreamResponse>>());
    expect(data.first, isA<FilteredStreamResponse>());
    expect(data.first.data, isA<TweetData>());
    expect(data.first.matchingRules, isA<List<MatchingRule>>());
    expect(data.first.matchingRules.isNotEmpty, isTrue);
  });

  test('.createFilteringRules', () async {
    final tweetsService = TweetsService(
      context: context.buildPostStub(
        UserContext.oauth2Only,
        '/2/tweets/search/stream/rules',
        'test/src/service/tweets/data/create_filtering_rules.json',
      ),
    );

    final response = await tweetsService.createFilteringRules(rules: [
      FilteringRuleParam(value: 'test'),
      FilteringRuleParam(value: 'hello'),
    ]);

    expect(
      response,
      isA<TwitterResponse<List<FilteringRuleData>, FilteringRuleMeta>>(),
    );
    expect(response.data, isA<List<FilteringRuleData>>());
    expect(response.meta, isA<FilteringRuleMeta>());
    expect(response.meta!.summary!.createdCount, 4);
    expect(response.meta!.summary!.notCreatedCount, 0);
  });

  test('.destroyFilteringRules', () async {
    final tweetsService = TweetsService(
      context: context.buildPostStub(
        UserContext.oauth2Only,
        '/2/tweets/search/stream/rules',
        'test/src/service/tweets/data/destroy_filtering_rules.json',
      ),
    );

    final response = await tweetsService.destroyFilteringRules(
      ruleIds: ['XXXX', 'YYYY'],
    );

    expect(response, isA<FilteringRuleMeta>());
    expect(response.summary!.deletedCount, 1);
    expect(response.summary!.notDeletedCount, 0);
  });

  test('.lookupFilteringRules', () async {
    final tweetsService = TweetsService(
      context: context.buildGetStub(
        UserContext.oauth2Only,
        '/2/tweets/search/stream/rules',
        'test/src/service/tweets/data/lookup_filtering_rules.json',
        {
          'ids': 'XXXX,YYYY',
        },
      ),
    );

    final response = await tweetsService.lookupFilteringRules(
      ruleIds: ['XXXX', 'YYYY'],
    );

    expect(
      response,
      isA<TwitterResponse<List<FilteringRuleData>, FilteringRuleMeta>>(),
    );
    expect(response.data, isA<List<FilteringRuleData>>());
    expect(response.meta, isA<FilteringRuleMeta>());
  });
}
