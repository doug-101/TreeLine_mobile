import 'package:flutter/material.dart';
import 'src/tree_core.dart';

void main() => runApp(TreeMobileApp());

class TreeMobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreeLine Mobile',
      home: TreeMobile(),
    );
  }
}

class _TreeMobileState extends State<TreeMobile> {
  static const _fn = '/sdcard/Download/SFBooks.trln';
  final _closedIcon = Icon(Icons.arrow_right, size: 24.0, color: Colors.blue);
  final _openIcon = Icon(Icons.arrow_drop_down, size: 24.0, color: Colors.blue);
  final _leafIcon = Icon(Icons.circle, size: 8.0, color: Colors.blue);
  final _treeStructure = TreeStructure(_fn);
  final _openSpots = <TreeSpot>{};
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

class TreeMobile extends StatefulWidget {
  @override
  State<TreeMobile> createState() => _TreeMobileState();
}
