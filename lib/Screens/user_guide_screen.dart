// ============================================================
//  user_guide_screen.dart  ·  NEXORA BUSINESS
//  Guía de usuario v2 · visual-first · 15 pasos
//  · Cada paso muestra un MINI MOCKUP de la pantalla real
//  · Máximo 4 bullets cortos por paso
//  · NO se puede saltar — se debe completar el recorrido
//  · Énfasis visual en Tienda en línea y Red Nexora
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexora_business/responsive_helper.dart';
import '../main.dart';

// ============================================================
//  Acentos
// ============================================================
class _C {
  static const primary   = Color(0xFF1A5CFF);
  static const cyan      = Color(0xFF06B6D4);
  static const success   = Color(0xFF10B981);
  static const warning   = Color(0xFFF59E0B);
  static const danger    = Color(0xFFEF4444);
  static const info      = Color(0xFF3B82F6);
  static const purple    = Color(0xFF8B5CF6);
  static const pink      = Color(0xFFEC4899);
  static const indigo    = Color(0xFF6366F1);
  static const orange    = Color(0xFFF97316);
  static const teal      = Color(0xFF14B8A6);
  static const muted     = Color(0xFF607B9E);

  static const network    = Color(0xFF06B6D4);
  static const myBusiness = Color(0xFF8B5CF6);

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradPurple  = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const gradNetwork = [Color(0xFF06B6D4), Color(0xFF3B82F6)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradGold    = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg          => dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface     => dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2    => dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3    => dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);
  Color get textHigh    => dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid     => dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted   => dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border      => dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong=> dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);
  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  List<BoxShadow> glow(Color c, {double o = 0.24}) => [
        BoxShadow(
          color: c.withOpacity(dark ? o + 0.10 : o),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ============================================================
//  MODELO
// ============================================================
class TourStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> bullets;
  final Widget Function(_P p) visual;
  final String? route;
  final String routeLabel;
  final bool highlight;

  TourStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bullets,
    required this.visual,
    this.route,
    this.routeLabel = 'Abrir pantalla',
    this.highlight = false,
  });
}

