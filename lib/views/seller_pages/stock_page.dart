import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/firebase_product.dart';

// Ajuste os caminhos de importação
import 'package:flutter_application_1/data_class/product.dart'; // Já inclui o enum TipoProdutoAgricola

// O enum MenuAcaoStock já deve estar aqui ou importado se o moveu
enum MenuAcaoStock { editar, apagar }

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final ProdutoService _produtoService = ProdutoService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _currentVendedorId;
  bool _isLoadingPageData = true;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  // Variável de estado para o tipo de produto selecionado no diálogo
  TipoProdutoAgricola? _tipoProdutoSelecionadoDialogo;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _carregarDadosUtilizador();
  }

  Future<void> _carregarDadosUtilizador() async {
    if (mounted) setState(() => _isLoadingPageData = true);
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentVendedorId = _currentUser!.uid;
    } else {}
    if (mounted) setState(() => _isLoadingPageData = false);
  }

  void _mostrarDialogoFormularioProduto({Produto? produtoExistente}) {
    bool isEditing = produtoExistente != null;
    String tituloDialogo =
        isEditing
            ? 'Editar Produto no Stock'
            : 'Adicionar Novo Produto ao Stock';
    bool isDialogLoading = false;

    // Inicializa o tipo de produto selecionado para o diálogo
    if (isEditing) {
      _tipoProdutoSelecionadoDialogo = produtoExistente.tipoProduto;
    } else {
      _tipoProdutoSelecionadoDialogo = null; // Começa nulo para novo produto
    }

    if (_currentVendedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Vendedor não identificado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isEditing) {
      _nomeController.text = produtoExistente.nome;
      _descricaoController.text = produtoExistente.descricao;
      _quantidadeController.text =
          produtoExistente.quantidadeEmStock.toString();
      // _tipoProdutoSelecionadoDialogo já foi definido acima
    } else {
      _nomeController.clear();
      _descricaoController.clear();
      _quantidadeController.text = '0';
      // _tipoProdutoSelecionadoDialogo começa como null
    }

    showDialog(
      context: context,
      barrierDismissible: !isDialogLoading,
      builder: (BuildContext context) {
        // StatefulBuilder para gerir o estado do Dropdown e do loading DENTRO do diálogo
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                tituloDialogo,
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _nomeController,
                        enabled: !isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Nome do Produto*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira o nome do produto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Dropdown para Tipo de Produto
                      DropdownButtonFormField<TipoProdutoAgricola>(
                        value: _tipoProdutoSelecionadoDialogo,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Produto*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.eco_outlined),
                        ),
                        hint: const Text('Selecione o tipo'),
                        items:
                            TipoProdutoAgricola.values.map((
                              TipoProdutoAgricola tipo,
                            ) {
                              return DropdownMenuItem<TipoProdutoAgricola>(
                                value: tipo,
                                child: Text(
                                  tipoProdutoAgricolaParaString(tipo),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            isDialogLoading
                                ? null
                                : (TipoProdutoAgricola? newValue) {
                                  setDialogState(() {
                                    // Usa o setDialogState do StatefulBuilder
                                    _tipoProdutoSelecionadoDialogo = newValue;
                                  });
                                },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Selecione um tipo de produto'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descricaoController,
                        enabled: !isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Descrição (Opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantidadeController,
                        enabled: !isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Quantidade em Stock*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira a quantidade.';
                          }
                          final int? quantidade = int.tryParse(value);
                          if (quantidade == null) {
                            return 'Por favor, insira um número inteiro válido.';
                          }
                          if (quantidade < 0) {
                            return 'A quantidade não pode ser negativa.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isDialogLoading
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.secondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(dialogContext).colorScheme.primary,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onPrimary,
                  ),
                  onPressed:
                      isDialogLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              // Validação extra para o tipo de produto selecionado
                              if (_tipoProdutoSelecionadoDialogo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor, selecione um tipo de produto.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setDialogState(() => isDialogLoading = true);

                              final nome = _nomeController.text.trim();
                              final descricao =
                                  _descricaoController.text.trim();
                              final quantidade = int.parse(
                                _quantidadeController.text,
                              );
                              const double precoPadrao = 0.0;

                              try {
                                if (isEditing) {
                                  Produto produtoAtualizado = Produto(
                                    id: produtoExistente.id,
                                    nome: nome,
                                    descricao: descricao,
                                    preco: produtoExistente.preco,
                                    idVendedor: produtoExistente.idVendedor,
                                    quantidadeEmStock: quantidade,
                                    tipoProduto:
                                        _tipoProdutoSelecionadoDialogo!, // Usa o tipo selecionado
                                  );
                                  await _produtoService
                                      .atualizarProdutoCompleto(
                                        produtoAtualizado,
                                      );
                                } else {
                                  Produto novoProduto = Produto(
                                    id: '',
                                    nome: nome,
                                    descricao: descricao,
                                    preco: precoPadrao,
                                    idVendedor: _currentVendedorId!,
                                    quantidadeEmStock: quantidade,
                                    tipoProduto:
                                        _tipoProdutoSelecionadoDialogo!, // Usa o tipo selecionado
                                  );
                                  await _produtoService
                                      .adicionarProdutoComStock(novoProduto);
                                }
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  Navigator.of(dialogContext).pop();
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Produto de stock ${isEditing ? "atualizado" : "adicionado"} com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setDialogState(() => isDialogLoading = false);
                                }
                              }
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
                                Theme.of(dialogContext).colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Text(
                            isEditing
                                ? 'Guardar Alterações'
                                : 'Adicionar Produto',
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarApagarProduto(Produto produto) {
    // ... (código existente para apagar, não precisa de alterações para 'tipoProduto')
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
                  onPressed:
                      isDialogLoading
                          ? null
                          : () async {
                            setDialogState(() => isDialogLoading = true);
                            try {
                              await _produtoService.removerProdutoDoStock(
                                produto.id,
                              );
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                Navigator.of(context).pop();
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Produto "${produto.nome}" removido do stock.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao remover: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(() => isDialogLoading = false);
                              }
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

  @override
  Widget build(BuildContext context) {
    // ... (build inicial com verificações de _isLoadingPageData e _currentVendedorId como antes) ...
    if (_isLoadingPageData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Meu Stock de Produtos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            key: Key("stock_page_loading_indicator"),
          ),
        ),
      );
    }

    if (_currentVendedorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Stock de Produtos')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  'Vendedor não identificado. Por favor, faça login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  child: const Text('Ir para Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Stock de Produtos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 2,
      ),
      body: StreamBuilder<List<Produto>>(
        stream: _produtoService.obterProdutosDoVendedor(_currentVendedorId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar stock: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                key: Key("stock_list_loading_indicator"),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ainda não tem produtos no seu stock.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no botão "+" para adicionar um produto ao stock.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          List<Produto> produtosEmStock = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: produtosEmStock.length,
            itemBuilder: (context, index) {
              final produto = produtosEmStock[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 4.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons
                            .eco_outlined, // Ícone pode ser dinâmico com base no tipoProduto
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      produto.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Exibir o tipo de produto
                          Text(
                            'Tipo: ${tipoProdutoAgricolaParaString(produto.tipoProduto)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            'Stock Atual: ${produto.quantidadeEmStock} unidades',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (produto.descricao.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Descrição: ${produto.descricao}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1, // Reduzido para dar espaço ao tipo
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<MenuAcaoStock>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      onSelected: (MenuAcaoStock acao) {
                        if (acao == MenuAcaoStock.editar) {
                          _mostrarDialogoFormularioProduto(
                            produtoExistente: produto,
                          );
                        } else if (acao == MenuAcaoStock.apagar) {
                          _confirmarApagarProduto(produto);
                        }
                      },
                      itemBuilder:
                          (BuildContext context) =>
                              <PopupMenuEntry<MenuAcaoStock>>[
                                const PopupMenuItem<MenuAcaoStock>(
                                  value: MenuAcaoStock.editar,
                                  child: ListTile(
                                    leading: Icon(Icons.edit_note_outlined),
                                    title: Text('Editar'),
                                  ),
                                ),
                                const PopupMenuItem<MenuAcaoStock>(
                                  value: MenuAcaoStock.apagar,
                                  child: ListTile(
                                    leading: Icon(Icons.delete_sweep_outlined),
                                    title: Text('Remover'),
                                  ),
                                ),
                              ],
                    ),
                    isThreeLine:
                        true, // Pode precisar ajustar com base no conteúdo
                    onTap:
                        () => _mostrarDialogoFormularioProduto(
                          produtoExistente: produto,
                        ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentVendedorId != null) {
            _mostrarDialogoFormularioProduto();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não é possível adicionar produto: Vendedor não identificado.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Novo Produto'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
