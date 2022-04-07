import 'package:flutter/material.dart';
import './sizeConfig.dart';

class MyFonts {
  static final String _fontFamily = 'OpenSans';

  static TextStyle get light =>
      TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400);
  static TextStyle get medium =>
      TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600);
  static TextStyle get extraBold =>
      TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900);
  static TextStyle get bold =>
      TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700);
  static TextStyle get semiBold =>
      TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800);
}

extension TextStyleHelpers on TextStyle {
  TextStyle setColor(Color color) => copyWith(color: color);
  TextStyle factor(double factor) =>
      copyWith(fontSize: factor * SizeConfig.horizontalBlockSize);
  TextStyle tsFactor(double tsFactor) =>
      copyWith(fontSize: tsFactor * SizeConfig.textScaleFactor);

  TextStyle size(double size) => copyWith(fontSize: size);
  TextStyle setheight(double height) => copyWith(height: height);
  TextStyle letterSpace(double space) => copyWith(letterSpacing: space);
}
