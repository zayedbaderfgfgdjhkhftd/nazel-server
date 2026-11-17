// Renders known Arabic / English / mixed text to PNG images with Chromium
// (correct Arabic shaping via HarfBuzz). Used to build OCR test fixtures.
//
// Usage: node tool/fixtures/render_text_images.js <outDir>
//
// Requires the `playwright` package with a Chromium build available.
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const outDir = path.resolve(process.argv[2] || 'test/fixtures');
const fontDir = path.resolve(__dirname, '../../assets/fonts');

// Keep in sync with test/fixtures/ocr_expected.json
const AR_LINES = [
  'سطر تطبيق عربي لمعالجة ملفات على جهازك',
  'الملفات لا تغادر الجهاز أبدا',
  'يعمل بدون إنترنت بعد أول زيارة',
  'استخراج النص من الصور باللغة العربية',
];
const EN_LINES = [
  'Satr keeps your files on your device',
  'Merge split and compress documents offline',
];

function page(lines, { dir, font, size }) {
  return `<!doctype html><html dir="${dir}"><head><meta charset="utf-8">
<style>
@font-face { font-family: Readex; src: url('file://${fontDir}/ReadexPro-Regular.ttf'); }
body { margin: 0; background: #fff; color: #111; }
.p { padding: 48px 56px; font-family: ${font}; font-size: ${size}px; line-height: 1.8; width: 1100px; }
</style></head><body><div class="p">${lines.map((l) => `<div>${l}</div>`).join('')}</div></body></html>`;
}

(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ deviceScaleFactor: 1 });
  const pg = await ctx.newPage();
  const jobs = [
    ['ocr_arabic_naskh.png', AR_LINES, { dir: 'rtl', font: "'Noto Naskh Arabic', serif", size: 40 }],
    ['ocr_arabic_readex.png', AR_LINES, { dir: 'rtl', font: 'Readex, sans-serif', size: 40 }],
    ['ocr_english.png', EN_LINES, { dir: 'ltr', font: "'DejaVu Serif', serif", size: 36 }],
  ];
  for (const [name, lines, opts] of jobs) {
    await pg.setContent(page(lines, opts));
    await pg.evaluate(() => document.fonts.ready);
    const el = await pg.$('.p');
    await el.screenshot({ path: path.join(outDir, name) });
    console.log('wrote', name);
  }
  await browser.close();
})();
