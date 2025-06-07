import 'dart:io'; // Adicionado para File, embora não usado diretamente aqui se a StockPage já trata o upload
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ajuste os caminhos de importação
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/product.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';
import 'package:flutter_application_1/data_class/firebase_product.dart';

enum MenuAcaoOferta { editar, apagar }

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final OfertaProdutoService _ofertaService = OfertaProdutoService();
  final AuthService _authService = AuthService();
  final ProdutoService _produtoService = ProdutoService();

  User? _currentUser;
  String? _currentVendedorId;

  String? _idProdutoGenericoSelecionado;
  Produto? _produtoBaseSelecionadoParaOferta;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoadingPageData = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUtilizador();
  }

  Future<void> _carregarDadosUtilizador() async {
    /* ... (como antes) ... */
    if (mounted) setState(() => _isLoadingPageData = true);
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentVendedorId = _currentUser!.uid;
    } else {
      print("SalesPage: Nenhum utilizador logado encontrado no initState!");
    }
    if (mounted) setState(() => _isLoadingPageData = false);
  }

  void _mostrarDialogoFormularioOferta({OfertaProduto? ofertaExistente}) {
    // ... (lógica de inicialização do diálogo e _idProdutoGenericoSelecionado como antes) ...
    bool isEditing = ofertaExistente != null;
    String tituloDialogo =
        isEditing ? 'Editar Oferta' : 'Criar Nova Oferta de Venda';
    bool _isDialogLoading = false;

    _produtoBaseSelecionadoParaOferta = null;

    if (isEditing) {
      _idProdutoGenericoSelecionado = ofertaExistente?.idProdutoGenerico;
      _tituloController.text = ofertaExistente!.tituloAnuncio;
      _descricaoController.text = ofertaExistente.descricaoAnuncio;
      _precoController.text = ofertaExistente.precoSugerido
          .toString()
          .replaceAll('.', ',');
      _quantidadeController.text =
          ofertaExistente.quantidadeDisponivelNestaOferta.toString();
      // Nota: Se _idProdutoGenericoSelecionado for definido, o FutureBuilder tentará encontrar
      // o _produtoBaseSelecionadoParaOferta e sua imageUrl.
    } else {
      _idProdutoGenericoSelecionado = null;
      _tituloController.clear();
      _descricaoController.clear();
      _precoController.clear();
      _quantidadeController.text = '1';
    }

    if (_currentVendedorId == null && !isEditing) {
      /* ... */
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
      barrierDismissible: !_isDialogLoading,
      builder: (BuildContext context) {
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
                      FutureBuilder<List<Produto>>(
                        future: _produtoService.fetchProdutosDoVendedor(
                          _currentVendedorId!,
                        ),
                        builder: (context, snapshotProdutos) {
                          // ... (lógica do FutureBuilder e DropdownButtonFormField como antes) ...
                          // A principal mudança será ao criar o objeto OfertaProduto
                          if (snapshotProdutos.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshotProdutos.hasError) {
                            return Text(
                              'Erro ao carregar produtos: ${snapshotProdutos.error}',
                            );
                          }
                          if (!snapshotProdutos.hasData ||
                              snapshotProdutos.data!.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Nenhum produto em stock. Adicione produtos na página de Stock primeiro.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          List<Produto> produtosEmStock =
                              snapshotProdutos.data!;
                          String? currentDropdownValue =
                              _idProdutoGenericoSelecionado;
                          if (_idProdutoGenericoSelecionado != null) {
                            if (!produtosEmStock.any(
                              (p) => p.id == _idProdutoGenericoSelecionado,
                            )) {
                              currentDropdownValue = null;
                              _produtoBaseSelecionadoParaOferta = null;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && dialogContext.mounted) {
                                  setDialogState(
                                    () => _idProdutoGenericoSelecionado = null,
                                  );
                                }
                              });
                            } else if (_produtoBaseSelecionadoParaOferta ==
                                    null ||
                                _produtoBaseSelecionadoParaOferta!.id !=
                                    _idProdutoGenericoSelecionado) {
                              _produtoBaseSelecionadoParaOferta =
                                  produtosEmStock.firstWhere(
                                    (p) =>
                                        p.id == _idProdutoGenericoSelecionado,
                                  );
                            }
                          }

                          return DropdownButtonFormField<String>(
                            value: currentDropdownValue,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Produto do Stock*',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              prefixIcon: const Icon(Icons.category_outlined),
                            ),
                            hint: const Text('Selecione um produto'),
                            disabledHint:
                                isEditing && ofertaExistente != null
                                    ? Text(
                                      produtosEmStock
                                          .firstWhere(
                                            (p) =>
                                                p.id ==
                                                ofertaExistente
                                                    .idProdutoGenerico,
                                            orElse:
                                                () => Produto(
                                                  id:
                                                      ofertaExistente
                                                          .idProdutoGenerico,
                                                  nome:
                                                      'Produto Original (Não no Stock)',
                                                  descricao: '',
                                                  preco: 0,
                                                  idVendedor: '',
                                                  tipoProduto:
                                                      TipoProdutoAgricola.outro,
                                                  imageUrl: null,
                                                ),
                                          )
                                          .nome,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                    : null,
                            onChanged:
                                isEditing || _isDialogLoading
                                    ? null
                                    : (String? newValue) {
                                      setDialogState(() {
                                        _idProdutoGenericoSelecionado =
                                            newValue;
                                        if (newValue != null) {
                                          _produtoBaseSelecionadoParaOferta =
                                              produtosEmStock.firstWhere(
                                                (p) => p.id == newValue,
                                              );
                                        } else {
                                          _produtoBaseSelecionadoParaOferta =
                                              null;
                                        }
                                      });
                                    },
                            items:
                                produtosEmStock.map<DropdownMenuItem<String>>((
                                  Produto produto,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: produto.id,
                                    child: Text(
                                      produto.nome,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                            validator: (value) {
                              if (_idProdutoGenericoSelecionado == null &&
                                  !isEditing) {
                                return 'Selecione um produto.';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Preview da Imagem do Produto Selecionado (se houver)
                      if (_produtoBaseSelecionadoParaOferta?.imageUrl != null &&
                          _produtoBaseSelecionadoParaOferta!
                              .imageUrl!
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _produtoBaseSelecionadoParaOferta!.imageUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stack) =>
                                      Icon(Icons.broken_image, size: 50),
                              loadingBuilder:
                                  (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : Center(
                                            child: SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                            ),
                          ),
                        ),

                      TextFormField(
                        controller: _tituloController,
                        /* ... (como antes) ... */ enabled: !_isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Título do Anúncio*',
                          hintText: 'Ex: Smartphone XPTO como novo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.title_outlined),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Insira um título.'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descricaoController,
                        /* ... (como antes) ... */ enabled: !_isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Descrição do Anúncio',
                          hintText: 'Detalhes, condição, extras, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precoController,
                        /* ... (como antes) ... */ enabled: !_isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Preço Sugerido (€)*',
                          hintText: 'Ex: 150,00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.euro_symbol_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Insira o preço.';
                          final preco = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (preco == null) return 'Preço inválido.';
                          if (preco <= 0) return 'O preço deve ser positivo.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantidadeController,
                        /* ... (como antes) ... */ enabled: !_isDialogLoading,
                        decoration: InputDecoration(
                          labelText: 'Quantidade para esta Oferta*',
                          hintText: 'Ex: 1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Insira a quantidade.';
                          final qtd = int.tryParse(value);
                          if (qtd == null) return 'Quantidade inválida.';
                          if (qtd <= 0)
                            return 'A quantidade deve ser positiva.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  /* ... (como antes) ... */ onPressed:
                      _isDialogLoading
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
                  /* ... (como antes, mas com imageUrl) ... */
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(dialogContext).colorScheme.primary,
                    foregroundColor:
                        Theme.of(dialogContext).colorScheme.onPrimary,
                  ),
                  onPressed:
                      _isDialogLoading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              if (_idProdutoGenericoSelecionado == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor, selecione um produto do stock.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              setDialogState(() => _isDialogLoading = true);
                              try {
                                OfertaProduto oferta = OfertaProduto(
                                  id: isEditing ? ofertaExistente!.id : '',
                                  idProdutoGenerico:
                                      _idProdutoGenericoSelecionado!,
                                  tituloAnuncio: _tituloController.text.trim(),
                                  descricaoAnuncio:
                                      _descricaoController.text.trim(),
                                  idVendedor: _currentVendedorId!,
                                  precoSugerido: double.parse(
                                    _precoController.text.replaceAll(',', '.'),
                                  ),
                                  quantidadeDisponivelNestaOferta: int.parse(
                                    _quantidadeController.text,
                                  ),
                                  dataCriacaoAnuncio:
                                      isEditing
                                          ? ofertaExistente!.dataCriacaoAnuncio
                                          : DateTime.now(),
                                  estadoAnuncio: 'Disponível',
                                  tipoProdutoAnuncio:
                                      _produtoBaseSelecionadoParaOferta
                                          ?.tipoProduto
                                          .name,
                                  imageUrl:
                                      _produtoBaseSelecionadoParaOferta
                                          ?.imageUrl, // Adiciona imageUrl do Produto base
                                  idComprador:
                                      isEditing
                                          ? ofertaExistente!.idComprador
                                          : null,
                                  dataTransacaoFinalizada:
                                      isEditing
                                          ? ofertaExistente!
                                              .dataTransacaoFinalizada
                                          : null,
                                  precoFinalTransacao:
                                      isEditing
                                          ? ofertaExistente!.precoFinalTransacao
                                          : null,
                                  quantidadeTransacionada:
                                      isEditing
                                          ? ofertaExistente!
                                              .quantidadeTransacionada
                                          : null,
                                );

                                if (isEditing) {
                                  await _ofertaService.atualizarOferta(oferta);
                                } else {
                                  await _ofertaService.adicionarOferta(oferta);
                                }
                                if (mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Oferta ${isEditing ? "atualizada" : "criada"} com sucesso!',
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
                                if (mounted)
                                  setDialogState(
                                    () => _isDialogLoading = false,
                                  );
                              }
                            }
                          },
                  child:
                      _isDialogLoading
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
                          : Text(isEditing ? 'Guardar' : 'Criar Oferta'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmarApagarOferta(OfertaProduto oferta) {
    /* ... (como antes) ... */
    bool _isDialogLoading = false;
    showDialog(
      context: context,
      barrierDismissible: !_isDialogLoading,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Confirmar Exclusão',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              content: Text(
                'Tem a certeza que deseja apagar a oferta "${oferta.tituloAnuncio}"?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      _isDialogLoading
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
                      _isDialogLoading
                          ? null
                          : () async {
                            setDialogState(() => _isDialogLoading = true);
                            try {
                              // Se a oferta tem uma imagem, pode querer apagá-la do Storage também
                              // if (oferta.imageUrl != null && oferta.imageUrl!.isNotEmpty) {
                              //   await StorageService().deleteImage(oferta.imageUrl!); // Assumindo que tem StorageService
                              // }
                              await _ofertaService.apagarOferta(oferta.id);
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Oferta "${oferta.tituloAnuncio}" apagada.',
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
                                      'Erro ao apagar: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted)
                                setDialogState(() => _isDialogLoading = false);
                            }
                          },
                  child:
                      _isDialogLoading
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
                          : const Text('Apagar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    /* ... (como antes) ... */
    Color chipColor;
    IconData iconData;
    switch (status.toLowerCase()) {
      case 'disponível':
        chipColor = Colors.green.shade600;
        iconData = Icons.check_circle_outline;
        break;
      case 'vendido':
        chipColor = Colors.blueGrey.shade400;
        iconData = Icons.receipt_long_outlined;
        break;
      default:
        chipColor = Colors.grey.shade500;
        iconData = Icons.info_outline;
    }
    return Chip(
      avatar: Icon(iconData, color: Colors.white, size: 16),
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0.0),
      labelPadding: const EdgeInsets.only(left: 2.0, right: 6.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build inicial com verificações de _isLoadingPageData e _currentVendedorId como antes) ...
    if (_isLoadingPageData)
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas Ofertas de Venda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    if (_currentVendedorId == null)
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas Ofertas de Venda')),
        body: Center(child: Text('Vendedor não identificado. Faça login.')),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Ofertas de Venda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: StreamBuilder<List<OfertaProduto>>(
        stream: _ofertaService.obterOfertasDoVendedor(_currentVendedorId!),
        builder: (context, snapshot) {
          // ... (lógica do StreamBuilder como antes) ...
          if (snapshot.hasError)
            return Center(child: Text('Erro: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('Nenhuma oferta criada.'));

          List<OfertaProduto> ofertas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: ofertas.length,
            itemBuilder: (context, index) {
              final oferta = ofertas[index];
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
                  padding: const EdgeInsets.all(8.0), // Padding geral no Card
                  child: Row(
                    // Usar Row para imagem ao lado das informações
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagem da Oferta (denormalizada do Produto)
                      if (oferta.imageUrl != null &&
                          oferta.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 12.0,
                            top: 4,
                            bottom: 4,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              oferta.imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : Container(
                                            width: 80,
                                            height: 80,
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                          ),
                              errorBuilder:
                                  (context, error, stack) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                            ),
                          ),
                        )
                      else // Placeholder se não houver imagem
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 12.0,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              Icons.sell_outlined,
                              size: 40,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              oferta.tituloAnuncio,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (oferta.tipoProdutoAnuncio != null &&
                                oferta.tipoProdutoAnuncio!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Tipo: ${stringForUser(oferta.tipoProdutoAnuncio)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 3.0,
                              ),
                              child: Text(
                                'Preço: ${oferta.precoSugerido.toStringAsFixed(2)} € - Qtd: ${oferta.quantidadeDisponivelNestaOferta}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            _buildStatusChip(
                              oferta.estadoAnuncio ?? 'Disponível',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<MenuAcaoOferta>(
                        /* ... (como antes) ... */
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        onSelected: (MenuAcaoOferta acao) {
                          if (acao == MenuAcaoOferta.editar) {
                            _mostrarDialogoFormularioOferta(
                              ofertaExistente: oferta,
                            );
                          } else if (acao == MenuAcaoOferta.apagar) {
                            _confirmarApagarOferta(oferta);
                          }
                        },
                        itemBuilder:
                            (BuildContext context) =>
                                <PopupMenuEntry<MenuAcaoOferta>>[
                                  const PopupMenuItem<MenuAcaoOferta>(
                                    value: MenuAcaoOferta.editar,
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Editar'),
                                    ),
                                  ),
                                  const PopupMenuItem<MenuAcaoOferta>(
                                    value: MenuAcaoOferta.apagar,
                                    child: ListTile(
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Apagar'),
                                    ),
                                  ),
                                ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        /* ... (como antes) ... */
        onPressed: () {
          if (_currentVendedorId != null) {
            _mostrarDialogoFormularioOferta();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vendedor não identificado.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nova Oferta'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
