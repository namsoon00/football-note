import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../domain/entities/news_article.dart';
import '../domain/entities/news_channel.dart';
import '../domain/repositories/news_repository.dart';
import '../domain/repositories/option_repository.dart';

class RssNewsRepository implements NewsRepository {
  final OptionRepository? _optionRepository;

  RssNewsRepository([this._optionRepository]);

  static const List<String> _blockedSourceKeywords = [
    '카지노',
    '도박',
    '토토',
    '베팅',
    '바카라',
    '성인',
    '유흥',
    'porn',
    'sex',
    'gambling',
    'betting',
    'casino',
  ];

  static const List<String> _blockedLinkKeywords = [
    '/casino',
    '/bet',
    '/gambling',
    '/adult',
    '/porn',
    'sportsbook',
  ];

  static const List<String> _defaultBlockedDomains = [
    'ad.doubleclick.net',
    'doubleclick.net',
    'googlesyndication.com',
    'taboola.com',
    'outbrain.com',
    'adnxs.com',
    'criteo.com',
    'mgid.com',
  ];

  static const List<String> _blockedSourceHintKeywords = [
    '보도자료',
    '홍보',
    '광고',
    'sponsored',
    'partner content',
  ];

  static const List<_FeedConfig> _feeds = [
    _FeedConfig(
      id: 'google_kleague_ko',
      name: 'Google News · K리그',
      url:
          'https://news.google.com/rss/search?q=K%EB%A6%AC%EA%B7%B8&hl=ko&gl=KR&ceid=KR:ko',
    ),
    _FeedConfig(
      id: 'google_domestic_ko',
      name: 'Google News · 국내축구',
      url:
          'https://news.google.com/rss/search?q=%EA%B5%AD%EB%82%B4%20%EC%B6%95%EA%B5%AC&hl=ko&gl=KR&ceid=KR:ko',
    ),
    _FeedConfig(
      id: 'google_kfa_ko',
      name: 'Google News · 대한축구협회',
      url:
          'https://news.google.com/rss/search?q=%EB%8C%80%ED%95%9C%EC%B6%95%EA%B5%AC%ED%98%91%ED%9A%8C&hl=ko&gl=KR&ceid=KR:ko',
    ),
    _FeedConfig(
      id: 'bbc_football_en',
      name: 'BBC Sport',
      url: 'https://feeds.bbci.co.uk/sport/football/rss.xml',
    ),
    _FeedConfig(
      id: 'google_premier_en',
      name: 'Google News · Premier League',
      url:
          'https://news.google.com/rss/search?q=Premier%20League%20football&hl=en-US&gl=US&ceid=US:en',
    ),
    _FeedConfig(
      id: 'google_ucl_en',
      name: 'Google News · Champions League',
      url:
          'https://news.google.com/rss/search?q=UEFA%20Champions%20League%20football&hl=en-US&gl=US&ceid=US:en',
    ),
    _FeedConfig(
      id: 'google_laliga_en',
      name: 'Google News · La Liga',
      url:
          'https://news.google.com/rss/search?q=La%20Liga%20football&hl=en-US&gl=US&ceid=US:en',
    ),
  ];

  @override
  List<NewsChannel> channels() {
    return _feeds
        .map((feed) => NewsChannel(id: feed.id, name: feed.name))
        .toList(growable: false);
  }

