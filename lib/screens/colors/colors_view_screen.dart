import 'dart:math';

import 'package:copic/common/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:copic/config/constants.dart';
import 'package:copic/common/functional.dart';
import 'package:copic/screens/colors/models.dart';

class ColorsViewScreen extends HookWidget {
  const ColorsViewScreen({Key? key}) : super(key: key);

  static const routeName = '/colors-view';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    TextTheme textTheme = Theme.of(context).textTheme;

    const colorsPerTab = 4;
    final tabsCount = (colors.length / colorsPerTab).ceil();
    final tabController = useTabController(initialLength: tabsCount);
    final isLastColorTab = useState(false);

    tabController.addListener(() {
      isLastColorTab.value = tabController.index == tabController.length - 1;
    });

    return Scaffold(
      body: Stack(
        children: [
          ...buildScaffoldBackground(context),
          Center(
            child: Container(
              height: 520,
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: kAppPaddingValue),
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0).copyWith(top: 20.0),
                        child: TabBarView(
                          controller: tabController,
                          // physics: const NeverScrollableScrollPhysics(
                          //     parent: ScrollPhysics()),
                          children: _buildTabs(
                            textTheme,
                            tabsCount,
                            colorsPerTab,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                      offset: const Offset(0, -35),
                      child: Button(
                        onPressed: () => _advanceShapes(tabController),
                        label: isLastColorTab.value
                            ? 'Start Guessing'
                            : 'Next Colors',
                      )),
                ],
              ),
            ),
          ),
          BottomNav(onPressed: () {}, icon: Icons.close_rounded),
        ],
      ),
    );
  }

  List<GridView> _buildTabs(TextTheme textTheme, int count, int colorsPerTab) {
    List<GridView> tabs = [];

    for (var i = 0; i < count; i++) {
      int start = i * colorsPerTab;
      int end = min(colors.length, start + colorsPerTab);
      final colorsOfInterest = colors.getRange(start, end);

      // debugPrint('$colorsOfInterest');
      tabs.add(GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 16 / 19,
        children: colorsOfInterest.map((colorShape) {
          return Column(
            children: [
              SvgPicture.asset(
                colorShape.svgUrl,
                width: 130,
                height: 130,
                color: colorShape.color,
              ),
              const SizedBox(height: 15),
              Text(
                colorShape.name.toUpperCase(),
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorShape.color, fontSize: 28, shadows: [
                  BoxShadow(
                    color: colorShape.shadowColor.withOpacity(0.36),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ]),
              ),
            ],
          );
        }).toList(),
      ));
    }

    return tabs;
  }

  void _advanceShapes(TabController controller) {
    if (controller.index == controller.length - 1) return;

    controller.animateTo(controller.index + 1,
        duration: const Duration(milliseconds: 500));
  }
}
