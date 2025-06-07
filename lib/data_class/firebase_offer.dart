// ficheiro: services/oferta_produto_service.dart - VERSÃO CORRIGIDA

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/data_class/offer.dart';
import 'package:flutter_application_1/data_class/product.dart';

class OfertaProdutoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'ofertasProduto';

  // Método CORRIGIDO para obter ofertas por categoria
  Stream<List<OfertaProduto>> obterOfertasPorCategoria(
    TipoProdutoAgricola categoria,
  ) {
    String categoriaString = tipoProdutoAgricolaParaString(categoria);
    
    // OPÇÃO 1: Query simplificada sem múltiplos where + orderBy
    return _firestore
        .collection(_collectionName)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .where('tipoProdutoAnuncio', isEqualTo: categoriaString)
        // Removemos o orderBy para evitar a necessidade de índice composto
        .snapshots()
        .map((snapshot) {
          List<OfertaProduto> ofertas = snapshot.docs.map((doc) {
            return OfertaProduto.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
          
          // Ordenação no lado do cliente
          ofertas.sort((a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio));
          
          return ofertas;
        });
  }

  // ALTERNATIVA: Método usando a abordagem original com produtos
  Stream<List<OfertaProduto>> obterOfertasPorCategoriaAlternativa(
    TipoProdutoAgricola categoria,
  ) {
    String categoriaString = tipoProdutoAgricolaParaString(categoria);
    
    return _firestore
        .collection('produtos')
        .where('tipoProduto', isEqualTo: categoriaString)
        .snapshots()
        .asyncMap((produtosSnapshot) async {
      
      List<String> idsProdutos = produtosSnapshot.docs
          .map((doc) => doc.id)
          .toList();
      
      if (idsProdutos.isEmpty) {
        return <OfertaProduto>[];
      }
      
      // Firestore tem limite de 10 items no whereIn
      List<String> idsLimitados = idsProdutos.take(10).toList();
      
      // Query simplificada sem orderBy para evitar necessidade de índice
      QuerySnapshot ofertasSnapshot = await _firestore
          .collection(_collectionName)
          .where('estadoAnuncio', isEqualTo: 'Disponível')
          .where('idProdutoGenerico', whereIn: idsLimitados)
          .get();
      
      List<OfertaProduto> ofertas = ofertasSnapshot.docs.map((doc) {
        return OfertaProduto.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }).toList();
      
      // Ordenação no lado do cliente
      ofertas.sort((a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio));
      
      return ofertas;
    });
  }

  // Método otimizado para obter todas as ofertas disponíveis
  Stream<List<OfertaProduto>> getTodasOfertasDisponiveisStream({
    String? termoPesquisa,
  }) {
    // Query simples apenas com estado
    Query query = _firestore
        .collection(_collectionName)
        .where('estadoAnuncio', isEqualTo: 'Disponível');

    return query.snapshots().map((snapshot) {
      List<OfertaProduto> ofertas = snapshot.docs.map((doc) {
        return OfertaProduto.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }).toList();

      // Ordenação por data no lado do cliente
      ofertas.sort((a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio));

      // Filtragem por texto no lado do cliente
      if (termoPesquisa != null && termoPesquisa.isNotEmpty) {
        String lowerTermo = termoPesquisa.toLowerCase().trim();
        if (lowerTermo.isNotEmpty) {
          ofertas = ofertas.where((oferta) {
            return oferta.tituloAnuncio.toLowerCase().contains(lowerTermo) ||
                oferta.descricaoAnuncio.toLowerCase().contains(lowerTermo) ||
                (oferta.tipoProdutoAnuncio?.toLowerCase().contains(lowerTermo) ?? false);
          }).toList();
        }
      }
      
      return ofertas;
    });
  }

  // Obter ofertas do vendedor (método simplificado)
  Stream<List<OfertaProduto>> obterOfertasDoVendedor(String idVendedor) {
    return _firestore
        .collection(_collectionName)
        .where('idVendedor', isEqualTo: idVendedor)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .snapshots()
        .map((snapshot) {
          List<OfertaProduto> ofertas = snapshot.docs.map((doc) {
            return OfertaProduto.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
          
          // Ordenação no cliente
          ofertas.sort((a, b) => b.dataCriacaoAnuncio.compareTo(a.dataCriacaoAnuncio));
          
          return ofertas;
        });
  }

  // Adicionar uma nova oferta
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

  // Obter contagem de ofertas por categoria (simplificado)
  Future<Map<TipoProdutoAgricola, int>> obterContagemOfertasPorCategoria() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('estadoAnuncio', isEqualTo: 'Disponível')
          .get();

      Map<TipoProdutoAgricola, int> contagem = {};
      
      // Inicializar todas as categorias com 0
      for (TipoProdutoAgricola tipo in TipoProdutoAgricola.values) {
        contagem[tipo] = 0;
      }

      // Contar ofertas por categoria
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? tipoProdutoString = data['tipoProdutoAnuncio'] as String?;
        
        if (tipoProdutoString != null) {
          try {
            TipoProdutoAgricola tipo = stringParaTipoProdutoAgricola(tipoProdutoString);
            contagem[tipo] = (contagem[tipo] ?? 0) + 1;
          } catch (e) {
            // Ignora tipos inválidos
            print('Tipo de produto inválido encontrado: $tipoProdutoString');
          }
        }
      }

      return contagem;
    } catch (e) {
      rethrow;
    }
  }

  // Obter categorias mais populares
  Future<List<TipoProdutoAgricola>> obterCategoriasMaisPopulares({int limite = 5}) async {
    try {
      Map<TipoProdutoAgricola, int> contagem = await obterContagemOfertasPorCategoria();
      
      List<MapEntry<TipoProdutoAgricola, int>> listaOrdenada = 
          contagem.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return listaOrdenada
          .where((entry) => entry.value > 0)
          .take(limite)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar uma oferta existente
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

  // Apagar uma oferta
  Future<void> apagarOferta(String ofertaId) async {
    try {
      await _firestore.collection(_collectionName).doc(ofertaId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Marcar oferta como vendida
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

  // Criar ofertas de teste
  Future<void> criarOfertasDeTesteManual(
    String idVendedorTeste,
    String idProdutoGenericoTeste1,
    String idProdutoGenericoTeste2,
  ) async {
    OfertaProduto oferta1 = OfertaProduto(
      id: '',
      idProdutoGenerico: idProdutoGenericoTeste1,
      tituloAnuncio: 'Laranjas do Algarve Fresquinhas!',
      descricaoAnuncio: 'Caixa de 5kg de laranjas sumarentas, acabadas de colher.',
      idVendedor: idVendedorTeste,
      precoSugerido: 12.50,
      quantidadeDisponivelNestaOferta: 10,
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(hours: 5)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(TipoProdutoAgricola.fruta),
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
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(TipoProdutoAgricola.laticinio),
    );

    OfertaProduto oferta3 = OfertaProduto(
      id: '',
      idProdutoGenerico: "ID_ALFACE_TESTE",
      tituloAnuncio: 'Alfaces Frescas da Horta',
      descricaoAnuncio: 'Alfaces biológicas, crocantes e deliciosas. Molho de 3 unidades.',
      idVendedor: idVendedorTeste,
      precoSugerido: 1.80,
      quantidadeDisponivelNestaOferta: 20,
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(hours: 2)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(TipoProdutoAgricola.vegetal),
    );

    try {
      await adicionarOferta(oferta1);
      await adicionarOferta(oferta2);
      await adicionarOferta(oferta3);
    } catch (e) {
      print('Erro ao criar ofertas de teste: $e');
    }
  }
}