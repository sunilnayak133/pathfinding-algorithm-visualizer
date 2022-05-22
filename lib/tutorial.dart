import 'package:flutter/material.dart';

Future<void> _showCustomDialog(
    BuildContext context,
    Widget Function(BuildContext, Animation<double>, Animation<double>)
        pageBuilder) async {
  await showGeneralDialog(
      context: context,
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: pageBuilder,
      transitionBuilder: _transitionBuilder);
}

void showTutorial(BuildContext context) async {
  await _showCustomDialog(context, _algoBuilder);
}

Widget _transitionBuilder(BuildContext _, Animation<double> anim,
    Animation<double> __, Widget child) {
  Tween<double> tween;
  if (anim.status == AnimationStatus.reverse) {
    tween = Tween(
      begin: 1,
      end: 0,
    );
  } else {
    tween = Tween(begin: 0, end: 1);
  }

  return ScaleTransition(
    scale: tween.animate(anim),
    child: FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

Widget _customDialog(
    BuildContext context,
    String text,
    String imgPath,
    Widget Function(BuildContext, Animation<double>, Animation<double>)?
        prevBuilder,
    Widget Function(BuildContext, Animation<double>, Animation<double>)?
        nextBuilder) {
  return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0)), //this right here
      child: SingleChildScrollView(
          child: Container(
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Text(text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24)),
                const Spacer(),
                imgPath != "" ? Image.asset(imgPath) : const Spacer(),
                const Spacer(),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  children: [
                    prevBuilder != null
                        ? TextButton(
                            style: TextButton.styleFrom(
                                fixedSize: const Size(150, 40),
                                backgroundColor: Colors.black,
                                primary: Colors.amber),
                            onPressed: () async {
                              Navigator.of(context, rootNavigator: true).pop();
                              await _showCustomDialog(context, prevBuilder);
                            },
                            child: const Text("Back"))
                        : const SizedBox.shrink(),
                    TextButton(
                        style: TextButton.styleFrom(
                            fixedSize: const Size(150, 40),
                            backgroundColor: Colors.black,
                            primary: Colors.amber),
                        onPressed: (() =>
                            {Navigator.of(context, rootNavigator: true).pop()}),
                        child: const Text("End Tutorial")),
                    nextBuilder != null
                        ? TextButton(
                            style: TextButton.styleFrom(
                                fixedSize: const Size(150, 40),
                                backgroundColor: Colors.black,
                                primary: Colors.amber),
                            onPressed: () async {
                              Navigator.of(context, rootNavigator: true).pop();
                              await _showCustomDialog(context, nextBuilder);
                            },
                            child: const Text("Next"))
                        : const SizedBox.shrink()
                  ],
                )
              ]))));
}

Widget _algoBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(context, "Choose an algorithm to start",
      "images/algoTut.gif", null, _patternBuilder);
}

Widget _patternBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(context, "Set up walls as needed",
      "images/patternTut.gif", _algoBuilder, _visualizeBuilder);
}

Widget _visualizeBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(
      context,
      "And then hit play to\nvisualize the algorithm!",
      "images/visTut.gif",
      _patternBuilder,
      _animSpeedBuilder);
}

Widget _animSpeedBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(context, "Change the animation speed\nusing this slider",
      "images/animSpeedTut.gif", _visualizeBuilder, _startEndMoveBuilder);
}

Widget _startEndMoveBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(
      context,
      "Move the start and end by\nclicking on them and dragging them wherever",
      "images/startEndTut.gif",
      _animSpeedBuilder,
      _manualWallBuilder);
}

Widget _manualWallBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(
      context,
      "You can also toggle walls by\nclicking and dragging anywhere on the grid",
      "images/manualWallTut.gif",
      _startEndMoveBuilder,
      _revisualizeBuilder);
}

Widget _revisualizeBuilder(
    BuildContext context, Animation<double> _, Animation<double> __) {
  return _customDialog(
      context,
      "Moving anything after the visualization\nwill update the path.",
      "images/dynamicVisTut.gif",
      _manualWallBuilder,
      null);
}
