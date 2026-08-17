import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cargos.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/tarjeta_form_dialog.dart';
import 'detalle_compra_screen.dart';
import 'registrar_compra_screen.dart';

class TarjetaDetalleScreen extends ConsumerStatefulWidget {
  final TarjetaModel tarjeta;
  const TarjetaDetalleScreen({super.key, required this.tarjeta});

  @override
  ConsumerState<TarjetaDetalleScreen> createState() => _TarjetaDetalleScreenState();
}

class _TarjetaDetalleScreenState extends ConsumerState<TarjetaDetalleScreen> {
  late DateTime _periodo = DateTime(DateTime.now().year, DateTime.now().month);
  bool _exportando = false;

  void _cambiarMes(int delta) {
    setState(() => _periodo = DateTime(_periodo.year, _periodo.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final tarjetasAsync = ref.watch(tarjetasProvider);
    final comprasAsync = ref.watch(comprasProvider);
    final tasaAsync = ref.watch(tasaCambioProvider);

    final tarjeta = tarjetasAsync.value?.firstWhere(
          (t) => t.id == widget.tarjeta.id,
          orElse: () => widget.tarjeta,
        ) ??
        widget.tarjeta;

    return Scaffold(
      appBar: AppBar(
        title: Text(tarjeta.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final editada = await mostrarFormularioTarjeta(context, existente: tarjeta);
              if (editada != null) await ref.read(tarjetaRepositoryProvider).actualizar(editada);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RegistrarCompraScreen(tarjetaInicial: tarjeta)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Compra'),
      ),
      body: SafeArea(
        child: comprasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (todasLasCompras) {
            final compras = todasLasCompras.where((c) => c.tarjetaId == tarjeta.id).toList();
            final cargos = aplanarCargos(compras)
                .where((c) => c.cuota.anio == _periodo.year && c.cuota.mes == _periodo.month)
                .toList()
              ..sort((a, b) => a.cuota.fechaVencimiento.compareTo(b.cuota.fechaVencimiento));

            final tasa = tasaAsync.value?.valor ?? 25.4;
            final totalHnl = cargos.where((c) => !c.cuota.pagada).fold<double>(
                  0.0,
                  (s, c) => s + (c.compra.moneda == Moneda.usd ? c.cuota.monto * tasa : c.cuota.monto),
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              child: ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _cambiarMes(-1)),
                                Text(
                                  formatearMesAnio(_periodo),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _cambiarMes(1)),
                              ],
                            ),
                            Text(
                              'Corte día ${tarjeta.diaCorte} · Pago día ${tarjeta.diaPago}',
                              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatearLempiras(totalHnl),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'pendiente este período',
                              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: cargos.isEmpty || _exportando
                                    ? null
                                    : () async {
                                        setState(() => _exportando = true);
                                        await exportarEstadoCuentaPdf(
                                          tarjeta: tarjeta,
                                          periodo: _periodo,
                                          cargos: cargos,
                                          tasaUsdHnl: tasa,
                                        );
                                        if (mounted) setState(() => _exportando = false);
                                      },
                                icon: _exportando
                                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Exportar estado de cuenta (PDF)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Cargos de este período', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    if (cargos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No hay cargos en este período.',
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                        ),
                      )
                    else
                      ...cargos.map((c) {
                        final etiqueta = c.cuota.esComision ? 'Comisión inicial' : 'Cuota ${c.cuota.numero} de ${c.compra.numCuotas}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DetalleCompraScreen(compra: c.compra, tarjeta: tarjeta)),
                            ),
                            leading: Checkbox(
                              value: c.cuota.pagada,
                              activeColor: AppColors.primario,
                              onChanged: (v) => ref.read(compraRepositoryProvider).marcarCuota(c.compra, c.cuota.numero, v ?? false),
                            ),
                            title: Text(c.compra.descripcion, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('$etiqueta · vence ${formatearFecha(c.cuota.fechaVencimiento)}'),
                            trailing: Text(
                              formatearMonto(c.cuota.monto, c.compra.moneda),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
