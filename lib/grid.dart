import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_finding_visualizer/patterns.dart';
import 'package:path_finding_visualizer/tutorial.dart';

enum CellState { eUnvisited, eVisited, eWall, ePath }

enum CellType { eDefault, eWall, eStart, eEnd }

enum AlgoType { eDijkstra, eAStar, eAStarDist, eBFS, eDFS }

const Map<AlgoType, String> gAlgoNames = {
  AlgoType.eDijkstra: "Dijkstra",
  AlgoType.eAStar: "A* (Manhattan)",
  AlgoType.eAStarDist: "A* (Diagonal)",
  AlgoType.eBFS: "Breadth First Search",
  AlgoType.eDFS: "Depth First Search",
};

enum PatternType { eRandom, eStair, eMazeH, eMazeV }

const Map<PatternType, String> gPatternNames = {
  PatternType.eRandom: "Random",
  PatternType.eStair: "Stair",
  PatternType.eMazeH: "Horizontal Maze",
  PatternType.eMazeV: "Vertical Maze",
};

enum GridMode { eStartChange, eEndChange, eWallPlace, eWallMove, eNoReaction }

class GraphData {
  GraphData(this.index, this.distance);
  int index;
  int distance;
}

class CellData {
  CellData(this.index, this.onMouseDown, this.onMouseEnter, this.onMouseExit,
      this.onMouseRelease, this.visitState, this.cellType);

  int index;
  void Function(int) onMouseDown;
  void Function(int) onMouseEnter;
  void Function(int) onMouseExit;
  void Function(int) onMouseRelease;
  CellState visitState;
  CellType cellType;
  double borderRadius = 0;
}

class CellDataNotifier extends ValueNotifier<CellData> {
  CellDataNotifier(CellData value) : super(value);

  int get index => value.index;

  bool shouldRestoreWall = false;

  CellState get visitState => value.visitState;
  set visitState(CellState visitState) {
    if (value.visitState != visitState) {
      value.visitState = visitState;
      notifyListeners();
    }
  }

  CellType get cellType => value.cellType;
  set cellType(CellType cellType) {
    if (value.cellType != cellType) {
      value.cellType = cellType;
      notifyListeners();
    }
  }

  void clear() {
    value.cellType = CellType.eDefault;
    value.visitState = CellState.eUnvisited;
    shouldRestoreWall = false;
    notifyListeners();
  }
}

class CellWidget extends StatelessWidget {
  const CellWidget(this.cellData, {Key? key}) : super(key: key);

  final ValueListenable<CellData> cellData;

  CellState get visitState => cellData.value.visitState;

  void _onMouseEnter(PointerEvent details) {
    if (details.down) {
      cellData.value.onMouseEnter(cellData.value.index);
    }
  }

  void _onMouseExit(PointerEvent details) {
    if (details.down) {
      cellData.value.onMouseExit(cellData.value.index);
    }
  }

  static const Map<CellState, Color> _colorMap = {
    CellState.eUnvisited: Colors.black,
    CellState.eVisited: Color.fromARGB(255, 94, 94, 94),
    CellState.ePath: Colors.amber,
    CellState.eWall: Colors.white
  };

  static const Map<CellType, Icon> _iconMap = {
    CellType.eDefault: Icon(null),
    CellType.eEnd: Icon(Icons.location_on),
    CellType.eStart: Icon(Icons.adjust),
    CellType.eWall: Icon(null)
  };

