import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/ciclo_facturacion.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/cuota_model.dart';
import '../models/tarjeta_model.dart';
import '../theme/app_theme.dart';

const cuotasPreset = [3, 6, 12, 18, 24];
const comisionSugeridaBac = {3: 6.0, 6: 9.0, 12: 13.0, 18: 18.0, 24: 24.0};

class SeleccionCuotas {
  final int numCuotas;
  final double porcentajeComision;
  const SeleccionCuotas({required this.numCuotas, required this.porcentajeComision});
}

Future<SeleccionCuotas?> mostrarSelectorCuotas(
  BuildContext context, {
  String titulo = 'Pasar a cuotas',
  TarjetaModel? tarjeta,
  double? montoTotal,
  Moneda moneda = Moneda.hnl,
}) {
  return showDialog<SeleccionCuotas>(
    context: context,
    builder: (_) => _SelectorCuotasDialog(titulo: titulo, tarjeta: tarjeta, montoTotal: montoTotal, moneda: moneda),
  );
}

class _SelectorCuotasDialog extends StatefulWidget {
  final String titulo;
  final TarjetaModel? tarjeta;
  final double? montoTotal;
  final Moneda moneda;

  const _SelectorCuotasDialog({required this.titulo, this.tarjeta, this.montoTotal, this.moneda = Moneda.hnl});

  @override
  State<_SelectorCuotasDialog> createState() => _SelectorCuotasDialogState();
}

class _SelectorCuotasDialogState extends State<_SelectorCuotasDialog> {
  final _cuotasCustomCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController(text: comisionSugeridaBac[cuotasPreset.first]!.toString());
  int _numCuotas = cuotasPreset.first;

  @override
  void dispose() {
    _cuotasCustomCtrl.dispose();
    _comisionCtrl.dispose();
    super.dispose();
  }

  List<CuotaModel>? get _preview {
    if (widget.tarjeta == null || widget.montoTotal == null) return null;
    final comision = double.tryParse(_comisionCtrl.text) ?? 0;
    return calcularCuotas(
      fechaCompra: DateTime.now(),
      diaCorte: widget.tarjeta!.diaCorte,
      diaPago: widget.tarjeta!.diaPago,
      montoTotal: widget.montoTotal!,
      numCuotas: _numCuotas,
      porcentajeComisionPrimerMes: comision,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cuotasCustomCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Otra cantidad'),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 1) setState(() => _numCuotas = n);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _comisionCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: '% comisión'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (preview != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primario.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Con ${widget.tarjeta!.nombre} te tocaría pagar', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    ...preview.map((c) {
                      final etiqueta = c.esComision ? 'Comisión inicial' : 'Cuota ${c.numero} de $_numCuotas';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 12))),
                            Text(formatearFecha(c.fechaVencimiento), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(formatearMonto(c.monto, widget.moneda), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final comision = double.tryParse(_comisionCtrl.text) ?? 0;
            Navigator.of(context).pop(SeleccionCuotas(numCuotas: _numCuotas, porcentajeComision: comision));
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
