import 'package:flutter/material.dart';
import '../widgets/responsive.dart';
import 'dashboard_screen.dart';
import 'historial_screen.dart';
import 'suscripciones_screen.dart';
import 'tarjetas_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  static const _destinos = [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
    NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Tarjetas'),
    NavigationDestination(icon: Icon(Icons.autorenew_outlined), selectedIcon: Icon(Icons.autorenew), label: 'Suscripciones'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Historial'),
  ];

  static const _paginas = [
    DashboardScreen(),
    TarjetasScreen(),
    SuscripcionesScreen(),
    HistorialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ancho = esPantallaAncha(context);

    if (ancho) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _indice,
              onDestinationSelected: (i) => setState(() => _indice = i),
              labelType: NavigationRailLabelType.all,
              destinations: _destinos
                  .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _paginas[_indice]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _paginas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: _destinos,
      ),
    );
  }
}
