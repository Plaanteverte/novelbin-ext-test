import 'package:mangayomi/bridge_lib.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart' show parse;

class NovelBinSource extends MProvider {
  NovelBinSource({required this.source});

  final MSource source;
  final Client client = Client();

  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0',
    'Referer': source.baseUrl,
  };

  @override
  bool get supportsLatest => false;

  // 1) Popular
  @override
Future<MPages> getPopular(int page) async {
  final url = '${source.baseUrl}/sort/top-hot-novel?page=$page';
  final res = (await client.get(Uri.parse(url), headers: headers)).body;

  final titles = xpath(res, '//h3[contains(@class, "novel") and contains(@class, "title")]/a/text()');
  final links = xpath(res, '//h3[contains(@class, "novel") and contains(@class, "title")]/a/@href');
  final covers = xpath(res, '//img[contains(@class, "cover") and contains(@class, "lazy")]/@data-src');

  List<MManga> mangaList = [];

  for (var i = 0; i < titles.length; i++) {
  MManga manga = MManga();
  manga.name = titles[i];

  var link = links[i];
  if (link.startsWith('http')) {
    final uri = Uri.parse(link);
    link = uri.path; // ✅ garde uniquement le chemin
  }

  manga.link = link; // ✅ pas de baseUrl ici !
  manga.imageUrl = covers.length > i ? covers[i] : "";
  mangaList.add(manga);
}

  return MPages(mangaList, true);
}


  // 2) Detail
  @override
  Future<MManga> getDetail(String url) async {
    final fullUrl = url.startsWith('http') ? url : source.baseUrl + url;
    final res = (await client.get(Uri.parse(fullUrl), headers: headers)).body;

    final title = xpath(res, '//meta[@property="og:title"]/@content').firstOrNull ?? 'No Title';
    final description = xpath(res, '//meta[@name="description"]/@content').firstOrNull ?? '';
    final imageUrl = xpath(res, '//meta[@property="og:image"]/@content').firstOrNull ?? '';
    final author = xpath(res, '//meta[@property="og:novel:author"]/@content').firstOrNull ?? 'Unknown';
    final genresString = xpath(res, '//meta[@property="og:novel:genre"]/@content').firstOrNull ?? '';
    final genres = genresString.isNotEmpty ? genresString.split(',') : <String>[];

    MManga manga = MManga();
    manga.name = title;
    manga.description = description;
    manga.imageUrl = imageUrl;
    manga.author = author;
    manga.genre = genres;
    manga.link = url;

    return manga;
  }

  // 3) Chapters - récupère la liste des chapitres à partir de la page manga
@override
Future<List<SChapter>> getChapters(String url) async {
  print('✅ getChapters called with URL: $url');

  try {
    final slug = url.split('/').last;
    print('🔍 Extracted slug: $slug');

    final res = await request(
      '$baseUrl/ajax/chapter-archive?novelId=$slug',
      headers: {"X-Requested-With": "XMLHttpRequest"},
    );

    print('📥 AJAX response length: ${res.length}');
    final doc = parseHtml(res);

    final elements = doc.querySelectorAll('ul.list-chapter li a');

    if (elements.isEmpty) {
      print('⚠️ Aucun chapitre trouvé (ul.list-chapter li a)');
      return [];
    }

    return elements.reversed.map((element) {
      final chapterUrl = element.attributes['href'] ?? '';
      final chapterName = element.text.trim();
      return SChapter(
        name: chapterName,
        url: chapterUrl.startsWith('http') ? chapterUrl : '$baseUrl$chapterUrl',
      );
    }).toList();
  } catch (e, stack) {
    print('🔥 Erreur dans getChapters: $e\n$stack');
    return [];
  }
}


  @override
  Future<String> cleanHtmlContent(String html) async => html;

  @override
  Future<List<MVideo>> getVideoList(String url) async => [];

  @override
  List<dynamic> getFilterList() => [];

  @override
  List<dynamic> getSourcePreferences() => [];
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

NovelBinSource main(MSource source) => NovelBinSource(source: source);