  @override
  Future<List<NewsArticle>> fetchLatest(String channelId) async {
    final feed = _feeds.firstWhere(
      (item) => item.id == channelId,
      orElse: () => _feeds.first,
    );
    final results = await _fetchFeed(feed);
    if (results.isEmpty) {
      throw StateError('Failed to fetch football news.');
    }
    final filtered = results.where(_isUsableArticle).toList();
    filtered.sort((a, b) {
      final at = a.publishedAt;
      final bt = b.publishedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    return filtered;
  }

  bool _isUsableArticle(NewsArticle article) {
    if (!_hasUsableImage(article)) return false;
    return !_isBlocked(article);
  }

  bool _hasUsableImage(NewsArticle article) {
    final url = article.imageUrl.trim();
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  bool _isBlocked(NewsArticle article) {
    final source = article.source.toLowerCase();
    final title = article.title.toLowerCase();
    final link = article.link.toLowerCase();
    final host = _hostOf(article.link);
    for (final keyword in _blockedSourceKeywords) {
      if (source.contains(keyword) || title.contains(keyword)) {
        return true;
      }
    }
    for (final keyword in _blockedSourceHintKeywords) {
      if (source.contains(keyword) || title.contains(keyword)) {
        return true;
      }
    }
    for (final keyword in _blockedLinkKeywords) {
      if (link.contains(keyword)) {
        return true;
      }
    }
    for (final domain in _allBlockedDomains()) {
      if (host == domain || host.endsWith('.$domain')) {
        return true;
      }
    }
    return false;
  }

  Set<String> _allBlockedDomains() {
    final merged = <String>{..._defaultBlockedDomains};
    final custom =
        _optionRepository?.getOptions('news_blocked_domains', const []) ??
            const <String>[];
    for (final domain in custom) {
      final normalized = _normalizeDomain(domain);
      if (normalized.isNotEmpty) {
        merged.add(normalized);
      }
    }
    return merged;
  }

  String _hostOf(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.host.isEmpty) return '';
    return uri.host.toLowerCase();
  }

  String _normalizeDomain(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return '';
    final withScheme = raw.contains('://') ? raw : 'https://$raw';
    final parsed = Uri.tryParse(withScheme);
    final host = parsed?.host.toLowerCase().trim() ?? raw;
    if (host.isEmpty) return '';
    return host;
  }

  Future<List<NewsArticle>> _fetchFeed(_FeedConfig feed) async {
    for (final request in _feedRequestsForPlatform(feed.url)) {
      try {
        final response = await http
            .get(Uri.parse(request.url))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          continue;
        }
        final results = _parseResponseByType(
          feed: feed,
          body: response.body,
          responseType: request.responseType,
        );

        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {
        // Try next proxy endpoint.
      }
    }
    return _fallbackArticles(feed);
  }

  List<_FeedRequest> _feedRequestsForPlatform(String url) {
    if (!kIsWeb) {
      return [
        _FeedRequest(url: url, responseType: _FeedResponseType.xml),
      ];
    }
    final encoded = Uri.encodeComponent(url);
    return [
      _FeedRequest(
        url: 'https://api.allorigins.win/raw?url=$encoded',
        responseType: _FeedResponseType.xml,
      ),
      _FeedRequest(
        url: 'https://api.allorigins.win/get?url=$encoded',
        responseType: _FeedResponseType.allOriginsGet,
      ),
      _FeedRequest(
        url: 'https://api.rss2json.com/v1/api.json?rss_url=$encoded',
        responseType: _FeedResponseType.rss2Json,
      ),
    ];
  }

  List<NewsArticle> _parseResponseByType({
    required _FeedConfig feed,
    required String body,
    required _FeedResponseType responseType,
  }) {
    switch (responseType) {
      case _FeedResponseType.xml:
        return _parseXmlItems(feed, body);
      case _FeedResponseType.allOriginsGet:
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return const [];
        final contents = decoded['contents'];
        if (contents is! String || contents.trim().isEmpty) return const [];
        return _parseXmlItems(feed, contents);
      case _FeedResponseType.rss2Json:
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return const [];
        final items = decoded['items'];
        if (items is! List) return const [];
        final results = <NewsArticle>[];
        for (final item in items.take(20)) {
          if (item is! Map) continue;
          final title = item['title']?.toString().trim() ?? '';
          final link = item['link']?.toString().trim() ?? '';
          if (title.isEmpty || link.isEmpty) continue;
          final dateRaw = item['pubDate']?.toString().trim();
          DateTime? publishedAt;
          if (dateRaw != null && dateRaw.isNotEmpty) {
            publishedAt = DateTime.tryParse(dateRaw);
          }
          final source = item['author']?.toString().trim();
          final imageUrl = _extractRss2JsonImage(item);
          results.add(
            NewsArticle(
              title: title,
              link: link,
              source: (source == null || source.isEmpty) ? feed.name : source,
              imageUrl: imageUrl,
              publishedAt: publishedAt,
            ),
          );
        }
        return results;
    }
  }

  List<NewsArticle> _parseXmlItems(_FeedConfig feed, String xmlBody) {
    final doc = XmlDocument.parse(xmlBody);
    final items = doc.findAllElements('item');
    final results = <NewsArticle>[];
    for (final item in items.take(20)) {
      final title = item.getElement('title')?.innerText.trim() ?? '';
      final link = item.getElement('link')?.innerText.trim() ?? '';
      if (title.isEmpty || link.isEmpty) continue;
      final pubDateRaw = item.getElement('pubDate')?.innerText.trim();
      DateTime? publishedAt;
      if (pubDateRaw != null && pubDateRaw.isNotEmpty) {
        publishedAt = DateTime.tryParse(pubDateRaw);
        publishedAt ??= _tryParseHttpDate(pubDateRaw);
      }
      results.add(
        NewsArticle(
          title: title,
          link: link,
          source: _extractSource(item, feed),
          imageUrl: _extractImageUrl(item),
          publishedAt: publishedAt,
        ),
      );
    }
    return results;
  }

  List<NewsArticle> _fallbackArticles(_FeedConfig feed) => const [];

  DateTime? _tryParseHttpDate(String raw) {
    try {
      return HttpDate.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _extractSource(XmlElement item, _FeedConfig feed) {
    final source = item.getElement('source')?.innerText.trim();
    if (source != null && source.isNotEmpty) {
      return source;
    }
    return feed.name;
  }

  String _extractImageUrl(XmlElement item) {
    final mediaThumb = item.getElement('media:thumbnail');
    final thumbUrl = mediaThumb?.getAttribute('url')?.trim();
    if (thumbUrl != null && thumbUrl.isNotEmpty) return thumbUrl;

    final mediaContent = item.getElement('media:content');
    final mediaContentUrl = mediaContent?.getAttribute('url')?.trim();
    if (mediaContentUrl != null && mediaContentUrl.isNotEmpty) {
      return mediaContentUrl;
    }

    final enclosure = item.getElement('enclosure');
    final encType = enclosure?.getAttribute('type')?.toLowerCase() ?? '';
    final encUrl = enclosure?.getAttribute('url')?.trim();
    if (encUrl != null &&
        encUrl.isNotEmpty &&
        (encType.startsWith('image/') || encType.isEmpty)) {
      return encUrl;
    }

    final description = item.getElement('description')?.innerText ?? '';
    final htmlImage = _extractImageFromHtml(description);
    if (htmlImage.isNotEmpty) return htmlImage;
    return '';
  }

  String _extractRss2JsonImage(Map item) {
    final thumb = item['thumbnail']?.toString().trim() ?? '';
    if (thumb.isNotEmpty) return thumb;

    final enclosure = item['enclosure'];
    if (enclosure is Map) {
      final encLink = enclosure['link']?.toString().trim() ?? '';
      if (encLink.isNotEmpty) return encLink;
    }

    final description = item['description']?.toString() ?? '';
    final htmlImage = _extractImageFromHtml(description);
    if (htmlImage.isNotEmpty) return htmlImage;
    return '';
  }

  String _extractImageFromHtml(String html) {
    final match = RegExp(
      "<img[^>]+src=[\"']([^\"']+)[\"']",
      caseSensitive: false,
    ).firstMatch(html);
    if (match == null) return '';
    return match.group(1)?.trim() ?? '';
  }
}

class _FeedConfig {
  final String id;
  final String name;
  final String url;

  const _FeedConfig({
    required this.id,
    required this.name,
    required this.url,
  });
}

enum _FeedResponseType {
  xml,
  allOriginsGet,
  rss2Json,
}

class _FeedRequest {
  final String url;
  final _FeedResponseType responseType;

  const _FeedRequest({
    required this.url,
    required this.responseType,
  });
}
