"""Measures Tesseract word accuracy on the OCR fixture images.

Usage: python3 tool/fixtures/ocr_accuracy.py <tessdata_dir> [lang]

Runs the `tesseract` CLI (same engine family as the app's Android library)
against the fixture images and prints the share of expected words found.
This does NOT exercise the app's Flutter code path; it is used to choose
which language model to bundle and to record honest accuracy numbers.
"""
import json
import os
import subprocess
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURES = os.path.join(HERE, '..', '..', 'test', 'fixtures')

TASHKEEL = {chr(c) for c in range(0x064B, 0x0660)} | {'ٰ', 'ـ'}


def norm(word: str) -> str:
    word = unicodedata.normalize('NFKC', word)
    word = ''.join(ch for ch in word if ch not in TASHKEEL)
    for a in 'أإآٱ':
        word = word.replace(a, 'ا')
    word = word.replace('ة', 'ه').replace('ى', 'ي')
    return word.strip('.,:;!?()[]"\'«»،؛').lower()


def main() -> None:
    tessdata = sys.argv[1]
    expected = json.load(open(os.path.join(FIXTURES, 'ocr_expected.json'), encoding='utf-8'))
    for image, spec in expected.items():
        lang = sys.argv[2] if len(sys.argv) > 2 else spec['lang']
        out = subprocess.run(
            ['tesseract', os.path.join(FIXTURES, image), '-', '--tessdata-dir', tessdata,
             '-l', lang, '--psm', '3'],
            capture_output=True, text=True, check=True).stdout
        got = [norm(w) for w in out.split()]
        want = [norm(w) for w in ' '.join(spec['lines']).split()]
        found = sum(1 for w in want if w in got)
        print(f'{image} [{lang}]: {found}/{len(want)} words '
              f'({100.0 * found / len(want):.1f}%)')
        for line in out.strip().splitlines():
            if line.strip():
                print('   |', line)


if __name__ == '__main__':
    main()
