import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
                ;
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
  late final headerName;
  void initState() {
    super.initState();
    _treeStructure = TreeStructure(widget.fileObj.path!);
    var fileName = widget.fileObj.name!;
    if (widget.fileObj.extension != null) {
      fileName = fileName.substring(
          0, fileName.length - widget.fileObj.extension!.length - 1);
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

class _DetailView extends StatelessWidget {
  final TreeNode node;

  _DetailView({Key? key, required this.node}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(node.formatRef.formatTitle(node)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Text(node.formatRef.formatOutput(node).join('\n')),
        ),
      ),
    );
  }
}
