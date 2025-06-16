import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/data_class/auth_service.dart';
import 'package:flutter_application_1/data_class/firebase_product.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';

class HomeSellerPage extends StatefulWidget {
  const HomeSellerPage({super.key});

  @override
  State<HomeSellerPage> createState() => _HomeSellerPageState();
}

class _HomeSellerPageState extends State<HomeSellerPage> {
  final AuthService _authService = AuthService();
  final ProdutoService _produtoService = ProdutoService();
  final OfertaProdutoService _ofertaProdutoService = OfertaProdutoService();

  int totalProdutos = 0;
  int anunciosAtivos = 0;
  int pedidosRecebidos = 0;
  double avaliacaoMedia = 0.0;

  String? _currentVendedorId;
  bool _isLoadingPageData = true;
  User? _currentUser;

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

      // Obter produtos do vendedor
      final produtos = await _produtoService.fetchProdutosDoVendedor(_currentVendedorId!);
      final int totalActivos = await _ofertaProdutoService.obterNumeroAnunciosActivosDoVendedor(_currentVendedorId!);
      final int totalPedidos = await _ofertaProdutoService.obterNumeroOfertasVendidasDoVendedor(_currentVendedorId!);
      // Exemplo de dados simulados:
      final ativos = totalActivos;
      final pedidos = totalPedidos;
      final avaliacao = 4.8; // <- simulado

      if (mounted) {
        setState(() {
          totalProdutos = produtos.length;
          anunciosAtivos = ativos;
          pedidosRecebidos = pedidos;
          avaliacaoMedia = avaliacao;
        });
      }
    } else {
      print("Nenhum utilizador logado encontrado!");
    }

    if (mounted) setState(() => _isLoadingPageData = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central do Vendedor'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoadingPageData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visão Geral da Sua Loja',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildResumoCards(screenWidth),
                    const SizedBox(height: 24),
                    // const Text(
                    //   'Gerenciar Anúncios',
                    //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    // ),
                    const SizedBox(height: 16),
                    // _buildAnunciosCards(screenWidth), // futuro
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResumoCards(double screenWidth) {
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    final cards = [
      _resumoCard('Total de Produtos', '$totalProdutos', '+10%', Colors.green),
      _resumoCard('Anúncios Ativos', '$anunciosAtivos', '+5%', Colors.green),
      _resumoCard('Pedidos Recebidos', '$pedidosRecebidos', '-2%', Colors.red),
      _resumoCard('Avaliação', '${avaliacaoMedia.toStringAsFixed(1)} / 5', '0%', Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: cards.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (_, index) => cards[index],
    );
  }

  Widget _resumoCard(String titulo, String valor, String variacao, Color cor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(variacao, style: TextStyle(color: cor)),
          ],
        ),
      ),
    );
  }
}
