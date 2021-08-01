// main.dart, the main user interface file.
// TreeLine_mobile, a reader for the TreeLine desktop program.
// Copyright (c) 2021, Douglas W. Bell.
// Free software, GPL v2 or later.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'src/tree_struct.dart';

void main() {
  runApp(MaterialApp(
    title: 'TreeLine Mobile',
    home: FileControl(),
  ));
}

/// Provides a simle view with a button to allow file browsing.
///
/// Buttons for other ways of getting the file could be added in the future.
class FileControl extends StatefulWidget {
  @override
  State<FileControl> createState() => _FileControlState();
}

class _FileControlState extends State<FileControl> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TreeLine Mobile'),
      ),
      body: ListView(
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text('File Browse'),
              onTap: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (result != null) {
                  PlatformFile fileObj = result.files.single;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreeView(fileObj: fileObj),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The main indented tree view.
class TreeView extends StatefulWidget {
  final PlatformFile fileObj;

  TreeView({Key? key, required this.fileObj}) : super(key: key);

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> {
  final _closedIcon = Icon(Icons.arrow_right, size: 24.0, color: Colors.blue);
  final _openIcon = Icon(Icons.arrow_drop_down, size: 24.0, color: Colors.blue);
  final _leafIcon = Icon(Icons.circle, size: 8.0, color: Colors.blue);
  late final _treeStructure;
  final _openSpots = <TreeSpot>{};
  late final headerName;
  void initState() {
    super.initState();
    _treeStructure = TreeStructure(widget.fileObj.path!);
    var fileName = widget.fileObj.name;
    var ext = widget.fileObj.extension;
    if (ext != null) {
      var endPos = fileName.length - ext.length - 1;
      if (endPos > 0) fileName = fileName.substring(0, endPos);
    }
    headerName = 'TreeLine - ' + fileName;
    FilePicker.platform.clearTemporaryFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(headerName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close File',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: _itemRows(),
      ),
    );
  }

  /// The widgets for each node in the tree.
  List<Widget> _itemRows() {
    final items = <Widget>[];
    for (var rootSpot in _treeStructure.rootSpots()) {
      for (var rankedSpot in rootSpot.outputOpenDescendGen(_openSpots)) {
        items.add(_row(rankedSpot));
      }
    }
    return items;
  }

  /// A single widget for a tree node.
  Widget _row(RankedSpot rankedSpot) {
    final node = rankedSpot.spotRef.nodeRef;
    final text = node.formatRef.formatTitle(node);
    return Container(
      padding:
          EdgeInsets.fromLTRB(25.0 * rankedSpot.level + 4.0, 8.0, 4.0, 8.0),
      child: GestureDetector(
        onTap: () {
          if (node.childList.isNotEmpty) {
            setState(() {
              if (_openSpots.contains(rankedSpot.spotRef)) {
                _openSpots.remove(rankedSpot.spotRef);
              } else {
                _openSpots.add(rankedSpot.spotRef);
              }
            });
          }
        },
        onLongPress: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _DetailView(node: node),
            ),
          );
        },
        child: Row(children: <Widget>[
          node.childList.isEmpty
              ? Container(
                  child: _leafIcon,
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                )
              : Container(
                  child: _openSpots.contains(rankedSpot.spotRef)
                      ? _openIcon
                      : _closedIcon,
                ),
          Expanded(child: Text(text, softWrap: true)),
        ]),
      ),
    );
  }
}

/// A detail view that shows node and child output after a long press.
class _DetailView extends StatelessWidget {
  final TreeNode node;

  _DetailView({Key? key, required this.node}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(node.formatRef.formatTitle(node)),
      ),
      body: ListView(
        children: _detailRows(node),
      ),
    );
  }

  List<Widget> _detailRows(TreeNode node) {
    final items = <Widget>[];
    items.add(
      Card(
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Html(
            data: node.formatRef.formatOutput(node).join('<br />'),
            onLinkTap: _launchURL,
          ),
        ),
      ),
    );
    for (var childNode in node.childList) {
      items.add(
        Card(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            child: Html(
              data: childNode.formatRef.formatOutput(childNode).join('<br />'),
              onLinkTap: _launchURL,
            ),
          ),
          margin: EdgeInsets.fromLTRB(20.0, 5.0, 5.0, 5.0),
        ),
      );
    }
    return items;
  }
}

/// Launches a clicked link in an external browser.
void _launchURL(String? url, _, __, ___) async {
  if (url != null && await canLaunch(url)) {
    await launch(url);
  }
}
