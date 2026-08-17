import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'home_shell.dart';
import 'pin_screen.dart';

enum _EstadoAuth { cargando, sinPin, bloqueado, desbloqueado }

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  _EstadoAuth _estado = _EstadoAuth.cargando;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    final pinService = ref.read(pinServiceProvider);
    final existePin = await pinService.existePin();
    if (!existePin) {
      setState(() => _estado = _EstadoAuth.sinPin);
      return;
    }
    final confiable = await pinService.dispositivoEsConfiable();
    setState(() => _estado = confiable ? _EstadoAuth.desbloqueado : _EstadoAuth.bloqueado);
  }

  @override
  Widget build(BuildContext context) {
    final desbloqueadoSesion = ref.watch(desbloqueadoProvider);

    if (desbloqueadoSesion || _estado == _EstadoAuth.desbloqueado) {
      return const HomeShell();
    }

    switch (_estado) {
      case _EstadoAuth.cargando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _EstadoAuth.sinPin:
        return PinScreen(modo: ModoPin.crear, onListo: () => ref.read(desbloqueadoProvider.notifier).state = true);
      case _EstadoAuth.bloqueado:
        return PinScreen(modo: ModoPin.ingresar, onListo: () => ref.read(desbloqueadoProvider.notifier).state = true);
      case _EstadoAuth.desbloqueado:
        return const HomeShell();
    }
  }
}
