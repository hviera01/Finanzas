import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/editar_compra_dialog.dart';
import '../widgets/responsive.dart';
import '../widgets/selector_cuotas_dialog.dart';

class DetalleCompraScreen extends ConsumerWidget {
  final CompraModel compra;
  final TarjetaModel? tarjeta;

  const DetalleCompraScreen({super.key, required this.compra, required this.tarjeta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(compraRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(compra.descripcion),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'editar') {
                final tarjetas = ref.read(tarjetasProvider).value ?? [];
                final edicion = await mostrarEditorCompra(context, compra: compra, tarjetas: tarjetas);
                if (edicion == null) return;
                await repo.editar(
                  compra,
                  tarjeta: edicion.tarjeta,
                  descripcion: edicion.descripcion,
                  montoTotal: edicion.montoTotal,
                  moneda: edicion.moneda,
                  fecha: edicion.fecha,
                );
                if (context.mounted) Navigator.of(context).pop();
              } else if (v == 'eliminar') {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Eliminar compra?'),
                    content: Text('Se eliminará "${compra.descripcion}" y todo su plan de pagos.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Eliminar', style: TextStyle(color: AppColors.peligro)),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await repo.eliminar(compra.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContenidoCentrado(
            anchoMaximo: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tarjeta?.nombre ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                            Text(formatearFecha(compra.fecha), style: TextStyle(color: Colors.black.withValues(alpha: 0.55))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formatearMonto(compra.montoTotal, compra.moneda),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        if (compra.numCuotas > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'A ${compra.numCuotas} cuotas · ${compra.porcentajeComisionPrimerMes.toStringAsFixed(2)}% de comisión',
                              style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _Resumen(
                                titulo: 'Pagado',
                                valor: formatearMonto(compra.totalPagado, compra.moneda),
                                color: AppColors.primario,
                              ),
                            ),
                            Expanded(
                              child: _Resumen(
                                titulo: 'Pendiente',
                                valor: formatearMonto(compra.totalPendiente, compra.moneda),
                                color: AppColors.peligro,
                              ),
                            ),
                          ],
                        ),
                        if (!compra.liquidada) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('¿Liquidar todo?'),
                                    content: Text(
                                      'Se va a marcar como pagado el saldo pendiente completo: ${formatearMonto(compra.totalPendiente, compra.moneda)}.',
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Liquidar')),
                                    ],
                                  ),
                                );
                                if (confirmar == true) await repo.liquidarTodo(compra);
                              },
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Liquidar todo'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (compra.numCuotas > 1) ...[
                  Text('Plan de pagos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...compra.cuotas.map((c) {
                    final etiqueta = c.esComision ? 'Comisión inicial' : 'Cuota ${c.numero} de ${compra.numCuotas}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: c.pagada,
                        onChanged: (v) => repo.marcarCuota(compra, c.numero, v ?? false),
                        activeColor: AppColors.primario,
                        title: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          c.pagada && c.fechaPago != null
                              ? 'Pagada el ${formatearFecha(c.fechaPago!)}'
                              : 'Vence el ${formatearFecha(c.fechaVencimiento)}',
                        ),
                        secondary: Text(
                          formatearMonto(c.monto, compra.moneda),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  Builder(builder: (context) {
                    final unica = compra.cuotas.first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: CheckboxListTile(
                            value: unica.pagada,
                            onChanged: (v) => repo.marcarCuota(compra, unica.numero, v ?? false),
                            activeColor: AppColors.primario,
                            title: const Text('Pago único', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              unica.pagada && unica.fechaPago != null
                                  ? 'Pagada el ${formatearFecha(unica.fechaPago!)}'
                                  : 'Vence el ${formatearFecha(unica.fechaVencimiento)}',
                            ),
                            secondary: Text(
                              formatearMonto(unica.monto, compra.moneda),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (!unica.pagada && tarjeta != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final seleccion = await mostrarSelectorCuotas(
                                  context,
                                  titulo: 'Pasar a cuotas',
                                  tarjeta: tarjeta,
                                  montoTotal: compra.montoTotal,
                                  moneda: compra.moneda,
                                );
                                if (seleccion == null) return;
                                await repo.convertirACuotas(
                                  compra,
                                  tarjeta: tarjeta!,
                                  numCuotas: seleccion.numCuotas,
                                  porcentajeComisionPrimerMes: seleccion.porcentajeComision,
                                );
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.call_split),
                              label: const Text('Pasar a cuotas'),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _Resumen({required this.titulo, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
        const SizedBox(height: 2),
        Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
