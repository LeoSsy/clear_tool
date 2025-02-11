import 'dart:async';

import 'package:clear_tool/const/colors.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/widget/empty_widget.dart';
import 'package:flutter/material.dart';

class MinePage extends StatefulWidget {
  const MinePage({Key? key}) : super(key: key);

  @override
  _MinePageState createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  StreamSubscription? streamSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppUtils.i18Translate('common.mine',context: context),
          style: const TextStyle(fontSize: 15, color: AppColor.textPrimary),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverFillRemaining(
            child: EmptyWidget(),
          )
        ],
      ),
    );
  }
}