  Widget _getWidgetToDisplay() {
    if (GridWidget.sIsPathVisible) {
      return Container(
        decoration: BoxDecoration(
          color: _colorMap[cellData.value.visitState],
        ),
        child: Center(child: _iconMap[cellData.value.cellType]),
      );
    }

    return AnimatedContainer(
      decoration: BoxDecoration(
        color: _colorMap[cellData.value.visitState],
        borderRadius: BorderRadius.circular(cellData.value.borderRadius),
      ),
      duration: const Duration(milliseconds: 250),
      child: Center(child: _iconMap[cellData.value.cellType]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: _onMouseEnter,
        onExit: _onMouseExit,
        child: Listener(
          child: _getWidgetToDisplay(),
          onPointerDown: (eventDetails) {
            cellData.value.onMouseDown(cellData.value.index);
          },
          onPointerUp: (eventDetails) {
            cellData.value.onMouseRelease(cellData.value.index);
          },
        ));
  }

  static const int dimension = 25;
}

class GridSettings {
  GridSettings(
      this.isVisualizing,
      this.algoType,
      this.patternType,
      this.animSpeed,
      this.onVisualizePressed,
      this.onResetPressed,
      this.onHelpPressed,
      this.onAnimSpeedChanged,
      this.onAlgoTypeChanged,
      this.onPatternTypeChanged);

  bool isVisualizing;
  AlgoType algoType;
  PatternType patternType;
  double animSpeed;

  Function() onVisualizePressed;
  Function() onResetPressed;
  Function(BuildContext) onHelpPressed;
  Function(double) onAnimSpeedChanged;
  Function(AlgoType) onAlgoTypeChanged;
  Function(PatternType) onPatternTypeChanged;
}

class GridSettingsNotifier extends ValueNotifier<GridSettings> {
  GridSettingsNotifier(GridSettings value) : super(value);

  bool get isVisualizing => value.isVisualizing;

  set onVisualizePressed(void Function() onVisualizePressed) {
    value.onVisualizePressed = onVisualizePressed;
  }

  set onResetPressed(void Function() onResetPressed) {
    value.onResetPressed = onResetPressed;
  }

  set onHelpPressed(void Function(BuildContext) onHelpPressed) {
    value.onHelpPressed = onHelpPressed;
  }

  set onAnimSpeedChanged(void Function(double) onAnimSpeedChanged) {
    value.onAnimSpeedChanged = onAnimSpeedChanged;
  }

  set onAlgoTypeChanged(void Function(AlgoType) onAlgoTypeChanged) {
    value.onAlgoTypeChanged = onAlgoTypeChanged;
  }

  set onPatternTypeChagned(void Function(PatternType) onPatternTypeChanged) {
    value.onPatternTypeChanged = onPatternTypeChanged;
  }

  set isVisualizing(bool _isVisualizing) {
    value.isVisualizing = _isVisualizing;
    notifyListeners();
  }

  AlgoType get algoType => value.algoType;
  set algoType(AlgoType _algoType) {
    value.algoType = _algoType;
    notifyListeners();
  }

  PatternType get patternType => value.patternType;
  set patternType(PatternType _patternType) {
    value.patternType = _patternType;
    notifyListeners();
  }

  double get animSpeed => value.animSpeed;
  set animSpeed(double animSpeed) {
    value.animSpeed = animSpeed;
    notifyListeners();
  }
}

class GridSettingsWidget extends StatelessWidget {
  const GridSettingsWidget(this.gridSettings, {Key? key}) : super(key: key);

  final ValueListenable<GridSettings> gridSettings;
  static const TextStyle sTextStyle = TextStyle(fontSize: 18);

  bool get isVisualizing => gridSettings.value.isVisualizing;
  AlgoType get algoType => gridSettings.value.algoType;
  PatternType get patternType => gridSettings.value.patternType;

  Function() get onVisualizePressed => gridSettings.value.onVisualizePressed;
  Function() get onResetPressed => gridSettings.value.onResetPressed;
  Function(BuildContext) get onHelpPressed => gridSettings.value.onHelpPressed;

  Function(double) get onAnimSpeedChanged =>
      gridSettings.value.onAnimSpeedChanged;

  void _onAlgoTypeChanged(AlgoType? newAlgoType) {
    gridSettings.value.onAlgoTypeChanged(newAlgoType ?? AlgoType.eDijkstra);
  }

