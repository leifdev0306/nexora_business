// ============================================================
//  soporte_screen.dart · NEXORA BUSINESS
//  Centro de soporte con chat premium y temporizador
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../responsive_helper.dart';

class _C {
  static const primary = Color(0xFF1A5CFF);
  static const cyan = Color(0xFF06B6D4);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const gold = Color(0xFFCA8A04);

  static const gradBrand = [Color(0xFF1A5CFF), Color(0xFF06B6D4)];
  static const gradGold = [Color(0xFFF59E0B), Color(0xFFCA8A04)];
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
  Color get textHigh =>
      dark ? const Color(0xFFEEF4FC) : const Color(0xFF0A1A33);
  Color get textMid =>
      dark ? const Color(0xFFB8CBE8) : const Color(0xFF1C3352);
  Color get textMuted =>
      dark ? const Color(0xFF7D95B6) : const Color(0xFF607B9E);
  Color get border =>
      dark ? const Color(0x291A5CFF) : const Color(0x141A5CFF);
  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: dark
              ? Colors.black.withOpacity(.30)
              : const Color(0xFF0A1A33).withOpacity(.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class SoporteScreen extends StatefulWidget {
  const SoporteScreen({Key? key}) : super(key: key);

  @override
  State<SoporteScreen> createState() => _SoporteScreenState();
}

class _SoporteScreenState extends State<SoporteScreen> {
  final _mensajeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  bool _recargando = false;

  static const int MAX_CARACTERES = 500;
  static const int TIEMPO_ESPERA_MINUTOS = 5;

  DateTime? _ultimoEnvio;
  int _segundosRestantes = 0;
  Timer? _timer;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _cargarUltimoEnvio();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarUltimoEnvio() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final box = provider.settingsBox;
    if (box != null) {
      final ultimo = box.get('ultimo_envio_soporte') as String?;
      if (ultimo != null) {
        _ultimoEnvio = DateTime.tryParse(ultimo);
      }
    }
    _actualizarTemporizador();
  }

  void _actualizarTemporizador() {
    if (_ultimoEnvio == null) {
      if (mounted) setState(() => _segundosRestantes = 0);
      return;
    }
    final ahora = DateTime.now();
    final diff = ahora.difference(_ultimoEnvio!);
    final segundosEspera = TIEMPO_ESPERA_MINUTOS * 60;
    final restantes =
        (segundosEspera - diff.inSeconds).clamp(0, segundosEspera);
    if (mounted) setState(() => _segundosRestantes = restantes);

    if (restantes > 0) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_segundosRestantes > 0) {
            _segundosRestantes--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  Future<void> _cargarMensajes() async {
    if (mounted) setState(() => _cargando = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final data = await provider.obtenerMensajesSoporte();
    if (!mounted) return;
    setState(() {
      _mensajes = data;
      _cargando = false;
    });
  }

  Future<void> _recargarMensajes() async {
    if (_recargando) return;
    setState(() => _recargando = true);
    await _cargarMensajes();
    if (mounted) setState(() => _recargando = false);
  }

  bool get _puedeEnviar =>
      _mensajeCtrl.text.trim().isNotEmpty &&
      _mensajeCtrl.text.length <= MAX_CARACTERES &&
      _segundosRestantes == 0 &&
      !_enviando;

  String get _tiempoRestanteTexto {
    if (_segundosRestantes <= 0) return 'Listo';
    final minutos = _segundosRestantes ~/ 60;
    final segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _mensajeCtrl.text.trim();
    if (!_puedeEnviar) return;

    setState(() => _enviando = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.enviarMensajeSoporte(mensaje);

      final ahora = DateTime.now();
      _ultimoEnvio = ahora;
      final box = provider.settingsBox;
      if (box != null) {
        await box.put('ultimo_envio_soporte', ahora.toIso8601String());
      }
      _mensajeCtrl.clear();
      _actualizarTemporizador();
      await _cargarMensajes();

      if (!mounted) return;
      mostrarSnackBar(
        mensaje: 'Mensaje enviado correctamente',
        esExito: true,
        icono: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      mostrarSnackBar(
        mensaje: 'Error: ${mensajeAmigable(e)}',
        esExito: false,
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final p = _P(Theme.of(context).brightness == Brightness.dark);
    final isDesktop = ResponsiveHelper.isDesktop();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: _appBar(p),
      body: Stack(
        children: [
          _background(p),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 14, 12, isDesktop ? 24 : 14, 0),
                child: _infoCard(p),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _mensajes.isEmpty
                        ? _emptyState(p)
                        : ListView.builder(
                            reverse: true,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                                isDesktop ? 24 : 12,
                                8,
                                isDesktop ? 24 : 12,
                                8),
                            itemCount: _mensajes.length,
                            itemBuilder: (_, i) =>
                                _mensajeBubble(_mensajes[i], provider, p),
                          ),
              ),
              _inputBar(p, isDesktop),
            ],
          ),
        ],
      ),
    );
  }

