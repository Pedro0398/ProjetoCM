// Em: pages/cart_page.dart (ou similar)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/cart_service.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';
import 'package:flutter_application_1/data_class/item_cart.dart';
import 'package:flutter_application_1/views/costumer_pages/explore_page.dart'; 
import 'package:flutter_application_1/data/notifiers.dart';


// Ajuste os caminhos
import 'package:flutter_application_1/data_class/user.dart' as app_user;

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CarrinhoService _carrinhoService = CarrinhoService();
  final AuthService _authService = AuthService();
  final OfertaProdutoService _ofertaService = OfertaProdutoService();

  User? _currentUser;
  String? _currentUserId;
  app_user.Utilizador? _appUserDetails;

  bool _isLoadingPage = true;
  bool _isCheckingOut = false;
  bool _isAddingFunds = false;

  final TextEditingController _fundosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _fundosController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (mounted) setState(() => _isLoadingPage = true);
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentUserId = _currentUser!.uid;
      _appUserDetails = await _authService.getUserData(_currentUserId!);
    } else {
      // ignore: avoid_print
      print("CartPage: Utilizador não logado!");
    }
    if (mounted) setState(() => _isLoadingPage = false);
  }

  Future<void> _mostrarDialogoAdicionarFundos() async {
    _fundosController.clear();
    final valorAdicionar = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        bool isDialogLoadingLocal = false;
        final formKeyDialog = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adicionar Fundos à Carteira'),
              content: Form(
                key: formKeyDialog,
                child: TextFormField(
                  controller: _fundosController,
                  enabled: !isDialogLoadingLocal,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor a adicionar (€)',
                    prefixIcon: Icon(Icons.euro_symbol),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira um valor.';
                    }
                    final val = double.tryParse(value.replaceAll(',', '.'));
                    if (val == null || val <= 0) {
                      return 'Insira um valor positivo válido.';
                    }
                    return null;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isDialogLoadingLocal
                          // ignore: dead_code
                          ? null
                          : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      isDialogLoadingLocal
                          // ignore: dead_code
                          ? null
                          : () {
                            if (formKeyDialog.currentState!.validate()) {
                              Navigator.of(context).pop(
                                double.parse(
                                  _fundosController.text.replaceAll(',', '.'),
                                ),
                              );
                            }
                          },
                  child:
                      isDialogLoadingLocal
                          // ignore: dead_code
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (valorAdicionar != null &&
        valorAdicionar > 0 &&
        _currentUserId != null) {
      if (mounted) setState(() => _isAddingFunds = true);
      try {
        await _authService.adicionarFundos(_currentUserId!, valorAdicionar);
        _appUserDetails = await _authService.getUserData(_currentUserId!);
        if (mounted) {
          setState(() {}); // Garante que a AppBar atualiza o saldo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${valorAdicionar.toStringAsFixed(2)}€ adicionados com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao adicionar fundos: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isAddingFunds = false);
      }
    }
  }

  Future<void> _processarCheckout(
    List<ItemCarrinho> itensCarrinho,
    double totalCarrinho,
  ) async {
    if (_currentUserId == null || _appUserDetails == null) return;
    setState(() => _isCheckingOut = true);
    try {
      await _authService.debitarFundos(_currentUserId!, totalCarrinho);
      for (var item in itensCarrinho) {
        await _ofertaService.marcarOfertaComoVendida(
          item.ofertaId,
          _currentUserId!,
          item.precoUnitario * item.quantidade,
          item.quantidade,
        );
      }
      await _carrinhoService.limparCarrinho(_currentUserId!);
      _appUserDetails = await _authService.getUserData(_currentUserId!);
      if (mounted) {
        setState(() {}); // Garante atualização do saldo após checkout
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra realizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro no checkout: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado no checkout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Carrinho')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Carrinho')),
        body: const Center(child: Text('Faça login para ver o seu carrinho.')),
      );
    }

    // Determinar a cor para os elementos da AppBar com base no brilho do tema da AppBar
    final appBarBrightness = ThemeData.estimateBrightnessForColor(
      Theme.of(context).appBarTheme.backgroundColor ??
          Theme.of(context).colorScheme.surface,
    );
    final Color appBarForegroundColor =
        appBarBrightness == Brightness.dark
            ? Colors
                .white // Cor para AppBar escura
            : Theme.of(context)
                .colorScheme
                .onSurface; // Cor para AppBar clara (ex: preto ou cinza escuro)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho de Compras'),
        // backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Pode definir se quiser
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 8.0),
            child: Center(
              child:
                  _isAddingFunds
                      ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: appBarForegroundColor, // COR ATUALIZADA
                          strokeWidth: 2.5,
                        ),
                      )
                      : TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              appBarForegroundColor, // COR ATUALIZADA
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                        label: Text(
                          'Saldo: ${_appUserDetails?.saldo.toStringAsFixed(2) ?? "0.00"}€',
                          style: TextStyle(
                            fontSize: 14,
                            color: appBarForegroundColor,
                          ), // COR ATUALIZADA
                        ),
                        onPressed: _mostrarDialogoAdicionarFundos,
                      ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ItemCarrinho>>(
        stream: _carrinhoService.obterItensCarrinho(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar carrinho: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'O seu carrinho está vazio.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.explore_outlined),
                    label: const Text('Explorar Ofertas'),
                    onPressed: () {
                      {
                        selectedPageNotifier.value = 1;
                      }
                    },
                  ),
                ],
              ),
            );
          }

          List<ItemCarrinho> itensCarrinho = snapshot.data!;
          double subtotal = itensCarrinho.fold(
            0,
            (sum, item) => sum + (item.precoUnitario * item.quantidade),
          );
          double totalCarrinho = subtotal;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: itensCarrinho.length,
                  itemBuilder: (context, index) {
                    final item = itensCarrinho[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Icon(
                            item.tipoProdutoAnuncio != null
                                ? Icons.label_important_outline
                                : Icons.shopping_basket_outlined,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          item.tituloAnuncio,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Qtd: ${item.quantidade} x ${item.precoUnitario.toStringAsFixed(2)}€\nTipo: ${item.tipoProdutoAnuncio ?? "N/A"}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(item.precoUnitario * item.quantidade).toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red.shade700,
                              ),
                              tooltip: 'Remover 1 unidade',
                              onPressed: () async {
                                try {
                                  int quantidadeAntiga = item.quantidade;
                                  if (item.quantidade > 1) {
                                    await _carrinhoService
                                        .atualizarQuantidadeItemCarrinho(
                                          _currentUserId!,
                                          item.id,
                                          item.quantidade - 1,
                                          -1,
                                        );
                                  } else {
                                    await _carrinhoService
                                        .removerItemDoCarrinho(
                                          _currentUserId!,
                                          item.id,
                                          quantidadeAntiga,
                                        );
                                  }
                                } catch (e) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao atualizar carrinho: ${e.toString().replaceFirst("Exception: ", "")}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '${subtotal.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${totalCarrinho.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon:
                              _isCheckingOut
                                  ? Container()
                                  : const Icon(Icons.payment_outlined),
                          label:
                              _isCheckingOut
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Finalizar Compra'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              (itensCarrinho.isEmpty || _isCheckingOut)
                                  ? null
                                  : () {
                                    _processarCheckout(
                                      itensCarrinho,
                                      totalCarrinho,
                                    );
                                  },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
