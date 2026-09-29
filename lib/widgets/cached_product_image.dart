// ============================================================
//  cached_product_image.dart  ·  NEXORA BUSINESS
//  Caché persistente en disco · offline-first
//  · Sobrevive reinicios (30 días por defecto)
//  · No depende de ImageCache de memoria
//  · Fallback con letra si no hay URL o falla
// ============================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// ============================================================
//  WIDGET
// ============================================================
class CachedProductImage extends StatelessWidget {
  final String? url;
  final String productName;
  final double width;
  final double height;
  final double radius;
  final Color accent;
  final Color dangerAccent;
  final BoxFit fit;
  final bool agotado;
  final bool showLoading;

  const CachedProductImage({
    Key? key,
    required this.url,
    required this.productName,
    this.width = 40,
    this.height = 40,
    this.radius = 11,
    this.accent = const Color(0xFF1A5CFF),
    this.dangerAccent = const Color(0xFFEF4444),
    this.fit = BoxFit.cover,
    this.agotado = false,
    this.showLoading = true,
  }) : super(key: key);

  bool get _hasUrl => url != null && url!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: _hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: fit,
                width: width,
                height: height,
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 120),
                cacheManager: ProductImageCacheManager.instance,
                placeholder: (_, __) =>
                    showLoading ? _loading() : _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: agotado
              ? [
                  dangerAccent.withOpacity(.20),
                  dangerAccent.withOpacity(.06),
                ]
              : [
                  accent.withOpacity(.20),
                  accent.withOpacity(.06),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        productName.isNotEmpty ? productName[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: (height * 0.38).clamp(10.0, 42.0),
          fontWeight: FontWeight.w900,
          color: agotado ? dangerAccent : accent,
        ),
      ),
    );
  }

  Widget _loading() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: agotado
              ? [
                  dangerAccent.withOpacity(.10),
                  dangerAccent.withOpacity(.03),
                ]
              : [
                  accent.withOpacity(.10),
                  accent.withOpacity(.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: (height * 0.35).clamp(14.0, 28.0),
        height: (height * 0.35).clamp(14.0, 28.0),
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation(
            agotado ? dangerAccent : accent,
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  CACHE MANAGER PERSISTENTE
//  · 30 días de validez
//  · Hasta 500 objetos en disco
//  · Base de datos JSON indexada (rápida)
//  · Carpeta temporal del SO (Android/iOS/Windows/Linux/Mac)
// ============================================================
class ProductImageCacheManager {
  static const key = 'nexoraProductImagesCache';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 500,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Elimina toda la caché manualmente (útil al cerrar sesión).
  static Future<void> clear() async {
    await instance.emptyCache();
  }
}

// ============================================================
//  VISOR FULLSCREEN con caché
// ============================================================
class CachedImageViewer extends StatelessWidget {
  final String url;
  const CachedImageViewer({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        cacheManager: ProductImageCacheManager.instance,
        placeholder: (_, __) => const Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2.4,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      ),
    );
  }
}