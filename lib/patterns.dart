import 'dart:math';

enum Orientation { eHorizontal, eVertical }

List<int> getRandomIndices(int numRows, int numColumns) {
  List<int> randomIndices = [];

  for (int i = 0; i < numRows; ++i) {
    for (int j = 0; j < numColumns; ++j) {
      int currIdx = (i * numColumns) + j;

      if (i == 0 || j == 0 || i == numRows - 1 || j == numColumns - 1) {
        randomIndices.add(currIdx);
      } else if (Random().nextDouble() > 0.8) {
        randomIndices.add(currIdx);
      }
    }
  }

  return randomIndices;
}

List<int> getStairIndices(int numRows, int numColumns) {
  List<int> stairIndices = [];
  int row = numRows - 1;
  bool shouldGoDown = false;

  for (int col = 0; col < numColumns - 1; ++col) {
    stairIndices.add(row * numColumns + col);

    if (!shouldGoDown) {
      --row;
      shouldGoDown = row == 1;
    } else {
      ++row;
      shouldGoDown = row != numRows - 2;
    }
  }

  return stairIndices;
}

List<int> _divide(List<int> currList, int xMin, int xMax, int yMin, int yMax,
    int numRows, int numColumns, Orientation orientation) {
  if (xMax - xMin <= 2 || yMax - yMin <= 2) return currList;

  if (orientation == Orientation.eHorizontal) {
    int currentRow =
        xMin + 1 + ((Random().nextInt((xMax - 2 - xMin)) ~/ 2) * 2);
    int randomCol = yMin + ((Random().nextInt((yMax - yMin)) ~/ 2) * 2);

    for (int col = yMin; col <= yMax; ++col) {
      if (col == randomCol) continue;
      currList.add(currentRow * numColumns + col);
    }

    Orientation nextOrientation = (currentRow - 2 - xMin > yMax - yMin)
        ? Orientation.eHorizontal
        : Orientation.eVertical;
    _divide(currList, xMin, currentRow - 1, yMin, yMax, numRows, numColumns,
        nextOrientation);

    nextOrientation = (xMax - (currentRow + 2) > yMax - yMin)
        ? Orientation.eHorizontal
        : Orientation.eVertical;

    _divide(currList, currentRow + 1, xMax, yMin, yMax, numRows, numColumns,
        nextOrientation);
  } else {
    int currentCol =
        yMin + 1 + ((Random().nextInt((yMax - 2 - yMin)) ~/ 2) * 2);
    int randomRow = xMin + ((Random().nextInt((xMax - xMin)) ~/ 2) * 2);

    for (int row = xMin; row <= xMax; ++row) {
      if (row == randomRow) continue;
      currList.add(row * numColumns + currentCol);
    }

    Orientation nextOrientation = (currentCol - 2 - yMin < xMax - xMin)
        ? Orientation.eHorizontal
        : Orientation.eVertical;
    _divide(currList, xMin, xMax, yMin, currentCol - 1, numRows, numColumns,
        nextOrientation);

    nextOrientation = (yMax - (currentCol + 2) < xMax - xMin)
        ? Orientation.eHorizontal
        : Orientation.eVertical;

    _divide(currList, xMin, xMax, currentCol + 1, yMax, numRows, numColumns,
        nextOrientation);
  }

  return currList;
}

List<int> _getMazeIndices(
    int numRows, int numColumns, Orientation orientation) {
  List<int> mazeIndices = [];

  for (int i = 0; i < numRows; ++i) {
    for (int j = 0; j < numColumns; ++j) {
      int currIdx = (i * numColumns) + j;

      // add borders
      if (i == 0 || j == 0 || i == numRows - 1 || j == numColumns - 1) {
        mazeIndices.add(currIdx);
      }
    }
  }

  _divide(mazeIndices, 1, numRows - 2, 1, numColumns - 2, numRows, numColumns,
      orientation);

  return mazeIndices;
}

List<int> getMazeHIndices(int numRows, int numColumns) {
  return _getMazeIndices(numRows, numColumns, Orientation.eHorizontal);
}

List<int> getMazeVIndices(int numRows, int numColumns) {
  return _getMazeIndices(numRows, numColumns, Orientation.eVertical);
}
