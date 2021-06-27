import 'dart:io' show File;
import 'dart:convert' show jsonDecode, HtmlEscape;

import 'package:uuid/uuid.dart' show Uuid;
import 'package:intl/intl.dart' show DateFormat;

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
      _format = adjustDateTimeFormat(_format);
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
    if (_type == 'Date') {
      var inputDateFormat = DateFormat('yyyy-MM-dd');
      var date = inputDateFormat.parse(storedText);
      var outputDateFormat = DateFormat(_format);
      storedText = outputDateFormat.format(date);
    } else if (_type == 'Time') {
      var inputTimeFormat = DateFormat('HH:mm:ss.S');
      var time = inputTimeFormat.parse(storedText);
      var outputTimeFormat = DateFormat(_format);
      storedText = outputTimeFormat.format(time);
    } else if (_type == 'DateTime') {
      var inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss.S');
      var dateTime = inputFormat.parse(storedText);
      var outputFormat = DateFormat(_format);
      storedText = outputFormat.format(dateTime);
    } else if (_type == 'Boolean') {
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

/// Holds fields and output definitions for a node type.
class NodeFormat {
  late String name;
  late bool _spaceBetween, _formatHtml;
  late ParsedLine _titleLine;
  var _outputLines = <ParsedLine>[];
  var _fieldMap = <String, Field>{};

  NodeFormat(Map<String, dynamic> jsonData) {
    name = jsonData['formatname'] ?? '';
    _spaceBetween = jsonData['spacebetween'] ?? true;
    _formatHtml = jsonData['formathtml'] ?? false;
    _titleLine = ParsedLine(jsonData['titleline'] ?? '');
    for (var lineString in jsonData['outputlines'] ?? []) {
      _outputLines.add(ParsedLine(lineString ?? ''));
    }
    for (var fieldData in jsonData['fields'] ?? []) {
      var field = Field(fieldData);
      _fieldMap[field.name] = field;
    }
    _updateLineParsing();
  }

  String formatTitle(TreeNode node) {
    return _titleLine
        .formattedLine(node,
            oneLine: true,
            skipBlanks: false,
            noHtml: true,
            formatHtml: _formatHtml)
        .trim();
  }

  List<String> formatOutput(TreeNode node,
      {bool skipBlanks = true, bool noHtml = true}) {
    return [
      for (var outLine in _outputLines)
        outLine.formattedLine(node,
            skipBlanks: skipBlanks, noHtml: noHtml, formatHtml: _formatHtml)
    ];
  }

  void _updateLineParsing() {
    _titleLine.parseLine(_fieldMap);
    _outputLines.forEach((line) => line.parseLine(_fieldMap));
  }
}

/// A single line of output, broken into fields and static text.
class ParsedLine {
  late final String _unparsedLine;
  var _textSegments = <String>[];
  var _lineFields = <Field>[];

  ParsedLine(this._unparsedLine);

  void parseLine(Map<String, Field> fieldMap) {
    _textSegments.clear();
    _lineFields.clear();
    var start = 0;
    var regExp = RegExp(r'{\*(\**|\?|!|&|#)([\w_\-.]+)\*}');
    for (var match in regExp.allMatches(_unparsedLine, start)) {
      _textSegments.add(_unparsedLine.substring(start, match.start));
      if (match.group(1) == '' && fieldMap.containsKey(match.group(2))) {
        _lineFields.add(fieldMap[match.group(2)!]!);
      } else {
        _textSegments.add(match.group(0)!);
      }
      start = match.end;
    }
    _textSegments.add(_unparsedLine.substring(start));
  }

  String formattedLine(TreeNode node,
      {bool oneLine = false,
      bool skipBlanks = true,
      bool noHtml = false,
      bool formatHtml = false}) {
    var initText = _textSegments[0];
    if (!formatHtml && !noHtml) initText = HtmlEscape().convert(initText);
    if (formatHtml && noHtml) initText = removeMarkup(initText);
    var result = StringBuffer(initText);
    var fieldsBlank = true;
    for (var i = 0; i < _lineFields.length; i++) {
      var fieldText = _lineFields[i].outputText(node,
          oneLine: oneLine, noHtml: noHtml, formatHtml: formatHtml);
      if (fieldText.length > 0) {
        fieldsBlank = false;
        result.write(fieldText);
      }
      var formText = _textSegments[i + 1];
      if (!formatHtml && !noHtml) formText = HtmlEscape().convert(formText);
      if (formatHtml && noHtml) formText = removeMarkup(formText);
      result.write(formText);
    }
    if (skipBlanks && fieldsBlank && _lineFields.length > 0) return '';
    return result.toString();
  }
}

/// Combination of a node spot and a level for output into trees.
class RankedSpot {
  final TreeSpot spotRef;
  final int level;

  RankedSpot(this.spotRef, this.level);
}

/// The data and children for a node in the tree.
class TreeNode {
  late NodeFormat formatRef;
  late String uId;
  late Map<String, String> data;
  var childList = <TreeNode>[];
  late List<String> _tmpChildRefs;
  var spotRefs = <TreeSpot>{};

  TreeNode(Map<String, dynamic> json, Map<String, NodeFormat> treeFormats) {
    var formatName = json['format'];
    if (treeFormats[formatName] != null) {
      formatRef = treeFormats[formatName]!;
    } else {
      formatRef = NodeFormat({});
    }
    uId = json['uid'] ?? Uuid().v1().replaceAll('-', '');
    data = json['data']?.cast<String, String>() ?? {};
    _tmpChildRefs = json['children']?.cast<String>() ?? [];
  }

  void assignRefs(Map<String, TreeNode> nodeDict) {
    for (var id in _tmpChildRefs) {
      var node = nodeDict[id];
      if (node != null) {
        childList.add(node);
      }
    }
  }

  void generateSpots(TreeSpot? parentSpot) {
    var spot = TreeSpot(this, parentSpot);
    spotRefs.add(spot);
    childList.forEach((node) => node.generateSpots(spot));
  }

  TreeSpot? matchedSpot(TreeSpot? parentSpot) {
    for (var spot in spotRefs) {
      if (spot.parentSpot == parentSpot) return spot;
    }
    return null;
  }
}

/// An individual location for a node; holds a reference to a parent.
///
/// Cloned nodes have multiple spots.
class TreeSpot {
  TreeNode nodeRef;
  TreeSpot? parentSpot;

  TreeSpot(this.nodeRef, this.parentSpot);

  List<TreeSpot> childSpots() {
    var spots = <TreeSpot>[];
    for (var childNode in nodeRef.childList) {
      var newSpot = childNode.matchedSpot(this);
      if (newSpot != null) spots.add(newSpot);
    }
    return spots;
  }

  Iterable<RankedSpot> outputDescendGen(
      {int initLevel = 0, bool includeRoot = true}) sync* {
    if (includeRoot) yield RankedSpot(this, initLevel);
    for (var childSpot in childSpots()) {
      yield* childSpot.outputDescendGen(initLevel: initLevel + 1);
    }
  }

  Iterable<RankedSpot> outputOpenDescendGen(Set<TreeSpot> openSpots,
      [int initLevel = 0]) sync* {
    yield RankedSpot(this, initLevel);
    if (openSpots.contains(this)) {
      for (var childSpot in childSpots()) {
        yield* childSpot.outputOpenDescendGen(openSpots, initLevel + 1);
      }
    }
  }
}

/// Top-level storage for tree formats and nodes.
class TreeStructure {
  var treeFormats = <String, NodeFormat>{};
  var nodeDict = <String, TreeNode>{};
  var childList = <TreeNode>[];

  TreeStructure(String filename) {
    var jsonData = jsonDecode(File(filename).readAsStringSync());
    for (var formatData in jsonData['formats']) {
      var nodeFormat = NodeFormat(formatData);
      treeFormats[nodeFormat.name] = nodeFormat;
    }
    for (var nodeInfo in jsonData['nodes']) {
      var node = TreeNode(nodeInfo, treeFormats);
      nodeDict[node.uId] = node;
    }
    nodeDict.values.forEach((node) => node.assignRefs(nodeDict));
    for (var id in jsonData['properties']['topnodes']) {
      var node = nodeDict[id];
      if (node != null) {
        childList.add(node);
        node.generateSpots(null);
      }
    }
  }

  List<TreeSpot> rootSpots() {
    return [for (var node in childList) node.matchedSpot(null)!];
  }

  Iterable<String> titles() sync* {
    for (var rootSpot in rootSpots()) {
      for (var item in rootSpot.outputDescendGen()) {
        var node = item.spotRef.nodeRef;
        yield '- ' * item.level + node.formatRef.formatTitle(node);
      }
    }
  }

  Iterable<String> output() sync* {
    for (var rootSpot in rootSpots()) {
      for (var item in rootSpot.outputDescendGen()) {
        var node = item.spotRef.nodeRef;
        for (var line in node.formatRef.formatOutput(node, noHtml: true)) {
          if (line.isNotEmpty) yield '- ' * item.level + line;
        }
        yield '';
      }
    }
  }
}

void main(List<String> args) {
  var treeStructure = TreeStructure(args[0]);
  for (var text in treeStructure.output()) {
    print(text);
  }
}

String removeMarkup(String text) {
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<.*?>'), '');
  return text;
}

String adjustDateTimeFormat(String origFormat) {
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
