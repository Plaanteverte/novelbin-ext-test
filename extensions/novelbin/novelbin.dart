import 'package:mangayomi/bridge_lib.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart' show parse;

class NovelBinSource extends MProvider {
  NovelBinSource({required this.source});
  final MSource source;
  final Client client = Client();

  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Referer': source.baseUrl,
  };

  @override
  bool get supportsLatest => false;

  @override
  Future<MPages> getPopular(int page) async {
    final url = "${source.baseUrl}/sort/top-hot-novel?page=$page";
    final res = (await client.get(Uri.parse(url), headers: headers)).body;

    final titles = xpath(res, '//h3[contains(@class, "novel")]/a/text()');
    final links = xpath(res, '//h3[contains(@class, "novel")]/a/@href');
    final covers = xpath(res, '//img[contains(@class, "cover")]/@data-src');

    List<MManga> mangaList = [];

    for (var i = 0; i < titles.length; i++) {
      MManga manga = MManga();
      manga.name = titles[i];
      manga.link = links[i].startsWith("http")
          ? links[i]
          : '${source.baseUrl}${links[i]}';
      manga.imageUrl = i < covers.length ? covers[i] : "";
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    throw Exception("DEBUG: getDetail appelé avec URL = $url");

    final res = (await client.get(Uri.parse(url), headers: headers)).body;

    final title = xpath(res, '//meta[@property="og:title"]/@content').firstOrNull ?? "No Title";
    final description = xpath(res, '//meta[@name="description"]/@content').firstOrNull ?? "";
    final imageUrl = xpath(res, '//meta[@property="og:image"]/@content').firstOrNull ?? "";
    final author = xpath(res, '//meta[@property="og:novel:author"]/@content').firstOrNull ?? "Unknown";
    final genresString = xpath(res, '//meta[@property="og:novel:genre"]/@content').firstOrNull ?? "";
    final genres = genresString.split(',').map((e) => e.trim()).toList();

    MManga manga = MManga();
    manga.name = title;
    manga.description = description;
    manga.imageUrl = imageUrl;
    manga.author = author;
    manga.genre = genres;
    manga.link = url; // lien absolu

    return manga;
  }

  @override
  Future<List<SChapter>> getChapters(String url) async {
    throw Exception("DEBUG: getChapters appelé avec URL = $url");

    final res = (await client.get(Uri.parse(url), headers: headers)).body;

    final chapterNames = xpath(res, '//ul[@id="chapterList"]/li/a/text()');
    final chapterLinks = xpath(res, '//ul[@id="chapterList"]/li/a/@href');

    List<SChapter> chapters = [];

    for (var i = 0; i < chapterNames.length; i++) {
      chapters.add(SChapter(
        name: chapterNames[i],
        url: chapterLinks[i].startsWith("http")
            ? chapterLinks[i]
            : '${source.baseUrl}${chapterLinks[i]}',
      ));
    }

    return chapters;
  }

  @override
  Future<String> getHtmlContent(String name, String url) async {
    final res = (await client.get(Uri.parse(url), headers: headers)).body;
    final contentParts = xpath(res, '//div[@id="chr-content"]/p');
    final html = contentParts.map((e) => "<p>${e}</p>").join('\n');
    return '<div>$html</div>';
  }

  @override
  Future<String> cleanHtmlContent(String html) async => html;
  @override
  Future<List<MVideo>> getVideoList(String url) async => [];
  @override
  List getFilterList() => [];
  @override
  List getSourcePreferences() => [];
}

NovelBinSource main(MSource source) => NovelBinSource(source: source);

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : this[0];
}
