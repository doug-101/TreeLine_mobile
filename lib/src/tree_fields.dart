import 'dart:convert' show HtmlEscape;
import 'package:intl/intl.dart' show DateFormat;
import 'gen_number.dart';
import 'numbering.dart';
import 'tree_struct.dart' show TreeNode;

/// A portion of the data held within a node.
class Field {
  late String name, _type, _format, _prefix, _suffix;
  var boolFormat = {true: 'yes', false: 'no'};

  Field(Map<String, dynamic> jsonData) {
    name = jsonData['fieldname'] ?? '';
    _type = jsonData['fieldtype'] ?? 'Text';
    _format = jsonData['format'] ?? '';
    _prefix = jsonData['prefix'] ?? '';
    _suffix = jsonData['suffix'] ?? '';
    if ({'Date', 'Time', 'DateTime'}.contains(_type)) {
      _format = _adjustDateTimeFormat(_format);
    } else if (_type == 'Boolean') {
      var tmpFormat = _format.replaceAll('//', '\0');
      var idx = tmpFormat.indexOf('/');
      if (idx >= 0) {
        boolFormat = {
          true: tmpFormat.substring(0, idx).trim().replaceAll('\0', '/'),
          false: tmpFormat.substring(idx + 1).trim().replaceAll('\0', '/')
        };
      }
    }
  }

  String outputText(TreeNode node,
      {bool oneLine = false, bool noHtml = false, bool formatHtml = false}) {
    var storedText = node.data[name] ?? '';
    if (storedText.isEmpty) return '';
    return _formatOutput(storedText,
        oneLine: oneLine, noHtml: noHtml, formatHtml: formatHtml);
  }

  String _formatOutput(String storedText,
      {bool oneLine = false, bool noHtml = false, bool formatHtml = false}) {
    var localPrefix = _prefix;
    var localSuffix = _suffix;
    switch (_type) {
      case 'Date':
        var inputDateFormat = DateFormat('yyyy-MM-dd');
        var date = inputDateFormat.parse(storedText);
        var outputDateFormat = DateFormat(_format);
        storedText = outputDateFormat.format(date);
        break;
      case 'Time':
        var inputTimeFormat = DateFormat('HH:mm:ss.S');
        var time = inputTimeFormat.parse(storedText);
        var outputTimeFormat = DateFormat(_format);
        storedText = outputTimeFormat.format(time);
        break;
      case 'DateTime':
        var inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss.S');
        var dateTime = inputFormat.parse(storedText);
        var outputFormat = DateFormat(_format);
        storedText = outputFormat.format(dateTime);
        break;
      case 'Boolean':
        switch (storedText.toLowerCase()) {
          case 'true':
          case 'yes':
            storedText = boolFormat[true]!;
            break;
          case 'false':
          case 'no':
            storedText = boolFormat[false]!;
            break;
        }
        break;
      case 'Number':
        try {
          var value = num.parse(storedText);
          storedText = numString(value, _format);
        } on FormatException {}
        break;
      case 'Numbering':
        storedText = NumberingGroup(_format).numString(storedText);
        break;
    }
    if (oneLine)
      storedText = RegExp(r'(.+?)<br\s*/?>', caseSensitive: false)
              .matchAsPrefix(storedText)
              ?.group(1) ??
          storedText;
    if (noHtml) {
      storedText = removeMarkup(storedText);
      if (formatHtml) {
        localPrefix = removeMarkup(localPrefix);
        localSuffix = removeMarkup(localSuffix);
      }
    }
    if (!formatHtml && !noHtml) {
      var htmlEscape = HtmlEscape();
      localPrefix = htmlEscape.convert(localPrefix);
      localSuffix = htmlEscape.convert(localSuffix);
    }
    return '$localPrefix$storedText$localSuffix';
  }
}

String removeMarkup(String text) {
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<.*?>'), '');
  return text;
}

String _adjustDateTimeFormat(String origFormat) {
  final replacements = const {
    '%-d': 'd',
    '%d': 'dd',
    '%a': 'EEE',
    '%A': 'EEEE',
    '%-m': 'M',
    '%m': 'MM',
    '%b': 'MMM',
    '%B': 'MMMM',
    '%y': 'yy',
    '%Y': 'yyyy',
    '%-j': 'D',
    '%-H': 'H',
    '%H': 'HH',
    '%-I': 'h',
    '%I': 'hh',
    '%-M': 'm',
    '%M': 'mm',
    '%-S': 's',
    '%S': 'ss',
    '%f': 'S',
    '%p': 'a',
    '%%': "'%'",
  };
  final regExp = RegExp(r'%-?[daAmbByYjHIMSfp%]');
  var newFormat = origFormat.replaceAllMapped(
      regExp,
      (Match m) => replacements[m.group(0)] != null
          ? "'${replacements[m.group(0)]}'"
          : m.group(0)!);
  newFormat = "'$newFormat'";
  newFormat = newFormat.replaceAll("''", "");
  return newFormat;
}
