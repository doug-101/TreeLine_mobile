// numbering.dart, provides fomatting for section or outline based node numbering.
// TreeLine_mobile, a reader for the TreeLine desktop program.
// Copyright (c) 2021, Douglas W. Bell.
// Free software, GPL v2 or later.

/// A group of numbering sequences.
class NumberingGroup {
  var basicFormats = <BasicNumbering>[];
  var isSectionStyle = false;

  NumberingGroup([String numFormat = '']) {
    if (numFormat.isNotEmpty) setFormat(numFormat);
  }

  void setFormat(String numFormat) {
    isSectionStyle = false;
    var formats = _splitText(numFormat.replaceAll('..', '.'), '/');
    if (formats.length < 2) {
      formats = _splitText(numFormat.replaceAll('//', '/'), '.');
      if (formats.length > 1) isSectionStyle = true;
    }
    basicFormats = [for (var format in formats) BasicNumbering(format)];
  }

  String numString(String inputNum) {
    if (inputNum.isEmpty) return '';
    var inputNums = [
      for (var numStr in inputNum.split('.')) int.parse(numStr)
    ];
    if (isSectionStyle) {
      var results = <String>[];
      for (int i = 0; i < inputNums.length; i++) {
        var basicFormat =
            i < basicFormats.length ? basicFormats[i] : basicFormats.last;
        results.add(basicFormat.numString(inputNums[i]));
      }
      return results.join('.');
    } else {
      var level = inputNums.length - 1;
      var basicFormat =
          level < basicFormats.length ? basicFormats[level] : basicFormats.last;
      return basicFormat.numString(inputNums[level]);
    }
  }
}

/// A single numbering item.
class BasicNumbering {
  var numFunction = _stringFromNum;
  var isUpperCase = true;
  var prefix = '';
  var suffix = '';

  BasicNumbering([String numFormat = '']) {
    if (numFormat.isNotEmpty) setFormat(numFormat);
  }

  void setFormat(String numFormat) {
    var match = RegExp(r'(.*?)([1AaIi]{1,2})(\W*)$').firstMatch(numFormat);
    if (match != null) {
      prefix = match.group(1)!;
      var series = match.group(2)!;
      suffix = match.group(3)!;
      if (series == '1') {
        numFunction = _stringFromNum;
      } else if ('Aa'.contains(series)) {
        numFunction = _alphaFromNum;
      } else if ('AAaa'.contains(series)) {
        numFunction = _alpha2FromNum;
      } else {
        numFunction = _romanFromNum;
      }
      isUpperCase = series == series.toUpperCase();
    } else {
      prefix = numFormat;
      numFunction = _stringFromNum;
      isUpperCase = true;
      suffix = '';
    }
  }

  String numString(int num) {
    return prefix + numFunction(num, isUpperCase) + suffix;
  }
}

/// Return a number string from an integer.
String _stringFromNum(int num, [bool upperCase = true]) {
  if (num < 1) return '';
  return num.toString();
}

/// Return an alphabetic string from an integer.
///
/// Sequence is 'A', 'B' ... 'Z', 'AA', 'BB' ... 'ZZ', 'AAA', 'BBB' ...
String _alphaFromNum(int num, [bool upperCase = true]) {
  if (num < 1) return '';
  var charPos = (num - 1) % 26;
  var char = String.fromCharCode(charPos + 'A'.codeUnitAt(0));
  var qty = (num - 1) ~/ 26 + 1;
  var result = char * qty;
  if (!upperCase) result = result.toLowerCase();
  return result;
}

/// Return an alphabetic string from an integer.
///
/// Sequence is 'AA', 'BB' ... 'ZZ', 'AAA', 'BBB' ... 'ZZZ', 'AAAA', 'BBBB' ...
String _alpha2FromNum(int num, [bool upperCase = true]) {
  if (num < 1) return '';
  var charPos = (num - 1) % 26;
  var char = String.fromCharCode(charPos + 'A'.codeUnitAt(0));
  var qty = (num - 1) ~/ 26 + 2;
  var result = char * qty;
  if (!upperCase) result = result.toLowerCase();
  return result;
}

/// Return a roman numeral string from an integer.
String _romanFromNum(int num, [bool upperCase = true]) {
  final romanDict = const {
    0: '',
    1: 'I',
    2: 'II',
    3: 'III',
    4: 'IV',
    5: 'V',
    6: 'VI',
    7: 'VII',
    8: 'VIII',
    9: 'IX',
    10: 'X',
    20: 'XX',
    30: 'XXX',
    40: 'XL',
    50: 'L',
    60: 'LX',
    70: 'LXX',
    80: 'LXXX',
    90: 'XC',
    100: 'C',
    200: 'CC',
    300: 'CCC',
    400: 'CD',
    500: 'D',
    600: 'DC',
    700: 'DCC',
    800: 'DCCC',
    900: 'CM',
    1000: 'M',
    2000: 'MM',
    3000: 'MMM'
  };
  if (num < 1 || num >= 4000) return '';
  var result = '';
  var factor = 1000;
  while (num > 0) {
    var digit = num - (num % factor);
    result += romanDict[digit]!;
    factor = factor ~/ 10;
    num -= digit;
  }
  if (!upperCase) result = result.toLowerCase();
  return result;
}

/// Split text using the given delimitter and return a list.
///
/// Double delimitters are not split and empty parts are ignored.
List<String> _splitText(String textStr, String delimitChar) {
  var result = <String>[];
  textStr = textStr.replaceAll(delimitChar * 2, '\0');
  for (var text in textStr.split(delimitChar)) {
    text = text.replaceAll('\0', delimitChar);
    if (text.isNotEmpty) result.add(text);
  }
  return result;
}

void main(List<String> args) {
  // print(BasicNumbering(args[0]).numString(int.tryParse(args[1]) ?? 0));
  print(NumberingGroup(args[0]).numString(args[1]));
}
