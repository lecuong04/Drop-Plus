import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.4.0.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // Using FlexColorScheme built-in FlexScheme enum based colors
    scheme: FlexScheme.blue,
    // Surface color adjustments.
    surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
    blendLevel: 1,
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnLevel: 8,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
      elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
      elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
      outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      toggleButtonsBorderSchemeColor: SchemeColor.primary,
      segmentedButtonSchemeColor: SchemeColor.primary,
      segmentedButtonBorderSchemeColor: SchemeColor.primary,
      unselectedToggleIsColored: true,
      sliderValueTinted: true,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorIsFilled: true,
      inputDecoratorBackgroundAlpha: 31,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
      fabUseShape: true,
      fabAlwaysCircular: true,
      fabSchemeColor: SchemeColor.tertiary,
      popupMenuRadius: 8.0,
      popupMenuElevation: 3.0,
      alignedDropdown: true,
      drawerIndicatorRadius: 12.0,
      drawerIndicatorSchemeColor: SchemeColor.primary,
      bottomNavigationBarMutedUnselectedLabel: false,
      bottomNavigationBarMutedUnselectedIcon: false,
      menuRadius: 8.0,
      menuElevation: 3.0,
      menuBarRadius: 0.0,
      menuBarElevation: 2.0,
      menuBarShadowColor: Color(0x00000000),
      searchBarElevation: 1.0,
      searchViewElevation: 1.0,
      searchUseGlobalShape: true,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
      navigationBarIndicatorRadius: 12.0,
      navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
      navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationRailUseIndicator: true,
      navigationRailIndicatorSchemeColor: SchemeColor.primary,
      navigationRailIndicatorOpacity: 1.00,
      navigationRailIndicatorRadius: 12.0,
      navigationRailBackgroundSchemeColor: SchemeColor.surface,
    ),
    // ColorScheme seed generation configuration for light mode.
    keyColors: const FlexKeyColors(
      useSecondary: true,
      useTertiary: true,
      keepPrimary: true,
    ),
    tones: FlexSchemeVariant.jolly.tones(Brightness.light),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // Using FlexColorScheme built-in FlexScheme enum based colors.
    scheme: FlexScheme.blue,
    // Surface color adjustments.
    surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
    blendLevel: 2,
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnLevel: 10,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
      elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
      elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
      outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      toggleButtonsBorderSchemeColor: SchemeColor.primary,
      segmentedButtonSchemeColor: SchemeColor.primary,
      segmentedButtonBorderSchemeColor: SchemeColor.primary,
      unselectedToggleIsColored: true,
      sliderValueTinted: true,
      inputDecoratorSchemeColor: SchemeColor.primary,
      inputDecoratorIsFilled: true,
      inputDecoratorBackgroundAlpha: 43,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      inputDecoratorFocusedBorderWidth: 1.0,
      inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
      fabUseShape: true,
      fabAlwaysCircular: true,
      fabSchemeColor: SchemeColor.tertiary,
      popupMenuRadius: 8.0,
      popupMenuElevation: 3.0,
      alignedDropdown: true,
      drawerIndicatorRadius: 12.0,
      drawerIndicatorSchemeColor: SchemeColor.primary,
      bottomNavigationBarMutedUnselectedLabel: false,
      bottomNavigationBarMutedUnselectedIcon: false,
      menuRadius: 8.0,
      menuElevation: 3.0,
      menuBarRadius: 0.0,
      menuBarElevation: 2.0,
      menuBarShadowColor: Color(0x00000000),
      searchBarElevation: 1.0,
      searchViewElevation: 1.0,
      searchUseGlobalShape: true,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
      navigationBarIndicatorRadius: 12.0,
      navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
      navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
      navigationRailUseIndicator: true,
      navigationRailIndicatorSchemeColor: SchemeColor.primary,
      navigationRailIndicatorOpacity: 1.00,
      navigationRailIndicatorRadius: 12.0,
      navigationRailBackgroundSchemeColor: SchemeColor.surface,
    ),
    // ColorScheme seed configuration setup for dark mode.
    keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
    tones: FlexSchemeVariant.jolly.tones(Brightness.dark),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
