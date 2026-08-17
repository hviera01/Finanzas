import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cargos.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../models/suscripcion_model.dart';
import '../widgets/responsive.dart';
import 'detalle_compra_screen.dart';
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

                    // "Próximo a pagar" tiene que sumar TODO lo que realmente cae en esa
                    // fecha de la tarjeta (pagos únicos, comisiones, cuotas y también
                    // suscripciones, que ya se cobran en la fecha de pago real de la
                    // tarjeta) — si no, el total no cuadra con el que se ve al entrar al
                    // detalle de la tarjeta. Las suscripciones además tienen su propia
                    // sección "Próximas renovaciones" y las cuotas su propio tablero de
                    // progreso más abajo, pero eso es solo una vista extra, no reemplaza
                    // que cuenten acá.
                    //
                    // Solo de hoy en adelante: una suscripción con fecha de inicio vieja
                    // (puesta a propósito para que contara el ciclo actual) puede generar
                    // cargos de meses ya pasados que nunca se pagaron — esos son historial
                    // atrasado, no "próximo a pagar", así que no cuentan acá.
                    final hoy = DateTime.now();
                    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
                    final cargos = todosLosCargos(compras, suscripciones, tarjetasPorId)
                        .where((c) => !c.pagada && !c.fechaVencimiento.isBefore(hoySinHora))
                        .toList();
                    final grupos = agruparPorPago(cargos);

                    final proximasRenovaciones = suscripciones.where((s) => s.activa).toList()
                      ..sort((a, b) => proximaRenovacionSuscripcion(a).compareTo(proximaRenovacionSuscripcion(b)));

                    final cuotasEnCurso = compras.where((c) => c.numCuotas > 1 && !c.liquidada).toList()
                      ..sort((a, b) {
                        final proximaA = a.cuotas.firstWhere((q) => !q.pagada, orElse: () => a.cuotas.last);
                        final proximaB = b.cuotas.firstWhere((q) => !q.pagada, orElse: () => b.cuotas.last);
                        return proximaA.fechaVencimiento.compareTo(proximaB.fechaVencimiento);
                      });

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
                        if (cuotasEnCurso.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text('Cuotas en curso', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ...cuotasEnCurso.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _FilaCuotaEnCurso(compra: c, tarjeta: tarjetasPorId[c.tarjetaId]),
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

class _FilaCuotaEnCurso extends StatelessWidget {
  final CompraModel compra;
  final TarjetaModel? tarjeta;

  const _FilaCuotaEnCurso({required this.compra, required this.tarjeta});

  @override
  Widget build(BuildContext context) {
    final total = compra.cuotas.length;
    final pagadas = compra.cuotas.where((c) => c.pagada).length;
    final proxima = compra.cuotas.where((c) => !c.pagada).isEmpty
        ? null
        : compra.cuotas.where((c) => !c.pagada).reduce((a, b) => a.fechaVencimiento.isBefore(b.fechaVencimiento) ? a : b);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetalleCompraScreen(compra: compra, tarjeta: tarjeta)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(compra.descripcion, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Text('$pagadas/$total', style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : pagadas / total,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primario),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tarjeta?.nombre ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  if (proxima != null)
                    Text(
                      'Próxima: ${formatearMonto(proxima.monto, compra.moneda)} · ${formatearFecha(proxima.fechaVencimiento)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
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
