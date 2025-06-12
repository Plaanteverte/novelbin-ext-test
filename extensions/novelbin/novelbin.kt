import eu.kanade.tachiyomi.source.model.*
import eu.kanade.tachiyomi.source.online.ParsedHttpSource
import okhttp3.Headers
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element

class NovelBin : ParsedHttpSource() {
    override val name = "NovelBin"
    override val baseUrl = "https://novelbin.com"
    override val lang = "en"
    override val supportsLatest = false

    private val ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
    override fun headersBuilder(): Headers.Builder = super.headersBuilder().add("User-Agent", ua)

    // Popular novels list page (first page)
    override fun popularMangaRequest(page: Int) = GET("$baseUrl/b", headers)

    override fun popularMangaSelector() = ".book-img-text li"

    override fun popularMangaFromElement(element: Element) = SManga.create().apply {
        val a = element.selectFirst("a")!!
        setUrlWithoutDomain(a.attr("href"))
        title = a.attr("title")
        thumbnail_url = element.selectFirst("img")?.attr("data-src")
    }

    override fun popularMangaNextPageSelector() = null // Pas de pagination pour l'instant

    override fun fetchMangaDetails(manga: SManga) = manga.apply {
        // Ici tu peux récupérer plus de détails si tu veux (genre, auteur, synopsis...)
        // Pour l'instant on ne fait rien (nop)
    }

    // Liste des chapitres du novel
    override fun chapterListSelector() = ".chapter-list a"

    override fun chapterFromElement(element: Element) = SChapter.create().apply {
        setUrlWithoutDomain(element.attr("href"))
        name = element.text().trim()
    }

    // Récupérer la liste des pages d’un chapitre
    // Ici on parse tous les paragraphes <p> dans #chr-content, chacun représentant une "page"
    override fun pageListParse(document: Document): List<Page> {
        val paragraphs = document.select("#chr-content p")
        return paragraphs.mapIndexed { index, element ->
            // Crée une page fictive avec un url custom (car pas d'images)
            // L’url doit être unique sinon Mangayomi ne gère pas les pages
            Page(index, document.location(), element.text())
        }
    }

    // Comme on a pas d’image, on retourne une chaîne vide
    override fun imageUrlParse(document: Document) = ""

    // Récupérer le texte complet du chapitre (chapitreDetailsParse n’est pas souvent utilisé dans Mangayomi 0.5+)
    override fun chapterDetailsParse(document: Document): String {
        return document.select("#chr-content p")
            .joinToString("\n\n") { it.text() }
    }
}
