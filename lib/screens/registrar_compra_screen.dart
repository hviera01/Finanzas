import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/ciclo_facturacion.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/selector_cuotas_dialog.dart' show cuotasPreset, comisionSugeridaBac;

class CuotaVista {
  final String etiqueta;
  final DateTime fecha;
  final double monto;
  const CuotaVista({required this.etiqueta, required this.fecha, required this.monto});
}

class RegistrarCompraScreen extends ConsumerStatefulWidget {
  final TarjetaModel? tarjetaInicial;
  const RegistrarCompraScreen({super.key, this.tarjetaInicial});

  @override
  ConsumerState<RegistrarCompraScreen> createState() => _RegistrarCompraScreenState();
}

class _RegistrarCompraScreenState extends ConsumerState<RegistrarCompraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _cuotasCustomCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController();

  TarjetaModel? _tarjeta;
  Moneda _moneda = Moneda.hnl;
  DateTime _fecha = DateTime.now();
  bool _aCuotas = false;
  int _numCuotas = 3;
  bool _pagadaYa = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tarjeta = widget.tarjetaInicial;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    _cuotasCustomCtrl.dispose();
    _comisionCtrl.dispose();
    super.dispose();
  }

  List<CuotaVista>? get _previewCuotas {
    if (_tarjeta == null) return null;
    final numCuotas = _aCuotas ? _numCuotas : 1;
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '')) ?? 0;
    final comision = _aCuotas ? (double.tryParse(_comisionCtrl.text.replaceAll(',', '')) ?? 0) : 0.0;
    final cuotas = calcularCuotas(
      fechaCompra: _fecha,
      diaCorte: _tarjeta!.diaCorte,
      diaPago: _tarjeta!.diaPago,
      montoTotal: monto,
      numCuotas: numCuotas,
      porcentajeComisionPrimerMes: comision,
    );
    return cuotas
        .map((c) => CuotaVista(
              etiqueta: c.esComision ? 'Comisión inicial' : (numCuotas > 1 ? 'Cuota ${c.numero} de $numCuotas' : 'Pago único'),
              fecha: c.fechaVencimiento,
              monto: c.monto,
            ))
        .toList();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tarjeta == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elegí una tarjeta')));
      return;
    }

    final monto = double.parse(_montoCtrl.text.replaceAll(',', ''));
    final numCuotas = _aCuotas ? _numCuotas : 1;
    final comision = _aCuotas ? (double.tryParse(_comisionCtrl.text.replaceAll(',', '')) ?? 0) : 0.0;

    var cuotas = calcularCuotas(
      fechaCompra: _fecha,
      diaCorte: _tarjeta!.diaCorte,
      diaPago: _tarjeta!.diaPago,
      montoTotal: monto,
      numCuotas: numCuotas,
      porcentajeComisionPrimerMes: comision,
    );

    if (!_aCuotas && _pagadaYa) {
      cuotas = [cuotas.first.copyWith(pagada: true, fechaPago: DateTime.now())];
    }

    final compra = CompraModel(
      id: const Uuid().v4(),
      tarjetaId: _tarjeta!.id,
      descripcion: _descripcionCtrl.text.trim(),
      montoTotal: monto,
      moneda: _moneda,
      fecha: _fecha,
      numCuotas: numCuotas,
      porcentajeComisionPrimerMes: comision,
      createdAt: DateTime.now(),
      cuotas: cuotas,
    );

    setState(() => _guardando = true);
    await ref.read(compraRepositoryProvider).crear(compra);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tarjetasAsync = ref.watch(tarjetasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: ContenidoCentrado(
            anchoMaximo: 560,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tarjetasAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                    data: (tarjetas) {
                      _tarjeta ??= tarjetas.isNotEmpty ? tarjetas.first : null;
                      return DropdownButtonFormField<TarjetaModel>(
                        initialValue: tarjetas.contains(_tarjeta) ? _tarjeta : null,
                        decoration: const InputDecoration(labelText: 'Tarjeta'),
                        items: tarjetas.map((t) => DropdownMenuItem(value: t, child: Text(t.nombre))).toList(),
                        onChanged: (t) => setState(() => _tarjeta = t),
                        validator: (v) => v == null ? 'Requerido' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción (ej. Amazon, cena, etc.)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _montoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: const InputDecoration(labelText: 'Monto'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => (double.tryParse(v ?? '') == null) ? 'Monto inválido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SegmentedButton<Moneda>(
                          segments: const [
                            ButtonSegment(value: Moneda.hnl, label: Text('L')),
                            ButtonSegment(value: Moneda.usd, label: Text('\$')),
                          ],
                          selected: {_moneda},
                          onSelectionChanged: (s) => setState(() => _moneda = s.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _elegirFecha,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha de la compra'),
                      child: Text(formatearFecha(_fecha)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _aCuotas,
                    onChanged: (v) => setState(() => _aCuotas = v),
                    title: const Text('Diferir a cuotas', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Con comisión inicial, tipo minicuotas'),
                    activeThumbColor: AppColors.primario,
                  ),
                  if (_aCuotas) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cuotasPreset.map((n) {
                        final seleccionado = _numCuotas == n && _cuotasCustomCtrl.text.isEmpty;
                        return ChoiceChip(
                          label: Text('$n cuotas'),
                          selected: seleccionado,
                          onSelected: (_) {
                            setState(() {
                              _numCuotas = n;
                              _cuotasCustomCtrl.clear();
                              _comisionCtrl.text = comisionSugeridaBac[n]!.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cuotasCustomCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Otra cantidad de cuotas'),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 1) setState(() => _numCuotas = n);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _comisionCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            decoration: const InputDecoration(labelText: '% comisión 1er pago'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => _aCuotas && double.tryParse(v ?? '') == null ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La comisión se cobra sola en el próximo pago; las $_numCuotas cuotas de capital arrancan el mes siguiente.',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _pagadaYa,
                      onChanged: (v) => setState(() => _pagadaYa = v ?? false),
                      title: const Text('Ya la pagué (dinero entregado de inmediato)'),
                    ),
                  ],
                  if (_previewCuotas != null) ...[
                    const SizedBox(height: 20),
                    _VistaPreviaFechas(cuotas: _previewCuotas!, moneda: _moneda),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar compra'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaPreviaFechas extends StatelessWidget {
  final List<CuotaVista> cuotas;
  final Moneda moneda;

  const _VistaPreviaFechas({required this.cuotas, required this.moneda});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primario.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Te tocaría pagar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          ...cuotas.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(c.etiqueta, style: const TextStyle(fontSize: 13))),
                    Text(formatearFecha(c.fecha), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text(formatearMonto(c.monto, moneda), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
