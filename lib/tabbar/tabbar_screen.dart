import 'package:clear_tool/home/clear_page/clear_page.dart';
import 'package:clear_tool/home/home_screen.dart';
import 'package:clear_tool/mine/mine_page.dart';
import 'package:clear_tool/state/app_state.dart';
import 'package:clear_tool/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TabbarScreen extends StatefulWidget {
  const TabbarScreen({Key? key}) : super(key: key);

  @override
  _TabbarScreenState createState() => _TabbarScreenState();
}

class _TabbarScreenState extends State<TabbarScreen> {
  final _tabTitles = [
    "common.home",
    "",
    "common.mine",
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
      ..add(const MinePage());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      AppUtils.pixelRatio = MediaQuery.of(context).devicePixelRatio;
      AppUtils.screenW = MediaQuery.of(context).size.width;
      AppUtils.screenH = MediaQuery.of(context).size.height;
      AppUtils.safeAreapadding = MediaQuery.of(context).padding;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppUtils.globalContext = context;
    return Stack(
      children: [
        Scaffold(
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
          // floatingActionButton: _buildFloatingActionButton(),
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            height: 60,
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
                  iconSize: 25,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedItemColor: Colors.black,
                  selectedItemColor: const Color.fromRGBO(5, 122, 229, 1),
                  onTap: (index) => _onTap(index),
                  type: BottomNavigationBarType.fixed,
                  items: __buildDarkBottomNavigationBarItem(),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: (MediaQuery.of(context).size.width / 2) - 90 / 2,
          bottom: MediaQuery.of(context).padding.bottom + 90 * 0.2,
          child: _buildFloatingActionButton(),
        ),
      ],
    );
  }

  _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    pageController.jumpToPage(index);
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
        label: _tabTitles[index] != ""
            ? AppUtils.i18Translate(_tabTitles[index])
            : '',
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ClearPage()),
        );
      },
      child: Image.asset(
        'assets/images/tab/clear_icon.png',
        fit: BoxFit.cover,
        width: 90,
        height: 90,
      ),
    );
  }
}
