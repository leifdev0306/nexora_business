// ============================================================
//  image_cache_warmer.dart  ·  NEXORA BUSINESS
//  Pre-descarga imágenes en segundo plano para que queden
//  disponibles offline sin intervención del usuario.
// ============================================================

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../widgets/cached_product_image.dart';

class ImageCacheWarmer {
  /// Descarga cada URL y la deja en caché persistente.
  /// Ignora errores individuales (una URL rota no rompe el lote).
  static Future<void> warmProducts(Iterable<String?> urls) async {
    final cm = ProductImageCacheManager.instance;
    final seen = <String>{};
    for (final raw in urls) {
      final u = raw?.trim();
      if (u == null || u.isEmpty) continue;
      if (!seen.add(u)) continue;
      try {
        // Si ya está en caché, downloadFile devuelve el archivo local
        // sin hacer request de red.
        await cm.downloadFile(u);
      } catch (_) {
        // Ignoramos imágenes que fallan (404, sin red, etc.)
      }
    }
  }

  /// Versión no-bloqueante: lanza la tarea y olvida.
  static void warmInBackground(Iterable<String?> urls) {
    Future.microtask(() => warmProducts(urls));
  }
}