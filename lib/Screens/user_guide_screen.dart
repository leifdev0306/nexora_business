// ============================================================
//  user_guide_screen.dart  ·  NEXORA BUSINESS
//  Guía de usuario premium · recorrido completo
//  · Sin "Categorías" (integrada en Inventario)
//  · Bloque destacado de Tienda en línea + Red Nexora
//  · Beneficios claros y visuales
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tu_mipyme/responsive_helper.dart';
import '../main.dart';

// ============================================================
//  Acentos compartidos
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
  static const gold      = Color(0xFFCA8A04);
  static const orange    = Color(0xFFF97316);
  static const teal      = Color(0xFF14B8A6);
  static const textMuted = Color(0xFF607B9E);
  static const textMid   = Color(0xFF1C3352);

  // ▼ Identidad visual de secciones (igual que home_screen)
  static const network    = Color(0xFF06B6D4); // Red Nexora
  static const myBusiness = Color(0xFF8B5CF6); // Mi Negocio / Tienda

  static const gradBrand   = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradPurple  = [Color(0xFF8B5CF6), Color(0xFFEC4899)];
  static const gradNetwork = [Color(0xFF06B6D4), Color(0xFF3B82F6)];
  static const gradSuccess = [Color(0xFF10B981), Color(0xFF06B6D4)];
  static const gradGold    = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
}

class _P {
  final bool dark;
  const _P(this.dark);
  Color get bg =>
      dark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FC);
  Color get surface =>
      dark ? const Color(0xFF122340) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      dark ? const Color(0xFF162B4D) : const Color(0xFFF7FAFF);
  Color get surface3 =>
      dark ? const Color(0xFF1E375C) : const Color(0xFFEFF4FE);
  Color get textHigh =>
      dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid =>
      dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted =>
      dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border =>
      dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  Color get borderStrong =>
      dark ? const Color(0x554A8BFF) : const Color(0x2E1A5CFF);
  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.42)
              : const Color(0xFF0A1A33).withOpacity(.10),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];
  List<BoxShadow> glow(Color c, {double o = 0.24}) => [
        BoxShadow(
          color: c.withOpacity(dark ? o + 0.10 : o),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ];
}

// ============================================================
//  MODELO: BOTÓN GUÍA
// ============================================================
class GuideButton {
  final IconData icon;
  final String label;
  final Color? color;
  const GuideButton(this.icon, this.label, {this.color});
}

// ============================================================
//  MODELO: BENEFICIO DESTACADO
// ============================================================
class GuideBenefit {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const GuideBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ============================================================
//  MODELO: PASO DEL TOUR
// ============================================================
class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? route;
  final String routeLabel;
  final List<GuideButton> buttons;
  final List<GuideBenefit> benefits;
  final bool highlight; // ← para destacar visualmente pasos importantes

  TourStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.route,
    this.routeLabel = '',
    this.buttons = const [],
    this.benefits = const [],
    this.highlight = false,
  });
}

// ============================================================
//  MAPEO DE COLORES LEGACY → NUEVA PALETA
// ============================================================
Color _stepColor(Color old) {
  if (old == Colors.blue) return _C.primary;
  if (old == Colors.purple) return _C.purple;
  if (old == Colors.orange) return _C.orange;
  if (old == Colors.green) return _C.success;
  if (old == Colors.indigo) return _C.indigo;
  if (old == Colors.pink) return _C.pink;
  if (old == Colors.cyan) return _C.cyan;
  if (old == Colors.red) return _C.danger;
  if (old == Colors.teal) return _C.teal;
  if (old == Colors.amber) return _C.warning;
  if (old == Colors.deepOrange) return _C.orange;
  if (old == Colors.brown) return const Color(0xFF92400E);
  if (old == Colors.deepPurple) return const Color(0xFF7C3AED);
  if (old == Colors.grey) return _C.textMuted;
  return old;
}

