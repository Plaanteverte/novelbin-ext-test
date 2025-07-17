/**
 * massnovel.sora.js
 * Extension Sora pour massnovel.fr
 */

async function searchResults(keyword) {
    try {
        const encoded = encodeURIComponent(keyword);
        const url = `https://massnovel.fr/?s=${encoded}&post_type%5B%5D=wp-manga`;
        const response = await soraFetch(url);
        const html = await response.text();

        const results = [];
        // Chaque item de résultat est dans .c-tabs-item__content
        const itemRegex = /<div class="c-tabs-item__content">([\s\S]*?)<\/div>\s*<\/div>/g;
        let itemMatch;
        while ((itemMatch = itemRegex.exec(html)) !== null) {
            const block = itemMatch[1];
            const hrefMatch = block.match(/<h3 class="h4">\s*<a href="([^"]+)"/);
            const titleMatch = block.match(/<h3 class="h4">[\s\S]*?<a [^>]+>([^<]+)<\/a>/);
            const imgMatch   = block.match(/<img[^>]+data-src="([^"]+)"/);

            if (hrefMatch && titleMatch) {
                results.push({
                    title: titleMatch[1].trim(),
                    image: imgMatch ? imgMatch[1].trim() : '',
                    href : hrefMatch[1].trim()
                });
            }
        }

        return JSON.stringify(results);
    } catch (e) {
        console.error('searchResults error:', e);
        return JSON.stringify([{ title: 'Error', image: '', href: '' }]);
    }
}

async function extractDetails(url) {
    try {
        const response = await soraFetch(url);
        const html = await response.text();

        // Titre
        const titleMatch = html.match(/<div class="post-title">\s*<h1>([\s\S]*?)<\/h1>/);
        const title = titleMatch ? titleMatch[1].trim() : 'Unknown';

        // Auteur(s)
        const authorMatches = [...html.matchAll(/<li class="author">[\s\S]*?<a[^>]+>([^<]+)<\/a>/g)];
        const authors = authorMatches.length
            ? authorMatches.map(m => m[1].trim()).join(', ')
            : 'Unknown';

        // Couverture
        const coverMatch = html.match(/<div class="summary_image">[\s\S]*?<img[^>]+src="([^"]+)"/);
        const cover = coverMatch ? coverMatch[1].trim() : '';

        // Statut
        const statusMatch = html.match(/<li class="status">[\s\S]*?<div class="summary-content">\s*([^<]+)<\/div>/);
        const status = statusMatch ? statusMatch[1].trim() : 'Unknown';

        // Description
        const descMatch = html.match(/<div class="description-summary">([\s\S]*?)<\/div>/);
        const description = descMatch
            ? descMatch[1].replace(/<[^>]+>/g,'').trim()
            : 'No description available';

        // Liste des chapitres (URLs + titres)
        const chapters = [];
        const chapRegex = /<ul class="main">[\s\S]*?(<li class="wp-manga-chapter">[\s\S]*?<\/li>)[\s\S]*?<\/ul>/;
        const listBlockMatch = html.match(chapRegex);
        if (listBlockMatch) {
            const liRegex = /<li class="wp-manga-chapter">[\s\S]*?<a href="([^"]+)">([\s\S]*?)<\/a>/g;
            let liMatch;
            while ((liMatch = liRegex.exec(listBlockMatch[0])) !== null) {
                chapters.push({
                    href: liMatch[1].trim(),
                    title: liMatch[2].trim()
                });
            }
        }

        const transformed = [{
            title,
            author     : authors,
            cover,
            status,
            description,
            chaptersList: chapters
        }];

        return JSON.stringify(transformed);
    } catch (e) {
        console.error('extractDetails error:', e);
        return JSON.stringify([{
            title: 'Error',
            author: 'Unknown',
            cover: '',
            status: '',
            description: 'Error loading details',
            chaptersList: []
        }]);
    }
}

async function extractChapters(url) {
    // Sur massnovel, on récupère via extractDetails la liste complète,
    // mais on peut la renvoyer ici si Sora l’attend séparément.
    // On réutilise extractDetails pour simplifier :
    const detailsJSON = await extractDetails(url);
    const details = JSON.parse(detailsJSON)[0];
    return JSON.stringify(details.chaptersList || []);
}

async function extractText(url) {
    try {
        const response = await soraFetch(url);
        const html = await response.text();

        // Le contenu du chapitre
        const contentMatch = html.match(/<div class="text-left reader-content">([\s\S]*?)<\/div>/);
        let content = contentMatch ? contentMatch[1] : '';
        // On enlève les balises inutiles
        content = content.replace(/<script[\s\S]*?>[\s\S]*?<\/script>/g, '')
                         .replace(/<[^>]+>/g, '')
                         .trim();

        return content;
    } catch (e) {
        console.error('extractText error:', e);
        return 'Error extracting text';
    }
}

async function soraFetch(url, options = { headers: {}, method: 'GET', body: null }) {
    try {
        return await fetchv2(url, options.headers, options.method, options.body);
    } catch {
        return fetch(url, options);
    }
}

// Pour tester :
// searchResults('mushoku').then(console.log);
// extractDetails('https://massnovel.fr/mushoku-tensei/').then(console.log);
// extractChapters('https://massnovel.fr/mushoku-tensei/').then(console.log);
// extractText('https://massnovel.fr/mushoku-tensei/chapter-1/').then(console.log);

export { searchResults, extractDetails, extractChapters, extractText };
