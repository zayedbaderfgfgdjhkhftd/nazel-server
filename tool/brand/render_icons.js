// Renders the brand SVGs into the PNG sizes Android / Google Play need.
//
// Usage: node tool/brand/render_icons.js
// Requires the `playwright` package with Chromium.
const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '../..');
const brand = path.join(root, 'assets/brand');
const res = path.join(root, 'android/app/src/main/res');

const LEGACY = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
const ADAPTIVE = { mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432 };

async function render(page, svgFile, size, outFile, { round = false } = {}) {
  const svg = fs.readFileSync(path.join(brand, svgFile), 'utf8');
  const clip = round ? 'border-radius:50%;overflow:hidden;' : '';
  await page.setViewportSize({ width: size, height: size });
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="width:${size}px;height:${size}px;${clip}">${svg.replace('<svg ', `<svg style="width:${size}px;height:${size}px;display:block" `)}</div>
  </body></html>`);
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  await page.screenshot({ path: outFile, omitBackground: true, clip: { x: 0, y: 0, width: size, height: size } });
}

(async () => {
  const browser = await chromium.launch();
  const page = await (await browser.newContext({ deviceScaleFactor: 1 })).newPage();
  for (const [d, s] of Object.entries(LEGACY)) {
    await render(page, 'satr-icon.svg', s, path.join(res, `mipmap-${d}/ic_launcher.png`));
    await render(page, 'satr-icon.svg', s, path.join(res, `mipmap-${d}/ic_launcher_round.png`), { round: true });
  }
  for (const [d, s] of Object.entries(ADAPTIVE)) {
    await render(page, 'satr-icon-foreground.svg', s, path.join(res, `mipmap-${d}/ic_launcher_foreground.png`));
    await render(page, 'satr-icon-monochrome.svg', s, path.join(res, `mipmap-${d}/ic_launcher_monochrome.png`));
  }
  await render(page, 'satr-icon.svg', 512, path.join(brand, 'play-store-512.png'));
  await render(page, 'satr-icon.svg', 192, path.join(brand, 'icon-192.png'));
  await browser.close();
  console.log('icons rendered');
})();
