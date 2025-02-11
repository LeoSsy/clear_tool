import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String? title;
  const EmptyWidget({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/common/empty.png'),
        Text(
          title ?? AppUtils.i18Translate('common.noData',context: context),
          style: const TextStyle(
            fontSize: 14,
            color: AppColor.subTitle999,
          ),
        )
      ],
    );
  }
}
