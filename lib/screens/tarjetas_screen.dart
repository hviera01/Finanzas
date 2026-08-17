import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import '../widgets/tarjeta_form_dialog.dart';
import 'tarjeta_detalle_screen.dart';

class TarjetasScreen extends ConsumerWidget {
  const TarjetasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarjetasAsync = ref.watch(tarjetasProvider);
    final repo = ref.read(tarjetaRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nueva = await mostrarFormularioTarjeta(context);
          if (nueva != null) await repo.crear(nueva);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tarjeta'),
      ),
      body: SafeArea(
        child: tarjetasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (tarjetas) {
            if (tarjetas.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Agregá tu primera tarjeta con el botón de abajo.',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: ContenidoCentrado(
                child: Column(
                  children: tarjetas.map((t) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primario.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.credit_card, color: AppColors.primario),
                        ),
                        title: Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('Corte día ${t.diaCorte} · Pago día ${t.diaPago}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'editar') {
                              final editada = await mostrarFormularioTarjeta(context, existente: t);
                              if (editada != null) await repo.actualizar(editada);
                            } else if (v == 'eliminar') {
                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('¿Eliminar tarjeta?'),
                                  content: Text('Se eliminará "${t.nombre}". Esto no borra las compras ya registradas con ella.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Eliminar', style: TextStyle(color: AppColors.peligro)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmar == true) await repo.eliminar(t.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'editar', child: Text('Editar')),
                            PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TarjetaDetalleScreen(tarjeta: t))),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
