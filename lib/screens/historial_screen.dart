import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formato.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import 'detalle_compra_screen.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  String? _filtroTarjetaId;

  @override
  Widget build(BuildContext context) {
    final tarjetasAsync = ref.watch(tarjetasProvider);
    final comprasAsync = ref.watch(comprasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de compras')),
      body: SafeArea(
        child: tarjetasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tarjetas) {
            final tarjetasPorId = {for (final t in tarjetas) t.id: t};
            return comprasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (compras) {
                final filtradas = _filtroTarjetaId == null
                    ? compras
                    : compras.where((c) => c.tarjetaId == _filtroTarjetaId).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: ContenidoCentrado(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _ChipFiltro(
                                label: 'Todas',
                                seleccionado: _filtroTarjetaId == null,
                                onTap: () => setState(() => _filtroTarjetaId = null),
                              ),
                              ...tarjetas.map((t) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _ChipFiltro(
                                      label: t.nombre,
                                      seleccionado: _filtroTarjetaId == t.id,
                                      onTap: () => setState(() => _filtroTarjetaId = t.id),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (filtradas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No hay compras registradas todavía.',
                                style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                              ),
                            ),
                          )
                        else
                          ...filtradas.map((c) {
                            final tarjeta = tarjetasPorId[c.tarjetaId];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => DetalleCompraScreen(compra: c, tarjeta: tarjeta)),
                                ),
                                title: Text(c.descripcion, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  '${tarjeta?.nombre ?? ''} · ${formatearFecha(c.fecha)}'
                                  '${c.numCuotas > 1 ? ' · ${c.cuotasPagadas}/${c.cuotas.length} pagadas' : ''}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(formatearMonto(c.montoTotal, c.moneda), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      c.liquidada ? 'Liquidada' : 'Pendiente',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: c.liquidada ? AppColors.primario : AppColors.acento,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({required this.label, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: seleccionado, onSelected: (_) => onTap());
  }
}
