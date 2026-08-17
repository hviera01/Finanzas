import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

enum ModoPin { crear, ingresar }

class PinScreen extends ConsumerStatefulWidget {
  final ModoPin modo;
  final VoidCallback onListo;

  const PinScreen({super.key, required this.modo, required this.onListo});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  bool _recordarDispositivo = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final pin = _pinCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'El PIN debe tener al menos 4 dígitos');
      return;
    }

    final pinService = ref.read(pinServiceProvider);

    if (widget.modo == ModoPin.crear) {
      if (pin != _pinConfirmCtrl.text.trim()) {
        setState(() => _error = 'Los PIN no coinciden');
        return;
      }
      setState(() {
        _cargando = true;
        _error = null;
      });
      await pinService.crearPin(pin);
      if (_recordarDispositivo) await pinService.recordarDispositivo(pin);
      widget.onListo();
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });
    final ok = await pinService.verificarPin(pin);
    if (!ok) {
      setState(() {
        _cargando = false;
        _error = 'PIN incorrecto';
      });
      _pinCtrl.clear();
      return;
    }
    if (_recordarDispositivo) await pinService.recordarDispositivo(pin);
    widget.onListo();
  }

  @override
  Widget build(BuildContext context) {
    final esCrear = widget.modo == ModoPin.crear;
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.credit_card_rounded, color: AppColors.acento, size: 44),
                const SizedBox(height: 16),
                Text(
                  esCrear ? 'Creá tu PIN de acceso' : 'Ingresá tu PIN',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  esCrear
                      ? 'Se usará para proteger el acceso a tus tarjetas y compras.'
                      : 'Protegiendo tus tarjetas y compras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _pinCtrl,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    hintText: 'PIN',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  onSubmitted: (_) => esCrear ? null : _confirmar(),
                ),
                if (esCrear) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinConfirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      hintText: 'Confirmá el PIN',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _recordarDispositivo,
                  onChanged: (v) => setState(() => _recordarDispositivo = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.acento,
                  title: Text(
                    'Recordar este dispositivo',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF8A65), fontSize: 13)),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _cargando ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acento,
                    foregroundColor: AppColors.fondoOscuro,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fondoOscuro),
                        )
                      : Text(
                          esCrear ? 'Crear PIN' : 'Entrar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
