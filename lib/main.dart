import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'src/tree_core.dart';

void main() {
  runApp(MaterialApp(
    title: 'TreeLine Mobile',
    home: FileControl(),
  ));
}

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
                FilePickerResult? result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  PlatformFile fileObj = result.files.single;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreeView(fileObj: fileObj),
                    ),
                  );
                  //FilePicker.platform.clearTemporaryFiles();
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
  void initState() {
    super.initState();
    _treeStructure = TreeStructure(widget.fileObj.path!);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TreeLine Mobile'),
      ),
      body: ListView(
        children: _itemRows(),
      ),
    );
  }

  List<Widget> _itemRows() {
    final items = <Widget>[];
    for (var rootSpot in _treeStructure.rootSpots()) {
      for (var rankedSpot in rootSpot.outputOpenDescendGen(_openSpots)) {
        items.add(_row(rankedSpot));
      }
    }
    return items;
  }

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
        child: Row(children: <Widget>[
          node.childList.isEmpty
              ? Container(
                  child: _leafIcon, padding: EdgeInsets.only(right: 5.0))
              : _openSpots.contains(rankedSpot.spotRef)
                  ? _openIcon
                  : _closedIcon,
          Expanded(child: Text(text, softWrap: true)),
        ]),
      ),
    );
  }
}