  void _onPatternTypeChanged(PatternType? newPatternType) {
    gridSettings.value
        .onPatternTypeChanged(newPatternType ?? PatternType.eRandom);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(alignment: WrapAlignment.center, children: [
      Container(
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 240),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                flex: 2,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Algorithm   ",
                      style: sTextStyle,
                    )),
              ),
              Flexible(
                  flex: 2,
                  child: DropdownButton<AlgoType>(
                      value: algoType,
                      isExpanded: true,
                      onChanged: isVisualizing ? null : _onAlgoTypeChanged,
                      items: <AlgoType>[
                        AlgoType.eDijkstra,
                        AlgoType.eAStar,
                        AlgoType.eAStarDist,
                        AlgoType.eBFS,
                        AlgoType.eDFS,
                      ].map<DropdownMenuItem<AlgoType>>((AlgoType algo) {
                        return DropdownMenuItem<AlgoType>(
                            value: algo,
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(gAlgoNames[algo] ?? "",
                                    style:
                                        const TextStyle(color: Colors.amber))));
                      }).toList()))
            ],
          )),
      Container(
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 240),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                flex: 1,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Walls  ",
                      style: sTextStyle,
                    )),
              ),
              Flexible(
                  flex: 2,
                  child: DropdownButton<PatternType>(
                      value: patternType,
                      isExpanded: true,
                      onChanged: isVisualizing ? null : _onPatternTypeChanged,
                      items: <PatternType>[
                        PatternType.eRandom,
                        PatternType.eStair,
                        PatternType.eMazeH,
                        PatternType.eMazeV
                      ].map<DropdownMenuItem<PatternType>>(
                          (PatternType pattern) {
                        return DropdownMenuItem<PatternType>(
                            value: pattern,
                            child: Align(
                                alignment: Alignment.center,
                                child: Text(gPatternNames[pattern] ?? "",
                                    style:
                                        const TextStyle(color: Colors.amber))));
                      }).toList()))
            ],
          )),
      Container(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 360),
          child: Align(
              alignment: Alignment.center,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    constraints:
                        const BoxConstraints(minWidth: 60, maxWidth: 60),
                    child: Align(
                        alignment: Alignment.center,
                        child: IconButton(
                            icon: const Icon(Icons.question_mark),
                            tooltip: "Tutorial",
                            onPressed: isVisualizing
                                ? null
                                : () => onHelpPressed(context)))),
                Container(
                    constraints:
                        const BoxConstraints(minWidth: 60, maxWidth: 60),
                    child: Align(
                        alignment: Alignment.center,
                        child: IconButton(
                            icon: const Icon(Icons.play_arrow_rounded),
                            iconSize: 40,
                            color: Colors.amber,
                            tooltip: "Visualize Algorithm",
                            onPressed:
                                isVisualizing ? null : onVisualizePressed))),
                Container(
                    constraints:
                        const BoxConstraints(minWidth: 60, maxWidth: 60),
                    child: Align(
                        alignment: Alignment.center,
                        child: IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: "Reset Grid",
                            onPressed: isVisualizing ? null : onResetPressed))),
              ]))),
      Container(
          constraints: const BoxConstraints(minWidth: 500, maxWidth: 500),
          child: Row(children: [
            const Flexible(child: Text("Animation Speed: ", style: sTextStyle)),
            Flexible(
                flex: 2,
                child: Slider(
                  label:
                      "Animation Speed: ${gridSettings.value.animSpeed.toStringAsFixed(2)}x",
                  activeColor: Colors.amber,
                  min: 0.25,
                  max: 3.0,
                  divisions: 11,
                  value: gridSettings.value.animSpeed,
                  onChanged: (value) => onAnimSpeedChanged(value),
                ))
          ])),
    ]);
  }
}

class GridWidget extends StatelessWidget {
  GridWidget({Key? key}) : super(key: key) {
    _gridSettings.onVisualizePressed = _onVisualizePressed;
    _gridSettings.onResetPressed = _resetGrid;
    _gridSettings.onHelpPressed = _onHelpPressed;
    _gridSettings.onAnimSpeedChanged = _onAnimSpeedChanged;
    _gridSettings.onAlgoTypeChanged = _onAlgorithmChanged;
    _gridSettings.onPatternTypeChagned = _onPatternTypeChanged;
    _populateCellDataList();
    _resetGrid();
  }

