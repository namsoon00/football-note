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

  static const List<String> _domesticFootballKeywords = [
    '국내축구',
    '한국축구',
    '프로축구',
    'k리그',
    'k league',
    'kleague',
    'k리그1',
    'k리그2',
    'k3리그',
    'k4리그',
    'k5리그',
    'k6리그',
    'k7리그',
    'wk리그',
    '코리아컵',
    '축구대표팀',
    '대표팀',
    '대한축구협회',
    '축구협회',
    '홍명보호',
    '울산 hd',
    '전북 현대',
    'fc서울',
    '수원 삼성',
    '수원fc',
    '포항 스틸러스',
    '대구fc',
    '인천 유나이티드',
    '광주fc',
    '대전하나시티즌',
    '강원fc',
    '제주 유나이티드',
    '김천 상무',
    'fc안양',
    '부천fc',
    '성남fc',
    '전남 드래곤즈',
    '부산 아이파크',
    '경남fc',
    '충남아산',
    '천안시티',
    '충북청주',
    '안산 그리너스',
    '김포fc',
    '화성fc',
  ];

  static const List<_FeedConfig> _feeds = [
    _FeedConfig(
      id: 'sports_khan_domestic_soccer_ko',
      name: '스포츠경향 · 국내축구',
      url: 'https://sports.khan.co.kr/rss/soccer_korea-soccer',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'sports_khan_soccer_ko',
      name: '스포츠경향 · 축구',
      url: 'https://sports.khan.co.kr/rss/soccer',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'sportschosun_soccer_ko',
      name: '스포츠조선 · 축구',
      url: 'https://www.sportschosun.com/rss/index_sc.htm',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'sportsdonga_soccer_ko',
      name: '스포츠동아 · 축구',
      url: 'https://rss.donga.com/sportsdonga/soccer.xml',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'newsis_sports_domestic_soccer_ko',
      name: '뉴시스 · 국내축구',
      url: 'https://www.newsis.com/RSS/sports.xml',
      requireImage: false,
      keywords: _domesticFootballKeywords,
    ),
    _FeedConfig(
      id: 'khan_sports_domestic_soccer_ko',
      name: '경향신문 · 국내축구',
      url: 'https://www.khan.co.kr/rss/rssdata/kh_sports.xml',
      requireImage: false,
      keywords: _domesticFootballKeywords,
    ),
    _FeedConfig(
      id: 'google_news_domestic_soccer_ko',
      name: 'Google 뉴스 · 국내축구',
      url:
          'https://news.google.com/rss/search?q=%EA%B5%AD%EB%82%B4%EC%B6%95%EA%B5%AC+OR+K%EB%A6%AC%EA%B7%B8+OR+%ED%95%9C%EA%B5%AD%EC%B6%95%EA%B5%AC&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_kleague_ko',
      name: 'Google 뉴스 · K리그',
      url:
          'https://news.google.com/rss/search?q=K%EB%A6%AC%EA%B7%B8&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_kleague1_ko',
      name: 'Google 뉴스 · K리그1',
      url:
          'https://news.google.com/rss/search?q=K%EB%A6%AC%EA%B7%B81&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_kleague2_ko',
      name: 'Google 뉴스 · K리그2',
      url:
          'https://news.google.com/rss/search?q=K%EB%A6%AC%EA%B7%B82&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_korea_national_team_ko',
      name: 'Google 뉴스 · 축구대표팀',
      url:
          'https://news.google.com/rss/search?q=%EC%B6%95%EA%B5%AC%EB%8C%80%ED%91%9C%ED%8C%80+OR+%EB%8C%80%ED%95%9C%EB%AF%BC%EA%B5%AD+%EC%B6%95%EA%B5%AC%EB%8C%80%ED%91%9C%ED%8C%80&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_kfa_ko',
      name: 'Google 뉴스 · 대한축구협회',
      url:
          'https://news.google.com/rss/search?q=%EB%8C%80%ED%95%9C%EC%B6%95%EA%B5%AC%ED%98%91%ED%9A%8C+OR+KFA+%EC%B6%95%EA%B5%AC&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_korea_cup_ko',
      name: 'Google 뉴스 · 코리아컵',
      url:
          'https://news.google.com/rss/search?q=%EC%BD%94%EB%A6%AC%EC%95%84%EC%BB%B5+%EC%B6%95%EA%B5%AC&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_wkleague_ko',
      name: 'Google 뉴스 · WK리그',
      url:
          'https://news.google.com/rss/search?q=WK%EB%A6%AC%EA%B7%B8+%EC%B6%95%EA%B5%AC&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'google_news_k3_k4_ko',
      name: 'Google 뉴스 · K3/K4리그',
      url:
          'https://news.google.com/rss/search?q=K3%EB%A6%AC%EA%B7%B8+OR+K4%EB%A6%AC%EA%B7%B8&hl=ko&gl=KR&ceid=KR:ko',
      requireImage: false,
    ),
    _FeedConfig(
      id: 'bbc_football_en',
      name: 'BBC Sport',
      url: 'https://feeds.bbci.co.uk/sport/football/rss.xml',
    ),
    _FeedConfig(
      id: 'bbc_premier_league_en',
      name: 'BBC Sport · Premier League',
      url: 'https://feeds.bbci.co.uk/sport/football/premier-league/rss.xml',
    ),
    _FeedConfig(
      id: 'bbc_champions_league_en',
      name: 'BBC Sport · Champions League',
      url: 'https://feeds.bbci.co.uk/sport/football/champions-league/rss.xml',
    ),
    _FeedConfig(
      id: 'skysports_football_en',
      name: 'Sky Sports · Football',
      url: 'https://www.skysports.com/rss/12040',
    ),
    _FeedConfig(
      id: 'espn_fc_en',
      name: 'ESPN FC',
      url: 'https://www.espn.com/espn/rss/soccer/news',
    ),
    _FeedConfig(
      id: 'guardian_football_en',
      name: 'The Guardian · Football',
      url: 'https://www.theguardian.com/football/rss',
    ),
    _FeedConfig(
      id: 'cbs_soccer_en',
      name: 'CBS Sports · Soccer',
      url: 'https://www.cbssports.com/rss/headlines/soccer/',
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
    final filtered = results.where((article) {
      return _isUsableArticle(feed: feed, article: article);
    }).toList();
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

  bool _isUsableArticle({
    required _FeedConfig feed,
    required NewsArticle article,
  }) {
    if (feed.keywords.isNotEmpty &&
        !_matchesAnyKeyword(article, feed.keywords)) {
      return false;
    }
    if (feed.requireImage && !_hasUsableImage(article)) return false;
    return !_isBlocked(article);
  }

  bool _matchesAnyKeyword(NewsArticle article, List<String> keywords) {
    final haystack =
        '${article.title} ${article.source} ${article.link}'.toLowerCase();
    for (final keyword in keywords) {
      if (haystack.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
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
      return [_FeedRequest(url: url, responseType: _FeedResponseType.xml)];
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
  final bool requireImage;
  final List<String> keywords;

  const _FeedConfig({
    required this.id,
    required this.name,
    required this.url,
    this.requireImage = true,
    this.keywords = const [],
  });
}

enum _FeedResponseType { xml, allOriginsGet, rss2Json }

class _FeedRequest {
  final String url;
  final _FeedResponseType responseType;

  const _FeedRequest({required this.url, required this.responseType});
}
