import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cargos.dart';
import '../core/formato.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../models/suscripcion_model.dart';
import '../widgets/responsive.dart';
import 'detalle_suscripcion_screen.dart';
import 'registrar_compra_screen.dart';
import 'tarjeta_detalle_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarjetasAsync = ref.watch(tarjetasProvider);
    final comprasAsync = ref.watch(comprasProvider);
    final suscripcionesAsync = ref.watch(suscripcionesProvider);
    final tasaAsync = ref.watch(tasaCambioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus tarjetas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: tasaAsync.when(
                data: (t) => Text(
                  '\$1 ≈ ${formatearLempiras(t.valor)}${t.esCache ? ' (últ.)' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                ),
                loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistrarCompraScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Registrar compra'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContenidoCentrado(
            child: tarjetasAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
              data: (tarjetas) {
                return comprasAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (e, _) => Text('Error: $e'),
                  data: (compras) {
                    final suscripciones = suscripcionesAsync.value ?? [];
                    final tasa = tasaAsync.value?.valor ?? 25.4;
                    final tarjetasPorId = {for (final t in tarjetas) t.id: t};

                    // "Próximo a pagar" es solo lo de las tarjetas (compras/cuotas) — las
                    // suscripciones se muestran aparte, más abajo, por su propia fecha
                    // de renovación (no como si fueran otra fecha de pago de la tarjeta).
                    final cargos = cargosDeCompras(compras).where((c) => !c.pagada).toList();
                    final grupos = agruparPorPago(cargos);

                    final proximasRenovaciones = suscripciones.where((s) => s.activa).toList()
                      ..sort((a, b) => proximaRenovacionSuscripcion(a).compareTo(proximaRenovacionSuscripcion(b)));

                    if (tarjetas.isEmpty) {
                      return _EstadoVacio(esPantallaAncha: esPantallaAncha(context));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (grupos.isNotEmpty) ...[
                          Text('Próximo a pagar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          _TarjetaProximoPago(
                            grupo: grupos.first,
                            tarjeta: tarjetasPorId[grupos.first.tarjetaId],
                            tasa: tasa,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text('Tus tarjetas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ...tarjetas.map((t) {
                          final gruposTarjeta = grupos.where((g) => g.tarjetaId == t.id).toList();
                          final proximo = gruposTarjeta.isEmpty ? null : gruposTarjeta.first;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FilaTarjeta(tarjeta: t, proximo: proximo, tasa: tasa),
                          );
                        }),
                        if (grupos.length > 1) ...[
                          const SizedBox(height: 24),
                          Text('Otros pagos próximos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ...grupos.skip(1).take(6).map((g) => _FilaGrupoPago(grupo: g, tarjeta: tarjetasPorId[g.tarjetaId], tasa: tasa)),
                        ],
                        if (proximasRenovaciones.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Próximas renovaciones', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ...proximasRenovaciones.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _FilaSuscripcion(suscripcion: s, tarjeta: tarjetasPorId[s.tarjetaId]),
                              )),
                        ],
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool esPantallaAncha;
  const _EstadoVacio({required this.esPantallaAncha});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.credit_card_off_outlined, size: 56, color: Colors.black.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Text('Todavía no registrás tarjetas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Andá a la pestaña "Tarjetas" para agregar la primera.',
            style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarjetaProximoPago extends StatelessWidget {
  final GrupoPago grupo;
  final TarjetaModel? tarjeta;
  final double tasa;

  const _TarjetaProximoPago({required this.grupo, required this.tarjeta, required this.tasa});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: tarjeta == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TarjetaDetalleScreen(tarjeta: tarjeta!, periodoInicial: grupo.fecha)),
              ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primario, AppColors.primarioClaro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarjeta?.nombre ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Vence el ${formatearFechaLarga(grupo.fecha)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
            const SizedBox(height: 18),
            Text(
              formatearLempiras(grupo.totalEnLempiras(tasa)),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${grupo.cargos.length} ${grupo.cargos.length == 1 ? "cargo" : "cargos"}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaTarjeta extends StatelessWidget {
  final TarjetaModel tarjeta;
  final GrupoPago? proximo;
  final double tasa;

  const _FilaTarjeta({required this.tarjeta, required this.proximo, required this.tasa});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TarjetaDetalleScreen(tarjeta: tarjeta, periodoInicial: proximo?.fecha)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primario.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card, color: AppColors.primario),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tarjeta.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      proximo == null ? 'Sin pagos pendientes' : 'Próximo pago: ${formatearFecha(proximo!.fecha)}',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              if (proximo != null)
                Text(
                  formatearLempiras(proximo!.totalEnLempiras(tasa)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaSuscripcion extends StatelessWidget {
  final SuscripcionModel suscripcion;
  final TarjetaModel? tarjeta;

  const _FilaSuscripcion({required this.suscripcion, required this.tarjeta});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetalleSuscripcionScreen(suscripcion: suscripcion, tarjeta: tarjeta)),
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.acento.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.autorenew_rounded, color: AppColors.acento, size: 20),
        ),
        title: Text(suscripcion.descripcion, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${tarjeta?.nombre ?? ''} · se renueva el ${formatearFecha(proximaRenovacionSuscripcion(suscripcion))}'),
        trailing: Text(
          formatearMonto(suscripcion.monto, suscripcion.moneda),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FilaGrupoPago extends StatelessWidget {
  final GrupoPago grupo;
  final TarjetaModel? tarjeta;
  final double tasa;

  const _FilaGrupoPago({required this.grupo, required this.tarjeta, required this.tasa});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: tarjeta == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TarjetaDetalleScreen(tarjeta: tarjeta!, periodoInicial: grupo.fecha)),
                ),
        title: Text(tarjeta?.nombre ?? ''),
        subtitle: Text(formatearFecha(grupo.fecha)),
        trailing: Text(formatearLempiras(grupo.totalEnLempiras(tasa)), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
