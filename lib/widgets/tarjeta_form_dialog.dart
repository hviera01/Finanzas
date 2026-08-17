import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/tarjeta_model.dart';

Future<TarjetaModel?> mostrarFormularioTarjeta(BuildContext context, {TarjetaModel? existente}) {
  return showDialog<TarjetaModel>(
    context: context,
    builder: (_) => _TarjetaFormDialog(existente: existente),
  );
}

class _TarjetaFormDialog extends StatefulWidget {
  final TarjetaModel? existente;
  const _TarjetaFormDialog({this.existente});

  @override
  State<_TarjetaFormDialog> createState() => _TarjetaFormDialogState();
}

class _TarjetaFormDialogState extends State<_TarjetaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreCtrl = TextEditingController(text: widget.existente?.nombre ?? '');
  late final _corteCtrl = TextEditingController(text: widget.existente?.diaCorte.toString() ?? '');
  late final _pagoCtrl = TextEditingController(text: widget.existente?.diaPago.toString() ?? '');

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _corteCtrl.dispose();
    _pagoCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final tarjeta = TarjetaModel(
      id: widget.existente?.id ?? const Uuid().v4(),
      nombre: _nombreCtrl.text.trim(),
      diaCorte: int.parse(_corteCtrl.text),
      diaPago: int.parse(_pagoCtrl.text),
      activa: widget.existente?.activa ?? true,
      createdAt: widget.existente?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(tarjeta);
  }

  String? _validarDia(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 31) return '1-31';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.existente != null;
    return AlertDialog(
      title: Text(editando ? 'Editar tarjeta' : 'Nueva tarjeta'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre de la tarjeta'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _corteCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Día de corte'),
                      validator: _validarDia,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pagoCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Día de pago'),
                      validator: _validarDia,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'El día de corte marca hasta cuándo entra una compra en el estado de cuenta actual; el día de pago es cuándo vence.',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
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
