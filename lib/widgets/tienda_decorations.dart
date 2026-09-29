// ============================================================
//  widgets/tienda_decorations.dart
//  Decoraciones compartidas para las pantallas de tienda.
//  Alto contraste + sombras profesionales en claro/oscuro.
// ============================================================
import 'package:flutter/material.dart';

const Color kTiendaPrimary = Color(0xFF5B4DE0);
const Color kTiendaPrimaryMid = Color(0xFF7C8BFF);
const Color kTiendaPrimaryEnd = Color(0xFF9B6BFF);

/// Fondo de página. Ligeramente más oscuro que las tarjetas
/// para que éstas resalten visualmente.
Color tiendaPageBackground(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF16162A) : const Color(0xFFEFF1F8);
}

/// Decoración para tarjetas estándar de la tienda.
/// Contraste fuerte, bordes visibles y sombra profesional.
BoxDecoration tiendaCardDecoration(
  BuildContext context, {
  bool hover = false,
  bool highlighted = false,
  double radius = 20,
  double borderWidth = 1.2,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final strong = hover || highlighted;

  if (isDark) {
    // Fondo página #16162A → tarjeta #2E2E4A (contraste evidente)
    return BoxDecoration(
      color: const Color(0xFF2E2E4A),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: strong
            ? kTiendaPrimaryMid.withOpacity(.65)
            : const Color(0xFF4F4F78),
        width: strong ? 1.8 : borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(hover ? .55 : .40),
          blurRadius: hover ? 34 : 22,
          offset: Offset(0, hover ? 14 : 8),
        ),
        BoxShadow(
          color: kTiendaPrimary.withOpacity(hover ? .35 : .15),
          blurRadius: 26,
          offset: const Offset(0, 6),
          spreadRadius: -8,
        ),
      ],
    );
  }

  // Fondo página #EFF1F8 → tarjeta blanco puro
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: strong
          ? kTiendaPrimary.withOpacity(.40)
          : const Color(0xFFDDE1ED),
      width: strong ? 1.8 : borderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1A237E).withOpacity(hover ? .18 : .10),
        blurRadius: hover ? 34 : 22,
        offset: Offset(0, hover ? 14 : 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(hover ? .10 : .05),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// Decoración para tarjetas destacadas (con tinte morado).
BoxDecoration tiendaHighlightDecoration(
  BuildContext context, {
  bool hover = false,
  double radius = 20,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isDark) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A2E60), Color(0xFF4A3A78)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: kTiendaPrimary.withOpacity(hover ? .75 : .45),
        width: 1.6,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(hover ? .55 : .40),
          blurRadius: hover ? 34 : 22,
          offset: Offset(0, hover ? 14 : 8),
        ),
        BoxShadow(
          color: kTiendaPrimary.withOpacity(hover ? .45 : .25),
          blurRadius: 30,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ],
    );
  }

  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF5F1FF)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: kTiendaPrimary.withOpacity(hover ? .50 : .25),
      width: 1.6,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1A237E).withOpacity(hover ? .20 : .12),
        blurRadius: hover ? 34 : 22,
        offset: Offset(0, hover ? 14 : 8),
      ),
      BoxShadow(
        color: kTiendaPrimary.withOpacity(hover ? .25 : .10),
        blurRadius: 26,
        offset: const Offset(0, 6),
        spreadRadius: -6,
      ),
    ],
  );
}