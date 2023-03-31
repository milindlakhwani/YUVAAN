import 'dart:async';
import 'dart:js' as js;

import 'package:collapsible_sidebar/collapsible_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:yuvaan_gui/globals/myColors.dart';
import 'package:yuvaan_gui/globals/myFonts.dart';
import 'package:yuvaan_gui/globals/sizeConfig.dart';
import 'package:yuvaan_gui/screens/body.dart';
import 'package:yuvaan_gui/widgets/custom_icons.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer timer;
  Widget main_body;
  int _currentPage = 0;
  List<String> _pages = ["Home", "Bioassembly", "Sensors"];
  Map<String, double> controller_values = {
    'Share': 0,
    'Options': 0,
  };

  final AssetImage _avatarImg = AssetImage('assets/images/yuvaan_logo.jpg');

  // @override
  // void initState() {
  //   super.initState();

  //   timer = Timer.periodic(const Duration(milliseconds: 150), (Timer t) {
  //     var state = js.JsObject.fromBrowserObject(js.context['state']);
  //     controller_values['Share'] = state['Share'];
  //     controller_values['Options'] = state['Options'];

  //     setState(() {
  //       if (controller_values['Share'] == 1) {
  //         if (_currentPage == 0) {
  //           _currentPage = 1;
  //         } else {
  //           _currentPage--;
  //         }
  //       } else if (controller_values['Options'] == 1) {
  //         if (_currentPage == 1) {
  //           _currentPage = 0;
  //         } else {
  //           _currentPage++;
  //         }
  //       }
  //     });
  //   });
  // }

  // @override
  // void dispose() {
  //   timer.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: CollapsibleSidebar(
        avatarImg: _avatarImg,
        isCollapsed: true,
        items: [
          CollapsibleItem(
            text: 'Home',
            icon: CupertinoIcons.home,
            onPressed: () {
              setState(() {
                _currentPage = 0;
              });
            },
            isSelected: _currentPage == 0,
          ),
          CollapsibleItem(
            text: 'Bioassembly',
            icon: CustomIcon.bio_assembly,
            onPressed: () {
              setState(() {
                _currentPage = 1;
              });
            },
            isSelected: _currentPage == 1,
          ),
          CollapsibleItem(
            text: 'Sensors',
            icon: Icons.sensors,
            onPressed: () {
              setState(() {
                _currentPage = 2;
              });
            },
            isSelected: _currentPage == 2,
          ),
        ],
        title: 'Yuvaan GUI',
        topPadding: 25,
        backgroundColor: navbar_color,
        selectedTextColor: kWhite,
        screenPadding: 0,
        textStyle: MyFonts.medium.factor(1).letterSpace(0.75),
        titleStyle: MyFonts.bold.factor(1.75),
        toggleTitle: '',
        selectedIconBox: selected_color,
        selectedIconColor: kWhite,
        borderRadius: 0,
        body: SingleChildScrollView(
          child: Body(
            currentPage: _pages[_currentPage],
          ),
        ),
        minWidth: 70,
        iconSize: 30,
        sidebarBoxShadow: [
          BoxShadow(
            color: bg,
            blurRadius: 20,
            spreadRadius: 0.01,
            offset: Offset(3, 3),
          ),
          BoxShadow(
            color: kBlack.withOpacity(0.5),
            blurRadius: 50,
            spreadRadius: 0.01,
            offset: Offset(3, 3),
          ),
        ],
      ),
    );
  }
}