  void _onHelpPressed(BuildContext thisContext) {
    showTutorial(thisContext);
  }

  void _onVisualizePressed() {
    sIsPathVisible = false;
    _visualizePath();
  }

  void _visualizePath() {
    sShouldRecompute = false;

    switch (_gridSettings.algoType) {
      case AlgoType.eDijkstra:
      case AlgoType.eAStar:
      case AlgoType.eAStarDist:
        {
          _findPathWeighted();
          break;
        }
      case AlgoType.eBFS:
        {
          _bfs();
          break;
        }
      case AlgoType.eDFS:
        {
          _dfs();
          break;
        }
    }
  }

  int heuristic(int idx) {
    switch (_gridSettings.algoType) {
      case AlgoType.eAStar:
        {
          int endX = sEndCellIndex ~/ sColumns;
          int endY = sEndCellIndex % sColumns;
          int x = idx ~/ sColumns;
          int y = idx % sColumns;
          return (x - endX).abs() + (y - endY).abs();
        }
      case AlgoType.eAStarDist:
        {
          int endX = sEndCellIndex ~/ sColumns;
          int endY = sEndCellIndex % sColumns;
          int x = idx ~/ sColumns;
          int y = idx % sColumns;
          return sqrt((x - endX) * (x - endX) + (y - endY) * (y - endY))
              .toInt();
        }
      case AlgoType.eDijkstra:
        return 0;
      default:
        return 0;
    }
  }

  // distance from start cell, for animation timing purposes
  int animDist(int idx) {
    int startX = sStartCellIndex ~/ sColumns;
    int startY = sStartCellIndex % sColumns;
    int x = idx ~/ sColumns;
    int y = idx % sColumns;
    return (x - startX).abs() + (y - startY).abs();
  }

  void _findPathWeighted() async {
    if (_gridSettings.isVisualizing) return;

    if (!sIsPathVisible) setVisualizing(true);

    List<int> distances =
        List.generate(sRows * sColumns, ((index) => sMaxDist), growable: false);

    distances[sStartCellIndex] = 0;

    List<int> previousNode =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    HeapPriorityQueue<GraphData> minHeap =
        HeapPriorityQueue<GraphData>((p0, p1) {
      int fScore0 = p0.distance;
      int fScore1 = p1.distance;
      if (fScore0 > fScore1) return 1;
      if (fScore0 == fScore1) return 0;
      return -1;
    });

    minHeap.add(GraphData(sStartCellIndex, 0));

    List<int> visitOrder =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    int currVisitIdx = 0;

    BoolList visited = BoolList(sRows * sColumns);

    while (minHeap.isNotEmpty && !visited[sEndCellIndex]) {
      if (sShouldRecompute) return;

      GraphData currNode = minHeap.removeFirst();
      int currIdx = currNode.index;

      getNeighborIndices(currIdx).forEach((element) {
        if (visited[element]) return;

        int altDistance = distances[currIdx] + 1;
        if (altDistance < distances[element]) {
          distances[element] = altDistance;
          previousNode[element] = currIdx;
          minHeap
              .add(GraphData(element, distances[element] + heuristic(element)));
        }
      });

      visited[currIdx] = true;
      visitOrder[currVisitIdx++] = currIdx;
    }

    List<int> revPath = [];

    // Only display a path if there is one
    if (previousNode[sEndCellIndex] != -1) {
      int currPath = sEndCellIndex;
      while (currPath != -1) {
        revPath.add(currPath);
        currPath = previousNode[currPath];
      }
    }

    await _showCellStates(visitOrder, distances, visited, revPath);
    setVisualizing(false);
  }

