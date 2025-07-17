// lightnovel.json
{
  "sourceName": "MassNovel",
  "iconUrl": "https://massnovel.fr/wp-content/uploads/2021/09/cropped-logo-1-192x192.png",
  "author": {
    "name": "Plante",
    "icon": ""
  },
  "version": "1.0.0",
  "language": "French",
  "baseUrl": "https://massnovel.fr",
  "searchBaseUrl": "https://massnovel.fr/?s=%s&post_type=wp-manga",
  "scriptUrl": "https://raw.githubusercontent.com/votre-repo/main/massnovel.js",
  "asyncJS": false
}

// massnovel.js

// Nettoie le texte HTML récupéré
function cleanText(text) {
  return text
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, ' ')
    .replace(/&#8217;/g, "'")
    .trim();
}

// Parse les résultats de recherche
function searchResults(html) {
  const results = [];
  // Chaque item dans <div class="page-item-detail">
  const itemRegex = /<div class="page-item-detail[\s\S]*?<\/div>/g;
  const items = html.match(itemRegex) || [];

  items.forEach(itemHtml => {
    const linkMatch = itemHtml.match(/<h3 class="h4 manga-title">\s*<a href="([^"]+)">([^<]+)<\/a>/);
    const imgMatch = itemHtml.match(/<img[^>]*class="attachment-manga_thumbnail"[^>]*src="([^"]+)"/);
    if (linkMatch) {
      results.push({
        title: cleanText(linkMatch[2]),
        image: imgMatch ? imgMatch[1] : '',
        href: linkMatch[1]
      });
    }
  });
  return results;
}

// Récupère les détails du novel: synopsis, auteur, genres
function extractDetails(html) {
  const descriptionMatch = html.match(/<div class="summary__content">([\s\S]*?)<\/div>/);
  const authorMatch = html.match(/<span class="author-content">[\s\S]*?<a[^>]*>([^<]+)<\/a>/);
  const genresMatch = html.match(/<div class="genres-content">([\s\S]*?)<\/div>/);

  let genres = '';
  if (genresMatch) {
    const genreLinks = genresMatch[1].match(/<a[^>]*>([^<]+)<\/a>/g) || [];
    genres = genreLinks.map(g => g.replace(/<[^>]+>/g, '').trim()).join(', ');
  }

  return {
    description: descriptionMatch ? cleanText(descriptionMatch[1]) : '',
    author: authorMatch ? cleanText(authorMatch[1]) : '',
    genres
  };
}

// Liste tous les chapitres disponibles
function extractEpisodes(html) {
  const chapters = [];
  // Chapitres sous <li class="wp-manga-chapter">
  const chapRegex = /<li[^>]*class="wp-manga-chapter[^"]*"[^>]*>[\s\S]*?<a href="([^"]+)">([^<]+)<\/a>/g;
  let match;
  while ((match = chapRegex.exec(html)) !== null) {
    const numMatch = match[2].match(/(\d+)/);
    chapters.push({
      href: match[1],
      number: numMatch ? numMatch[1] : match[2]
    });
  }
  // Inverse l'ordre pour du plus ancien au plus récent
  return chapters.reverse();
}

// Récupère le contenu textuel du chapitre
function extractStreamUrl(html) {
  const contentMatch = html.match(/<div class="reading-content[\s\S]*?">([\s\S]*?)<\/div>/);
  return contentMatch ? cleanText(contentMatch[1]) : '';
}
