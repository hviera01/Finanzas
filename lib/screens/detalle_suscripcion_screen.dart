import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cargos.dart';
import '../core/formato.dart';
import '../models/suscripcion_model.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/suscripcion_form_dialog.dart';

class DetalleSuscripcionScreen extends ConsumerWidget {
  final SuscripcionModel suscripcion;
  final TarjetaModel? tarjeta;

  const DetalleSuscripcionScreen({super.key, required this.suscripcion, required this.tarjeta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(suscripcionRepositoryProvider);
    final tarjetasPorId = tarjeta == null ? <String, TarjetaModel>{} : {tarjeta!.id: tarjeta!};
    final cargos = cargosDeSuscripciones([suscripcion], tarjetasPorId)
      ..sort((a, b) => b.fechaVencimiento.compareTo(a.fechaVencimiento));

    return Scaffold(
      appBar: AppBar(
        title: Text(suscripcion.descripcion),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'editar') {
                final tarjetas = ref.read(tarjetasProvider).value ?? [];
                final editada = await mostrarFormularioSuscripcion(context, tarjetas: tarjetas, existente: suscripcion);
                if (editada != null) await repo.actualizar(editada);
                if (context.mounted) Navigator.of(context).pop();
              } else if (v == 'cancelar') {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Cancelar suscripción?'),
                    content: Text('"${suscripcion.descripcion}" no volverá a generar cobros después de este mes.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Cancelar suscripción', style: TextStyle(color: AppColors.peligro)),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  await repo.cancelar(suscripcion);
                  if (context.mounted) Navigator.of(context).pop();
                }
              } else if (v == 'reactivar') {
                await repo.reactivar(suscripcion);
                if (context.mounted) Navigator.of(context).pop();
              } else if (v == 'eliminar') {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Eliminar suscripción?'),
                    content: Text('Se eliminará "${suscripcion.descripcion}" y su historial de cobros.'),
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
                  await repo.eliminar(suscripcion.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              if (suscripcion.activa)
                const PopupMenuItem(value: 'cancelar', child: Text('Cancelar suscripción'))
              else
                const PopupMenuItem(value: 'reactivar', child: Text('Reactivar')),
              const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
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
                            if (!suscripcion.activa)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.peligro.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Cancelada', style: TextStyle(color: AppColors.peligro, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          formatearMonto(suscripcion.monto, suscripcion.moneda),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Se cobra el día ${suscripcion.diaCobro} de cada mes',
                            style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Historial de cobros', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (cargos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Todavía no hay cobros generados para esta suscripción.',
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                    ),
                  )
                else
                  ...cargos.map((c) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: c.pagada,
                        onChanged: (v) => repo.marcarPago(suscripcion, c.periodoKey!, v ?? false),
                        activeColor: AppColors.primario,
                        title: Text(formatearMesAnio(c.fechaVencimiento), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Vence el ${formatearFecha(c.fechaVencimiento)}'),
                        secondary: Text(
                          formatearMonto(c.monto, c.moneda),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