  void _bfs() async {
    if (_gridSettings.isVisualizing) return;

    if (!sIsPathVisible) setVisualizing(true);

    List<int> previousNode =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    List<int> visitOrder =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    int currVisitIdx = 0;

    Queue<int> bfsQueue = Queue.from({sStartCellIndex});
    int currIdx = -1;

    BoolList visited = BoolList(sRows * sColumns);
    BoolList seen = BoolList(sRows * sColumns);

    seen[sStartCellIndex] = true;

    while (bfsQueue.isNotEmpty && !visited[sEndCellIndex]) {
      if (sShouldRecompute) return;
      currIdx = bfsQueue.removeFirst();

      List<int> neighbours = getNeighborIndices(currIdx);
      for (int i = 0; i < neighbours.length; ++i) {
        int idx = neighbours[i];
        if (visited[idx] || seen[idx]) continue;

        seen[idx] = true;
        previousNode[idx] = currIdx;
        bfsQueue.add(idx);
      }

      visited[currIdx] = true;
      visitOrder[currVisitIdx++] = currIdx;
    }

    List<int> revPath = [];

    // Only display a path if there is one
    if (previousNode[sEndCellIndex] != -1) {
      int currPath = sEndCellIndex;
      while (currPath != -1) {
        revPath.add(currPath);
        currPath = previousNode[currPath];
      }
    }

    await _showNonWeightedCellStates(visitOrder, visited, revPath);
    setVisualizing(false);
  }

  void _dfs() async {
    if (_gridSettings.isVisualizing) return;

    if (!sIsPathVisible) setVisualizing(true);

    List<int> previousNode =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    List<int> visitOrder =
        List.generate(sRows * sColumns, ((index) => -1), growable: false);

    int currVisitIdx = 0;

    // use it as a stack
    Queue<int> dfsQueue = Queue.from({sStartCellIndex});
    int currIdx = -1;

    BoolList visited = BoolList(sRows * sColumns);
    BoolList seen = BoolList(sRows * sColumns);

    seen[sStartCellIndex] = true;

    while (dfsQueue.isNotEmpty && !visited[sEndCellIndex]) {
      if (sShouldRecompute) return;
      currIdx = dfsQueue.removeFirst();

      List<int> neighbours = getNeighborIndices(currIdx);
      for (int i = 0; i < neighbours.length; ++i) {
        int idx = neighbours[i];
        if (visited[idx] || seen[idx]) continue;

        seen[idx] = true;
        previousNode[idx] = currIdx;
        dfsQueue.addFirst(idx);
      }

      visited[currIdx] = true;
      visitOrder[currVisitIdx++] = currIdx;
    }

    List<int> revPath = [];

    // Only display a path if there is one
    if (previousNode[sEndCellIndex] != -1) {
      int currPath = sEndCellIndex;
      while (currPath != -1) {
        revPath.add(currPath);
        currPath = previousNode[currPath];
      }
    }

    await _showNonWeightedCellStates(visitOrder, visited, revPath);
    setVisualizing(false);
  }

  Future<void> _showCellStates(List<int> visitOrder, List<int> distances,
      BoolList visited, List<int> revPath) async {
    // if the path is already visible, we don't need to animate, just set all the states

    if (visitOrder.isEmpty) {
      _clearVisitStates();
      return;
    }

    if (sIsPathVisible) {
      for (int i = 0; i < sRows * sColumns; ++i) {
        if (sShouldRecompute) return;
        if (_cellDataList[i].visitState == CellState.eWall) continue;
        _cellDataList[i].visitState =
            visited[i] ? CellState.eVisited : CellState.eUnvisited;
      }

      for (int i = 0; i < revPath.length; ++i) {
        if (sShouldRecompute) return;
        _cellDataList[revPath[i]].visitState = CellState.ePath;
      }
    }
    // otherwise, we need to animate, with each step being determined by the distance
    else {
      int originalDuration = 30;
      int currDist = 0;
      int currNode = visitOrder[0];
      int visitIdx = 0;
      _clearVisitStates();

      while (currNode != -1 && visitIdx < sRows * sColumns - 1) {
        if (currDist >= distances[currNode] + heuristic(currNode)) {
          _cellDataList[currNode].visitState = CellState.eVisited;
          currNode = visitOrder[++visitIdx];
        } else {
          currDist = distances[currNode] + heuristic(currNode);
          await _delay(originalDuration ~/ _gridSettings.animSpeed);
        }
      }

      for (int i = revPath.length - 1; i >= 0; --i) {
        _cellDataList[revPath[i]].visitState = CellState.ePath;
        await _delay(originalDuration ~/ _gridSettings.animSpeed);
      }

      sIsPathVisible = true;
    }
  }

