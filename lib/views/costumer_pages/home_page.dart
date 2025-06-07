import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ajuste os imports para os seus caminhos
import 'package:flutter_application_1/data_class/user.dart';
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/firebase_offer.dart';
import 'package:flutter_application_1/data_class/product.dart';

// Serviço para gerir utilizadores
class UtilizadorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'utilizadores';

  // Obter vendedores em destaque (por exemplo, os que têm mais ofertas ativas)
  Future<List<Utilizador>> obterVendedoresEmDestaque({int limite = 6}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('tipoUtilizador', isEqualTo: 'Vendedor')
          .limit(limite)
          .get();

      return querySnapshot.docs.map((doc) {
        return Utilizador.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter vendedores em destaque: $e');
      }
      return [];
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boas-vindas
            const Text(
              'Bem-vindo, comprador!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubra produtos frescos e locais',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Secção Vendedores em Destaque
            const Text(
              'Vendedores em Destaque',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de vendedores
            FutureBuilder<List<Utilizador>>(
              future: UtilizadorService().obterVendedoresEmDestaque(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar vendedores',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum vendedor encontrado',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                List<Utilizador> vendedores = snapshot.data!;

                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vendedores.length,
                    itemBuilder: (context, index) {
                      Utilizador vendedor = vendedores[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OfertasVendedorPage(
                                vendedor: vendedor,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              // Ícone do perfil
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.green[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Nome do vendedor
                              Text(
                                vendedor.nome,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Outras secções podem ser adicionadas aqui
            const Text(
              'Categorias Mais Populares',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Grid de categorias dinâmicas
            FutureBuilder<List<TipoProdutoAgricola>>(
              future: OfertaProdutoService().obterCategoriasMaisPopulares(limite: 4),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar categorias',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma categoria encontrada',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                List<TipoProdutoAgricola> categorias = snapshot.data!;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: categorias.map((categoria) {
                    return _buildCategoriaCard(context, categoria);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaCard(BuildContext context, TipoProdutoAgricola categoria) {
    // Mapear categorias para ícones e cores
    IconData icon;
    Color cor;
    String nome = tipoProdutoAgricolaParaString(categoria);

    switch (categoria) {
      case TipoProdutoAgricola.fruta:
        icon = Icons.apple;
        cor = Colors.orange;
        break;
      case TipoProdutoAgricola.vegetal:
        icon = Icons.eco;
        cor = Colors.green;
        break;
      case TipoProdutoAgricola.legume:
        icon = Icons.grass;
        cor = Colors.lightGreen;
        break;
      case TipoProdutoAgricola.laticinio:
        icon = Icons.local_drink;
        cor = Colors.blue;
        break;
      case TipoProdutoAgricola.ovo:
        icon = Icons.egg;
        cor = Colors.amber;
        break;
      case TipoProdutoAgricola.cereal:
        icon = Icons.grain;
        cor = Colors.brown;
        break;
      case TipoProdutoAgricola.leguminosa:
        icon = Icons.spa;
        cor = Colors.teal;
        break;
      case TipoProdutoAgricola.carne:
        icon = Icons.restaurant;
        cor = Colors.red;
        break;
      case TipoProdutoAgricola.peixeDeAguaDoce:
        icon = Icons.set_meal;
        cor = Colors.cyan;
        break;
      case TipoProdutoAgricola.azeite:
        icon = Icons.water_drop;
        cor = Colors.yellow;
        break;
      case TipoProdutoAgricola.vinho:
        icon = Icons.wine_bar;
        cor = Colors.purple;
        break;
      case TipoProdutoAgricola.mel:
        icon = Icons.hive;
        cor = Colors.orangeAccent;
        break;
      case TipoProdutoAgricola.ervaAromatica:
        icon = Icons.local_florist;
        cor = Colors.indigo;
        break;
      case TipoProdutoAgricola.cogumelo:
        icon = Icons.forest;
        cor = Colors.deepOrange;
        break;
      case TipoProdutoAgricola.frutoSeco:
        icon = Icons.scatter_plot;
        cor = Colors.deepPurple;
        break;
      case TipoProdutoAgricola.transformado:
        icon = Icons.factory;
        cor = Colors.blueGrey;
        break;
      case TipoProdutoAgricola.plantaOrnamental:
        icon = Icons.local_florist;
        cor = Colors.pink;
        break;
      case TipoProdutoAgricola.outro:
        icon = Icons.category;
        cor = Colors.grey;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfertasPorCategoriaPage(categoria: categoria),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cor, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  nome,
                  style: TextStyle(
                    color: cor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nova página para mostrar as ofertas de um vendedor específico
class OfertasVendedorPage extends StatelessWidget {
  final Utilizador vendedor;

  const OfertasVendedorPage({super.key, required this.vendedor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ofertas de ${vendedor.nome}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header do vendedor
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(
                bottom: BorderSide(color: Colors.green[200]!),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  vendedor.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vendedor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Lista de ofertas
          Expanded(
            child: StreamBuilder<List<OfertaProduto>>(
              stream: OfertaProdutoService().obterOfertasDoVendedor(vendedor.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar ofertas',
                          style: TextStyle(fontSize: 18, color: Colors.red[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Este vendedor ainda não tem ofertas disponíveis',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                List<OfertaProduto> ofertas = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ofertas.length,
                  itemBuilder: (context, index) {
                    OfertaProduto oferta = ofertas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título e preço
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    oferta.tituloAnuncio,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '€${oferta.precoSugerido.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Tipo de produto
                            if (oferta.tipoProdutoAnuncio != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  oferta.tipoProdutoAnuncio!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Descrição
                            Text(
                              oferta.descricaoAnuncio,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Quantidade disponível
                            Row(
                              children: [
                                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Quantidade: ${oferta.quantidadeDisponivelNestaOferta}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
          ),
        ],
      ),
    );
  }
}

// Nova página para mostrar ofertas por categoria - CORRIGIDA
class OfertasPorCategoriaPage extends StatefulWidget {
  final TipoProdutoAgricola categoria;

  const OfertasPorCategoriaPage({super.key, required this.categoria});

  @override
  State<OfertasPorCategoriaPage> createState() => _OfertasPorCategoriaPageState();
}

class _OfertasPorCategoriaPageState extends State<OfertasPorCategoriaPage> {
  // Cache para vendedores para evitar múltiplas consultas
  final Map<String, Utilizador?> _vendedoresCache = {};

  @override
  Widget build(BuildContext context) {
    String nomeCategoria = tipoProdutoAgricolaParaString(widget.categoria);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ofertas de $nomeCategoria'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<OfertaProduto>>(
        stream: OfertaProdutoService().obterOfertasPorCategoriaAlternativa(widget.categoria),
        builder: (context, snapshot) {
          // Debug: Adicione estes prints temporariamente
          print('Snapshot state: ${snapshot.connectionState}');
          print('Has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            print('Stack trace: ${snapshot.stackTrace}');
          }
          print('Has data: ${snapshot.hasData}');
          if (snapshot.hasData) {
            print('Data length: ${snapshot.data?.length}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar ofertas',
                    style: TextStyle(fontSize: 18, color: Colors.red[600]),
                  ),
                  const SizedBox(height: 8),
                  // Mostra mais detalhes do erro para debug
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${snapshot.error}',
                      style: TextStyle(fontSize: 12, color: Colors.red[400]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Recarrega a página
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma oferta encontrada para $nomeCategoria',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verifique se existem produtos cadastrados nesta categoria',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          List<OfertaProduto> ofertas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ofertas.length,
            itemBuilder: (context, index) {
              OfertaProduto oferta = ofertas[index];
              
              return FutureBuilder<String>(
                future: _obterNomeVendedor(oferta.idVendedor),
                builder: (context, vendedorSnapshot) {
                  String nomeVendedor = 'Carregando...';
                  if (vendedorSnapshot.hasData) {
                    nomeVendedor = vendedorSnapshot.data!;
                  } else if (vendedorSnapshot.hasError) {
                    nomeVendedor = 'Vendedor desconhecido';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Adicione navegação para detalhes da oferta se necessário
                        print('Oferta selecionada: ${oferta.tituloAnuncio}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título e preço
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    oferta.tituloAnuncio,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '€${oferta.precoSugerido.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Nome do vendedor
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Vendedor: $nomeVendedor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Descrição
                            Text(
                              oferta.descricaoAnuncio,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Quantidade disponível e data
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Quantidade: ${oferta.quantidadeDisponivelNestaOferta}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatarData(oferta.dataCriacaoAnuncio),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Método otimizado para obter nome do vendedor com cache
  Future<String> _obterNomeVendedor(String idVendedor) async {
    // Verifica se já temos o vendedor em cache
    if (_vendedoresCache.containsKey(idVendedor)) {
      Utilizador? vendedor = _vendedoresCache[idVendedor];
      return vendedor?.nome ?? 'Vendedor desconhecido';
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('utilizadores')
          .doc(idVendedor)
          .get();
      
      Utilizador? vendedor;
      if (doc.exists) {
        vendedor = Utilizador.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      // Armazena no cache (mesmo que seja null)
      _vendedoresCache[idVendedor] = vendedor;
      
      return vendedor?.nome ?? 'Vendedor desconhecido';
    } catch (e) {
      print('Erro ao obter vendedor $idVendedor: $e');
      _vendedoresCache[idVendedor] = null;
      return 'Erro ao carregar vendedor';
    }
  }

  // Método para formatar a data de criação
  String _formatarData(DateTime data) {
    Duration diferenca = DateTime.now().difference(data);
    
    if (diferenca.inDays > 0) {
      return '${diferenca.inDays}d atrás';
    } else if (diferenca.inHours > 0) {
      return '${diferenca.inHours}h atrás';
    } else if (diferenca.inMinutes > 0) {
      return '${diferenca.inMinutes}min atrás';
    } else {
      return 'Agora';
    }
  }
}