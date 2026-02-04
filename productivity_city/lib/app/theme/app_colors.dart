import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color pageBackground = Color(0xFFF4EFEB);
  static const Color pageTopTint = Color(0xFFF4EFEB);
  static const Color pageBottomTint = Color(0xFFF4EFEB);

  static const Color bgPrimary = pageBackground;
  static const Color bgSecondary = pageTopTint;
  static const Color bgAccentWash = pageBottomTint;

  static const Color surfacePrimary = Color(0xFFFFFBF5);
  static const Color surfaceSecondary = Color(0xFFF1E2CF);
  static const Color surfaceMuted = Color(0xFFE7DACA);
  static const Color surfaceSoft = Color(0xFFF5EFE6);

  static const Color cardPrimary = surfacePrimary;
  static const Color cardSecondary = surfaceSecondary;
  static const Color cardMuted = surfaceMuted;

  static const Color textPrimary = Color(0xFF7B4E22);
  static const Color textSecondary = Color(0xFFA57F5B);
  static const Color textMuted = Color(0xFFC3A68A);
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color accentGold = Color(0xFFF0B33A);
  static const Color accentCoin = Color(0xFFF3C653);
  static const Color accentOlive = Color(0xFFBAC39D);
  static const Color accentOliveDark = Color(0xFFA3AC82);
  static const Color accentBrown = Color(0xFFA16437);
  static const Color accentBrownDark = Color(0xFF7C4C26);

  static const Color success = Color(0xFF8E9C79);
  static const Color warning = Color(0xFFDB9D4A);
  static const Color danger = Color(0xFFC97967);

  static const Color categoryStudy = Color(0xFFD9C4A2);
  static const Color categoryWork = Color(0xFFE6C2A7);
  static const Color categoryHealth = Color(0xFFC6D7A7);
  static const Color categoryPersonal = Color(0xFFD6C5E1);

  static const Color borderSoft = Color(0xFFE3D3C0);
  static const Color borderStrong = Color(0xFFD1BA9F);

  static const Color navBackground = Color(0xFFFFFBF6);
  static const Color navSelected = Color(0xFFD1D1CC);
  static const Color navInactive = Color(0xFF9D8F7E);

  static const Color shadow = Color(0x14000000);

  static const Color grass = Color(0xFF8AD03F);
  static const Color grassDark = Color(0xFF6DB62D);
  static const Color road = Color(0xFF76716E);
  static const Color roadEdge = Color(0xFFBEB8B4);
  static const Color roadCenter = Color(0xFF595654);
}
