import 'package:flutter/material.dart';

const double kBreakpointAncho = 700;

bool esPantallaAncha(BuildContext context) => MediaQuery.of(context).size.width >= kBreakpointAncho;

/// Centra el contenido y le pone un ancho máximo en pantallas anchas
/// (desktop/web), mientras que en móvil ocupa todo el ancho disponible.
class ContenidoCentrado extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;

  const ContenidoCentrado({super.key, required this.child, this.anchoMaximo = 900});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: child,
      ),
    );
  }
}