  Future<void> _showNonWeightedCellStates(
      List<int> visitOrder, BoolList visited, List<int> revPath) async {
    if (visitOrder.isEmpty) {
      _clearVisitStates();
      return;
    }

    if (sIsPathVisible) {
      for (int i = 0; i < sRows * sColumns; ++i) {
        if (sShouldRecompute) return;
        if (_cellDataList[i].visitState == CellState.eWall) continue;
        _cellDataList[i].visitState =
            visited[i] ? CellState.eVisited : CellState.eUnvisited;
      }

      for (int i = 0; i < revPath.length; ++i) {
        if (sShouldRecompute) return;
        _cellDataList[revPath[i]].visitState = CellState.ePath;
      }
    }
    // otherwise, we need to animate, with each step being determined by the distance
    else {
      int originalDuration = 30;
      int currNode = visitOrder[0];
      int visitIdx = 0;
      _clearVisitStates();

      while (currNode != -1 && visitIdx < sRows * sColumns - 1) {
        _cellDataList[currNode].visitState = CellState.eVisited;
        currNode = visitOrder[++visitIdx];
        await Future.delayed(
            Duration(microseconds: 3 ~/ _gridSettings.animSpeed));
      }

      for (int i = revPath.length - 1; i >= 0; --i) {
        _cellDataList[revPath[i]].visitState = CellState.ePath;
        await _delay(originalDuration ~/ _gridSettings.animSpeed);
      }

      sIsPathVisible = true;
    }
  }

  Future<void> _delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  void setVisualizing(bool isVisualizing) {
    _gridSettings.isVisualizing = isVisualizing;
  }

  void _onAlgorithmChanged(AlgoType algo) {
    _gridSettings.algoType = algo;
  }

  void _onPatternTypeChanged(PatternType pattern) {
    sIsPathVisible = false;
    _gridSettings.patternType = pattern;
    switch (pattern) {
      case PatternType.eRandom:
        {
          _addWalls(getRandomIndices(sRows, sColumns));
          break;
        }
      case PatternType.eStair:
        {
          _addWalls(getStairIndices(sRows, sColumns));
          break;
        }
      case PatternType.eMazeH:
        {
          _addWalls(getMazeHIndices(sRows, sColumns));
          break;
        }
      case PatternType.eMazeV:
        {
          _addWalls(getMazeVIndices(sRows, sColumns));
          break;
        }
    }
  }

  Future<void> _addWalls(List<int> wallIndices) async {
    _clearGrid(onlyClearWalls: true);
    _clearVisitStates();

    for (int i = 0; i < wallIndices.length; ++i) {
      int idx = wallIndices[i];
      if (idx == sStartCellIndex || idx == sEndCellIndex) continue;
      _toggleWall(idx);
      //await Future.delayed(const Duration(microseconds: 1));
    }
  }

  void _populateCellDataList() {
    _cellDataList.clear();
    for (int i = 0; i < sRows * sColumns; ++i) {
      CellDataNotifier cdn = CellDataNotifier(CellData(
          i,
          _onGridCellTap,
          _onGridCellEnter,
          _onGridCellExit,
          _onGridCellMouseRelease,
          CellState.eUnvisited,
          CellType.eDefault));
      _cellDataList.add(cdn);
    }
  }

  void _clearGrid({bool onlyClearWalls = false}) {
    for (int i = 0; i < sRows * sColumns; ++i) {
      if (!onlyClearWalls || _isWall(i)) _cellDataList[i].clear();
    }
  }

