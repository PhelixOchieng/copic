import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:copic/common/common.dart';
import 'package:copic/common/storage/storage.dart';
import 'package:copic/common/models/color_shape.dart';
import 'package:copic/config/constants.dart';

import './widgets/widgets.dart';

class ColorsGuessScreen extends StatefulHookWidget {
  const ColorsGuessScreen({Key? key}) : super(key: key);

  static const routeName = '/colors-guess';

  @override
  State<ColorsGuessScreen> createState() => _ColorsGuessScreenState();
}

class _ColorsGuessScreenState extends State<ColorsGuessScreen> {
  List<ColorShape> _colorsToTest = colors..shuffle();

  ValueNotifier<Duration>? _timePerColor;
  TabController? _tabController;
  AnimationController? _animationController;

  DateTime _lastColorAdvance = DateTime.now();

  int _correctGuesses = 0;
  bool _isEndGame = false;

  @override
  void initState() {
    super.initState();

    _colorsToTest =
        _colorsToTest.getRange(0, min(_colorsToTest.length, 10)).toList();

    _setTimePerColor();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Color primaryColor = Theme.of(context).primaryColor;

    _timePerColor = useState(const Duration(seconds: 5));
    _tabController = useTabController(initialLength: _colorsToTest.length + 1);
    _animationController = useAnimationController(
      duration: _timePerColor!.value,
    )..addStatusListener((status) {
        // debugPrint('State Change: $status');
        if (status != AnimationStatus.completed) return;

        DateTime now = DateTime.now();
        Duration thresholdTime =
            _timePerColor!.value - const Duration(milliseconds: 50);
        if (now.difference(_lastColorAdvance) < thresholdTime) return;

        _playWrong();
        _advanceToNextColor();
        _lastColorAdvance = now;
      });

    double animationValue = useAnimation(_animationController!);
    if (!_isEndGame && !_animationController!.isAnimating) {
      _animationController!.forward();
    }

    return Scaffold(
      body: Stack(children: [
        ...buildScaffoldBackground(context),
        Center(
          child: Container(
            height: !_isEndGame ? 540 : 450,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: kAppPaddingValue),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    !_isEndGame
                        ? LinearProgressIndicator(
                            value: animationValue,
                            minHeight: 10,
                            color: primaryColor,
                            backgroundColor: primaryColor.withOpacity(0.1))
                        : const SizedBox.shrink(),
                    const SizedBox(height: 40),
                    Expanded(
                      child: Column(
                        children: [
                          ..._buildInstructions(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(
                                  parent: ScrollPhysics()),
                              children: _buildTabs(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    !_isEndGame
                        ? Text(
                            '${_tabController!.index + 1} of ${_colorsToTest.length}',
                          )
                        : const SizedBox.shrink()
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildTabs() {
    List<Widget> tabs = [];

    for (var i = 0; i < _colorsToTest.length; i++) {
      ColorShape colorShape = _colorsToTest[i];

      tabs.add(ColorShapeTab(
          colorShape: colorShape,
          colorsToTest: _colorsToTest,
          onAdvance: (ColorShape guessedColor) {
            if (guessedColor.name == colorShape.name) {
              _playCorrect();

              setState(() {
                _correctGuesses += 1;
              });
            } else {
              _playWrong();
            }

            _animationController?.stop();
            Future.delayed(
              const Duration(milliseconds: 300),
              () => _advanceToNextColor(),
            );
          }));
    }

    tabs.add(CompletionTab(
      score: _correctGuesses,
      total: _colorsToTest.length,
    ));
    return tabs;
  }

  List<Widget> _buildInstructions() {
    if (!_isEndGame) {
      return [
        const Text('Which color is shown below?'),
        const SizedBox(height: 10)
      ];
    }

    return [const SizedBox.shrink()];
  }

  void _advanceToNextColor() {
    TabController tabController = _tabController!;
    AnimationController animationController = _animationController!;

    if (tabController.index == _colorsToTest.length - 1) {
      Future.delayed(const Duration(milliseconds: 600), () => _playGameEnd());

      setState(() {
        _isEndGame = true;
      });
    }

    tabController.index =
        min(_colorsToTest.length + 1, tabController.index + 1);

    if (_isEndGame) {
      animationController.stop();
    } else {
      animationController.reset();
    }
  }

  Future<void> _setTimePerColor() async {
    String difficulty = await LocalStorage.read('difficulty') ?? 'Easy';
    Duration timePerColor = const Duration(seconds: 5);

    switch (difficulty.toLowerCase()) {
      case 'medium':
        timePerColor = const Duration(seconds: 3);
        break;
      case 'hard':
        timePerColor = const Duration(seconds: 2);
        break;
      default:
    }

    _timePerColor?.value = timePerColor;
  }

  Future<void> _playCorrect() async {
    await TonePlayer.instance.play('right_answer.mp3');
  }

  Future<void> _playWrong() async {
    await TonePlayer.instance.play('wrong_answer.mp3', volume: 0.8);
  }

  Future<void> _playGameEnd() async {
    await TonePlayer.instance.play('game_over.mp3', volume: 0.8);
  }
}
