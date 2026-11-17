"""Generates image and special PDF fixtures for the tests.

Run AFTER tool/fixtures/make_pdfs.js and render_text_images.js:
    python3 tool/fixtures/make_fixtures.py [outDir]

Needs: Pillow, pillow-heif (HEIC fixture only) and the `qpdf` CLI
(encrypted/rotated fixtures). These are fixture-generation tools only and are
NOT part of the app.
"""
import io
import os
import random
import subprocess
import sys

from PIL import Image, ImageDraw

OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else 'test/fixtures')


def photo(w, h, seed=1):
    """A photo-like image (smooth gradients + noise) that JPEG compresses
    poorly at high quality, so compression tests are meaningful."""
    rnd = random.Random(seed)
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            r = int(128 + 100 * ((x / w) - 0.5) + rnd.randint(-40, 40))
            g = int(128 + 100 * ((y / h) - 0.5) + rnd.randint(-40, 40))
            b = int(160 + rnd.randint(-60, 60))
            px[x, y] = (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    d = ImageDraw.Draw(img)
    d.ellipse([w * 0.2, h * 0.2, w * 0.6, h * 0.7], fill=(230, 180, 40))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)

    # JPEG stored landscape with EXIF orientation 6 (display rotated 90 CW ->
    # upright portrait 300x400).
    img = photo(400, 300, 2)
    exif = Image.Exif()
    exif[0x0112] = 6
    img.save(os.path.join(OUT, 'photo_exif6.jpg'), 'JPEG', quality=90, exif=exif.tobytes())

    photo(640, 480, 3).save(os.path.join(OUT, 'photo.jpg'), 'JPEG', quality=90)

    rgba = Image.new('RGBA', (300, 200), (0, 0, 0, 0))
    ImageDraw.Draw(rgba).rectangle([30, 30, 270, 170], fill=(20, 90, 200, 255))
    rgba.save(os.path.join(OUT, 'alpha.png'))

    photo(320, 240, 4).save(os.path.join(OUT, 'photo.webp'), 'WEBP', quality=85)

    try:
        import pillow_heif
        pillow_heif.register_heif_opener()
        photo(320, 240, 5).save(os.path.join(OUT, 'photo.heic'), 'HEIF', quality=80)
    except Exception as e:  # pragma: no cover
        print('HEIC skipped:', e)

    # Signature-like photo: dark strokes on an off-white background.
    sig = Image.new('RGB', (500, 200), (245, 244, 240))
    d = ImageDraw.Draw(sig)
    d.line([(40, 150), (120, 60), (200, 140), (280, 50), (420, 120)], fill=(20, 30, 90), width=8)
    sig.save(os.path.join(OUT, 'signature_photo.jpg'), 'JPEG', quality=92)

    # Large photo for the PDF-with-images fixture.
    big = photo(2400, 1800, 6)
    big_path = os.path.join(OUT, '_big_photo.jpg')
    big.save(big_path, 'JPEG', quality=95, dpi=(300, 300))
    pdf_bytes = io.BytesIO()
    a4 = (595, 842)
    page = Image.open(big_path)
    # Pillow writes the JPEG stream as-is (DCTDecode) into the PDF.
    page.save(pdf_bytes, 'PDF', resolution=300.0)
    with open(os.path.join(OUT, 'with_images.pdf'), 'wb') as f:
        f.write(pdf_bytes.getvalue())
    os.remove(big_path)

    # Scanned (image-only) PDF from the Arabic OCR image.
    scan = Image.open(os.path.join(OUT, 'ocr_arabic_naskh.png')).convert('RGB')
    scan.save(os.path.join(OUT, 'scanned.pdf'), 'PDF', resolution=150.0)

    one = os.path.join(OUT, 'one_page.pdf')
    # Encrypted with a user password (qpdf, AES-256).
    subprocess.run(['qpdf', '--encrypt', '1234', '1234', '256', '--', one,
                    os.path.join(OUT, 'encrypted.pdf')], check=True)
    # Rotated: page 1 has /Rotate 90.
    subprocess.run(['qpdf', one, '--rotate=+90:1', os.path.join(OUT, 'rotated.pdf')], check=True)

    # Corrupt: the first 40% of a valid file followed by junk.
    data = open(one, 'rb').read()
    with open(os.path.join(OUT, 'corrupt.pdf'), 'wb') as f:
        f.write(data[: int(len(data) * 0.4)] + b'\x00garbage' * 50)

    # Not a PDF despite the extension.
    with open(os.path.join(OUT, 'fake.pdf'), 'wb') as f:
        f.write(b'This is plain text, not a PDF.\n' * 20)

    # Content stream that leaves the CTM scaled (no q/Q). Stamps added later
    # must not inherit this scale.
    content = b'2 0 0 2 0 0 cm 0 0 1 rg 10 10 50 50 re f'
    objs = [
        b'<< /Type /Catalog /Pages 2 0 R >>',
        b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 400] /Contents 4 0 R /Resources << >> >>',
        b'<< /Length %d >>\nstream\n' % len(content) + content + b'\nendstream',
    ]
    out = io.BytesIO()
    out.write(b'%PDF-1.4\n')
    offsets = []
    for i, o in enumerate(objs, 1):
        offsets.append(out.tell())
        out.write(b'%d 0 obj\n' % i + o + b'\nendobj\n')
    xref = out.tell()
    out.write(b'xref\n0 %d\n0000000000 65535 f \n' % (len(objs) + 1))
    for off in offsets:
        out.write(b'%010d 00000 n \n' % off)
    out.write(b'trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' % (len(objs) + 1, xref))
    with open(os.path.join(OUT, 'unbalanced_cm.pdf'), 'wb') as f:
        f.write(out.getvalue())

    print('fixtures written to', OUT)


if __name__ == '__main__':
    main()
