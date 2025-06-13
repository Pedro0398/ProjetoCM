// ficheiro: lib/data_class/firebase_offer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/product.dart';

class OfertaProdutoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'ofertasProduto';

  // =======================================================================
  // NOVO MÉTODO - Use este para criar novas ofertas a partir do stock
  // =======================================================================
  /// Cria e adiciona uma nova oferta com base num Produto do stock.
  /// Garante que o imageUrl e outros dados são copiados corretamente.
  Future<void> criarOfertaAPartirDeProduto({
    required Produto produtoBase,
    required String titulo,
    required String descricao,
    required double preco,
    required int quantidade,
  }) async {
    if (produtoBase.id.isEmpty || produtoBase.idVendedor.isEmpty) {
      throw Exception("O produto base ou o vendedor não têm ID válido.");
    }

    // Cria a nova oferta, copiando os dados relevantes do produto base
    final novaOferta = OfertaProduto(
      id: '', // O Firestore irá gerar o ID
      idProdutoGenerico: produtoBase.id,
      tituloAnuncio: titulo,
      descricaoAnuncio: descricao,
      idVendedor: produtoBase.idVendedor,
      precoSugerido: preco,
      quantidadeDisponivelNestaOferta: quantidade,
      dataCriacaoAnuncio: DateTime.now(),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        produtoBase.tipoProduto,
      ),
      imageUrl: produtoBase.imageUrl, // AQUI ACONTECE A MAGIA!
    );

    await adicionarOferta(novaOferta);
  }

  // Método antigo de adicionar, mantido para compatibilidade e testes
  Future<DocumentReference> adicionarOferta(OfertaProduto oferta) async {
    try {
      if (oferta.estadoAnuncio.isEmpty) {
        oferta.estadoAnuncio = 'Disponível';
      }
      return await _firestore
          .collection(_collectionName)
          .add(oferta.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // --- O RESTO DOS SEUS MÉTODOS PERMANECE IGUAL ---

  Stream<List<OfertaProduto>> obterOfertasPorCategoria(
    TipoProdutoAgricola categoria,
  ) {
    String categoriaString = tipoProdutoAgricolaParaString(categoria);
    return _firestore
        .collection(_collectionName)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .where('tipoProdutoAnuncio', isEqualTo: categoriaString)
        .snapshots()
        .map((snapshot) {
          List<OfertaProduto> ofertas =
              snapshot.docs.map((doc) {
                return OfertaProduto.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                );
              }).toList();
          ofertas.sort(
            (a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio),
          );
          return ofertas;
        });
  }

  Stream<List<OfertaProduto>> obterOfertasPorCategoriaAlternativa(
    TipoProdutoAgricola categoria,
  ) {
    String categoriaString = tipoProdutoAgricolaParaString(categoria);
    return _firestore
        .collection('produtos')
        .where('tipoProduto', isEqualTo: categoriaString)
        .snapshots()
        .asyncMap((produtosSnapshot) async {
          List<String> idsProdutos =
              produtosSnapshot.docs.map((doc) => doc.id).toList();
          if (idsProdutos.isEmpty) {
            return <OfertaProduto>[];
          }
          List<String> idsLimitados = idsProdutos.take(10).toList();
          QuerySnapshot ofertasSnapshot =
              await _firestore
                  .collection(_collectionName)
                  .where('estadoAnuncio', isEqualTo: 'Disponível')
                  .where('idProdutoGenerico', whereIn: idsLimitados)
                  .get();
          List<OfertaProduto> ofertas =
              ofertasSnapshot.docs.map((doc) {
                return OfertaProduto.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                );
              }).toList();
          ofertas.sort(
            (a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio),
          );
          return ofertas;
        });
  }

  Stream<List<OfertaProduto>> getTodasOfertasDisponiveisStream({
    String? termoPesquisa,
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('estadoAnuncio', isEqualTo: 'Disponível');

    return query.snapshots().map((snapshot) {
      List<OfertaProduto> ofertas =
          snapshot.docs.map((doc) {
            return OfertaProduto.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
      ofertas.sort(
        (a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio),
      );
      if (termoPesquisa != null && termoPesquisa.isNotEmpty) {
        String lowerTermo = termoPesquisa.toLowerCase().trim();
        if (lowerTermo.isNotEmpty) {
          ofertas =
              ofertas.where((oferta) {
                return oferta.tituloAnuncio.toLowerCase().contains(
                      lowerTermo,
                    ) ||
                    oferta.descricaoAnuncio.toLowerCase().contains(
                      lowerTermo,
                    ) ||
                    (oferta.tipoProdutoAnuncio?.toLowerCase().contains(
                          lowerTermo,
                        ) ??
                        false);
              }).toList();
        }
      }
      return ofertas;
    });
  }

  Stream<List<OfertaProduto>> obterOfertasDoVendedor(String idVendedor) {
    return _firestore
        .collection(_collectionName)
        .where('idVendedor', isEqualTo: idVendedor)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .snapshots()
        .map((snapshot) {
          List<OfertaProduto> ofertas =
              snapshot.docs.map((doc) {
                return OfertaProduto.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                );
              }).toList();
          ofertas.sort(
            (a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio),
          );
          return ofertas;
        });
  }

  Future<Map<TipoProdutoAgricola, int>>
  obterContagemOfertasPorCategoria() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collectionName)
              .where('estadoAnuncio', isEqualTo: 'Disponível')
              .get();
      Map<TipoProdutoAgricola, int> contagem = {};
      for (TipoProdutoAgricola tipo in TipoProdutoAgricola.values) {
        contagem[tipo] = 0;
      }
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? tipoProdutoString = data['tipoProdutoAnuncio'] as String?;
        if (tipoProdutoString != null) {
          try {
            TipoProdutoAgricola tipo = stringParaTipoProdutoAgricola(
              tipoProdutoString,
            );
            contagem[tipo] = (contagem[tipo] ?? 0) + 1;
          } catch (e) {
            print('Tipo de produto inválido encontrado: $tipoProdutoString');
          }
        }
      }
      return contagem;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TipoProdutoAgricola>> obterCategoriasMaisPopulares({
    int limite = 5,
  }) async {
    try {
      Map<TipoProdutoAgricola, int> contagem =
          await obterContagemOfertasPorCategoria();
      List<MapEntry<TipoProdutoAgricola, int>> listaOrdenada =
          contagem.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return listaOrdenada
          .where((entry) => entry.value > 0)
          .take(limite)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atualizarOferta(OfertaProduto oferta) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(oferta.id)
          .update(oferta.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> apagarOferta(String ofertaId) async {
    try {
      await _firestore.collection(_collectionName).doc(ofertaId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> marcarOfertaComoVendida(
    String ofertaId,
    String compradorId,
    double precoFinal,
    int quantidadeComprada,
  ) async {
    try {
      await _firestore.collection(_collectionName).doc(ofertaId).update({
        'estadoAnuncio': 'Vendido',
        'idComprador': compradorId,
        'dataTransacaoFinalizada': Timestamp.now(),
        'precoFinalTransacao': precoFinal,
        'quantidadeTransacionada': quantidadeComprada,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> criarOfertasDeTesteManual(
    String idVendedorTeste,
    String idProdutoGenericoTeste1,
    String idProdutoGenericoTeste2,
  ) async {
    OfertaProduto oferta1 = OfertaProduto(
      id: '',
      idProdutoGenerico: idProdutoGenericoTeste1,
      tituloAnuncio: 'Laranjas do Algarve Fresquinhas!',
      descricaoAnuncio:
          'Caixa de 5kg de laranjas sumarentas, acabadas de colher.',
      idVendedor: idVendedorTeste,
      precoSugerido: 12.50,
      quantidadeDisponivelNestaOferta: 10,
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(hours: 5)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        TipoProdutoAgricola.fruta,
      ),
      imageUrl:
          'https://frutasol.pt/wp-content/uploads/2021/03/laranja-algarve.jpg', // Exemplo de URL
    );

    OfertaProduto oferta2 = OfertaProduto(
      id: '',
      idProdutoGenerico: idProdutoGenericoTeste2,
      tituloAnuncio: 'Queijo de Cabra Curado Artesanal',
      descricaoAnuncio: 'Queijo intenso e saboroso, produção limitada.',
      idVendedor: idVendedorTeste,
      precoSugerido: 8.75,
      quantidadeDisponivelNestaOferta: 5,
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(days: 1)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        TipoProdutoAgricola.laticinio,
      ),
    );

    // ... (pode adicionar mais ofertas de teste) ...
  }
}