  Widget _background(_P p) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -160,
              child: _orb(420, _C.primary.withOpacity(p.dark ? .12 : .07)),
            ),
            Positioned(
              bottom: -220,
              left: -140,
              child: _orb(440, _C.cyan.withOpacity(p.dark ? .10 : .06)),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(_P p) {
    return AppBar(
      backgroundColor: p.surface,
      foregroundColor: p.textHigh,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Soporte',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Estamos para ayudarte',
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
          tooltip: 'Recargar',
          icon: _recargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.refresh_rounded, color: p.textHigh),
          onPressed: _recargando ? null : _recargarMensajes,
        ),
      ],
    );
  }

  Widget _infoCard(_P p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primary.withOpacity(p.dark ? .12 : .06),
            _C.cyan.withOpacity(p.dark ? .06 : .03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primary.withOpacity(.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: _C.gradBrand),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(.32),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Envíanos tu consulta o problema. Te responderemos a la brevedad.\n'
              'Máximo $MAX_CARACTERES caracteres · 1 mensaje cada $TIEMPO_ESPERA_MINUTOS minutos.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: p.textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(_P p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.primary.withOpacity(.16),
                    _C.cyan.withOpacity(.06),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 42, color: _C.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay mensajes aún',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: p.textHigh,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escribe tu primera consulta abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Fix: solo campos reales ({id, mensaje, fecha, esAdmin})
  Widget _mensajeBubble(
      Map<String, dynamic> msg, AppProvider provider, _P p) {
    final esAdmin = msg['esAdmin'] == true;

    final gradColors = esAdmin ? _C.gradGold : _C.gradBrand;
    final bgColor = esAdmin
        ? _C.warning.withOpacity(p.dark ? .14 : .08)
        : _C.primary.withOpacity(p.dark ? .14 : .08);
    final borderColor = esAdmin
        ? _C.warning.withOpacity(.32)
        : _C.primary.withOpacity(.24);

    final fecha = msg['fecha'] != null
        ? DateFormat('HH:mm').format(
            DateTime.tryParse(msg['fecha'].toString()) ?? DateTime.now())
        : '';

    // Admin a la izquierda, usuario a la derecha
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            esAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (esAdmin) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradColors),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: _C.warning.withOpacity(.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esAdmin ? 4 : 16),
                  bottomRight: Radius.circular(esAdmin ? 16 : 4),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        esAdmin ? 'Soporte' : 'Tú',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: esAdmin ? _C.warning : _C.primary,
                        ),
                      ),
                      if (esAdmin) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(colors: _C.gradGold),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'STAFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    msg['mensaje'] ?? '',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: p.textHigh,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fecha,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.textMuted,
                        ),
                      ),
                      if (!esAdmin) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.done_all_rounded,
                            size: 12, color: _C.success),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!esAdmin) ...[
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _C.gradBrand),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: _C.primary.withOpacity(.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputBar(_P p, bool isDesktop) {
    final puedeEnviar = _puedeEnviar;
    final tieneTimer = _segundosRestantes > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 12, 12, isDesktop ? 24 : 12, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: TextField(
                      controller: _mensajeCtrl,
                      focusNode: _focusNode,
                      maxLength: MAX_CARACTERES,
                      enabled: !tieneTimer,
                      maxLines: 4,
                      minLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: p.textHigh,
                      ),
                      decoration: InputDecoration(
                        hintText: tieneTimer
                            ? 'Podrás enviar en $_tiempoRestanteTexto'
                            : 'Escribe tu mensaje…',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: p.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: puedeEnviar ? _enviarMensaje : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: puedeEnviar
                            ? const LinearGradient(colors: _C.gradBrand)
                            : null,
                        color: puedeEnviar ? null : p.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: puedeEnviar
                            ? null
                            : Border.all(color: p.border),
                        boxShadow: puedeEnviar
                            ? [
                                BoxShadow(
                                  color: _C.primary.withOpacity(.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: _enviando
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              tieneTimer
                                  ? Icons.timer_rounded
                                  : Icons.send_rounded,
                              color:
                                  puedeEnviar ? Colors.white : p.textMuted,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_mensajeCtrl.text.length}/$MAX_CARACTERES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _mensajeCtrl.text.length >
                            MAX_CARACTERES * 0.9
                        ? _C.warning
                        : p.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                if (tieneTimer) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.warning.withOpacity(p.dark ? .16 : .10),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _C.warning.withOpacity(.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_clock_rounded,
                            size: 11, color: _C.warning),
                        const SizedBox(width: 4),
                        Text(
                          _tiempoRestanteTexto,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _C.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 11, color: _C.success),
                      const SizedBox(width: 4),
                      Text(
                        'Listo para enviar',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _C.success.withOpacity(.9),
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                if (tieneTimer)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1 -
                            (_segundosRestantes /
                                (TIEMPO_ESPERA_MINUTOS * 60)),
                        minHeight: 4,
                        backgroundColor: p.border,
                        valueColor:
                            const AlwaysStoppedAnimation(_C.warning),
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

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}