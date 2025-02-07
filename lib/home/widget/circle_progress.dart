import 'package:clear_tool/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

class CircleProgressBar extends StatefulWidget {
  final ValueNotifier<double> valueNotifier;
  const CircleProgressBar({Key? key, required this.valueNotifier})
      : super(key: key);

  @override
  _CircleProgressBarState createState() => _CircleProgressBarState();
}

class _CircleProgressBarState extends State<CircleProgressBar> {
  late Color color = Colors.blue;

  @override
  void initState() {
    widget.valueNotifier.addListener(() {
      initColor();
    });
    initColor();
    super.initState();
  }

  initColor() {
    final value = widget.valueNotifier.value;
    if (value > 90) {
      color = AppColor.red;
    } else if (value > 70) {
      color = Colors.orange;
    } else if (value > 30) {
      color = AppColor.yellow;
    } else {
      color = AppColor.mainColor;
    }
  }

  @override
  void dispose() {
    widget.valueNotifier.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SimpleCircularProgressBar(
          size: 130,
          startAngle: 90,
          progressColors: [color],
          valueNotifier: widget.valueNotifier,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '已使用',
              style: TextStyle(
                fontSize: 13,
                color: AppColor.textPrimary,
              ),
            ),
             Text(
              '${widget.valueNotifier.value.toStringAsFixed(0)}%',
              style:const TextStyle(
                fontSize: 26,
                color: AppColor.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
      ],
    );
  }
}
