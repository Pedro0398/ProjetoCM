import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/product.dart';

final class StockUtils {
  static void confirmProductDeletion(
    Produto produto,
    BuildContext context,
    Function onPressed,
    Function onCancelPressed,
  ) {
    bool isDialogLoading = false;
    showDialog(
      context: context,
      barrierDismissible: !isDialogLoading,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Confirmar Remoção',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              content: Text(
                'Tem a certeza que deseja remover o produto "${produto.nome}" do seu stock? (Esta ação não pode ser desfeita e pode afetar ofertas de venda associadas a este produto base).',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isDialogLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () {
                    try {
                      setDialogState(() => isDialogLoading = true);
                      onPressed();
                    } catch (e) {
                      rethrow;
                    } finally {
                      setDialogState(() => isDialogLoading = false);
                    }
                  },
                  child:
                      isDialogLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          )
                          : const Text('Remover'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