  void _clearVisitStates() {
    for (int i = 0; i < sRows * sColumns; ++i) {
      if (_cellDataList[i].cellType != CellType.eWall) {
        _cellDataList[i].visitState = CellState.eUnvisited;
      }
    }
  }

  void _resetGrid() {
    sIsPathVisible = false;
    _clearGrid();

    sStartCellIndex = getIndex(sRows ~/ 2, sColumns ~/ 4);
    sEndCellIndex = getIndex(sRows ~/ 2, 3 * sColumns ~/ 4);

    _cellDataList[sStartCellIndex].cellType = CellType.eStart;
    _cellDataList[sEndCellIndex].cellType = CellType.eEnd;
  }

  void _onAnimSpeedChanged(double newAnimSpeed) {
    _gridSettings.animSpeed = newAnimSpeed;
  }

  bool _isWall(int index) {
    return _cellDataList[index].visitState == CellState.eWall ||
        _cellDataList[index].cellType == CellType.eWall;
  }

  bool _shouldRestoreWall(int index) {
    return _cellDataList[index].shouldRestoreWall;
  }

  void _changeStart(int newIndex) {
    _cellDataList[sStartCellIndex].cellType =
        _shouldRestoreWall(sStartCellIndex)
            ? CellType.eWall
            : CellType.eDefault;
    _cellDataList[sStartCellIndex].visitState =
        _shouldRestoreWall(sStartCellIndex)
            ? CellState.eWall
            : CellState.eUnvisited;

    _cellDataList[newIndex].cellType = CellType.eStart;
    _cellDataList[newIndex].visitState = CellState.eUnvisited;
    sStartCellIndex = newIndex;
  }

  void _changeEnd(int newIndex) {
    _cellDataList[sEndCellIndex].cellType =
        _shouldRestoreWall(sEndCellIndex) ? CellType.eWall : CellType.eDefault;
    _cellDataList[sEndCellIndex].visitState = _shouldRestoreWall(sEndCellIndex)
        ? CellState.eWall
        : CellState.eUnvisited;
    _cellDataList[newIndex].cellType = CellType.eEnd;
    _cellDataList[newIndex].visitState = CellState.eUnvisited;
    sEndCellIndex = newIndex;
  }

  void _toggleWall(int cellIndex) {
    if (_isWall(cellIndex)) {
      _cellDataList[cellIndex].cellType = CellType.eDefault;
      _cellDataList[cellIndex].visitState = CellState.eUnvisited;
      _cellDataList[cellIndex].shouldRestoreWall = false;
    } else if (_cellDataList[cellIndex].cellType == CellType.eDefault) {
      _cellDataList[cellIndex].cellType = CellType.eWall;
      _cellDataList[cellIndex].visitState = CellState.eWall;
      _cellDataList[cellIndex].shouldRestoreWall = true;
    }
  }

  void _onGridCellTap(int cellIndex) {
    if (cellIndex == sStartCellIndex) {
      sGridMode = GridMode.eStartChange;
    } else if (cellIndex == sEndCellIndex) {
      sGridMode = GridMode.eEndChange;
    } else {
      sGridMode = GridMode.eWallPlace;
    }
  }

  void _onGridCellEnter(int cellIndex) {
    // mouse entered while mouse button is down
    if (cellIndex == sStartCellIndex || cellIndex == sEndCellIndex) return;
    if (_gridSettings.isVisualizing && !sIsPathVisible) return;

    switch (sGridMode) {
      case GridMode.eStartChange:
        {
          _changeStart(cellIndex);
          break;
        }
      case GridMode.eEndChange:
        {
          _changeEnd(cellIndex);
          break;
        }
      case GridMode.eWallPlace:
        {
          // shouldn't happen
          break;
        }
      case GridMode.eWallMove:
        {
          _toggleWall(cellIndex);
          break;
        }
      case GridMode.eNoReaction:
        // shouldn't happen
        return;
    }

    if (sIsPathVisible) {
      sShouldRecompute = true;
      _visualizePath();
    }
  }

