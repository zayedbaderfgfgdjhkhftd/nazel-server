// Generates text PDF fixtures with Chromium (real Arabic shaping, embedded
// fonts and a text layer), like PDFs users get from browsers/office apps.
//
// Usage: node tool/fixtures/make_pdfs.js [outDir]
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const outDir = path.resolve(process.argv[2] || 'test/fixtures');
const fontDir = path.resolve(__dirname, '../../assets/fonts');

const css = `
@font-face { font-family: Readex; src: url('file://${fontDir}/ReadexPro-Regular.ttf'); }
@page { size: A4; margin: 20mm; }
body { font-family: Readex, 'Noto Naskh Arabic', sans-serif; font-size: 14pt; line-height: 1.7; }
h1 { font-size: 22pt; }
.page { page-break-after: always; }
.page:last-child { page-break-after: auto; }
`;

function doc(dir, bodies) {
  return `<!doctype html><html dir="${dir}"><head><meta charset="utf-8"><title>Satr fixture</title>
<style>${css}</style></head><body>${bodies.map((b) => `<div class="page">${b}</div>`).join('')}</body></html>`;
}

const AR = 'سطر تطبيق عربي لمعالجة ملفات على جهازك. الملفات لا تغادر الجهاز أبدا.';
const EN = 'Satr keeps your files on your device. Merge, split and compress documents offline.';

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const jobs = [
    ['one_page.pdf', 'ltr', [`<h1>One page</h1><p>${EN}</p>`]],
    ['fifty_pages.pdf', 'ltr', Array.from({ length: 50 }, (_, i) => `<h1>Page ${i + 1}</h1><p>${EN}</p>`)],
    ['arabic_text.pdf', 'rtl', [`<h1>مستند عربي</h1><p>${AR}</p><p>يعمل بدون إنترنت بعد أول زيارة.</p>`]],
    ['english_text.pdf', 'ltr', [`<h1>English document</h1><p>${EN}</p>`]],
    ['mixed_text.pdf', 'rtl', [`<h1>مستند مختلط Mixed</h1><p>${AR}</p><p dir="ltr">${EN}</p><p>رقم الطلب 2024 في ملف PDF.</p>`]],
    ['three_pages.pdf', 'ltr', [1, 2, 3].map((i) => `<h1>Page ${i}</h1><p>${EN}</p>`)],
  ];
  for (const [name, dir, bodies] of jobs) {
    await page.setContent(doc(dir, bodies));
    await page.evaluate(() => document.fonts.ready);
    await page.pdf({ path: path.join(outDir, name), format: 'A4', printBackground: true });
    console.log('wrote', name);
  }
  await browser.close();
})();
