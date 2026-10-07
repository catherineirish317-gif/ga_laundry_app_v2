import 'package:flutter/material.dart';

/// One shared color palette for the whole app (customer AND admin),
/// matching the G A Laundry Shop banner: bubbly mint and aqua first,
/// heart pink as the highlight, dark teal only for text.
class AppColors {
  AppColors._();

  // Brand: fresh aqua-teal (from the mint logo circle, a bit deeper so white text stays readable)
  static const Color primary = Color(0xFF1FBFB0); // app bars, buttons, links, prices
  static const Color primaryDark = Color(0xFF12968D); // gradients, pressed states
  static const Color primaryLight = Color(0xFF6FE8DA); // lighter mint for gradients
  static const Color deepTeal = Color(0xFF1A4E65); // old dark teal, for text on aqua/mint only

  // Brand: mint (logo circle)
  static const Color accent = Color(0xFF4EDFCE); // gradient ends, highlights

  // Brand: pink (heart)
  static const Color pink = Color(0xFFFF70AB); // loyalty stamps, special highlights
  static const Color pinkSoft = Color(0xFFFFE3EF); // light pink tinted cards

  // Brand: light aqua (footer bar)
  static const Color aqua = Color(0xFFB2EFF0); // soft bars, selected rows
  static const Color primarySoft = Color(0xFFE6F8FA); // very light aqua: banners and tinted cards

  // Text and surfaces
  static const Color ink = Color(0xFF10303F); // main text, dark sidebar
  static const Color textSecondary = Color(0xFF5A7382);
  static const Color textMuted = Color(0xFF93A7B3);
  static const Color border = Color(0xFFD7E6EB);
  static const Color background = Color(0xFFF1FAFB);

  // Status (same meaning everywhere)
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  /// Standard brand gradient (aqua-teal to mint): the bubbly look.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}