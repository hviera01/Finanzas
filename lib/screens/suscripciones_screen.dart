import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formato.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/suscripcion_form_dialog.dart';
import 'detalle_suscripcion_screen.dart';

class SuscripcionesScreen extends ConsumerWidget {
  const SuscripcionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suscripcionesAsync = ref.watch(suscripcionesProvider);
    final tarjetasAsync = ref.watch(tarjetasProvider);
    final repo = ref.read(suscripcionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suscripciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final tarjetas = tarjetasAsync.value ?? [];
          if (tarjetas.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registrá una tarjeta')));
            return;
          }
          final nueva = await mostrarFormularioSuscripcion(context, tarjetas: tarjetas);
          if (nueva != null) await repo.crear(nueva);
        },
        icon: const Icon(Icons.add),
        label: const Text('Suscripción'),
      ),
      body: SafeArea(
        child: suscripcionesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (suscripciones) {
            final tarjetasPorId = {for (final t in tarjetasAsync.value ?? []) t.id: t};
            if (suscripciones.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Agregá tus cargos recurrentes (Netflix, Spotify, etc.) con el botón de abajo.',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final activas = suscripciones.where((s) => s.activa).toList();
            final canceladas = suscripciones.where((s) => !s.activa).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...activas.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FilaSuscripcion(
                            nombreTarjeta: tarjetasPorId[s.tarjetaId]?.nombre ?? '',
                            descripcion: s.descripcion,
                            monto: formatearMonto(s.monto, s.moneda),
                            subtitulo: 'Se cobra el día ${s.diaCobro} de cada mes',
                            activa: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DetalleSuscripcionScreen(suscripcion: s, tarjeta: tarjetasPorId[s.tarjetaId])),
                            ),
                          ),
                        )),
                    if (canceladas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Canceladas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54)),
                      const SizedBox(height: 10),
                      ...canceladas.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FilaSuscripcion(
                              nombreTarjeta: tarjetasPorId[s.tarjetaId]?.nombre ?? '',
                              descripcion: s.descripcion,
                              monto: formatearMonto(s.monto, s.moneda),
                              subtitulo: s.fechaCancelacion != null ? 'Cancelada el ${formatearFecha(s.fechaCancelacion!)}' : 'Cancelada',
                              activa: false,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DetalleSuscripcionScreen(suscripcion: s, tarjeta: tarjetasPorId[s.tarjetaId])),
                              ),
                            ),
                          )),
                    ],
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

class _FilaSuscripcion extends StatelessWidget {
  final String nombreTarjeta;
  final String descripcion;
  final String monto;
  final String subtitulo;
  final bool activa;
  final VoidCallback onTap;

  const _FilaSuscripcion({
    required this.nombreTarjeta,
    required this.descripcion,
    required this.monto,
    required this.subtitulo,
    required this.activa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: activa ? 1 : 0.55,
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.acento.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.autorenew_rounded, color: AppColors.acento),
          ),
          title: Text(descripcion, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$nombreTarjeta · $subtitulo'),
          trailing: Text(monto, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
