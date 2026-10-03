/// Turns an HTML email body into readable plain text: drops scripts and
/// styles, keeps line breaks at block boundaries, strips tags, decodes the
/// common entities (including ₹). Bank alert emails are often HTML-only, so
/// without this there is nothing for the parser to read.
String htmlToText(String html) {
  var text = html
      .replaceAll(
        RegExp(
          r'<(script|style)[^>]*>.*?</\1>',
          caseSensitive: false,
          dotAll: true,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ')
      .replaceAll(
        RegExp(
          r'<br\s*/?>|</(p|div|tr|li|h[1-6]|table)>',
          caseSensitive: false,
        ),
        '\n',
      )
      .replaceAll(RegExp(r'</t[dh]>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');

  const named = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&rupee;': '₹',
  };
  named.forEach(
    (entity, replacement) => text = text.replaceAll(entity, replacement),
  );
  text = text.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(2)!, radix: m.group(1) == 'x' ? 16 : 10);
    return code == null ? ' ' : String.fromCharCode(code);
  });

  return text
      .replaceAll(RegExp(r'[ \t ]+'), ' ')
      .replaceAll(RegExp(r' ?\n ?'), '\n')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();
}
