import 'package:clear_tool/extension/number_extension.dart';
import 'package:clear_tool/home/home_screen.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:clear_tool/utils/permission_utils.dart';
import 'package:flutter/material.dart';

class TabbarScreen extends StatefulWidget {
  const TabbarScreen({Key? key}) : super(key: key);

  @override
  _TabbarScreenState createState() => _TabbarScreenState();
}

class _TabbarScreenState extends State<TabbarScreen> {
  final _tabTitles = [
    "首页",
    "",
    "我的",
  ];

  final _images = [
    "assets/images/tab/tab_home_icon",
    "",
    "assets/images/tab/tab_mine_icon",
  ];

  int _currentIndex = 0;

  late PageController pageController;
  final List<Widget> _pages = [];


  @override
  void initState() {
    super.initState();
     pageController = PageController();
    _pages
      ..add(const HomeScreen())
      ..add(const SizedBox())
      ..add(const HomeScreen());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AppUtils.pixelRatio = MediaQuery.of(context).devicePixelRatio;
      AppUtils.screenW = MediaQuery.of(context).size.width;
      AppUtils.screenH = MediaQuery.of(context).size.height;
      AppUtils.safeAreapadding = MediaQuery.of(context).padding;
    });
    checkPermission();
  }

  void checkPermission() async{
   final havePermission =  await PermissionUtils.checkPhotosPermisson();
   if (havePermission) {
     
   }
  }


  @override
  Widget build(BuildContext context) {
    AppUtils.globalContext = context;
    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Theme(
            data: Theme.of(context).copyWith(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              iconSize: 25,
              unselectedItemColor: Colors.black,
              selectedItemColor: const Color.fromRGBO(5, 122, 229, 1),
              onTap: (index) => _onTap(index),
              type: BottomNavigationBarType.fixed,
              items: __buildDarkBottomNavigationBarItem(),
            ),
          ),
        ),
      ),
    );
  }

  _onTap(int index) {
    if (_tabTitles[index] == "清理") {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  /// icons
  List<BottomNavigationBarItem> __buildDarkBottomNavigationBarItem() {
    return List.generate(
      _tabTitles.length,
      (index) => BottomNavigationBarItem(
        tooltip: "",
        icon: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _images[index] == ""
              ? const SizedBox(height: 20)
              : Image.asset(
                  '${_images[index]}.png',
                  width: 22,
                  height: 22,
                ),
        ),
        activeIcon: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _images[index] == ""
              ? const SizedBox(height: 20)
              : Image.asset(
                  '${_images[index]}_sel.png',
                  width: 22,
                  height: 22,
                ),
        ),
        label: _tabTitles[index],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: null, // 去除系统默认动画效果
      elevation: 0,
      backgroundColor: Colors.transparent,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      },
      child: SizedBox(
        width: 160.autoSize,
        height: 160.autoSize,
        child:Image.asset('assets/images/tab/clear_icon.png',width: 100.autoSize,height: 100.autoSize,),
      ),
    );
  }
}
