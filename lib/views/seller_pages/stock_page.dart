// ficheiro: lib/stock_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/firebase_product.dart';
import 'package:flutter_application_1/data_class/product.dart';
import 'package:flutter_application_1/data_class/storage_service.dart';
import 'package:image_picker/image_picker.dart';

// Importe os novos serviços

enum MenuAcaoStock { editar, apagar }

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final ProdutoService _produtoService = ProdutoService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _currentVendedorId;
  bool _isLoadingPageData = true;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  TipoProdutoAgricola? _tipoProdutoSelecionadoDialogo;

  File? _imagemSelecionada;
  String? _urlImagemExistente;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _carregarDadosUtilizador();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUtilizador() async {
    if (mounted) setState(() => _isLoadingPageData = true);
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentVendedorId = _currentUser!.uid;
    } else {
      // Lógica de utilizador não encontrado, se necessário
    }
    if (mounted) setState(() => _isLoadingPageData = false);
  }

  Future<void> _escolherImagem(
    ImageSource source,
    Function(File) onImageSelected,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (imagem != null) {
      onImageSelected(File(imagem.path));
    }
  }

  void _mostrarOpcoesImagem(Function(File) onImageSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria de Fotos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _escolherImagem(ImageSource.gallery, onImageSelected);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmara'),
                onTap: () {
                  Navigator.of(context).pop();
                  _escolherImagem(ImageSource.camera, onImageSelected);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoFormularioProduto({Produto? produtoExistente}) {
    final bool isEditing = produtoExistente != null;
    final String tituloDialogo =
        isEditing
            ? 'Editar Produto no Stock'
            : 'Adicionar Novo Produto ao Stock';
    bool isDialogLoading = false;

    // Resetar estado do formulário/dialogo
    _imagemSelecionada = null;
    _urlImagemExistente = null;
    _formKey.currentState?.reset();

    if (isEditing) {
      _nomeController.text = produtoExistente.nome;
      _descricaoController.text = produtoExistente.descricao;
      _quantidadeController.text =
          produtoExistente.quantidadeEmStock.toString();
      _tipoProdutoSelecionadoDialogo = produtoExistente.tipoProduto;
      _urlImagemExistente = produtoExistente.imageUrl;
    } else {
      _nomeController.clear();
      _descricaoController.clear();
      _quantidadeController.text = '0';
      _tipoProdutoSelecionadoDialogo = null;
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

    showDialog(
      context: context,
      barrierDismissible: !isDialogLoading,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void setImagemDialogo(File imagem) {
              setDialogState(() {
                _imagemSelecionada = imagem;
                _urlImagemExistente =
                    null; // Prioriza a nova imagem sobre a antiga
              });
            }

            return AlertDialog(
              title: Text(tituloDialogo),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // --- SECÇÃO DE UPLOAD DE IMAGEM ---
                      Text(
                        "Imagem do Produto (Opcional)",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap:
                            isDialogLoading
                                ? null
                                : () => _mostrarOpcoesImagem(setImagemDialogo),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                            image:
                                _imagemSelecionada != null
                                    ? DecorationImage(
                                      image: FileImage(_imagemSelecionada!),
                                      fit: BoxFit.cover,
                                    )
                                    : (_urlImagemExistente != null &&
                                        _urlImagemExistente!.isNotEmpty)
                                    ? DecorationImage(
                                      image: NetworkImage(_urlImagemExistente!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              (_imagemSelecionada == null &&
                                      (_urlImagemExistente == null ||
                                          _urlImagemExistente!.isEmpty))
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 40,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Carregar Imagem'),
                                      ],
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nomeController,
                        enabled: !isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Nome do Produto*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Por favor, insira o nome.'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TipoProdutoAgricola>(
                        value: _tipoProdutoSelecionadoDialogo,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Produto*',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.eco_outlined),
                        ),
                        hint: const Text('Selecione o tipo'),
                        items:
                            TipoProdutoAgricola.values
                                .map(
                                  (tipo) => DropdownMenuItem(
                                    value: tipo,
                                    child: Text(
                                      tipoProdutoAgricolaParaStringForUser(
                                        tipo,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            isDialogLoading
                                ? null
                                : (newValue) => setDialogState(
                                  () =>
                                      _tipoProdutoSelecionadoDialogo = newValue,
                                ),
                        validator:
                            (value) =>
                                value == null
                                    ? 'Selecione um tipo de produto.'
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
                          prefixIcon: const Icon(Icons.description_outlined),
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
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Insira a quantidade.';
                          if (int.tryParse(value) == null)
                            return 'Insira um número válido.';
                          if (int.parse(value) < 0)
                            return 'A quantidade não pode ser negativa.';
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
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed:
                      isDialogLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              setDialogState(() => isDialogLoading = true);
                              try {
                                String? finalImageUrl = _urlImagemExistente;

                                if (_imagemSelecionada != null) {
                                  if (isEditing &&
                                      _urlImagemExistente != null &&
                                      _urlImagemExistente!.isNotEmpty) {
                                    await _storageService.removerImagem(
                                      _urlImagemExistente!,
                                    );
                                  }
                                  finalImageUrl = await _storageService
                                      .uploadImagemProduto(
                                        ficheiro: _imagemSelecionada!,
                                        idVendedor: _currentVendedorId!,
                                      );
                                }

                                if (isEditing) {
                                  Produto produtoAtualizado = Produto(
                                    id: produtoExistente.id,
                                    nome: _nomeController.text.trim(),
                                    descricao: _descricaoController.text.trim(),
                                    preco: produtoExistente.preco,
                                    idVendedor: produtoExistente.idVendedor,
                                    quantidadeEmStock: int.parse(
                                      _quantidadeController.text.trim(),
                                    ),
                                    tipoProduto:
                                        _tipoProdutoSelecionadoDialogo!,
                                    imageUrl: finalImageUrl,
                                  );
                                  await _produtoService
                                      .atualizarProdutoCompleto(
                                        produtoAtualizado,
                                      );
                                } else {
                                  Produto novoProduto = Produto(
                                    id: '',
                                    nome: _nomeController.text.trim(),
                                    descricao: _descricaoController.text.trim(),
                                    preco: 0.0,
                                    idVendedor: _currentVendedorId!,
                                    quantidadeEmStock: int.parse(
                                      _quantidadeController.text.trim(),
                                    ),
                                    tipoProduto:
                                        _tipoProdutoSelecionadoDialogo!,
                                    imageUrl: finalImageUrl,
                                  );
                                  await _produtoService
                                      .adicionarProdutoComStock(novoProduto);
                                }
                                if (mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Produto ${isEditing ? "atualizado" : "adicionado"} com sucesso!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
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
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                          : Text(isEditing ? 'Guardar' : 'Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarApagarProduto(Produto produto) {
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
                'Tem a certeza que deseja remover o produto "${produto.nome}"? Esta ação também irá apagar a imagem associada.',
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
                              // Primeiro apaga a imagem do Storage, se existir
                              if (produto.imageUrl != null &&
                                  produto.imageUrl!.isNotEmpty) {
                                await _storageService.removerImagem(
                                  produto.imageUrl!,
                                );
                              }
                              // Depois apaga o registo do Firestore
                              await _produtoService.removerProdutoDoStock(
                                produto.id,
                              );
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Produto "${produto.nome}" removido.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
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
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
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
    if (_isLoadingPageData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu Stock de Produtos')),
        body: const Center(child: CircularProgressIndicator()),
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
                  onPressed: () async => await _authService.signOut(),
                  child: const Text('Ir para Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Stock de Produtos'), elevation: 2),
      body: StreamBuilder<List<Produto>>(
        stream: _produtoService.obterProdutosDoVendedor(_currentVendedorId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar stock: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Ainda não tem produtos no stock.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Clique no botão "+" para adicionar.',
                    style: TextStyle(color: Colors.grey),
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
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        (produto.imageUrl != null &&
                                produto.imageUrl!.isNotEmpty)
                            ? NetworkImage(produto.imageUrl!)
                            : null,
                    child:
                        (produto.imageUrl == null || produto.imageUrl!.isEmpty)
                            ? const Icon(Icons.eco_outlined, color: Colors.grey)
                            : null,
                  ),
                  title: Text(
                    produto.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo: ${tipoProdutoAgricolaParaStringForUser(produto.tipoProduto)}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Stock: ${produto.quantidadeEmStock} unidades',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<MenuAcaoStock>(
                    icon: const Icon(Icons.more_vert),
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
                  isThreeLine: true,
                  onTap:
                      () => _mostrarDialogoFormularioProduto(
                        produtoExistente: produto,
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoFormularioProduto(),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Novo Produto'),
      ),
    );
  }
}
