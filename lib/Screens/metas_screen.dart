import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../responsive_helper.dart';
import '../main.dart';
import 'servicio_cancelado_screen.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({Key? key}) : super(key: key);

  @override
  _MetasScreenState createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  final _diariaCtrl = TextEditingController();
  final _semanalCtrl = TextEditingController();
  final _mensualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.meta != null) {
      _diariaCtrl.text = provider.meta!.metaDiaria.toString();
      _semanalCtrl.text = provider.meta!.metaSemanal.toString();
      _mensualCtrl.text = provider.meta!.metaMensual.toString();
    }
  }

  @override
  void dispose() {
    _diariaCtrl.dispose();
    _semanalCtrl.dispose();
    _mensualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    if (!provider.empresaActiva) {
      return ServicioCanceladoScreen(onLogout: () => provider.logout());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveHelper.isDesktop();
    final isSmall = ResponsiveHelper.isSmallMobile(context);
    final meta = provider.meta;

    // Calcular progreso con los datos del período actual
    final ventasActuales = provider.getTotalVentas(provider.inicioPeriodo, provider.finPeriodo);
    final metaDiaria = meta?.metaDiaria ?? 0;
    final metaSemanal = meta?.metaSemanal ?? 0;
    final metaMensual = meta?.metaMensual ?? 0;
    final periodoLabel = provider.getPeriodoLabel(); // ✅ Obtenemos el texto del período

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de Ventas'),
        elevation: 0,
        backgroundColor: isDark ? colorFondoOscuroCard : Theme.of(context).primaryColor,
        foregroundColor: isDark ? colorTextoOscuro : Colors.white,
      ),
      body: ResponsiveHelper.wrapScaffoldBody(
        context,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              ? _buildDesktopLayout(
                  context,
                  provider,
                  isDark,
                  isSmall,
                  meta,
                  ventasActuales,
                  metaDiaria,
                  metaSemanal,
                  metaMensual,
                  periodoLabel, // ✅ Pasamos el período
                )
              : _buildMobileLayout(
                  context,
                  provider,
                  isDark,
                  isSmall,
                  meta,
                  ventasActuales,
                  metaDiaria,
                  metaSemanal,
                  metaMensual,
                  periodoLabel, // ✅ Pasamos el período
                ),
        ),
      ),
    );
  }

  // ============================================================
  // LAYOUT ESCRITORIO (dos columnas)
  // ============================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    bool isSmall,
    MetaVenta? meta,
    double ventasActuales,
    double metaDiaria,
    double metaSemanal,
    double metaMensual,
    String periodoLabel,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: Formulario
        Expanded(
          flex: 1,
          child: _buildFormularioCard(
            context,
            provider,
            isDark,
            isSmall,
            true,
            meta,
          ),
        ),
        const SizedBox(width: 24),
        // Columna derecha: Progreso
        Expanded(
          flex: 1,
          child: _buildProgresoCard(
            context,
            isDark,
            isSmall,
            true,
            ventasActuales,
            metaDiaria,
            metaSemanal,
            metaMensual,
            meta,
            periodoLabel, // ✅ Pasamos el período
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LAYOUT MÓVIL (una columna)
  // ============================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    bool isSmall,
    MetaVenta? meta,
    double ventasActuales,
    double metaDiaria,
    double metaSemanal,
    double metaMensual,
    String periodoLabel,
  ) {
    return Column(
      children: [
        _buildFormularioCard(
          context,
          provider,
          isDark,
          isSmall,
          false,
          meta,
        ),
        const SizedBox(height: 16),
        _buildProgresoCard(
          context,
          isDark,
          isSmall,
          false,
          ventasActuales,
          metaDiaria,
          metaSemanal,
          metaMensual,
          meta,
          periodoLabel, // ✅ Pasamos el período
        ),
      ],
    );
  }

  // ============================================================
  // TARJETA DE FORMULARIO
  // ============================================================

  Widget _buildFormularioCard(
    BuildContext context,
    AppProvider provider,
    bool isDark,
    bool isSmall,
    bool isDesktop,
    MetaVenta? meta,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? colorFondoOscuroCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: isDark ? colorAcentoOscuro : Colors.blue.shade700),
                const SizedBox(width: 10),
                Text(
                  '📊 Configurar Metas',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorTextoOscuro : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Define tus objetivos de ventas por período. Las barras de progreso se actualizarán automáticamente.',
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                color: isDark ? colorTextoOscuroSecundario : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Meta Diaria
            _buildInputField(
              controller: _diariaCtrl,
              label: 'Meta diaria (\$)',
              icon: Icons.today,
              isDark: isDark,
              isSmall: isSmall,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 12),
            // Meta Semanal
            _buildInputField(
              controller: _semanalCtrl,
              label: 'Meta semanal (\$)',
              icon: Icons.calendar_view_week,
              isDark: isDark,
              isSmall: isSmall,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 12),
            // Meta Mensual
            _buildInputField(
              controller: _mensualCtrl,
              label: 'Meta mensual (\$)',
              icon: Icons.calendar_month,
              isDark: isDark,
              isSmall: isSmall,
              isDesktop: isDesktop,
            ),
            const SizedBox(height: 20),
            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: isSmall ? 48 : 54,
              child: ElevatedButton.icon(
                onPressed: () => _guardarMetas(context, provider),
                icon: const Icon(Icons.save),
                label: Text(
                  'Guardar Metas',
                  style: TextStyle(
                    fontSize: isSmall ? 15 : 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isSmall,
    required bool isDesktop,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isDark ? colorTextoOscuroSecundario : Colors.grey.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        labelStyle: TextStyle(
          color: isDark ? colorTextoOscuroSecundario : Colors.black87,
          fontSize: isSmall ? 13 : 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? colorBordeOscuro : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? colorAcentoOscuro : Colors.blue.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: isDark ? colorTextoOscuro : Colors.black87,
        fontSize: isSmall ? 14 : 16,
      ),
    );
  }

  // ============================================================
  // TARJETA DE PROGRESO (CORREGIDA: ahora recibe periodoLabel)
  // ============================================================

  Widget _buildProgresoCard(
    BuildContext context,
    bool isDark,
    bool isSmall,
    bool isDesktop,
    double ventasActuales,
    double metaDiaria,
    double metaSemanal,
    double metaMensual,
    MetaVenta? meta,
    String periodoLabel, // ✅ Recibimos el texto del período
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? colorFondoOscuroCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: isDark ? colorAcentoOscuro : Colors.green.shade700),
                const SizedBox(width: 10),
                Text(
                  '📈 Progreso de Metas',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorTextoOscuro : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Período: $periodoLabel', // ✅ Usamos el parámetro
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                color: isDark ? colorTextoOscuroSecundario : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ventas actuales: \$${_formatNumber(ventasActuales)}',
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: isDark ? colorTextoOscuro : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (meta == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange.withOpacity(0.12) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.orange.withOpacity(0.3) : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: isDark ? Colors.orange.shade300 : Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aún no has definido metas. Configura tus metas en el formulario de la izquierda.',
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 15,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildMetaProgress(
                label: 'Diaria',
                meta: metaDiaria,
                actual: ventasActuales,
                isDark: isDark,
                isSmall: isSmall,
              ),
              const SizedBox(height: 12),
              _buildMetaProgress(
                label: 'Semanal',
                meta: metaSemanal,
                actual: ventasActuales,
                isDark: isDark,
                isSmall: isSmall,
              ),
              const SizedBox(height: 12),
              _buildMetaProgress(
                label: 'Mensual',
                meta: metaMensual,
                actual: ventasActuales,
                isDark: isDark,
                isSmall: isSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaProgress({
    required String label,
    required double meta,
    required double actual,
    required bool isDark,
    required bool isSmall,
  }) {
    final porcentaje = meta > 0 ? (actual / meta * 100).clamp(0, 100) : 0;
    final color = porcentaje >= 80
        ? Colors.green
        : porcentaje >= 50
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 14 : 16,
                color: isDark ? colorTextoOscuro : Colors.black87,
              ),
            ),
            Text(
              '\$${_formatNumber(actual)} / \$${_formatNumber(meta)}',
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                color: isDark ? colorTextoOscuroSecundario : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: porcentaje / 100,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  color: color,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text(
                '${porcentaje.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        if (porcentaje >= 80 && actual > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: isSmall ? 16 : 20),
                const SizedBox(width: 4),
                Text(
                  '¡Excelente! Meta casi alcanzada.',
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GUARDAR METAS (LÓGICA ORIGINAL)
  // ============================================================

  Future<void> _guardarMetas(BuildContext context, AppProvider provider) async {
    final diaria = double.tryParse(_diariaCtrl.text) ?? 0;
    final semanal = double.tryParse(_semanalCtrl.text) ?? 0;
    final mensual = double.tryParse(_mensualCtrl.text) ?? 0;

    if (diaria > 0 && semanal > 0 && mensual > 0) {
      try {
        await provider.guardarMeta(MetaVenta(
          id: '',
          metaDiaria: diaria,
          metaSemanal: semanal,
          metaMensual: mensual,
          fechaActualizacion: DateTime.now(),
        ));
        mostrarSnackBar(mensaje: 'Metas guardadas correctamente', esExito: true);
      } catch (e) {
        mostrarSnackBar(mensaje: 'Error al guardar metas: $e', esExito: false);
      }
    } else {
      mostrarSnackBar(mensaje: 'Ingresa valores válidos (mayores que 0)', esExito: false);
    }
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return NumberFormat('#,###').format(number);
    } else {
      return NumberFormat('#,##0.00').format(number);
    }
  }
}