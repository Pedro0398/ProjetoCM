import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para User
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/cart_service.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/product.dart';
import 'package:flutter_application_1/views/costumer_pages/cart_page.dart';
import 'package:flutter_application_1/views/widgets/navbar_widget.dart';

// Importar CarrinhoService

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorarOfertasPageState();
}

class _ExplorarOfertasPageState extends State<ExplorePage> {
  final OfertaProdutoService _ofertaService = OfertaProdutoService();
  final CarrinhoService _carrinhoService =
      CarrinhoService(); // Instância do CarrinhoService
  final AuthService _authService = AuthService(); // Instância do AuthService
  final TextEditingController _searchController = TextEditingController();

  User? _currentUser;
  String? _currentUserId;

  String? _termoPesquisaAtual;
  TipoProdutoAgricola? _filtroTipoSelecionado;
  RangeValues? _filtroFaixaPreco;
  List<OfertaProduto> _ofertasDestaque = [];

  // Mapa para controlar o estado de carregamento de cada botão "Adicionar"
  final Map<String, bool> _isAddingToCart = {};

  @override
  void initState() {
    super.initState();
    _carregarDadosUtilizador(); // Carrega dados do utilizador
    _searchController.addListener(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _searchController.text != _termoPesquisaAtual) {
          setState(() {
            _termoPesquisaAtual = _searchController.text;
          });
        }
      });
    });
    _carregarDestaquesIniciais();
  }

  Future<void> _carregarDadosUtilizador() async {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _currentUserId = _currentUser!.uid;
    }
    // Não precisa de setState aqui se a UI principal não depender disto imediatamente
    // ou se for apenas para as ações dos botões.
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
    // ... (código do diálogo de filtros permanece o mesmo) ...
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
                        ...TipoProdutoAgricola.values.map((
                          TipoProdutoAgricola tipo,
                        ) {
                          return DropdownMenuItem<TipoProdutoAgricola>(
                            value: tipo,
                            child: Text(tipoProdutoAgricolaParaString(tipo)),
                          );
                        }),
                      ],
                      onChanged: (TipoProdutoAgricola? novoValor) {
                        setModalState(() {
                          _filtroTipoSelecionado = novoValor;
                        });
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
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          _filtroFaixaPreco = values;
                        });
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
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: const Text('Limpar Filtros'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {});
                            }
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
      // TODO: Opcionalmente, navegar para a página de login
      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginPage()));
      return;
    }

    if ((_isAddingToCart[oferta.id] ?? false)) return; // Já está a adicionar

    setState(() {
      _isAddingToCart[oferta.id] = true;
    });

    try {
      // Adiciona 1 unidade da oferta por defeito
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
        setState(() {
          _isAddingToCart[oferta.id] = false;
        });
      }
    }
  }

  Widget _buildOfertaCard(BuildContext context, OfertaProduto oferta) {
    final bool isCurrentlyAdding = _isAddingToCart[oferta.id] ?? false;
    final bool isEsgotado =
        oferta.quantidadeDisponivelNestaOferta <= 0 ||
        oferta.estadoAnuncio.toLowerCase() == 'esgotado';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: () {
          // TODO: Navegar para a página de detalhes da oferta/produto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Clicou em: ${oferta.tituloAnuncio}')),
          );
        },
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: Adicionar Imagem
                  Text(
                    oferta.tituloAnuncio,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (oferta.tipoProdutoAnuncio != null &&
                      oferta.tipoProdutoAnuncio!.isNotEmpty)
                    Chip(
                      label: Text(
                        oferta.tipoProdutoAnuncio!,
                        style: TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Theme.of(
                        context,
                        // ignore: deprecated_member_use
                      ).colorScheme.secondaryContainer.withOpacity(0.7),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelPadding: EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${oferta.precoSugerido.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Disponível: ${oferta.quantidadeDisponivelNestaOferta}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isEsgotado ? Colors.red : Colors.grey[700],
                    ),
                  ),
                  if (oferta.descricaoAnuncio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        oferta.descricaoAnuncio,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child:
                    isEsgotado
                        ? Chip(
                          label: Text(
                            'Esgotado',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red.shade400,
                        )
                        : FilledButton.tonalIcon(
                          icon:
                              isCurrentlyAdding
                                  ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.add_shopping_cart_outlined,
                                    size: 18,
                                  ),
                          label: const Text('Adicionar'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          onPressed:
                              isCurrentlyAdding
                                  ? null
                                  : () => _adicionarOfertaAoCarrinho(oferta),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (o resto do método build como antes, incluindo a barra de pesquisa, destaques e StreamBuilder/GridView)
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
                  fillColor: Theme.of(
                    context,
                    // ignore: deprecated_member_use
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.7),
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
                height:
                    280, // Altura ajustada para o card com mais info e botão
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: _ofertasDestaque.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 200, // Largura ajustada
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
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erro: ${snapshot.error}'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty &&
                        _termoPesquisaAtual == null &&
                        _filtroTipoSelecionado == null &&
                        _filtroFaixaPreco == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhuma oferta disponível no momento.'),
                    ),
                  );
                }

                List<OfertaProduto> ofertas = snapshot.data ?? [];

                if (_filtroTipoSelecionado != null) {
                  ofertas =
                      ofertas
                          .where(
                            (o) =>
                                o.tipoProdutoAnuncio ==
                                _filtroTipoSelecionado!.name,
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

                if (ofertas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhuma oferta encontrada com os filtros aplicados.',
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio:
                        0.58, // Ajustado para mais conteúdo no card
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
      //bottomNavigationBar: const NavBar(),
    );
  }
}
