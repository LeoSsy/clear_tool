import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';

class ClearPage extends StatefulWidget {
  const ClearPage({Key? key}) : super(key: key);

  @override
  _ClearPageState createState() => _ClearPageState();
}

class _ClearPageState extends State<ClearPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgColor,
      appBar: AppBar(
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Image.asset(
              'assets/images/common/back.png',
            ),
          ),
        ),
        title: Text(
          AppUtils.i18Translate('home.smartClear'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList.list(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Text(
                      '检测完成',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const LinearProgressIndicator(
                            value: 10, color: AppColor.mainColor),
                        const SizedBox(width: 6),
                        Text(
                          '100%',
                          style: TextStyle(
                            fontSize: 7,
                            color: AppColor.textPrimary,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
