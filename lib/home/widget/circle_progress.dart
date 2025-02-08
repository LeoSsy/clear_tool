import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

class CircleProgressBar extends StatelessWidget {
  final Color color;
  final ValueNotifier<double> valueNotifier;
  const CircleProgressBar(
      {Key? key, required this.color, required this.valueNotifier})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(167.autoSize! / 2),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 1),
                color: color,
                blurRadius: 23.5,
                blurStyle: BlurStyle.normal,
              )
            ],
          ),
          width: 197.autoSize!,
          height: 197.autoSize!,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(167.autoSize! / 2),
            color: Colors.white,
          ),
          width: 167.autoSize!,
          height: 167.autoSize!,
        ),
        SimpleCircularProgressBar(
          size: 160.autoSize!,
          startAngle: 90,
          progressColors: [color],
          valueNotifier: ValueNotifier(90),
          backColor: Colors.white,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppUtils.i18Translate('home.useSpace'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              '${valueNotifier.value.toStringAsFixed(0)}%',
              style: const TextStyle(
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
