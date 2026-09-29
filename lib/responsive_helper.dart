import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class ResponsiveHelper {
  // Detección de escritorio
  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  // Obtener el ancho de la pantalla (útil para decidir tamaños)
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Determinar si es móvil pequeño (ancho < 600)
  static bool isSmallMobile(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

  // Escalar fuente según el ancho de la pantalla (AJUSTADO para móviles más grandes)
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (isDesktop()) {
      return baseSize * 1.2; // Escritorio más grande
    } else if (width < 400) {
      return baseSize * 0.95; // Móvil muy pequeño: casi igual a base
    } else if (width < 600) {
      return baseSize * 1.0; // Móvil estándar: tamaño base
    } else {
      return baseSize * 1.05; // Tablet: ligeramente más grande
    }
  }

  // Padding responsivo según ancho
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (isDesktop()) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    } else if (width < 400) {
      return const EdgeInsets.all(10); // Aumentado ligeramente
    } else if (width < 600) {
      return const EdgeInsets.all(14); // Aumentado
    } else {
      return const EdgeInsets.all(18); // Aumentado
    }
  }

  // Padding interno para tarjetas, listas, etc.
  static EdgeInsets getCardPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (isDesktop()) {
      return const EdgeInsets.all(20);
    } else if (width < 400) {
      return const EdgeInsets.all(10);
    } else if (width < 600) {
      return const EdgeInsets.all(14);
    } else {
      return const EdgeInsets.all(18);
    }
  }

  // Ancho máximo del contenido
  static double getMaxWidth(BuildContext context) {
    if (isDesktop()) {
      return 1400;
    }
    return double.infinity;
  }

  // Grid: número de columnas según el ancho
  static int getGridCrossAxisCount(BuildContext context, {int mobile = 2, int desktop = 4}) {
    final width = getScreenWidth(context);
    if (isDesktop()) {
      return desktop;
    } else if (width < 400) {
      return 2; // Móvil muy pequeño, 2 columnas
    } else if (width < 600) {
      return 3; // Móvil estándar, 3 columnas
    } else {
      return mobile;
    }
  }

  // Envolver Scaffold body con márgenes centrales
  static Widget wrapScaffoldBody(BuildContext context, Widget child, {EdgeInsets? padding}) {
    final effectivePadding = padding ?? ResponsiveHelper.getResponsivePadding(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ResponsiveHelper.getMaxWidth(context)),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}