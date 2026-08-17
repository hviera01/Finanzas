import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/compra_model.dart';
import '../models/suscripcion_model.dart';
import '../models/tarjeta_model.dart';

Future<SuscripcionModel?> mostrarFormularioSuscripcion(
  BuildContext context, {
  required List<TarjetaModel> tarjetas,
  SuscripcionModel? existente,
  TarjetaModel? tarjetaInicial,
}) {
  return showDialog<SuscripcionModel>(
    context: context,
    builder: (_) => _SuscripcionFormDialog(tarjetas: tarjetas, existente: existente, tarjetaInicial: tarjetaInicial),
  );
}

class _SuscripcionFormDialog extends StatefulWidget {
  final List<TarjetaModel> tarjetas;
  final SuscripcionModel? existente;
  final TarjetaModel? tarjetaInicial;

  const _SuscripcionFormDialog({required this.tarjetas, this.existente, this.tarjetaInicial});

  @override
  State<_SuscripcionFormDialog> createState() => _SuscripcionFormDialogState();
}

class _SuscripcionFormDialogState extends State<_SuscripcionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _descripcionCtrl = TextEditingController(text: widget.existente?.descripcion ?? '');
  late final _montoCtrl = TextEditingController(text: widget.existente?.monto.toString() ?? '');
  late final _diaCtrl = TextEditingController(text: widget.existente?.diaCobro.toString() ?? '');
  late Moneda _moneda = widget.existente?.moneda ?? Moneda.hnl;
  late DateTime _fechaInicio = widget.existente?.fechaInicio ?? DateTime.now();
  TarjetaModel? _tarjeta;

  @override
  void initState() {
    super.initState();
    final tarjetaIdExistente = widget.existente?.tarjetaId;
    if (tarjetaIdExistente != null) {
      final coincidencias = widget.tarjetas.where((t) => t.id == tarjetaIdExistente);
      _tarjeta = coincidencias.isEmpty ? null : coincidencias.first;
    }
    _tarjeta ??= widget.tarjetaInicial ?? (widget.tarjetas.isNotEmpty ? widget.tarjetas.first : null);
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    _diaCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_tarjeta == null) return;

    final suscripcion = SuscripcionModel(
      id: widget.existente?.id ?? const Uuid().v4(),
      tarjetaId: _tarjeta!.id,
      descripcion: _descripcionCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text),
      moneda: _moneda,
      diaCobro: int.parse(_diaCtrl.text),
      activa: widget.existente?.activa ?? true,
      fechaInicio: _fechaInicio,
      fechaCancelacion: widget.existente?.fechaCancelacion,
      pagos: widget.existente?.pagos ?? const {},
    );
    Navigator.of(context).pop(suscripcion);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    return AlertDialog(
      title: Text(editando ? 'Editar suscripción' : 'Nueva suscripción'),
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
                decoration: const InputDecoration(labelText: 'Descripción (ej. Netflix, Spotify)'),
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
                      decoration: const InputDecoration(labelText: 'Monto mensual'),
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
              TextFormField(
                controller: _diaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Día del mes en que se renueva/cobra'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 31) return '1-31';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final elegida = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (elegida != null) setState(() => _fechaInicio = elegida);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Cliente desde / primer cobro'),
                  child: Text('${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Si ya venías pagando esta suscripción, poné la fecha real en que empezó — así se refleja el cobro de este mes si ya tocaba.',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
              ),
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
