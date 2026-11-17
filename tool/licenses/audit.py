"""Audits the licence of every Dart package in pubspec.lock.

Usage: python3 tool/licenses/audit.py [--markdown]

Reads each package's LICENSE file from the pub cache and classifies it.
Exits with status 1 if any package is GPL/AGPL/LGPL or unknown, so it can
run in CI. With --markdown, prints a table for LICENSES.md.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
PUB_CACHE = os.environ.get('PUB_CACHE', os.path.expanduser('~/.pub-cache'))
FLUTTER_ROOT = os.environ.get('FLUTTER_ROOT', '/opt/flutter')


def packages():
    lock = open(os.path.join(ROOT, 'pubspec.lock'), encoding='utf-8').read()
    for m in re.finditer(r'\n  (\S+):\n    dependency: "?([^"\n]+)"?\n    description:(.*?)\n    source: (\w+)\n    version: "([^"]+)"', lock, re.S):
        name, dep, desc, source, version = m.groups()
        yield name, dep, source, version


# Packages used only by desktop (Linux) plugin implementations. They are not
# compiled into the Android app. dbus (MPL-2.0) <- file_picker_linux.
DESKTOP_ONLY = {'dbus'}


def classify(text):
    t = text.lower()
    # MPL-2.0's own text mentions the GNU licences, so check it first.
    if 'mozilla public license' in t:
        return 'MPL-2.0'
    if 'gnu affero' in t:
        return 'AGPL'
    if 'gnu lesser' in t or 'lgpl' in t:
        return 'LGPL'
    if 'gnu general public' in t:
        return 'GPL'
    if 'apache license' in t and 'version 2.0' in t:
        return 'Apache-2.0'
    if 'permission is hereby granted, free of charge' in t:
        return 'MIT'
    if 'permission to use, copy, modify, and/or distribute this software for any' in t:
        return 'ISC'
    if 'redistribution and use in source and binary forms' in t:
        return 'BSD-3-Clause' if 'neither the name' in t or 'endorse or promote' in t else 'BSD-2-Clause'
    if 'zlib' in t and 'altered source versions' in t:
        return 'Zlib'
    return 'UNKNOWN'


def license_text(name, source, version):
    if source == 'sdk':
        return open(os.path.join(FLUTTER_ROOT, 'LICENSE'), encoding='utf-8', errors='ignore').read()
    d = os.path.join(PUB_CACHE, 'hosted', 'pub.dev', f'{name}-{version}')
    for fn in ('LICENSE', 'LICENSE.md', 'LICENSE.txt', 'COPYING'):
        p = os.path.join(d, fn)
        if os.path.exists(p):
            return open(p, encoding='utf-8', errors='ignore').read()
    return ''


def main():
    md = '--markdown' in sys.argv
    bad = []
    rows = []
    for name, dep, source, version in packages():
        lic = classify(license_text(name, source, version))
        rows.append((name, version, dep, lic + (' (Linux desktop only, not in the Android app)' if name in DESKTOP_ONLY else '')))
        if lic in ('GPL', 'AGPL', 'LGPL', 'UNKNOWN') or (lic == 'MPL-2.0' and name not in DESKTOP_ONLY):
            bad.append((name, lic))
    if md:
        print('| Package | Version | Dependency | Licence |')
        print('|---|---|---|---|')
        for r in rows:
            print(f'| {r[0]} | {r[1]} | {r[2]} | {r[3]} |')
    else:
        for r in rows:
            print(f'{r[3]:14} {r[0]} {r[1]} ({r[2]})')
    if bad:
        print('\nNOT ALLOWED / UNKNOWN:', bad, file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