// ============================================================
//  SCREEN
// ============================================================
class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  int _currentStep = 0;
  late final List<TourStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
  }

  // ══════════════════════════════════════════════════════════
  //  DEFINICIÓN DE PASOS · 15 pasos visuales
  // ══════════════════════════════════════════════════════════
  List<TourStep> _buildSteps() {
    return [
      // ─── 1. BIENVENIDA
      TourStep(
        title: 'Bienvenido a Nexora Business',
        subtitle: 'Tu centro de mando, sin internet',
        icon: Icons.rocket_launch_rounded,
        color: _C.primary,
        bullets: const [
          'Funciona offline — todo se sincroniza al volver la conexión',
          'Móvil y PC con la misma cuenta',
          '3 días de prueba con todo desbloqueado',
          'Usa siempre datos reales, no de prueba',
        ],
        visual: (p) => _welcomeVisual(p),
        routeLabel: 'Comenzar el recorrido',
      ),

      // ─── 2. INVENTARIO
      TourStep(
        title: 'Paso 1 · Tu inventario',
        subtitle: 'Todo tu catálogo en un solo lugar',
        icon: Icons.inventory_2_rounded,
        color: _C.warning,
        bullets: const [
          'Cada producto guarda stock, precios y lotes',
          'Hasta 4 precios distintos por producto',
          'Filtra por categoría o busca por nombre',
          'Toca un producto para ver todo su detalle',
        ],
        visual: (p) => _inventarioVisual(p),
        route: '/productos',
        routeLabel: 'Abrir Inventario',
      ),

      // ─── 3. REABASTECER + FIFO
      TourStep(
        title: 'Paso 2 · Reabastecer',
        subtitle: 'Cada compra = un lote nuevo',
        icon: Icons.add_box_rounded,
        color: _C.success,
        bullets: const [
          'Cada lote tiene su propio precio de compra',
          'Al vender, se descuenta primero el lote más viejo (FIFO)',
          'Así el costo real es siempre exacto',
          'Introduce SIEMPRE el precio real de compra',
        ],
        visual: (p) => _fifoVisual(p),
        route: '/reabastecer',
        routeLabel: 'Abrir Reabastecer',
      ),

      // ─── 4. MODOS DE VENTA
      TourStep(
        title: 'Paso 3 · Dos modos de venta',
        subtitle: 'Elige según cómo trabaja tu negocio',
        icon: Icons.point_of_sale_rounded,
        color: _C.indigo,
        bullets: const [
          'Tiempo real: registras cada venta al instante',
          'Cierre diario: registras el stock al abrir/cerrar',
          'Puedes cambiar de modo desde Configuración',
          'El modo activo se muestra en el botón principal',
        ],
        visual: (p) => _modosVisual(p),
        route: '/settings',
        routeLabel: 'Cambiar modo',
      ),

      // ─── 5. VENDER TIEMPO REAL
      TourStep(
        title: 'Paso 4 · Vender en tiempo real',
        subtitle: 'Carrito rápido, cobro en segundos',
        icon: Icons.shopping_cart_rounded,
        color: _C.success,
        bullets: const [
          'Busca el producto y agrégalo al carrito',
          'Ajusta cantidad o activa "Mayorista"',
          'Elige método de pago: Efectivo, Transfer, etc.',
          'Toca COBRAR — el stock baja al instante',
        ],
        visual: (p) => _ventaVisual(p),
        route: '/nueva-venta',
        routeLabel: 'Abrir Ventas',
      ),

      // ─── 6. CIERRE DIARIO
      TourStep(
        title: 'Paso 5 · Cierre diario',
        subtitle: 'Abre el día → vende → cierra el día',
        icon: Icons.event_available_rounded,
        color: _C.warning,
        bullets: const [
          'Al abrir: la app captura el stock inicial',
          'Al cerrar: introduces cuánto quedó de cada producto',
          'La app calcula las ventas por diferencia',
          'Si sales antes, el progreso se guarda como borrador',
        ],
        visual: (p) => _cierreVisual(p),
        route: '/cierre-diario',
        routeLabel: 'Abrir Cierre Diario',
      ),

      // ─── 7. HISTORIAL
      TourStep(
        title: 'Paso 6 · Historial de ventas',
        subtitle: 'Consulta, filtra y audita todo',
        icon: Icons.history_rounded,
        color: _C.indigo,
        bullets: const [
          'Filtra por Hoy, Semana o Mes',
          'Toca una venta para ver su detalle completo',
          'Si te equivocaste, puedes cancelar (restaura stock)',
          'Ideal para devoluciones y auditorías',
        ],
        visual: (p) => _historialVisual(p),
        route: '/historial',
        routeLabel: 'Abrir Historial',
      ),

      // ─── 8. CLIENTES + DEUDAS
      TourStep(
        title: 'Paso 7 · Clientes y deudas',
        subtitle: 'Quién te debe y a quién le debes',
        icon: Icons.people_alt_rounded,
        color: _C.purple,
        bullets: const [
          'Agrega clientes con teléfono y dirección',
          'Marca clientes como proveedores si aplica',
          'Registra deudas por cobrar o por pagar',
          'Marca como pagada cuando se salde',
        ],
        visual: (p) => _clientesVisual(p),
        route: '/clientes',
        routeLabel: 'Abrir Clientes',
      ),

      // ─── 9. GASTOS + MERMAS
      TourStep(
        title: 'Paso 8 · Gastos y mermas',
        subtitle: 'Controla egresos y pérdidas',
        icon: Icons.receipt_long_rounded,
        color: _C.danger,
        bullets: const [
          'Gastos: servicios, insumos, alquiler, personal…',
          'Mermas: productos dañados, perdidos o vencidos',
          'Ambos se descuentan de la ganancia neta',
          'Registra siempre el costo real para no distorsionar reportes',
        ],
        visual: (p) => _gastosVisual(p),
        route: '/gastos',
        routeLabel: 'Abrir Gastos',
      ),

      // ─── 10. SUCURSALES + MOVIMIENTOS
      TourStep(
        title: 'Paso 9 · Múltiples sucursales',
        subtitle: 'Un solo negocio, varios puntos',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF92400E),
        bullets: const [
          'Cada sucursal con su propio inventario y ventas',
          'Asigna un gestor por sucursal',
          'Mueve productos entre sucursales con trazabilidad',
          'Sucursal adicional: +500 cup',
        ],
        visual: (p) => _sucursalesVisual(p),
        route: '/sucursales',
        routeLabel: 'Abrir Sucursales',
      ),

      // ─── 11. REPORTES + METAS
      TourStep(
        title: 'Paso 10 · Reportes y metas',
        subtitle: 'Conoce la salud real de tu negocio',
        icon: Icons.insights_rounded,
        color: _C.teal,
        bullets: const [
          'KPIs: ventas, ganancia bruta, ganancia neta, margen %',
          'Gráfico de evolución de los últimos 7 días',
          'Ranking de productos y clientes más activos',
          'Define metas diaria/semanal/mensual y mira tu progreso',
        ],
        visual: (p) => _reportesVisual(p),
        route: '/reportes',
        routeLabel: 'Abrir Reportes',
      ),

      // ─── 12. EQUIPO
      TourStep(
        title: 'Paso 11 · Tu equipo',
        subtitle: 'Vendedores, gestores y nóminas',
        icon: Icons.people_outline_rounded,
        color: _C.warning,
        bullets: const [
          'Crea cuentas para vendedores (plan Normal: 2, Premium: 5)',
          'Cada vendedor solo ve su sucursal y sus ventas',
          'Promueve vendedores a gestor si necesitas',
          'Nóminas: salario base + comisiones automáticas',
        ],
        visual: (p) => _equipoVisual(p),
        route: '/vendedores',
        routeLabel: 'Abrir Vendedores',
      ),

      // ═════════════════════════════════════════════════════════
      //  ⭐ 13. TIENDA EN LÍNEA · DESTACADO
      // ═════════════════════════════════════════════════════════
      TourStep(
        title: 'Paso 12 · 🌟 Tu Tienda en Línea',
        subtitle: 'Vende al mundo sin costo extra',
        icon: Icons.storefront_rounded,
        color: _C.myBusiness,
        highlight: true,
        bullets: const [
          'Publica tu catálogo en internet en minutos',
          'Comparte el enlace por WhatsApp y redes',
          'Tus clientes piden directo por WhatsApp',
          'Se sincroniza con tu inventario real',
        ],
        visual: (p) => _tiendaVisual(p),
        route: '/mi-tienda',
        routeLabel: 'Abrir Mi Tienda',
      ),

      // ═════════════════════════════════════════════════════════
      //  ⭐ 14. RED NEXORA · DESTACADO
      // ═════════════════════════════════════════════════════════
      TourStep(
        title: 'Paso 13 · 🌐 Red Nexora',
        subtitle: 'Descubre, conecta y crece',
        icon: Icons.hub_rounded,
        color: _C.network,
        highlight: true,
        bullets: const [
          'Directorio de negocios y servicios de toda la plataforma',
          'Clientes te encuentran buscando productos como los tuyos',
          'Crea alianzas estratégicas con otros negocios',
          'Invita amigos: 2 referidos que paguen = 50% de descuento',
        ],
        visual: (p) => _redVisual(p),
        route: '/tiendas',
        routeLabel: 'Explorar Red Nexora',
      ),

      // ─── 15. FINAL
      TourStep(
        title: '¡Estás listo para empezar!',
        subtitle: 'Configura, paga y contacta soporte',
        icon: Icons.emoji_events_rounded,
        color: _C.success,
        bullets: const [
          'Configura tasa USD, impuestos y tema en ⚙ Configuración',
          'Paga tu plan desde 💳 Realizar pago',
          '¿Dudas? 🎧 Soporte responde en la misma app',
          'Todo se sincroniza solo al recuperar conexión',
        ],
        visual: (p) => _finalVisual(p),
        routeLabel: 'Comenzar a usar la app',
      ),
    ];
  }

  // ============================================================
  //  VISUAL BUILDERS
  // ============================================================

  // ─── 1. WELCOME · grid de 4 features
  Widget _welcomeVisual(_P p) {
    final items = [
      {'icon': Icons.cloud_off_rounded, 'title': 'Offline', 'color': _C.warning},
      {'icon': Icons.devices_rounded, 'title': 'Móvil + PC', 'color': _C.primary},
      {'icon': Icons.security_rounded, 'title': 'Seguro', 'color': _C.success},
      {'icon': Icons.auto_awesome_rounded, 'title': '3 días gratis', 'color': _C.purple},
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (items[i]['color'] as Color).withOpacity(.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(items[i]['icon'] as IconData,
                        color: items[i]['color'] as Color, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    items[i]['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ─── 2. INVENTARIO · mockup de producto
  Widget _inventarioVisual(_P p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _productMockup(p, name: 'Camiseta', price: '350', stock: '8',
              badge: 'DISPONIBLE', badgeColor: _C.success),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _badgeLegend('Agotado', _C.danger, p),
              const SizedBox(height: 6),
              _badgeLegend('Stock bajo', _C.warning, p),
              const SizedBox(height: 6),
              _badgeLegend('Disponible', _C.success, p),
              const SizedBox(height: 6),
              _badgeLegend('Top ventas', _C.warning, p),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productMockup(_P p,
      {required String name,
      required String price,
      required String stock,
      required String badge,
      required Color badgeColor}) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: p.surface3,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    color: p.textMuted, size: 32),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: p.textHigh)),
                const SizedBox(height: 3),
                Text('\$$price',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _C.primary)),
                const SizedBox(height: 2),
                Text('$stock uds',
                    style: TextStyle(fontSize: 9, color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeLegend(String label, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
        ],
      ),
    );
  }

  // ─── 3. FIFO · lotes consumidos en orden
  Widget _fifoVisual(_P p) {
    return Column(
      children: [
        Row(
          children: [
            _loteBox('#1', '2024', '\$100', _C.danger, p, active: true),
            _arrow(p),
            _loteBox('#2', '2025', '\$120', _C.warning, p),
            _arrow(p),
            _loteBox('#3', '2026', '\$140', _C.success, p),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _C.danger.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.danger.withOpacity(.28)),
          ),
          child: Row(
            children: [
              const Icon(Icons.south_rounded, color: _C.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Al vender, primero se consume el lote más viejo',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.textHigh),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loteBox(String num, String year, String precio, Color color, _P p,
      {bool active = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(active ? .18 : .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: color.withOpacity(active ? .55 : .28),
              width: active ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text('Lote $num',
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 2),
            Text(year,
                style: TextStyle(fontSize: 9, color: p.textMuted)),
            const SizedBox(height: 4),
            Text(precio,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh)),
          ],
        ),
      ),
    );
  }

  Widget _arrow(_P p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_rounded,
          size: 14, color: p.textMuted),
    );
  }

  // ─── 4. MODOS · comparación side-by-side
  Widget _modosVisual(_P p) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _modoCard(
                p,
                icon: Icons.bolt_rounded,
                titulo: 'Tiempo real',
                desc: 'Registra cada venta al instante',
                color: _C.primary,
                ejemplos: 'Tiendas, minimarkets',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modoCard(
                p,
                icon: Icons.event_available_rounded,
                titulo: 'Cierre diario',
                desc: 'Stock al abrir y al cerrar',
                color: _C.warning,
                ejemplos: 'Cafeterías, puestos',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modoCard(_P p,
      {required IconData icon,
      required String titulo,
      required String desc,
      required Color color,
      required String ejemplos}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.32), width: 1.3),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(titulo,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text(desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: p.textMid)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(ejemplos,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }

  // ─── 5. VENTA · mockup del carrito
  Widget _ventaVisual(_P p) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              _mockCartItem('Camiseta', '2', '\$350', '\$700', p),
              const SizedBox(height: 8),
              _mockCartItem('Pantalón', '1', '\$500', '\$500', p),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.success.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.success.withOpacity(.30)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_rounded,
                        color: _C.success, size: 16),
                    const SizedBox(width: 8),
                    Text('Total',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: p.textHigh)),
                    const Spacer(),
                    const Text('\$1,200',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _C.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _C.gradSuccess),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: _C.success.withOpacity(.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('COBRAR',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mockCartItem(String name, String qty, String price, String subtotal, _P p) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _C.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_rounded,
              color: _C.primary, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.textHigh)),
              Text('${qty}x $price',
                  style: TextStyle(fontSize: 9.5, color: p.textMuted)),
            ],
          ),
        ),
        Text(subtotal,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: _C.primary)),
      ],
    );
  }

  // ─── 6. CIERRE DIARIO · timeline
  Widget _cierreVisual(_P p) {
    final steps = [
      {'icon': Icons.wb_sunny_rounded, 'title': 'Abrir', 'color': _C.warning},
      {'icon': Icons.storefront_rounded, 'title': 'Vender', 'color': _C.primary},
      {'icon': Icons.nights_stay_rounded, 'title': 'Cerrar', 'color': _C.indigo},
      {'icon': Icons.auto_awesome_rounded, 'title': 'Cálculo', 'color': _C.success},
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (steps[i]['color'] as Color).withOpacity(.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: (steps[i]['color'] as Color).withOpacity(.32)),
                    ),
                    child: Icon(steps[i]['icon'] as IconData,
                        color: steps[i]['color'] as Color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(steps[i]['title'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh)),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.chevron_right_rounded,
                    size: 16, color: p.textMuted),
              ),
          ],
        ],
      ),
    );
  }

  // ─── 7. HISTORIAL · lista de ventas
  Widget _historialVisual(_P p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          _mockSaleRow('Camiseta', '2x \$350', '\$700', 'hoy 10:30', _C.success, p),
          Divider(height: 1, color: p.border),
          _mockSaleRow('Pantalón', '1x \$500', '\$500', 'hoy 09:15', _C.success, p),
          Divider(height: 1, color: p.border),
          _mockSaleRow('Gorra', '3x \$120', '\$360', 'ayer 18:00', _C.danger, p,
              badge: 'Cancelada'),
        ],
      ),
    );
  }

  Widget _mockSaleRow(String name, String qty, String total, String fecha,
      Color estado, _P p, {String? badge}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: estado.withOpacity(.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              estado == _C.success
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: estado,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: p.textHigh)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: estado.withOpacity(.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                color: estado)),
                      ),
                    ],
                  ],
                ),
                Text('$qty · $fecha',
                    style: TextStyle(fontSize: 9.5, color: p.textMuted)),
              ],
            ),
          ),
          Text(total,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: estado)),
        ],
      ),
    );
  }

  // ─── 8. CLIENTES + DEUDAS · 2 cards
  Widget _clientesVisual(_P p) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.purple.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.purple.withOpacity(.28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _C.purple.withOpacity(.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _C.purple, size: 22),
                ),
                const SizedBox(height: 8),
                Text('Cliente',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: _C.purple)),
                const SizedBox(height: 4),
                Text('Juan Pérez',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: p.textHigh)),
                Text('+53 5555-1234',
                    style: TextStyle(fontSize: 9.5, color: p.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.danger.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.danger.withOpacity(.28)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _C.danger.withOpacity(.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.money_off_rounded,
                      color: _C.danger, size: 22),
                ),
                const SizedBox(height: 8),
                Text('Deuda',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: _C.danger)),
                const SizedBox(height: 4),
                Text('\$2,500',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh)),
                Text('vence 15/11',
                    style: TextStyle(fontSize: 9.5, color: p.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 9. GASTOS + MERMAS
  Widget _gastosVisual(_P p) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.danger.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.danger.withOpacity(.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: _C.danger, size: 18),
                    const SizedBox(width: 6),
                    Text('Gastos',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: _C.danger)),
                  ],
                ),
                const SizedBox(height: 8),
                _mockLine('Alquiler', '\$500', p),
                _mockLine('Luz', '\$120', p),
                _mockLine('Insumos', '\$300', p),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _C.orange.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.orange.withOpacity(.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: _C.orange, size: 18),
                    const SizedBox(width: 6),
                    Text('Mermas',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: _C.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                _mockLine('Dañado', '3 uds', p),
                _mockLine('Vencido', '1 ud', p),
                _mockLine('Perdido', '2 uds', p),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mockLine(String label, String value, _P p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: p.textMid)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: p.textHigh)),
        ],
      ),
    );
  }

  // ─── 10. SUCURSALES · diagrama de transferencia
  Widget _sucursalesVisual(_P p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _branchCard('Sucursal A', 'La Habana', _C.primary, p),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    color: _C.success, size: 24),
                const SizedBox(height: 2),
                Text('10 uds',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _C.success)),
              ],
            ),
          ),
          _branchCard('Sucursal B', 'Vedado', _C.success, p),
        ],
      ),
    );
  }

  Widget _branchCard(String name, String city, Color color, _P p) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withOpacity(.28)),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_rounded, color: color, size: 22),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh)),
            Text(city,
                style: TextStyle(fontSize: 9, color: p.textMuted)),
          ],
        ),
      ),
    );
  }

  // ─── 11. REPORTES · KPIs + progreso
  Widget _reportesVisual(_P p) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard('\$12,500', 'Ventas', Icons.trending_up_rounded,
                  _C.success, p),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard('\$4,200', 'Ganancia', Icons.savings_rounded,
                  _C.cyan, p),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard('78%', 'Meta', Icons.flag_rounded,
                  _C.warning, p),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Progreso semanal',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh)),
                  const Spacer(),
                  const Text('78%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _C.warning)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.78,
                  minHeight: 8,
                  backgroundColor: p.border,
                  valueColor: const AlwaysStoppedAnimation(_C.warning),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String value, String label, IconData icon, Color color, _P p) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: p.textHigh)),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: p.textMuted)),
        ],
      ),
    );
  }

  // ─── 12. EQUIPO · podio
  Widget _equipoVisual(_P p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _podiumItem('2', 'María', '\$8,400', _C.muted, 46, p),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _podiumItem('1', 'Pedro', '\$12,500', _C.warning, 60, p),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _podiumItem('3', 'Luis', '\$5,200', _C.orange, 38, p),
        ),
      ],
    );
  }

  Widget _podiumItem(String rank, String name, String amount, Color color,
      double height, _P p) {
    final medal = rank == '1' ? '🥇' : (rank == '2' ? '🥈' : '🥉');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(name,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: p.textHigh)),
        Text(amount,
            style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(.60)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(rank,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ─── 13. TIENDA · phone mockup
  Widget _tiendaVisual(_P p) {
    return Center(
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: _C.myBusiness.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: _C.gradPurple),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Mi Tienda',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: p.textHigh)),
                  ),
                  const Icon(Icons.share_rounded,
                      color: _C.myBusiness, size: 12),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniProd('👕', p),
                  const SizedBox(width: 4),
                  _miniProd('👖', p),
                  const SizedBox(width: 4),
                  _miniProd('🧢', p),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradPurple),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_rounded, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text('Pedir por WhatsApp',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniProd(String emoji, _P p) {
    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: p.border),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
      ),
    );
  }

  // ─── 14. RED NEXORA · grafo
  Widget _redVisual(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.network.withOpacity(p.dark ? .14 : .08),
            _C.info.withOpacity(.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.network.withOpacity(.32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _networkNode('🏪', 'Tú', _C.myBusiness, p, big: true),
              _networkNode('🍔', 'Comida', _C.orange, p),
              _networkNode('💻', 'Tech', _C.info, p),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.network.withOpacity(.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.network.withOpacity(.32)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hub_rounded, color: _C.network, size: 12),
                const SizedBox(width: 5),
                Text('Conectado con 3 negocios',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: p.textHigh)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _networkNode('💅', 'Belleza', _C.pink, p),
              _networkNode('🔧', 'Reparación', _C.teal, p),
            ],
          ),
        ],
      ),
    );
  }

  Widget _networkNode(String emoji, String label, Color color, _P p,
      {bool big = false}) {
    return Column(
      children: [
        Container(
          width: big ? 48 : 38,
          height: big ? 48 : 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.18),
            borderRadius: BorderRadius.circular(big ? 14 : 11),
            border: Border.all(
                color: color.withOpacity(.32), width: big ? 1.5 : 1),
            boxShadow: big
                ? [
                    BoxShadow(
                        color: color.withOpacity(.32),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(emoji, style: TextStyle(fontSize: big ? 22 : 16)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: p.textHigh)),
      ],
    );
  }

  // ─── 15. FINAL · 3 cards
  Widget _finalVisual(_P p) {
    final items = [
      {'icon': Icons.settings_rounded, 'title': 'Configuración', 'color': _C.muted},
      {'icon': Icons.payment_rounded, 'title': 'Realizar pago', 'color': _C.cyan},
      {'icon': Icons.support_agent_rounded, 'title': 'Soporte', 'color': _C.purple},
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (items[i]['color'] as Color).withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (items[i]['color'] as Color).withOpacity(.28)),
              ),
              child: Column(
                children: [
                  Icon(items[i]['icon'] as IconData,
                      color: items[i]['color'] as Color, size: 22),
                  const SizedBox(height: 6),
                  Text(items[i]['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh)),
                ],
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  // ============================================================
  //  NAVEGACIÓN · NO OMITIBLE
  // ============================================================
  bool get _esFinal => _currentStep == _steps.length - 1;

  void _avanzar() {
    final step = _steps[_currentStep];
    if (step.route != null) {
      Navigator.pushNamed(context, step.route!).then((_) {
        if (!mounted) return;
        if (_currentStep < _steps.length - 1) {
          setState(() => _currentStep++);
        }
      });
    } else {
      if (_esFinal) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.marcarGuiaVista();
        Navigator.pop(context);
      } else {
        setState(() => _currentStep++);
      }
    }
  }

  void _retroceder() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _intentarSalir() async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: _C.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completa la guía',
                style: TextStyle(
                    color: p.textHigh,
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Es rápida y te ayudará a usar Nexora correctamente.',
              style: TextStyle(
                  color: p.textMid, fontSize: 13.5, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.primary.withOpacity(p.dark ? .14 : .08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.primary.withOpacity(.28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline_rounded,
                      color: _C.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vas en el paso ${_currentStep + 1} de ${_steps.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.textHigh),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Continuar guía'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    final step = _steps[_currentStep];
    final total = _steps.length;
    final progress = (_currentStep + 1) / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _intentarSalir();
      },
      child: Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(
          backgroundColor: p.surface,
          foregroundColor: p.textHigh,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _C.gradBrand),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _C.primary.withOpacity(.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Guía de usuario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: p.textHigh,
                    ),
                  ),
                  Text(
                    'Paso ${_currentStep + 1} de $total',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      top: -160,
                      right: -140,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _C.primary.withOpacity(p.dark ? .10 : .06),
                              _C.primary.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -200,
                      left: -160,
                      child: Container(
                        width: 420,
                        height: 420,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _C.cyan.withOpacity(p.dark ? .08 : .05),
                              _C.cyan.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                // Barra de progreso
                Container(
                  height: 5,
                  color: p.dark
                      ? Colors.white.withOpacity(.05)
                      : _C.primary.withOpacity(.08),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            step.color,
                            step.color.withOpacity(.65)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainCard(step, p, isDesktop),
                            const SizedBox(height: 14),
                            _buildDataWarning(p),
                            const SizedBox(height: 14),
                            _buildNavigation(p),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  CARD PRINCIPAL · estructura visual
  // ============================================================
  Widget _buildMainCard(TourStep step, _P p, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: step.highlight
              ? step.color.withOpacity(.45)
              : p.border,
          width: step.highlight ? 1.5 : 1,
        ),
        boxShadow: step.highlight
            ? [
                BoxShadow(
                  color: step.color.withOpacity(.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isDesktop ? 60 : 54,
                height: isDesktop ? 60 : 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      step.color.withOpacity(.22),
                      step.color.withOpacity(.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: step.color.withOpacity(.32),
                    width: step.highlight ? 1.5 : 1,
                  ),
                ),
                child: Icon(step.icon,
                    color: step.color, size: isDesktop ? 30 : 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step.highlight) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [step.color, step.color.withOpacity(.72)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('DESTACADO',
                                style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: p.textHigh,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Visual showcase
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: step.visual(p),
          ),
          const SizedBox(height: 18),

          // Bullets cortos
          ...step.bullets.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: step.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: p.textMid,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ============================================================
  //  ADVERTENCIA DE DATOS REALES
  // ============================================================
  Widget _buildDataWarning(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(p.dark ? .12 : .06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.warning.withOpacity(.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: _C.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Usa datos reales para que los reportes sean precisos.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textMid,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  NAVEGACIÓN INFERIOR
  // ============================================================
  Widget _buildNavigation(_P p) {
    final step = _steps[_currentStep];
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _avanzar,
            icon: Icon(
              _esFinal
                  ? Icons.check_rounded
                  : (step.route != null
                      ? Icons.open_in_new_rounded
                      : Icons.arrow_forward_rounded),
              size: 20,
            ),
            label: Text(
              step.routeLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: step.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (step.route != null) ...[
          const SizedBox(height: 8),
          Text(
            'Al volver, avanzas automáticamente',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: p.textMuted,
            ),
          ),
        ],
        if (_currentStep > 0) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _retroceder,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Paso anterior'),
              style: OutlinedButton.styleFrom(
                foregroundColor: p.textMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                side: BorderSide(color: p.border),
              ),
            ),
          ),
        ],
      ],
    );
  }
}