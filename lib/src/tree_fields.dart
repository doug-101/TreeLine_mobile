// tree_fields.dart, provides output for field types.
// TreeLine_mobile, a reader for the TreeLine desktop program.
// Copyright (c) 2021, Douglas W. Bell.
// Free software, GPL v2 or later.

import 'dart:convert' show HtmlEscape;
import 'package:intl/intl.dart' show DateFormat;
import 'gen_number.dart';
import 'numbering.dart';
import 'tree_struct.dart' show TreeNode;

var _errorStr = '#####';

/// A portion of the data held within a node.
class Field {
  late String name, _type, _format, _prefix, _suffix;
  var boolFormat = {true: 'yes', false: 'no'};
  var _outputSeparator = '';

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
    _outputSeparator = node.formatRef.outputSeparator;
    return _formatOutput(storedText,
        oneLine: oneLine, noHtml: noHtml, formatHtml: formatHtml);
  }

  String _formatOutput(String storedText,
      {bool oneLine = false, bool noHtml = false, bool formatHtml = false}) {
    var localPrefix = _prefix;
    var localSuffix = _suffix;
    try {
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
            default:
              storedText = _errorStr;
          }
          break;
        case 'Number':
          var value = num.parse(storedText);
          storedText = numString(value, _format);
          break;
        case 'Numbering':
          storedText = NumberingGroup(_format).numString(storedText);
          break;
        case 'Combination':
        case 'AutoCombination':
          var selections = _splitText(storedText, '/');
          storedText = selections.join(_outputSeparator);
          break;
      }
    } on FormatException {
      storedText = _errorStr;
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

/// Split text using the given delimitter and return a list.
///
/// Double delimitters are not split, empty parts are ignored and
/// duplicates are removed.
List<String> _splitText(String textStr, String delimitChar) {
  var result = <String>[];
  textStr = textStr.replaceAll(delimitChar * 2, '\0');
  for (var text in textStr.split(delimitChar)) {
    text = text.replaceAll('\0', delimitChar);
    if (text.isNotEmpty && !result.contains(text)) result.add(text);
  }
  return result;
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
