import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../arabic/normalize.dart';

/// Writes a minimal, valid Word document (.docx). Each paragraph gets its own
/// direction: Arabic paragraphs are right-to-left (w:bidi + w:rtl).
/// Lines inside a paragraph are kept with line breaks.
Uint8List buildDocx(String text, {String title = ''}) {
  final paragraphs = text.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));
  final body = StringBuffer();
  for (final para in paragraphs) {
    final rtl = isRtlText(para);
    final lines = para.split('\n');
    body.write('<w:p><w:pPr>');
    if (rtl) body.write('<w:bidi/>');
    body.write('</w:pPr>');
    for (var i = 0; i < lines.length; i++) {
      body.write('<w:r><w:rPr>');
      if (rtl) body.write('<w:rtl/>');
      body.write('</w:rPr>');
      if (i > 0) body.write('<w:br/>');
      body.write('<w:t xml:space="preserve">${_esc(lines[i])}</w:t></w:r>');
    }
    body.write('</w:p>');
  }

  const contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '</Types>';
  const rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '</Relationships>';
  const docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>';
  const styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:docDefaults><w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/>'
      '<w:sz w:val="24"/><w:szCs w:val="24"/><w:lang w:val="en-US" w:bidi="ar-SA"/>'
      '</w:rPr></w:rPrDefault>'
      '<w:pPrDefault><w:pPr><w:spacing w:after="160" w:line="300" w:lineRule="auto"/></w:pPr></w:pPrDefault>'
      '</w:docDefaults></w:styles>';
  final core = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/">'
      '<dc:title>${_esc(title)}</dc:title></cp:coreProperties>';
  final document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>'
      '</w:sectPr></w:body></w:document>';

  final archive = Archive()
    ..addFile(ArchiveFile.bytes('[Content_Types].xml', utf8.encode(contentTypes)))
    ..addFile(ArchiveFile.bytes('_rels/.rels', utf8.encode(rels)))
    ..addFile(ArchiveFile.bytes('word/document.xml', utf8.encode(document)))
    ..addFile(ArchiveFile.bytes('word/_rels/document.xml.rels', utf8.encode(docRels)))
    ..addFile(ArchiveFile.bytes('word/styles.xml', utf8.encode(styles)))
    ..addFile(ArchiveFile.bytes('docProps/core.xml', utf8.encode(core)));
  return ZipEncoder().encodeBytes(archive);
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll(RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');
