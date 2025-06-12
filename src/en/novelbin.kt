import eu.kanade.tachiyomi.source.model.*
import eu.kanade.tachiyomi.source.online.ParsedHttpSource
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import okhttp3.Headers

class NovelBin : ParsedHttpSource() {
    override val name = "NovelBin"
    override val baseUrl = "https://novelbin.com"
    override val lang = "en"
    override val supportsLatest = false

    private val ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
    override fun headersBuilder() = super.headersBuilder().add("User-Agent", ua)

    override fun popularMangaRequest(page: Int) = GET("$baseUrl/b", headers)
    override fun popularMangaSelector() = ".book-img-text li"
    override fun popularMangaFromElement(e: Element) = SManga.create().apply {
        val a = e.selectFirst("a")!!
        setUrlWithoutDomain(a.attr("href"))
        title = a.attr("title")
        thumbnail_url = e.selectFirst("img")?.attr("data-src")
    }
    override fun popularMangaNextPageSelector() = null

    override fun fetchMangaDetails(manga: SManga) = manga.apply {
        // nop
    }

    override fun chapterListSelector() = ".chapter-list a"
    override fun chapterFromElement(e: Element) = SChapter.create().apply {
        setUrlWithoutDomain(e.attr("href"))
        name = e.text().trim()
    }

    override fun pageListParse(document: Document) = emptyList<Page>()
    override fun imageUrlParse(document: Document) = ""

    override fun chapterDetailsParse(document: Document): String {
        return document.select("#chr-content p")
            .joinToString("\n\n") { it.text() }
    }
}