  void _onGridCellExit(int cellIndex) {
    if (sGridMode == GridMode.eWallPlace) {
      sGridMode = GridMode.eWallMove;
      _toggleWall(cellIndex);
    }
  }

  void _onGridCellMouseRelease(int cellIndex) {
    if (_gridSettings.isVisualizing && !sIsPathVisible) {
      sGridMode = GridMode.eNoReaction;
      return;
    }

    // start and end will not need to be handled here, just walls
    if (sGridMode == GridMode.eWallPlace) {
      _toggleWall(cellIndex);

      if (sIsPathVisible) {
        sShouldRecompute = true;
        _visualizePath();
      }
    }

    sGridMode = GridMode.eNoReaction;
  }

  bool isValidCell(int x, int y) {
    bool isWithinBounds = (x >= 0 && y >= 0 && x < sRows && y < sColumns);
    return isWithinBounds &&
        _cellDataList[getIndex(x, y)].cellType != CellType.eWall;
  }

  List<int> getNeighborIndices(int idx) {
    List<int> neighborIndices = [];
    int x = idx ~/ sColumns;
    int y = idx % sColumns;

    if (!isValidCell(x, y)) return neighborIndices;

    if (isValidCell(x, y + 1)) neighborIndices.add(getIndex(x, y + 1));
    if (isValidCell(x, y - 1)) neighborIndices.add(getIndex(x, y - 1));
    if (isValidCell(x + 1, y)) neighborIndices.add(getIndex(x + 1, y));
    if (isValidCell(x - 1, y)) neighborIndices.add(getIndex(x - 1, y));

    return neighborIndices;
  }

  static int getIndex(int row, int column) {
    return (row * sColumns) + column;
  }

  void _setGridDimensions(BuildContext context) {
    MediaQueryData queryData = MediaQuery.of(context);
    int cols = queryData.size.width ~/ CellWidget.dimension;
    int rows = (queryData.size.height * 0.75) ~/ CellWidget.dimension;

    if (rows == sRows && cols == sColumns) {
      return; // don't erase grid if nothing changed
    }

    sRows = rows;
    sColumns = cols;
    sMaxDist = sRows * sColumns;
    _populateCellDataList();
    _resetGrid();
  }

  @override
  Widget build(BuildContext context) {
    _setGridDimensions(context);
    return DefaultTabController(
        initialIndex: 0,
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Pathfinding Algorithm Visualizer"),
            ),
            body: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<GridSettings>(
                      valueListenable: _gridSettings,
                      builder: (context, value, child) {
                        return GridSettingsWidget(_gridSettings);
                      }),
                  Expanded(
                      flex: 12,
                      child: Container(
                          constraints: BoxConstraints(
                              maxWidth: (48 * sColumns).toDouble()),
                          child: GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: sColumns,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                              children: _cellDataList
                                  .map((e) => ValueListenableBuilder<CellData>(
                                      valueListenable: e,
                                      builder: (context, value, child) {
                                        return Container(
                                            constraints: const BoxConstraints(
                                                minHeight: 10, minWidth: 10),
                                            child:
                                                Center(child: CellWidget(e)));
                                      }))
                                  .toList()))),
                ])));
  }

  static int sRows = 25;
  static int sColumns = 60;
  static int sMaxDist = sRows * sColumns;

  static int sStartCellIndex = getIndex(sRows ~/ 2, sColumns ~/ 4);
  static int sEndCellIndex = getIndex(sRows ~/ 2, 3 * sColumns ~/ 4);
  static bool sIsPathVisible = false;

  final List<CellDataNotifier> _cellDataList = [];
  final GridSettingsNotifier _gridSettings = GridSettingsNotifier(GridSettings(
      false,
      AlgoType.eDijkstra,
      PatternType.eRandom,
      1,
      () => null,
      () => null,
      (context) => null,
      (animSpeed) => null,
      (algoType) => null,
      (patternType) => null));

  static bool sShouldRecompute = false;
  static GridMode sGridMode = GridMode.eNoReaction;
}
