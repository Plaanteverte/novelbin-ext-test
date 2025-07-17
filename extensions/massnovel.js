// massnovel.sora.js
// Extension Sora pour massnovel.fr

// --- Exposition des handlers pour Sora ---
window.searchResults   = searchResults;
window.extractDetails  = extractDetails;
window.extractChapters = extractChapters;
window.extractText     = extractText;

const CORS_PROXY = 'https://api.allorigins.win/raw?url='; // pour contourner CORS

async function searchResults(keyword) {
    try {
        const encoded = encodeURIComponent(keyword);
        const targetUrl = `https://massnovel.fr/?s=${encoded}&post_type%5B%5D=wp-manga`;
        const response = await soraFetch(CORS_PROXY + encodeURIComponent(targetUrl));
        const html = await response.text();

        const results = [];
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
        const response = await soraFetch(CORS_PROXY + encodeURIComponent(url));
        const html = await response.text();

        const titleMatch = html.match(/<div class="post-title">\s*<h1>([\s\S]*?)<\/h1>/);
        const title = titleMatch ? titleMatch[1].trim() : 'Unknown';

        const authorMatches = [...html.matchAll(/<li class="author">[\s\S]*?<a[^>]+>([^<]+)<\/a>/g)];
        const authors = authorMatches.length
            ? authorMatches.map(m => m[1].trim()).join(', ')
            : 'Unknown';

        const coverMatch = html.match(/<div class="summary_image">[\s\S]*?<img[^>]+src="([^"]+)"/);
        const cover = coverMatch ? coverMatch[1].trim() : '';

        const statusMatch = html.match(/<li class="status">[\s\S]*?<div class="summary-content">\s*([^<]+)<\/div>/);
        const status = statusMatch ? statusMatch[1].trim() : 'Unknown';

        const descMatch = html.match(/<div class="description-summary">([\s\S]*?)<\/div>/);
        const description = descMatch
            ? descMatch[1].replace(/<[^>]+>/g, '').trim()
            : 'No description available';

        const chapters = [];
        const listBlockMatch = html.match(/<ul class="main">([\s\S]*?)<\/ul>/);
        if (listBlockMatch) {
            const liRegex = /<li class="wp-manga-chapter">[\s\S]*?<a href="([^"]+)">([\s\S]*?)<\/a>/g;
            let liMatch;
            while ((liMatch = liRegex.exec(listBlockMatch[1])) !== null) {
                chapters.push({ href: liMatch[1].trim(), title: liMatch[2].trim() });
            }
        }

        return JSON.stringify([{
            title,
            author: authors,
            cover,
            status,
            description,
            chaptersList: chapters
        }]);
    } catch (e) {
        console.error('extractDetails error:', e);
        return JSON.stringify([{ title: 'Error', author: 'Unknown', cover: '', status: '', description: 'Error loading details', chaptersList: [] }]);
    }
}

async function extractChapters(url) {
    // réutilise extractDetails
    const details = JSON.parse(await extractDetails(url))[0];
    return JSON.stringify(details.chaptersList || []);
}

async function extractText(url) {
    try {
        const response = await soraFetch(CORS_PROXY + encodeURIComponent(url));
        const html = await response.text();
        const contentMatch = html.match(/<div class="text-left reader-content">([\s\S]*?)<\/div>/);
        let content = contentMatch ? contentMatch[1] : '';
        content = content.replace(/<script[\s\S]*?>[\s\S]*?<\/script>/g, '')
                         .replace(/<[^>]+>/g, '')
                         .trim();
        return content;
    } catch (e) {
        console.error('extractText error:', e);
        return 'Error extracting text';
    }
}

// Simplified fetch without fetchv2 to ensure Response methods
async function soraFetch(url, options = { headers: {}, method: 'GET', body: null }) {
    const response = await fetch(url, options);
    if (!response.ok) {
        throw new Error(`Network response was not ok: ${response.status}`);
    }
    return response;
}
