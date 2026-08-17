import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/formato.dart';
import '../models/compra_model.dart';
import '../models/tarjeta_model.dart';

class EdicionCompra {
  final String descripcion;
  final TarjetaModel tarjeta;
  final double montoTotal;
  final Moneda moneda;
  final DateTime fecha;

  const EdicionCompra({
    required this.descripcion,
    required this.tarjeta,
    required this.montoTotal,
    required this.moneda,
    required this.fecha,
  });
}

Future<EdicionCompra?> mostrarEditorCompra(
  BuildContext context, {
  required CompraModel compra,
  required List<TarjetaModel> tarjetas,
}) {
  return showDialog<EdicionCompra>(
    context: context,
    builder: (_) => _EditarCompraDialog(compra: compra, tarjetas: tarjetas),
  );
}

class _EditarCompraDialog extends StatefulWidget {
  final CompraModel compra;
  final List<TarjetaModel> tarjetas;
  const _EditarCompraDialog({required this.compra, required this.tarjetas});

  @override
  State<_EditarCompraDialog> createState() => _EditarCompraDialogState();
}

class _EditarCompraDialogState extends State<_EditarCompraDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _descripcionCtrl = TextEditingController(text: widget.compra.descripcion);
  late final _montoCtrl = TextEditingController(text: widget.compra.montoTotal.toString());
  late Moneda _moneda = widget.compra.moneda;
  late DateTime _fecha = widget.compra.fecha;
  TarjetaModel? _tarjeta;

  @override
  void initState() {
    super.initState();
    final coincidencias = widget.tarjetas.where((t) => t.id == widget.compra.tarjetaId);
    _tarjeta = coincidencias.isEmpty ? (widget.tarjetas.isNotEmpty ? widget.tarjetas.first : null) : coincidencias.first;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_tarjeta == null) return;
    Navigator.of(context).pop(EdicionCompra(
      descripcion: _descripcionCtrl.text.trim(),
      tarjeta: _tarjeta!,
      montoTotal: double.parse(_montoCtrl.text),
      moneda: _moneda,
      fecha: _fecha,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar compra'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _descripcionCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<TarjetaModel>(
                initialValue: widget.tarjetas.contains(_tarjeta) ? _tarjeta : null,
                decoration: const InputDecoration(labelText: 'Tarjeta'),
                items: widget.tarjetas.map((t) => DropdownMenuItem(value: t, child: Text(t.nombre))).toList(),
                onChanged: (t) => setState(() => _tarjeta = t),
                validator: (v) => v == null ? 'Requerido' : null,
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
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Inválido' : null,
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
              if (widget.compra.numCuotas > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Esto recalcula las ${widget.compra.numCuotas} cuotas con el nuevo monto/fecha; las que ya marcaste pagadas se mantienen.',
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
