// ficheiro: lib/views/explore_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/cart_service.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/product.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorarOfertasPageState();
}

class _ExplorarOfertasPageState extends State<ExplorePage> {
  final OfertaProdutoService _ofertaService = OfertaProdutoService();
  final CarrinhoService _carrinhoService = CarrinhoService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  User? _currentUser;
  String? _currentUserId;

  String? _termoPesquisaAtual;
  TipoProdutoAgricola? _filtroTipoSelecionado;
  RangeValues? _filtroFaixaPreco;
  List<OfertaProduto> _ofertasDestaque = [];
  final Map<String, bool> _isAddingToCart = {};

  @override
  void initState() {
    super.initState();
    _carregarDadosUtilizador();
    _searchController.addListener(() {
      if (mounted && _searchController.text != _termoPesquisaAtual) {
        setState(() {
          _termoPesquisaAtual = _searchController.text;
        });
      }
    });
    _carregarDestaquesIniciais();
  }

  Future<void> _carregarDadosUtilizador() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentUserId = _currentUser!.uid;
    }
  }

  Future<void> _carregarDestaquesIniciais() async {
    _ofertaService.getTodasOfertasDisponiveisStream().take(1).listen((ofertas) {
      if (mounted) {
        setState(() {
          _ofertasDestaque = ofertas.take(5).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _abrirDialogoFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Filtrar Ofertas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tipo de Produto:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    DropdownButtonFormField<TipoProdutoAgricola>(
                      value: _filtroTipoSelecionado,
                      hint: const Text('Todos os tipos'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<TipoProdutoAgricola>(
                          value: null,
                          child: Text('Todos os Tipos'),
                        ),
                        ...TipoProdutoAgricola.values.map((tipo) {
                          return DropdownMenuItem<TipoProdutoAgricola>(
                            value: tipo,
                            child: Text(
                              tipoProdutoAgricolaParaStringForUser(tipo),
                            ),
                          );
                        }),
                      ],
                      onChanged: (novoValor) {
                        setModalState(() => _filtroTipoSelecionado = novoValor);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Faixa de Preço (€):',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    RangeSlider(
                      values: _filtroFaixaPreco ?? const RangeValues(0, 500),
                      min: 0,
                      max: 500,
                      divisions: 50,
                      labels:
                          _filtroFaixaPreco != null
                              ? RangeLabels(
                                '${_filtroFaixaPreco!.start.round()}€',
                                '${_filtroFaixaPreco!.end.round()}€',
                              )
                              : null,
                      onChanged: (values) {
                        setModalState(() => _filtroFaixaPreco = values);
                      },
                    ),
                    Text(
                      _filtroFaixaPreco != null
                          ? 'Selecionado: ${_filtroFaixaPreco!.start.round()}€ - ${_filtroFaixaPreco!.end.round()}€'
                          : 'Preço: Qualquer',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _filtroTipoSelecionado = null;
                              _filtroFaixaPreco = null;
                            });
                            if (mounted) setState(() {});
                          },
                          child: const Text('Limpar Filtros'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Aplicar'),
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
    );
  }

  Future<void> _adicionarOfertaAoCarrinho(OfertaProduto oferta) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precisa estar logado para adicionar ao carrinho.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if ((_isAddingToCart[oferta.id] ?? false)) return;
    setState(() => _isAddingToCart[oferta.id] = true);
    try {
      await _carrinhoService.adicionarItemAoCarrinho(
        _currentUserId!,
        oferta,
        1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${oferta.tituloAnuncio} adicionado ao carrinho!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao adicionar: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart[oferta.id] = false);
      }
    }
  }

  // MÉTODO ATUALIZADO PARA MOSTRAR A IMAGEM
  Widget _buildOfertaCard(BuildContext context, OfertaProduto oferta) {
    final bool isCurrentlyAdding = _isAddingToCart[oferta.id] ?? false;
    final bool isEsgotado =
        oferta.quantidadeDisponivelNestaOferta <= 0 ||
        oferta.estadoAnuncio.toLowerCase() == 'esgotado';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Corta a imagem para as bordas do cartão
      child: InkWell(
        onTap: () {
          // TODO: Navegar para a página de detalhes da oferta
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECÇÃO DA IMAGEM ---
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[200],
              child:
                  (oferta.imageUrl != null && oferta.imageUrl!.isNotEmpty)
                      ? Image.network(
                        oferta.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder:
                            (context, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                        errorBuilder:
                            (context, error, stack) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.eco_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
            ),

            // --- CONTEÚDO DO CARTÃO ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          oferta.tituloAnuncio,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${oferta.precoSugerido.toStringAsFixed(2)} €',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Disponível: ${oferta.quantidadeDisponivelNestaOferta}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child:
                          isEsgotado
                              ? const Chip(label: Text('Esgotado'))
                              : FilledButton.tonalIcon(
                                icon:
                                    isCurrentlyAdding
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.add_shopping_cart_outlined,
                                          size: 18,
                                        ),
                                label: const Text('Adicionar'),
                                onPressed:
                                    isCurrentlyAdding
                                        ? null
                                        : () =>
                                            _adicionarOfertaAoCarrinho(oferta),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Produtos Agrícolas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onPressed: _abrirDialogoFiltros,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome, tipo...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                ),
              ),
            ),

            if (_ofertasDestaque.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Destaques Para Si',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 320, // Altura ajustada para o novo card com imagem
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _ofertasDestaque.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 210, // Largura ajustada
                      child: _buildOfertaCard(context, _ofertasDestaque[index]),
                    );
                  },
                ),
              ),
              const Divider(height: 24, indent: 12, endIndent: 12),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Text(
                'Todas as Ofertas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            StreamBuilder<List<OfertaProduto>>(
              stream: _ofertaService.getTodasOfertasDisponiveisStream(
                termoPesquisa: _termoPesquisaAtual,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Erro: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<OfertaProduto> ofertas = snapshot.data ?? [];

                // Filtragem no lado do cliente
                if (_filtroTipoSelecionado != null) {
                  ofertas =
                      ofertas
                          .where(
                            (o) =>
                                o.tipoProdutoAnuncio ==
                                tipoProdutoAgricolaParaString(
                                  _filtroTipoSelecionado!,
                                ),
                          )
                          .toList();
                }
                if (_filtroFaixaPreco != null) {
                  ofertas =
                      ofertas
                          .where(
                            (o) =>
                                o.precoSugerido >= _filtroFaixaPreco!.start &&
                                o.precoSugerido <= _filtroFaixaPreco!.end,
                          )
                          .toList();
                }

                if (ofertas.isEmpty)
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhuma oferta encontrada.'),
                    ),
                  );

                // GRIDVIEW ATUALIZADO
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio:
                        0.65, // Rácio ajustado para o card mais alto
                  ),
                  itemCount: ofertas.length,
                  itemBuilder: (context, index) {
                    return _buildOfertaCard(context, ofertas[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
