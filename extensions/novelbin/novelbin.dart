import 'package:mangayomi/bridge_lib.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart' show parse;

class NovelBinSource extends MProvider {
  NovelBinSource({required this.source});

  final MSource source;
  final Client client = Client();

  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0',
        'Referer': source.baseUrl,
      };

  @override
  bool get supportsLatest => false;

  @override
  Future<MPages> getPopular(int page) async {
    final url = "${source.baseUrl}/sort/top-hot-novel?page=$page";
    final res = (await client.get(Uri.parse(url), headers: headers)).body;

    final titles =
        xpath(res, '//h3[contains(@class, "novel") and contains(@class, "title")]/a/text()');
    final links =
        xpath(res, '//h3[contains(@class, "novel") and contains(@class, "title")]/a/@href');
    final covers =
        xpath(res, '//img[contains(@class, "cover") and contains(@class, "lazy")]/@data-src');

    List<MManga> mangaList = [];

    for (var i = 0; i < titles.length; i++) {
      MManga manga = MManga();
      manga.name = titles[i];
      manga.link = links[i];
      manga.imageUrl = covers.length > i ? covers[i] : "";
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    // NovelBin ne supporte pas les latest updates
    return MPages([], false);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filters) async {
    final url = "${source.baseUrl}/search?keyword=${Uri.encodeComponent(query)}&page=$page";
    final res = (await client.get(Uri.parse(url), headers: headers)).body;

    final titles = xpath(res, '//div[contains(@class,"book-info")]/a/text()');
    final links = xpath(res, '//div[contains(@class,"book-info")]/a/@href');
    final covers = xpath(res, '//div[contains(@class,"book-img")]/img/@data-src');

    List<MManga> mangaList = [];

    for (var i = 0; i < titles.length; i++) {
      MManga manga = MManga();
      manga.name = titles[i];
      manga.link = links[i];
      manga.imageUrl = covers.length > i ? covers[i] : "";
      mangaList.add(manga);
    }

    return MPages(mangaList, true);
  }

  @override
  Future<MManga> getDetail(String url) async {
    String fullUrl;
    if (url.startsWith("http")) {
      fullUrl = url;
    } else if (url.startsWith("/")) {
      fullUrl = source.baseUrl + url;
    } else {
      fullUrl = source.baseUrl + "/" + url;
    }

    final res = (await client.get(Uri.parse(fullUrl), headers: headers)).body;

    final titleList = xpath(res, '//meta[@property="og:title"]/@content');
    final descriptionList = xpath(res, '//meta[@name="description"]/@content');
    final imageUrlList = xpath(res, '//meta[@property="og:image"]/@content');
    final authorList = xpath(res, '//meta[@property="og:novel:author"]/@content');
    final genresList = xpath(res, '//meta[@property="og:novel:genre"]/@content');

    final title = titleList.isNotEmpty ? titleList[0] : "No Title";
    final description = descriptionList.isNotEmpty ? descriptionList[0] : "";
    final imageUrl = imageUrlList.isNotEmpty ? imageUrlList[0] : "";
    final author = authorList.isNotEmpty ? authorList[0] : "Unknown";
    final genresString = genresList.isNotEmpty ? genresList[0] : "";
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

  String getSlugFromUrl(String url) {
    Uri uri = Uri.parse(url);
    List<String> parts = uri.pathSegments;
    if (parts.length >= 2 && parts[0] == 'b') {
      return parts[1];
    }
    return '';
  }

  @override
  Future<List<SChapter>> getChapters(String url) async {
    final slug = getSlugFromUrl(url);
    if (slug.isEmpty) {
      throw Exception("Impossible d'extraire le slug du novel");
    }

    final ajaxUrl = '${source.baseUrl}/ajax/chapter-archive?novelId=$slug';

    final response = await client.get(Uri.parse(ajaxUrl), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erreur HTTP ${response.statusCode}');
    }

    final document = parse(response.body);
    final chapterElements = document.querySelectorAll('ul.list-chapter li a');

    List<SChapter> chapters = [];
    for (var el in chapterElements) {
      final href = el.attributes['href'] ?? '';
      final title = el.attributes['title'] ?? el.text.trim();
      chapters.add(SChapter(
        name: title,
        url: href.startsWith('http') ? href : '${source.baseUrl}$href',
      ));
    }

    return chapters;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    final fullUrl = source.baseUrl + url;
    final res = (await client.get(Uri.parse(fullUrl), headers: headers)).body;

    final pages = xpath(res, '//div[@id="chr-content"]/p/text()');

    return pages;
  }

  @override
  Future<String> getHtmlContent(String name, String url) async {
    final fullUrl = source.baseUrl + url;
    final res = (await client.get(Uri.parse(fullUrl), headers: headers)).body;

    final contentParts = xpath(res, '//div[@id="chr-content"]/p');
    final contentHtml = contentParts.map((p) => "<p>${p}</p>").join('\n');

    return '<div>$contentHtml</div>';
  }

  @override
  Future<String> cleanHtmlContent(String html) async {
    return html;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    return [];
  }

  @override
  List<dynamic> getFilterList() => [];

  @override
  List<dynamic> getSourcePreferences() => [];
}

NovelBinSource main(MSource source) => NovelBinSource(source: source);
