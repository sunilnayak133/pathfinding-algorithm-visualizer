import 'dart:html';

import 'package:flutter/material.dart';
import 'package:path_finding_visualizer/grid.dart';

void main() {
  runApp(const PathFindingVisualizer());
}

class PathFindingVisualizer extends StatelessWidget {
  const PathFindingVisualizer({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pathfinding Algorithm Visualizer",
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      home: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: ((notification) {
            build(context);
            return true;
          }),
          child: GridWidget()),
      debugShowCheckedModeBanner: false,
    );
  }
}