// ============================================================
//  PANTALLA
// ============================================================
class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  _UserGuideScreenState createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  int _currentStep = 0;
  late List<TourStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      // ════════════════════════════════════════════════════════
      //  BIENVENIDA
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '👋 ¡Bienvenido a Nexora Business!',
        description:
            'Tu centro de mando para gestionar el negocio de forma completa, segura y sin depender de internet.\n\n'
            '▸ Funciona offline: todo se guarda en el dispositivo y se sincroniza al recuperar la conexión.\n'
            '▸ Diseñada para móvil y PC: la interfaz se adapta al tamaño de pantalla.\n'
            '▸ Planes Normal y Premium, con 3 días de prueba gratuita con todas las funciones desbloqueadas.\n'
            '▸ Datos cifrados localmente y respaldo en la nube.\n\n'
            '⚠️ IMPORTANTE: usa siempre datos reales. Los datos de prueba distorsionan los reportes y las estadísticas.\n\n'
            '⬇️ Esta guía te llevará por TODAS las funciones, paso a paso y sin saltarse ninguna.',
        icon: Icons.rocket_launch_rounded,
        color: _C.primary,
        routeLabel: 'Comenzar el recorrido',
      ),

      // ════════════════════════════════════════════════════════
      //  INVENTARIO + CATEGORÍAS (fusionado)
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📦 Paso 1: Inventario y Productos',
        description:
            'Aquí vive todo tu catálogo. Cada producto guarda precios, stock, lotes e historial.\n\n'
            'ANTES DE EMPEZAR: organiza tus productos por categorías. Se crean y editan directamente desde el inventario.\n\n'
            '▸ Crea productos con: nombre, categoría, precios (compra / venta / transferencia / mayorista) y unidad.\n'
            '▸ Puedes asignar hasta 4 precios distintos: venta normal, transferencia, mayorista efectivo y mayorista transferencia.\n'
            '▸ Filtra por categoría, busca por nombre o activa el ícono ⚠ para ver solo agotados.\n'
            '▸ Ordena por stock crítico con el ícono de flecha ↑↓.\n'
            '▸ Toca cualquier producto para ver su detalle: lotes, márgenes, historial y acciones.\n\n'
            '✅ El costo de venta se calcula automáticamente con FIFO (primero en entrar, primero en salir).',
        icon: Icons.inventory_2_rounded,
        color: _C.warning,
        route: '/productos',
        routeLabel: 'Abrir Inventario',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Agregar producto', color: _C.warning),
          GuideButton(Icons.edit_rounded, 'Editar', color: _C.primary),
          GuideButton(Icons.add_box_rounded, 'Reabastecer', color: _C.success),
          GuideButton(Icons.swap_horiz_rounded, 'Mover', color: _C.cyan),
          GuideButton(Icons.warning_amber_rounded, 'Merma', color: _C.orange),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
        ],
        benefits: const [
          GuideBenefit(
            icon: Icons.category_rounded,
            title: 'Categorías integradas',
            subtitle: 'Organiza sin salir del inventario',
            color: _C.purple,
          ),
          GuideBenefit(
            icon: Icons.attach_money_rounded,
            title: 'Hasta 4 precios',
            subtitle: 'Normal, transferencia y 2 mayoristas',
            color: _C.success,
          ),
          GuideBenefit(
            icon: Icons.filter_alt_rounded,
            title: 'Filtros y búsqueda',
            subtitle: 'Encuentra productos al instante',
            color: _C.primary,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  REABASTECER
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📥 Paso 2: Reabastecer con lotes (FIFO)',
        description:
            'Cada compra que haces entra como un nuevo lote con su propio precio. La app usa FIFO: al vender, descuenta primero los lotes más antiguos.\n\n'
            '▸ Toca el ícono ➕ verde en la tarjeta del producto.\n'
            '▸ Ingresa la cantidad y el precio de compra real de ese lote.\n'
            '▸ El stock se incrementa automáticamente y se guarda el historial completo.\n\n'
            '⚠️ Muy importante: introduce SIEMPRE el precio de compra real. Si pones un valor incorrecto, la ganancia reportada será incorrecta.',
        icon: Icons.add_box_rounded,
        color: _C.success,
        route: '/reabastecer',
        routeLabel: 'Abrir Reabastecer',
        buttons: const [
          GuideButton(Icons.add_box_rounded, 'Reabastecer', color: _C.success),
          GuideButton(Icons.save_rounded, 'Guardar lote', color: _C.primary),
          GuideButton(Icons.history_rounded, 'Ver historial de lotes'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  MODO DE VENTAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🛒 Paso 3: Elige tu modo de ventas',
        description:
            'Nexora se adapta a dos formas distintas de trabajar. Selecciona el modo desde Configuración ⚙ → "Modo de ventas".\n\n'
            '🔵 MODO TIEMPO REAL:\n'
            '▸ Registra cada venta individualmente, en el momento.\n'
            '▸ Ideal para comercios donde cada cliente paga al instante.\n\n'
            '🟠 MODO CIERRE DIARIO:\n'
            '▸ Registras el stock al abrir el negocio y al cerrar introduces lo que quedó.\n'
            '▸ La app calcula las ventas por diferencia (inicial − final).\n'
            '▸ Ideal para cafeterías, puestos, tiendas con ventas dispersas.\n\n'
            '⚠️ El modo se puede cambiar cuando quieras.',
        icon: Icons.point_of_sale_rounded,
        color: _C.indigo,
        route: '/settings',
        routeLabel: 'Abrir Configuración',
        buttons: const [
          GuideButton(Icons.point_of_sale_rounded, 'Modo tiempo real', color: _C.primary),
          GuideButton(Icons.event_available_rounded, 'Modo cierre diario', color: _C.warning),
          GuideButton(Icons.check_circle_rounded, 'Modo activo', color: _C.success),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  VENTA EN TIEMPO REAL
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🛒 Paso 4: Vender en tiempo real',
        description:
            'Con el modo tiempo real activo, el botón flotante del inicio abre esta pantalla.\n\n'
            '▸ Busca el producto o selecciónalo de la lista.\n'
            '▸ Ajusta la cantidad (mantén pulsado el + para subir rápido).\n'
            '▸ Activa "Mayorista" para aplicar el precio al por mayor.\n'
            '▸ Elige el método de pago: Efectivo CUP, Efectivo USD, Transferencia, Transfermóvil, EnZona.\n'
            '▸ Asigna un cliente (opcional) para controlar su saldo pendiente.\n'
            '▸ Puedes agregar varios productos antes de confirmar.\n\n'
            '✅ El stock se descuenta al instante usando FIFO.',
        icon: Icons.point_of_sale_rounded,
        color: _C.success,
        route: '/nueva-venta',
        routeLabel: 'Abrir Ventas',
        buttons: const [
          GuideButton(Icons.search_rounded, 'Buscar producto'),
          GuideButton(Icons.add_shopping_cart_rounded, 'Agregar al carrito', color: _C.primary),
          GuideButton(Icons.shopping_bag_rounded, 'Mayorista', color: _C.purple),
          GuideButton(Icons.person_rounded, 'Asignar cliente'),
          GuideButton(Icons.payments_rounded, 'Cobrar y confirmar', color: _C.success),
          GuideButton(Icons.close_rounded, 'Cancelar', color: _C.danger),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  CIERRE DIARIO
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🌅 Paso 5: Cierre diario',
        description:
            'Con el modo cierre diario activo, el botón flotante del inicio abre esta pantalla.\n\n'
            'PROCESO DE USO:\n'
            '▸ 1) Al abrir el negocio, toca "Iniciar el día". La app captura el stock actual.\n'
            '▸ 2) Durante el día trabaja normal; no registres ventas individuales.\n'
            '▸ 3) Al cerrar, toca el botón flotante otra vez. Verás cada producto con un campo para el stock restante.\n'
            '▸ 4) Navega con "Anterior" y "Siguiente". Usa los atajos "Igual al inicial", "Mitad" o "Cero".\n'
            '▸ 5) Toca "Finalizar cierre del día". La app calcula las ventas por diferencia.\n\n'
            '💡 Si sales antes de terminar, el progreso se guarda como borrador.',
        icon: Icons.event_available_rounded,
        color: _C.warning,
        route: '/cierre-diario',
        routeLabel: 'Abrir Cierre Diario',
        buttons: const [
          GuideButton(Icons.play_arrow_rounded, 'Iniciar día', color: _C.success),
          GuideButton(Icons.arrow_back_ios_rounded, 'Anterior'),
          GuideButton(Icons.arrow_forward_ios_rounded, 'Siguiente', color: _C.primary),
          GuideButton(Icons.repeat_rounded, 'Igual al inicial'),
          GuideButton(Icons.percent_rounded, 'Mitad'),
          GuideButton(Icons.remove_circle_outline_rounded, 'Cero', color: _C.danger),
          GuideButton(Icons.check_circle_rounded, 'Finalizar cierre', color: _C.success),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  HISTORIAL
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📜 Paso 6: Historial de ventas',
        description:
            'Consulta, filtra y gestiona todas las ventas registradas.\n\n'
            '▸ Filtra por período: Hoy, Semana o Mes.\n'
            '▸ Toca una venta para ver su detalle completo.\n'
            '▸ Los administradores pueden cancelar una venta: el stock se restaura.\n'
            '▸ Útil para detectar errores, hacer devoluciones o auditar el día.',
        icon: Icons.history_rounded,
        color: _C.indigo,
        route: '/historial',
        routeLabel: 'Abrir Historial',
        buttons: const [
          GuideButton(Icons.filter_list_rounded, 'Filtrar'),
          GuideButton(Icons.visibility_rounded, 'Ver detalle'),
          GuideButton(Icons.delete_rounded, 'Cancelar venta', color: _C.danger),
          GuideButton(Icons.search_rounded, 'Buscar'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  CLIENTES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '👥 Paso 7: Clientes',
        description:
            'Administra tu cartera de clientes y su saldo pendiente.\n\n'
            '▸ Agrega clientes con nombre, teléfono y dirección.\n'
            '▸ Al vender a un cliente, el monto se acumula como "saldo pendiente" si se marca como fiado.\n'
            '▸ Los clientes pueden marcarse como proveedores.\n'
            '▸ Cada cliente guarda su historial de compras y deudas.',
        icon: Icons.people_alt_rounded,
        color: _C.purple,
        route: '/clientes',
        routeLabel: 'Abrir Clientes',
        buttons: const [
          GuideButton(Icons.person_add_rounded, 'Nuevo cliente', color: _C.success),
          GuideButton(Icons.edit_rounded, 'Editar'),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.storefront_rounded, 'Marcar proveedor'),
          GuideButton(Icons.phone_rounded, 'Llamar'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  DEUDAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '💰 Paso 8: Deudas',
        description:
            'Registra deudas tanto de clientes (cuentas por cobrar) como de proveedores (cuentas por pagar).\n\n'
            '▸ Crea una deuda indicando tipo, monto, concepto y fecha de vencimiento.\n'
            '▸ Al marcar como pagada, se registra la fecha y el método de pago.\n'
            '▸ Puedes llevar el control de cuánto te deben y cuánto debes.\n'
            '▸ Compatible con CUP y USD (monto y tasa de cambio).',
        icon: Icons.money_off_rounded,
        color: _C.pink,
        route: '/deudas',
        routeLabel: 'Abrir Deudas',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nueva deuda', color: _C.primary),
          GuideButton(Icons.check_rounded, 'Marcar pagada', color: _C.success),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.attach_money_rounded, 'Monto'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  GASTOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '💸 Paso 9: Gastos',
        description:
            'Registra todos los egresos del negocio para llevar un control financiero preciso.\n\n'
            '▸ Concepto, monto, categoría y fecha.\n'
            '▸ Clasifica por tipo (servicios, insumos, alquiler, personal, etc.).\n'
            '▸ Filtra por fecha o categoría para analizar por período.\n'
            '▸ Edita o elimina un gasto si cometiste un error.\n\n'
            '✅ Los gastos se restan automáticamente en el cálculo de ganancia neta.',
        icon: Icons.receipt_long_rounded,
        color: _C.danger,
        route: '/gastos',
        routeLabel: 'Abrir Gastos',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nuevo gasto', color: _C.primary),
          GuideButton(Icons.edit_rounded, 'Editar'),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.category_rounded, 'Categoría'),
          GuideButton(Icons.attach_money_rounded, 'Monto'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  MERMAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '⚠️ Paso 10: Mermas (pérdidas)',
        description:
            'Registra productos dañados, perdidos, para autoconsumo o merma natural.\n\n'
            '▸ Selecciona el producto y la cantidad perdida.\n'
            '▸ Elige el motivo: Estropeado, Autoconsumo, Pérdida o Merma natural.\n'
            '▸ La app descuenta el stock y calcula el costo real con FIFO.\n'
            '▸ Si fue un error, puedes cancelar la merma y se restaura el stock.\n\n'
            '💡 Una merma bien registrada te ayuda a conocer la pérdida real de tu negocio.',
        icon: Icons.warning_amber_rounded,
        color: _C.orange,
        route: '/mermas',
        routeLabel: 'Abrir Mermas',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nueva merma', color: _C.orange),
          GuideButton(Icons.cancel_rounded, 'Cancelar merma', color: _C.danger),
          GuideButton(Icons.history_rounded, 'Ver historial'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  MOVIMIENTOS ENTRE SUCURSALES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🔀 Paso 11: Movimientos entre sucursales',
        description:
            'Transfiere productos de una sucursal a otra sin perder trazabilidad.\n\n'
            '▸ La app descuenta el stock en origen y lo suma en destino.\n'
            '▸ Si el producto no existe en destino, se crea automáticamente clonando sus precios.\n'
            '▸ Puedes cancelar un movimiento: restaura los stocks.\n'
            '▸ Cada movimiento guarda el costo real del lote transferido.\n\n'
            '⚠️ Para mover, necesitas al menos 2 sucursales creadas.',
        icon: Icons.swap_horiz_rounded,
        color: _C.cyan,
        route: '/movimientos-sucursales',
        routeLabel: 'Abrir Movimientos',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nuevo movimiento', color: _C.cyan),
          GuideButton(Icons.cancel_rounded, 'Cancelar movimiento', color: _C.danger),
          GuideButton(Icons.history_rounded, 'Ver historial'),
          GuideButton(Icons.swap_horiz_rounded, 'Invertir'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  METAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🎯 Paso 12: Metas de ventas',
        description:
            'Fija objetivos diarios, semanales y mensuales. Mide tu progreso en tiempo real.\n\n'
            '▸ Las barras de progreso del inicio se actualizan con cada venta.\n'
            '▸ Modifica las metas cuando quieras según temporada o estrategia.\n'
            '▸ Se muestra el porcentaje cumplido en la tarjeta "Rendimiento" del panel desktop.\n\n'
            '✅ Motiva a tu equipo y ajusta decisiones con datos concretos.',
        icon: Icons.flag_rounded,
        color: _C.pink,
        route: '/metas',
        routeLabel: 'Abrir Metas',
        buttons: const [
          GuideButton(Icons.save_rounded, 'Guardar metas', color: _C.success),
          GuideButton(Icons.edit_rounded, 'Editar'),
          GuideButton(Icons.flag_rounded, 'Meta diaria', color: _C.primary),
          GuideButton(Icons.flag_rounded, 'Meta semanal', color: _C.warning),
          GuideButton(Icons.flag_rounded, 'Meta mensual', color: _C.purple),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  REPORTES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📊 Paso 13: Reportes y análisis',
        description:
            'Visualiza la salud financiera de tu negocio.\n\n'
            '▸ KPIs clave: ventas, costos FIFO, ganancias bruta y neta, margen %, ticket promedio.\n'
            '▸ Gráfico de evolución de los últimos 7 días.\n'
            '▸ Ranking de productos más vendidos y clientes más activos.\n'
            '▸ Rendimiento por vendedor (solo admin).\n'
            '▸ Exporta a PDF, Excel o CSV (plan Premium).\n\n'
            '✅ Los reportes sólo son precisos si usas datos reales.',
        icon: Icons.insights_rounded,
        color: _C.cyan,
        route: '/reportes',
        routeLabel: 'Abrir Reportes',
        buttons: const [
          GuideButton(Icons.filter_list_rounded, 'Filtrar período'),
          GuideButton(Icons.picture_as_pdf_rounded, 'Exportar PDF', color: _C.danger),
          GuideButton(Icons.table_chart_rounded, 'Exportar Excel', color: _C.success),
          GuideButton(Icons.share_rounded, 'Compartir'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  VENDEDORES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '👤 Paso 14: Vendedores (solo admin)',
        description:
            'Crea cuentas para tus vendedores y gestores.\n\n'
            '▸ Plan Normal: hasta 2 vendedores por sucursal.\n'
            '▸ Plan Premium: hasta 5 vendedores por sucursal.\n'
            '▸ Cada vendedor ve solo su sucursal y sus ventas.\n'
            '▸ Puedes promover un vendedor a gestor.\n'
            '▸ Elimina vendedores que ya no trabajen contigo.\n\n'
            '💡 Los gestores pueden ver todas las ventas de su sucursal.',
        icon: Icons.people_outline_rounded,
        color: _C.warning,
        route: '/vendedores',
        routeLabel: 'Abrir Vendedores',
        buttons: const [
          GuideButton(Icons.person_add_rounded, 'Nuevo vendedor', color: _C.success),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.upgrade_rounded, 'Promover a gestor', color: _C.primary),
          GuideButton(Icons.storefront_rounded, 'Asignar sucursal'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ESTADÍSTICAS VENDEDORES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📈 Paso 15: Estadísticas de vendedores',
        description:
            'Compara el rendimiento de cada vendedor.\n\n'
            '▸ Total de ventas realizadas.\n'
            '▸ Monto total vendido.\n'
            '▸ Ganancia aportada al negocio.\n'
            '▸ Ranking ordenado de mayor a menor.\n\n'
            '✅ Útil para bonos por comisión, evaluaciones y decisiones de personal.',
        icon: Icons.leaderboard_rounded,
        color: _C.orange,
        route: '/estadisticas-vendedores',
        routeLabel: 'Abrir Estadísticas',
        buttons: const [
          GuideButton(Icons.refresh_rounded, 'Actualizar'),
          GuideButton(Icons.sort_rounded, 'Ordenar'),
          GuideButton(Icons.share_rounded, 'Compartir'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  SUCURSALES
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🏢 Paso 16: Sucursales',
        description:
            'Gestiona múltiples locales o puntos de venta desde una sola cuenta.\n\n'
            '▸ Cada sucursal tiene su propio inventario, ventas y gastos.\n'
            '▸ Asigna un gestor por sucursal.\n'
            '▸ Puedes mover productos entre sucursales.\n'
            '▸ El costo de sucursales adicionales se suma al plan (500 cup/sucursal).\n\n'
            '⚠️ No puedes eliminar una sucursal con productos o ventas asociadas.',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF92400E),
        route: '/sucursales',
        routeLabel: 'Abrir Sucursales',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nueva sucursal', color: _C.success),
          GuideButton(Icons.edit_rounded, 'Editar'),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.person_rounded, 'Asignar gestor'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  NÓMINAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '💼 Paso 17: Nóminas',
        description:
            'Paga a tu personal con cálculo automático de salario y comisiones.\n\n'
            '▸ Define el empleado: salario base, tipo de contrato y % de comisión.\n'
            '▸ La app calcula las comisiones según las ventas del período.\n'
            '▸ Al generar la nómina, se crea automáticamente un gasto asociado.\n'
            '▸ Guarda el histórico de pagos por empleado.\n\n'
            '✅ El costo de personal se refleja en los reportes de ganancia neta.',
        icon: Icons.payments_rounded,
        color: _C.purple,
        route: '/nominas',
        routeLabel: 'Abrir Nóminas',
        buttons: const [
          GuideButton(Icons.person_add_rounded, 'Nuevo empleado', color: _C.success),
          GuideButton(Icons.attach_money_rounded, 'Generar nómina', color: _C.primary),
          GuideButton(Icons.delete_rounded, 'Desactivar', color: _C.danger),
          GuideButton(Icons.history_rounded, 'Ver pagos'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  TRANSFERENCIAS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🏦 Paso 18: Transferencias',
        description:
            'Registra los datos bancarios de cada venta pagada por transferencia.\n\n'
            '▸ Guarda: nombre, carnet, teléfono, número de transferencia, monto y fecha.\n'
            '▸ Vinculada a una venta específica.\n'
            '▸ Se sincroniza con la nube para respaldo.\n\n'
            '💡 Útil para auditoría, reclamos y control de cobros por banco.',
        icon: Icons.receipt_long_rounded,
        color: _C.warning,
        route: '/transferencias',
        routeLabel: 'Abrir Transferencias',
        buttons: const [
          GuideButton(Icons.add_rounded, 'Nueva transferencia', color: _C.success),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
          GuideButton(Icons.visibility_rounded, 'Ver detalle'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ⭐ TIENDA EN LÍNEA · DESTACADO · BENEFICIOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🛍️ Paso 19: Mi Tienda en línea',
        description:
            'Publica tu catálogo en internet y vende a todo el mundo. Sin costo adicional y en minutos.\n\n'
            'CÓMO FUNCIONA:\n'
            '▸ Entra a "Mi tienda" desde el menú lateral o desde la tarjeta de Tienda en línea en el inicio.\n'
            '▸ Publica los productos que quieras mostrar al público con foto, descripción y precio.\n'
            '▸ Personaliza el nombre, logo, descripción, teléfono, WhatsApp, dirección y horario de tu tienda.\n'
            '▸ Comparte el enlace de tu tienda con tus clientes por WhatsApp, redes sociales o donde quieras.\n\n'
            '✅ BENEFICIOS CLAVE:\n'
            '▸ Muestra tus productos 24/7 incluso cuando tu local esté cerrado.\n'
            '▸ Recibe consultas y pedidos directo por WhatsApp y teléfono.\n'
            '▸ Atrae clientes nuevos que te encuentran buscando en la red.\n'
            '▸ No necesitas una página web propia ni saber diseño.\n'
            '▸ Se sincroniza automáticamente con tu inventario.',
        icon: Icons.storefront_rounded,
        color: _C.myBusiness,
        route: '/mi-tienda',
        routeLabel: 'Abrir Mi Tienda',
        highlight: true,
        buttons: const [
          GuideButton(Icons.edit_rounded, 'Editar tienda', color: _C.myBusiness),
          GuideButton(Icons.visibility_rounded, 'Ver vista previa', color: _C.cyan),
          GuideButton(Icons.share_rounded, 'Compartir enlace', color: _C.success),
          GuideButton(Icons.cloud_upload_rounded, 'Publicar producto', color: _C.primary),
        ],
        benefits: const [
          GuideBenefit(
            icon: Icons.public_rounded,
            title: 'Visible 24/7',
            subtitle: 'Tus productos en internet sin parar',
            color: _C.myBusiness,
          ),
          GuideBenefit(
            icon: Icons.share_rounded,
            title: 'Comparte y vende',
            subtitle: 'Un enlace. Mil clientes posibles.',
            color: _C.pink,
          ),
          GuideBenefit(
            icon: Icons.chat_rounded,
            title: 'Pedidos por WhatsApp',
            subtitle: 'Tus clientes te escriben directo',
            color: _C.success,
          ),
          GuideBenefit(
            icon: Icons.currency_exchange_rounded,
            title: 'Sin costo extra',
            subtitle: 'Incluida en tu plan',
            color: _C.cyan,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ⭐ PUBLICAR PRODUCTOS · BENEFICIOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '☁️ Paso 20: Publicar productos',
        description:
            'Publicar un producto es la acción más poderosa de tu tienda. En 30 segundos lo expones al mundo.\n\n'
            'CÓMO HACERLO:\n'
            '▸ Entra a "Mi tienda" → botón "Publicar producto" (o desde la sección Mi Negocio).\n'
            '▸ Elige uno o varios productos de tu inventario.\n'
            '▸ Ajusta el nombre, descripción, foto y precio público (puede ser distinto al de tu tienda física).\n'
            '▸ Confirma y aparecerá al instante en tu tienda pública.\n\n'
            '✅ BENEFICIOS:\n'
            '▸ Pon todo tu catálogo en vitrina digital en un clic.\n'
            '▸ Muestra solo los productos que quieras: destaca lo que necesitas vender más.\n'
            '▸ Cada producto publicado es un cliente potencial más.\n'
            '▸ Administra fácil: activa, desactiva o elimina productos cuando quieras sin afectar tu inventario real.',
        icon: Icons.cloud_upload_rounded,
        color: _C.myBusiness,
        route: '/publicar-producto',
        routeLabel: 'Abrir Publicar Producto',
        highlight: true,
        buttons: const [
          GuideButton(Icons.inventory_2_rounded, 'Elegir producto', color: _C.info),
          GuideButton(Icons.image_rounded, 'Cambiar foto'),
          GuideButton(Icons.attach_money_rounded, 'Precio público', color: _C.success),
          GuideButton(Icons.cloud_upload_rounded, 'Publicar', color: _C.primary),
          GuideButton(Icons.visibility_off_rounded, 'Despublicar', color: _C.danger),
        ],
        benefits: const [
          GuideBenefit(
            icon: Icons.speed_rounded,
            title: '30 segundos',
            subtitle: 'Publica desde tu catálogo',
            color: _C.primary,
          ),
          GuideBenefit(
            icon: Icons.inventory_rounded,
            title: 'Productos ilimitados',
            subtitle: 'Publica todo lo que quieras',
            color: _C.myBusiness,
          ),
          GuideBenefit(
            icon: Icons.attach_money_rounded,
            title: 'Precio público distinto',
            subtitle: 'Ajusta al mercado online',
            color: _C.success,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ⭐ PRODUCTOS PUBLICADOS · BENEFICIOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '📋 Paso 21: Productos publicados',
        description:
            'El panel de control de tu tienda. Aquí ves todo lo que ya está en vitrina pública.\n\n'
            'QUÉ PUEDES HACER:\n'
            '▸ Ver de un vistazo todos los productos que el público ve.\n'
            '▸ Activar o desactivar cada uno sin tocar el inventario real.\n'
            '▸ Cambiar el precio público, la foto o la descripción de cada producto.\n'
            '▸ Eliminar productos publicados que ya no quieras mostrar.\n'
            '▸ Verificar que tienes la información correcta antes de compartir tu enlace.\n\n'
            '✅ BENEFICIOS:\n'
            '▸ Control total sin salir de la app.\n'
            '▸ Prueba qué productos venden más online.\n'
            '▸ Actualiza tu vitrina al instante cuando cambies precios.',
        icon: Icons.inventory_rounded,
        color: _C.myBusiness,
        route: '/productos-publicados',
        routeLabel: 'Abrir Productos Publicados',
        highlight: true,
        buttons: const [
          GuideButton(Icons.check_circle_rounded, 'Activo', color: _C.success),
          GuideButton(Icons.cancel_rounded, 'Oculto', color: _C.danger),
          GuideButton(Icons.edit_rounded, 'Editar', color: _C.primary),
          GuideButton(Icons.delete_rounded, 'Eliminar', color: _C.danger),
        ],
        benefits: const [
          GuideBenefit(
            icon: Icons.toggle_on_rounded,
            title: 'Activa / desactiva',
            subtitle: 'Sin tocar tu inventario',
            color: _C.success,
          ),
          GuideBenefit(
            icon: Icons.auto_fix_high_rounded,
            title: 'Edita al instante',
            subtitle: 'Cambios visibles al público ya',
            color: _C.primary,
          ),
          GuideBenefit(
            icon: Icons.trending_up_rounded,
            title: 'Detecta tus hits',
            subtitle: 'Descubre qué funciona online',
            color: _C.pink,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ⭐ RED NEXORA · EXPLORAR NEGOCIOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🌐 Paso 22: Red Nexora · Explora negocios',
        description:
            'La Red Nexora conecta tu negocio con el de otros emprendedores y clientes de toda la plataforma.\n\n'
            'QUÉ ENCUENTRAS:\n'
            '▸ Un directorio de tiendas y servicios publicados por otras empresas.\n'
            '▸ Búsqueda por categoría: alimentos, electrónica, reparación, belleza, servicios…\n'
            '▸ Ficha completa de cada negocio: nombre, descripción, contacto, WhatsApp, horario y ubicación.\n'
            '▸ Catálogo de productos y servicios que cada negocio publique.\n\n'
            '✅ BENEFICIOS DE ESTAR EN LA RED:\n'
            '▸ Descubrimiento mutuo: otros negocios te encuentran y tú los encuentras a ellos.\n'
            '▸ Más tráfico: clientes que buscan productos como los tuyos llegan a tu tienda.\n'
            '▸ Crea alianzas estratégicas (ver paso siguiente) para colaborar con otros negocios.\n'
            '▸ Da visibilidad a tu marca en toda la comunidad Nexora.\n'
            '▸ Todo incluido en tu plan, sin costo adicional.',
        icon: Icons.hub_rounded,
        color: _C.network,
        route: '/tiendas',
        routeLabel: 'Explorar Red Nexora',
        highlight: true,
        buttons: const [
          GuideButton(Icons.search_rounded, 'Buscar negocio'),
          GuideButton(Icons.filter_alt_rounded, 'Filtrar categoría'),
          GuideButton(Icons.location_on_rounded, 'Ver ubicación', color: _C.success),
          GuideButton(Icons.call_rounded, 'Contactar', color: _C.primary),
          GuideButton(Icons.favorite_rounded, 'Guardar favorito', color: _C.pink),
        ],
        benefits: const [
          GuideBenefit(
            icon: Icons.groups_rounded,
            title: 'Comunidad activa',
            subtitle: 'Cientos de negocios conectados',
            color: _C.network,
          ),
          GuideBenefit(
            icon: Icons.travel_explore_rounded,
            title: 'Descubre clientes',
            subtitle: 'Otros te encuentran a ti',
            color: _C.cyan,
          ),
          GuideBenefit(
            icon: Icons.handshake_rounded,
            title: 'Alianzas 1:1',
            subtitle: 'Colabora con otros negocios',
            color: _C.purple,
          ),
          GuideBenefit(
            icon: Icons.trending_up_rounded,
            title: 'Más ventas',
            subtitle: 'Aparece donde buscan',
            color: _C.success,
          ),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  ALIANZAS Y REFERIDOS
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🤝 Paso 23: Alianzas y Referidos',
        description:
            'Conecta con otras empresas y gana bonos por invitar usuarios.\n\n'
            'ALIANZAS:\n'
            '▸ Envía solicitudes de alianza a otras empresas de la Red Nexora.\n'
            '▸ Acepta o rechaza las que recibas.\n'
            '▸ Una alianza activa permite colaboración mutua entre negocios.\n\n'
            'REFERIDOS:\n'
            '▸ Comparte Nexora con otros negocios.\n'
            '▸ Cuando 2 empresas referidas paguen su plan, ganas un bono del 50% de descuento.\n'
            '▸ Los bonos se aplican automáticamente al siguiente pago.',
        icon: Icons.handshake_rounded,
        color: _C.pink,
        routeLabel: 'Ver explicación completa',
        buttons: const [
          GuideButton(Icons.share_rounded, 'Invitar amigos', color: _C.pink),
          GuideButton(Icons.handshake_rounded, 'Solicitar alianza', color: _C.primary),
          GuideButton(Icons.check_rounded, 'Aceptar', color: _C.success),
          GuideButton(Icons.close_rounded, 'Rechazar', color: _C.danger),
          GuideButton(Icons.star_rounded, 'Ver bonos', color: _C.warning),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  MÓDULO FISCAL
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🧾 Paso 24: Módulo Fiscal',
        description:
            'Herramientas orientativas para el cálculo de impuestos.\n\n'
            '▸ Impuesto sobre ventas (%).\n'
            '▸ Impuesto sobre utilidades (%).\n'
            '▸ Libro de ingresos y gastos ordenado cronológicamente con saldo acumulado.\n'
            '▸ Exportable para presentar al contador.\n\n'
            '⚠️ Los valores son orientativos. Consulta siempre con un contador profesional.',
        icon: Icons.request_quote_rounded,
        color: _C.purple,
        route: '/fiscal',
        routeLabel: 'Abrir Módulo Fiscal',
        buttons: const [
          GuideButton(Icons.filter_list_rounded, 'Filtrar período'),
          GuideButton(Icons.picture_as_pdf_rounded, 'Exportar PDF', color: _C.danger),
          GuideButton(Icons.table_chart_rounded, 'Exportar Excel', color: _C.success),
          GuideButton(Icons.share_rounded, 'Compartir'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  FACTURACIÓN
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🧾 Paso 25: Facturación',
        description:
            'Genera facturas profesionales para tus clientes.\n\n'
            '▸ Selecciona una venta ya registrada.\n'
            '▸ La app genera una factura con los datos del negocio y del cliente.\n'
            '▸ Puedes exportarla a PDF y compartirla.\n\n'
            '💡 Ideal para clientes que necesitan comprobante formal.',
        icon: Icons.receipt_rounded,
        color: _C.cyan,
        route: '/facturacion',
        routeLabel: 'Abrir Facturación',
        buttons: const [
          GuideButton(Icons.picture_as_pdf_rounded, 'Descargar PDF', color: _C.danger),
          GuideButton(Icons.share_rounded, 'Compartir factura', color: _C.primary),
          GuideButton(Icons.print_rounded, 'Imprimir'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  CONFIGURACIÓN
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '⚙️ Paso 26: Configuración',
        description:
            'Ajusta la app a tu medida.\n\n'
            '▸ MODO DE VENTAS: alterna entre Tiempo real y Cierre diario.\n'
            '▸ TASA DE CAMBIO USD: define el valor para conversiones.\n'
            '▸ IMPUESTOS: porcentajes usados en el módulo fiscal.\n'
            '▸ TEMA: claro, oscuro o sistema.\n\n'
            '💡 Los cambios se aplican al instante y se guardan localmente.',
        icon: Icons.settings_rounded,
        color: _C.textMuted,
        route: '/settings',
        routeLabel: 'Abrir Configuración',
        buttons: const [
          GuideButton(Icons.point_of_sale_rounded, 'Modo tiempo real', color: _C.primary),
          GuideButton(Icons.event_available_rounded, 'Modo cierre diario', color: _C.warning),
          GuideButton(Icons.monetization_on_rounded, 'Tasa USD'),
          GuideButton(Icons.percent_rounded, 'Impuestos'),
          GuideButton(Icons.light_mode_rounded, 'Tema claro'),
          GuideButton(Icons.dark_mode_rounded, 'Tema oscuro'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  REALIZAR PAGO
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '💳 Paso 27: Realizar pago y planes',
        description:
            'Gestiona tu suscripción y los planes disponibles.\n\n'
            'PLANES:\n'
            '▸ Prueba gratuita: 3 días con todas las funciones Premium.\n'
            '▸ Normal: 2 vendedores por sucursal.\n'
            '▸ Premium: 5 vendedores por sucursal, tienda en línea, notificaciones de stock y exportación a PDF/Excel.\n'
            '▸ Sucursal adicional: +500 cup cada una.\n\n'
            'CÓMO PAGAR:\n'
            '▸ Registra el número de transacción bancaria.\n'
            '▸ Envía la solicitud. El equipo la aprueba y se activa el período (30 días + 3 de gracia).\n'
            '▸ Si tienes un bono activo, se aplica automáticamente.\n\n'
            '⏰ La app te avisa con un banner cuando se acerca el próximo pago.',
        icon: Icons.payment_rounded,
        color: _C.cyan,
        route: '/pago',
        routeLabel: 'Abrir Realizar Pago',
        buttons: const [
          GuideButton(Icons.credit_card_rounded, 'Pagar ahora', color: _C.success),
          GuideButton(Icons.receipt_rounded, 'Ver solicitud'),
          GuideButton(Icons.star_rounded, 'Bono aplicado', color: _C.warning),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  SOPORTE
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🎧 Paso 28: Soporte',
        description:
            'Contáctanos si tienes dudas, problemas o sugerencias.\n\n'
            '▸ Envía mensajes al equipo de soporte desde la app.\n'
            '▸ Recibirás la respuesta en el mismo chat.\n'
            '▸ Útil si tuviste un error, un cobro pendiente o una consulta técnica.\n\n'
            '✅ El botón de soporte está siempre disponible.',
        icon: Icons.support_agent_rounded,
        color: _C.purple,
        route: '/soporte',
        routeLabel: 'Abrir Soporte',
        buttons: const [
          GuideButton(Icons.send_rounded, 'Enviar mensaje', color: _C.primary),
          GuideButton(Icons.refresh_rounded, 'Actualizar chat'),
          GuideButton(Icons.history_rounded, 'Ver histórico'),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  SINCRONIZACIÓN OFFLINE
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🔄 Paso 29: Sincronización offline',
        description:
            'Trabaja sin conexión a internet sin perder nada.\n\n'
            '▸ Todo se guarda localmente (Hive) de forma inmediata y segura.\n'
            '▸ Cuando recuperas la conexión, se sincroniza automáticamente en segundo plano.\n'
            '▸ Puedes forzar la sincronización manual tocando el ícono ↻.\n'
            '▸ Si hay operaciones pendientes, verás un badge rojo con el número.\n'
            '▸ Si falla la sincronización, la app reintenta cada 30 segundos.\n\n'
            '✅ Nunca pierdes datos, aunque estés días sin conexión.',
        icon: Icons.sync_rounded,
        color: _C.cyan,
        routeLabel: 'Entendido, siguiente',
        buttons: const [
          GuideButton(Icons.sync_rounded, 'Sincronizar ahora', color: _C.primary),
          GuideButton(Icons.cloud_off_rounded, 'Sin conexión', color: _C.warning),
          GuideButton(Icons.cloud_done_rounded, 'Sincronizado', color: _C.success),
        ],
      ),

      // ════════════════════════════════════════════════════════
      //  CIERRE
      // ════════════════════════════════════════════════════════
      TourStep(
        title: '🎉 ¡Guía completada!',
        description:
            'Ya conoces todas las funciones de Nexora Business. Ahora puedes gestionar tu negocio como un profesional.\n\n'
            '✅ RESUMEN DE LO APRENDIDO:\n'
            '▸ Inventario con precios múltiples y categorías integradas.\n'
            '▸ Reabastecer con lotes y cálculo FIFO automático.\n'
            '▸ Dos modos de ventas: tiempo real y cierre diario.\n'
            '▸ Clientes, deudas, gastos y mermas.\n'
            '▸ Movimientos entre sucursales.\n'
            '▸ Metas, reportes y estadísticas.\n'
            '▸ Vendedores, gestores, nóminas y transferencias.\n'
            '▸ 🌟 Tienda en línea: pública, sin costo extra, con pedidos por WhatsApp.\n'
            '▸ 🌟 Red Nexora: descubre negocios, crea alianzas y gana visibilidad.\n'
            '▸ Alianzas, referidos y bonos.\n'
            '▸ Módulo fiscal y facturación.\n'
            '▸ Configuración, planes y soporte.\n'
            '▸ Sincronización offline automática.\n\n'
            '🔑 RECUERDA SIEMPRE:\n'
            '▸ Usa datos reales para que los reportes sean precisos.\n'
            '▸ Publica tu tienda en línea y compártela en tus redes.\n'
            '▸ Revisa el banner de pago para no interrumpir el servicio.\n'
            '▸ Si tienes dudas, abre la guía o contacta a soporte.\n\n'
            '¡Éxito con tu negocio! 🚀',
        icon: Icons.emoji_events_rounded,
        color: _C.success,
        routeLabel: 'Finalizar y comenzar a usar la app',
        benefits: const [
          GuideBenefit(
            icon: Icons.check_circle_rounded,
            title: 'Guía completada',
            subtitle: 'Ahora eres un experto',
            color: _C.success,
          ),
        ],
      ),
    ];
  }

  void _goToStep(int index) {
    final step = _steps[index];
    if (step.route != null) {
      Navigator.pushNamed(context, step.route!).then((_) {
        if (_currentStep < _steps.length - 1) {
          setState(() => _currentStep++);
        }
      });
    } else {
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
      } else {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.marcarGuiaVista();
        Navigator.pop(context);
      }
    }
  }

  void _volverPaso() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _confirmarSalida() async {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    if (_currentStep == _steps.length - 1) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.marcarGuiaVista();
      Navigator.pop(context);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.warning.withOpacity(.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _C.warning, size: 19),
            ),
            const SizedBox(width: 12),
            Text(
              '¿Salir de la guía?',
              style: TextStyle(
                color: p.textHigh,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Aún no has terminado el recorrido. Te recomendamos completar los '
          '${_steps.length} pasos para conocer todas las funciones.\n\n'
          '¿Seguro que quieres salir?',
          style: TextStyle(color: p.textMid, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Continuar',
              style: TextStyle(
                  color: p.textMid, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salir de todas formas',
              style: TextStyle(
                color: _C.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.marcarGuiaVista();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();
    final step = _steps[_currentStep];
    final totalSteps = _steps.length;
    final progress = (_currentStep + 1) / totalSteps;
    final stepColor = _stepColor(step.color);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmarSalida();
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
                  const Text(
                    'Guía de usuario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Paso ${_currentStep + 1} de $totalSteps',
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
          actions: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: p.textHigh),
              onPressed: _confirmarSalida,
              tooltip: 'Salir',
            ),
          ],
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
                          colors: [stepColor, stepColor.withOpacity(.65)],
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
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainCard(
                                step, stepColor, isDesktop, p),
                            if (step.benefits.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildBenefits(step, p),
                            ],
                            const SizedBox(height: 14),
                            _buildDataWarning(p),
                            const SizedBox(height: 14),
                            _buildStepIndicator(p, totalSteps),
                            const SizedBox(height: 20),
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
  //  CARD PRINCIPAL
  // ============================================================
  Widget _buildMainCard(
      TourStep step, Color stepColor, bool isDesktop, _P p) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: step.highlight
              ? stepColor.withOpacity(.45)
              : p.border,
          width: step.highlight ? 1.5 : 1,
        ),
        boxShadow: step.highlight
            ? [
                BoxShadow(
                  color: stepColor.withOpacity(.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : p.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header con icono y título
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isDesktop ? 64 : 56,
                height: isDesktop ? 64 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      stepColor.withOpacity(.24),
                      stepColor.withOpacity(.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: stepColor.withOpacity(.32),
                    width: step.highlight ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stepColor.withOpacity(.20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(step.icon,
                    color: stepColor, size: isDesktop ? 32 : 28),
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
                            colors: [
                              stepColor,
                              stepColor.withOpacity(.72),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: stepColor.withOpacity(.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'DESTACADO',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: isDesktop ? 22 : 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: p.textHigh,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── Descripción con formato
          _buildDescription(step.description, p),

          // ─── Botones de la sección
          if (step.buttons.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildButtonsShowcase(step, p),
          ],
          const SizedBox(height: 22),

          // ─── Botón de acción principal
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _goToStep(_currentStep),
              icon: Icon(
                step.route != null
                    ? Icons.arrow_forward_rounded
                    : (_currentStep == _steps.length - 1
                        ? Icons.check_rounded
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
                backgroundColor: stepColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          if (step.route != null) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Al regresar, avanzarás automáticamente al siguiente paso',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: p.textMuted,
                ),
              ),
            ),
          ],
          if (_currentStep > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _volverPaso,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Paso anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.textMid,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: p.border),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  //  DESCRIPCIÓN CON FORMATO
  // ============================================================
  Widget _buildDescription(String text, _P p) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('▸')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Text(
                    '▸',
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trimmed.substring(1).trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: p.textMid,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (trimmed.startsWith('⚠️') ||
            trimmed.startsWith('💡') ||
            trimmed.startsWith('✅') ||
            trimmed.startsWith('🔑') ||
            trimmed.startsWith('⏰') ||
            trimmed.startsWith('🛍️') ||
            trimmed.startsWith('🌐')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: p.border),
              ),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13.5,
                  color: p.textMid,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          );
        } else if (trimmed == 'ALIANZAS:' ||
            trimmed == 'REFERIDOS:' ||
            trimmed == 'PLANES:' ||
            trimmed == 'CÓMO PAGAR:' ||
            trimmed == 'CÓMO FUNCIONA:' ||
            trimmed == 'QUÉ ENCUENTRAS:' ||
            trimmed == 'QUÉ PUEDES HACER:' ||
            trimmed == 'PROCESO DE USO:' ||
            trimmed == 'ANTES DE EMPEZAR:' ||
            trimmed == 'MODO TIEMPO REAL:' ||
            trimmed == 'MODO CIERRE DIARIO:' ||
            trimmed == '✅ BENEFICIOS:' ||
            trimmed == '✅ BENEFICIOS DE ESTAR EN LA RED:' ||
            trimmed == '✅ RESUMEN DE LO APRENDIDO:' ||
            trimmed == '🔑 RECUERDA SIEMPRE:' ||
            trimmed == '🔵 MODO TIEMPO REAL:' ||
            trimmed == '🟠 MODO CIERRE DIARIO:') {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: _C.gradBrand),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trimmed,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: p.textHigh,
                  ),
                ),
              ],
            ),
          );
        } else if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 14.5,
                color: p.textHigh,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  // ============================================================
  //  BENEFICIOS DESTACADOS
  // ============================================================
  Widget _buildBenefits(TourStep step, _P p) {
    final isDesktop = ResponsiveHelper.isDesktop();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            step.color.withOpacity(p.dark ? .16 : .09),
            step.color.withOpacity(p.dark ? .05 : .025),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: step.color.withOpacity(.32), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: step.color.withOpacity(.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [step.color, step.color.withOpacity(.72)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: step.color.withOpacity(.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.stars_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Text(
                'BENEFICIOS CLAVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: step.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          isDesktop
              ? Row(
                  children: step.benefits
                      .map((b) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _benefitTile(b, p),
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: step.benefits
                      .map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _benefitTile(b, p),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _benefitTile(GuideBenefit b, _P p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: b.color.withOpacity(.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: b.color.withOpacity(.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: b.color.withOpacity(.30)),
            ),
            child: Icon(b.icon, color: b.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: p.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  b.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BOTONES SHOWCASE
  // ============================================================
  Widget _buildButtonsShowcase(TourStep step, _P p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.touch_app_rounded,
                size: 16, color: _C.primary),
            const SizedBox(width: 8),
            Text(
              'Botones de esta sección',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: step.buttons.map((b) {
              final c = _stepColor(b.color ?? _C.primary);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: c.withOpacity(.32)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(b.icon, size: 15, color: c),
                    const SizedBox(width: 6),
                    Text(
                      b.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: p.textHigh,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  ADVERTENCIA DE DATOS REALES
  // ============================================================
  Widget _buildDataWarning(_P p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(p.dark ? .12 : .06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.warning.withOpacity(.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.warning.withOpacity(.22),
                  _C.warning.withOpacity(.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.warning.withOpacity(.28)),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: _C.warning, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Usa datos reales. Los datos de prueba distorsionan reportes y estadísticas.',
              style: TextStyle(
                fontSize: 12.5,
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
  //  INDICADOR DE PASO
  // ============================================================
  Widget _buildStepIndicator(_P p, int total) {
    final pct = (_currentStep / (total - 1)) * 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.timeline_rounded,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Progreso: $_currentStep de ${total - 1}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: p.textHigh,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}