// Renders store/feature_graphic.png (1024x500) for Google Play.
// Usage: node tool/brand/render_feature_graphic.js
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const fonts = path.join(root, 'assets/fonts');
const icon = fs.readFileSync(path.join(root, 'assets/brand/satr-icon.svg'), 'utf8');

const html = `<!doctype html><html dir="rtl"><head><meta charset="utf-8"><style>
@font-face { font-family: Readex; src: url('file://${fonts}/ReadexPro-Bold.ttf'); font-weight: 700; }
@font-face { font-family: Readex; src: url('file://${fonts}/ReadexPro-Regular.ttf'); font-weight: 400; }
html, body { margin: 0; }
.wrap { width: 1024px; height: 500px; background: #121417; color: #F3F4F6; display: flex; align-items: center;
  gap: 56px; padding: 0 80px; box-sizing: border-box; font-family: Readex, sans-serif; }
.icon svg { width: 220px; height: 220px; display: block; }
h1 { font-size: 96px; margin: 0; line-height: 1.2; font-weight: 700; }
.line { display: inline-block; font-size: 38px; line-height: 1.5; font-weight: 700;
  background: #FFD23F; color: #121417; padding: 4px 18px 8px; border-radius: 12px; }
p { font-size: 26px; color: #A1A8B3; margin: 22px 0 0; }
.latin { font-size: 28px; color: #A1A8B3; margin-top: 4px; direction: ltr; text-align: right; }
</style></head><body><div class="wrap">
  <div class="icon">${icon}</div>
  <div>
    <h1>سَطر</h1>
    <div class="latin">Satr PDF</div>
    <div style="margin-top:20px"><div class="line">أدوات PDF بالعربي</div></div>
    <p>تعمل على جهازك · بدون إنترنت · بدون رفع للملفات</p>
  </div>
</div></body></html>`;

(async () => {
  const browser = await chromium.launch();
  const page = await (await browser.newContext({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 })).newPage();
  await page.setContent(html);
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.join(root, 'store'), { recursive: true });
  await page.screenshot({ path: path.join(root, 'store/feature_graphic.png'), clip: { x: 0, y: 0, width: 1024, height: 500 } });
  await browser.close();
  console.log('store/feature_graphic.png');
})();
