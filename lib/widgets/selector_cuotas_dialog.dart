import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const cuotasPreset = [3, 6, 12, 18, 24];
const comisionSugeridaBac = {3: 6.0, 6: 9.0, 12: 13.0, 18: 18.0, 24: 24.0};

class SeleccionCuotas {
  final int numCuotas;
  final double porcentajeComision;
  const SeleccionCuotas({required this.numCuotas, required this.porcentajeComision});
}

Future<SeleccionCuotas?> mostrarSelectorCuotas(BuildContext context, {String titulo = 'Pasar a cuotas'}) {
  return showDialog<SeleccionCuotas>(
    context: context,
    builder: (_) => _SelectorCuotasDialog(titulo: titulo),
  );
}

class _SelectorCuotasDialog extends StatefulWidget {
  final String titulo;
  const _SelectorCuotasDialog({required this.titulo});

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

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              ],
            ),
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
