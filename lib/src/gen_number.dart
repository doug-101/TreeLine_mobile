// gen_number.dart, provides formatting of numeric field types.
// TreeLine_mobile, a reader for the TreeLine desktop program.
// Copyright (c) 2021, Douglas W. Bell.
// Free software, GPL v2 or later.

import 'dart:math';

/// Formats a value including an exponent.
String numString(num value, String strFormat) {
  var expPos = _charPos('eE', strFormat);
  if (expPos < 0) {
    return basicNumString(value, strFormat);
  }
  var mainFormat = strFormat.substring(0, expPos);
  var expFormat = strFormat.substring(expPos + 1);
  var exp = (log(value.abs()) / ln10).floor();
  var mainNum = value / pow(10, exp);
  var totalPlcs = RegExp(r'[#0]').allMatches(mainFormat).length;
  if (totalPlcs > 1) {
    mainNum = double.tryParse(mainNum.toStringAsFixed(totalPlcs - 1)) ?? 0.0;
  } else {
    mainNum = mainNum.round().toDouble();
  }
  var radix = _getRadix(strFormat);
  var radixPos = mainFormat.indexOf(radix);
  var wholeFormat = mainFormat;
  if (radixPos >= 0) wholeFormat = mainFormat.substring(0, radixPos);
  var wholePlcs = RegExp(r'[#0]').allMatches(wholeFormat).length;
  var expChg = wholePlcs - (log(mainNum.abs()) / ln10).floor();
  mainNum = mainNum * pow(10, expChg);
  exp -= expChg;
  var c = strFormat.contains('e') ? 'e' : 'E';
  return '${basicNumString(mainNum, mainFormat)}$c' +
      '${basicNumString(exp, expFormat)}';
}

/// Formats a number without an exponent.
String basicNumString(num value, String strFormat) {
  var radix = _getRadix(strFormat);
  strFormat = _unescapeFormat(radix, strFormat);
  var radixPos = strFormat.indexOf(radix);
  if (radixPos < 0) radixPos = strFormat.length;
  var formatCharsWhole = strFormat.substring(0, radixPos).split('');
  var formatCharsFract = <String>[];
  if (radixPos + 1 < strFormat.length) {
    formatCharsFract = strFormat.substring(radixPos + 1).split('');
  }
  var decPlcs = RegExp(r'[#0]').allMatches(formatCharsFract.join()).length;
  var valueStr = value.toStringAsFixed(decPlcs);
  radixPos = valueStr.indexOf('.');
  if (radixPos < 0) radixPos = valueStr.length;
  var valueCharsWhole = valueStr.substring(0, radixPos).split('');
  var valueCharsFract = <String>[];
  if (radixPos + 1 < valueStr.length) {
    valueCharsFract = valueStr.substring(radixPos + 1).split('');
  }
  while (valueCharsFract.isNotEmpty && valueCharsFract.last == '0') {
    valueCharsFract.removeLast();
  }
  var sign = valueCharsWhole[0] == '-' ? valueCharsWhole.removeAt(0) : '+';
  var result = <String>[];
  var c = '';
  while (valueCharsWhole.isNotEmpty || formatCharsWhole.isNotEmpty) {
    c = formatCharsWhole.isNotEmpty ? formatCharsWhole.removeLast() : '';
    if (c.isNotEmpty && !'#0 +-'.contains(c)) {
      if (valueCharsWhole.isNotEmpty || formatCharsWhole.contains('0')) {
        result.insert(0, c);
      }
    } else if (valueCharsWhole.isNotEmpty && c != ' ') {
      result.insert(0, valueCharsWhole.removeLast());
      if (c.isNotEmpty && '+-'.contains(c)) {
        formatCharsWhole.add(c);
      }
    } else if ('0 '.contains(c)) {
      result.insert(0, c);
    } else if ('+-'.contains(c)) {
      if (sign == '-' || c == '+') {
        result.insert(0, sign);
      }
      sign = '';
    }
  }
  if (sign == '-') {
    if (result[0] == ' ') {
      result = [result.join().replaceFirst(RegExp(r'\s(?!\s)'), '-')];
    } else {
      result.insert(0, '-');
    }
  }
  if (formatCharsFract.isNotEmpty ||
      (strFormat.isNotEmpty && strFormat.endsWith(radix))) {
    result.add(radix);
  }
  while (formatCharsFract.isNotEmpty) {
    c = formatCharsFract.removeAt(0);
    if (!'#0 '.contains(c)) {
      if (valueCharsFract.isNotEmpty || formatCharsFract.contains('0')) {
        result.add(c);
      }
    } else if (valueCharsFract.isNotEmpty) {
      result.add(valueCharsFract.removeAt(0));
    } else if ('0 '.contains(c)) {
      result.add('0');
    }
  }
  return result.join();
}

/// Return the earliest position of a searchChars in text.
int _charPos(String searchChars, String text) {
  var result = -1;
  for (var char in searchChars.split('')) {
    var tmpResult = text.indexOf(char);
    if (result < 0 || (tmpResult >= 0 && tmpResult < result)) {
      result = tmpResult;
    }
  }
  return result;
}

/// Return the radix character (. or ,) used in format.
/// Infers from use of slashed separators and non-slashed radix.
/// Assumes radix is "." if ambiguous.
String _getRadix(String strFormat) {
  if (!strFormat.contains(r'\,') &&
      (strFormat.contains(r'\.') ||
          (strFormat.contains(',') && !strFormat.contains('.')))) {
    return ',';
  }
  return '.';
}

/// Return format with escapes removed from non-radix separators.
String _unescapeFormat(String radix, String strFormat) {
  if (radix == '.') return strFormat.replaceAll(r'\,', ',');
  return strFormat.replaceAll(r'\.', '.');
}

void main(List<String> args) {
  print(numString(num.tryParse(args[0]) ?? 0, args[1]));
}
