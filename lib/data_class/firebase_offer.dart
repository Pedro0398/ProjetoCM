// ficheiro: services/oferta_produto_service.dart (ou o caminho que usa para os seus serviços)

import 'package:cloud_firestore/cloud_firestore.dart';
// Ajuste os caminhos de importação para as suas classes de dados
import 'package:flutter_application_1/data_class/offer.dart'; // Sua classe OfertaProduto
import 'package:flutter_application_1/data_class/product.dart'; // Sua classe Produto (contém TipoProdutoAgricola e tipoProdutoAgricolaParaString)

class OfertaProdutoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName =
      'ofertasProduto'; // Nome da sua coleção no Firestore

  // Adicionar uma nova oferta
  Future<DocumentReference> adicionarOferta(OfertaProduto oferta) async {
    try {
      // Garante que o estado é 'Disponível' se não foi explicitamente definido
      // (O construtor da OfertaProduto já faz isto se tiver valor por defeito)
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

  // Obter um stream das ofertas DISPONÍVEIS de um vendedor específico
  Stream<List<OfertaProduto>> obterOfertasDoVendedor(String idVendedor) {
    return _firestore
        .collection(_collectionName)
        .where('idVendedor', isEqualTo: idVendedor)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .orderBy('dataCriacaoAnuncio', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OfertaProduto.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();
        });
  }

  // NOVO MÉTODO: Obter um stream de TODAS as ofertas disponíveis (para a ExplorarOfertasPage)
  Stream<List<OfertaProduto>> getTodasOfertasDisponiveisStream({
    String? termoPesquisa,
    // Os filtros mais complexos (tipo, preço) serão aplicados no lado do cliente
    // na ExplorarOfertasPage para simplificar as queries ao Firestore e a gestão de índices.
  }) {
    Query query = _firestore
        .collection(_collectionName)
        .where('estadoAnuncio', isEqualTo: 'Disponível')
        .orderBy(
          'dataCriacaoAnuncio',
          descending: true,
        ); // Mais recentes primeiro

    return query.snapshots().map((snapshot) {
      List<OfertaProduto> ofertas =
          snapshot.docs.map((doc) {
            return OfertaProduto.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            );
          }).toList();

      // Filtragem por texto no lado do cliente (para simplificar)
      // Isto é feito depois de receber os dados do Firebase.
      // Para grandes volumes de dados, uma solução de pesquisa no servidor seria melhor.
      if (termoPesquisa != null && termoPesquisa.isNotEmpty) {
        String lowerTermo = termoPesquisa.toLowerCase().trim();
        if (lowerTermo.isNotEmpty) {
          // Garante que não filtra com string vazia após trim
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
                        false) ||
                    // Poderia adicionar mais campos à pesquisa aqui, se relevante
                    // Ex: oferta.idProdutoGenerico.toLowerCase().contains(lowerTermo)
                    false;
              }).toList();
        }
      }
      return ofertas;
    });
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

  // Método para marcar uma oferta como vendida (chamado do lado do comprador/pagamento)
  Future<void> marcarOfertaComoVendida(
    String ofertaId,
    String compradorId,
    double precoFinal,
    int quantidadeComprada,
  ) async {
    try {
      // Numa transação, idealmente verificaria se a quantidade ainda está disponível
      // e atualizaria o stock do produto base. Aqui, apenas atualizamos a oferta.
      await _firestore.collection(_collectionName).doc(ofertaId).update({
        'estadoAnuncio': 'Vendido',
        'idComprador': compradorId,
        'dataTransacaoFinalizada': Timestamp.now(),
        'precoFinalTransacao': precoFinal,
        'quantidadeTransacionada': quantidadeComprada,
        // Poderia reduzir 'quantidadeDisponivelNestaOferta' se fosse venda parcial,
        // mas a sua classe OfertaProduto não suporta isso diretamente na lógica 'marcarComoVendido'.
        // Se a oferta é para 1 unidade, quantidadeDisponivelNestaOferta poderia ir para 0.
      });
    } catch (e) {
      rethrow;
    }
  }

  // Criar ofertas de teste manuais (atualizado para incluir tipoProdutoAnuncio)
  Future<void> criarOfertasDeTesteManual(
    String idVendedorTeste,
    String idProdutoGenericoTeste1,
    String idProdutoGenericoTeste2,
  ) async {
    // Assumindo que TipoProdutoAgricola e tipoProdutoAgricolaParaString estão acessíveis
    // via import de 'product.dart' ou similar.
    OfertaProduto oferta1 = OfertaProduto(
      id: '',
      idProdutoGenerico: idProdutoGenericoTeste1, // ID de um Produto existente
      tituloAnuncio: 'Laranjas do Algarve Fresquinhas!',
      descricaoAnuncio:
          'Caixa de 5kg de laranjas sumarentas, acabadas de colher.',
      idVendedor: idVendedorTeste,
      precoSugerido: 12.50,
      quantidadeDisponivelNestaOferta: 10, // Quantidade de caixas disponíveis
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(hours: 5)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        TipoProdutoAgricola.fruta,
      ),
    );

    OfertaProduto oferta2 = OfertaProduto(
      id: '',
      idProdutoGenerico:
          idProdutoGenericoTeste2, // ID de outro Produto existente
      tituloAnuncio: 'Queijo de Cabra Curado Artesanal',
      descricaoAnuncio: 'Queijo intenso e saboroso, produção limitada.',
      idVendedor: idVendedorTeste,
      precoSugerido: 8.75,
      quantidadeDisponivelNestaOferta: 5, // Quantidade de queijos disponíveis
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(days: 1)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        TipoProdutoAgricola.laticinio,
      ),
    );
    OfertaProduto oferta3 = OfertaProduto(
      id: '',
      idProdutoGenerico: "ID_ALFACE_TESTE", // ID de um Produto do tipo vegetal
      tituloAnuncio: 'Alfaces Frescas da Horta',
      descricaoAnuncio:
          'Alfaces biológicas, crocantes e deliciosas. Molho de 3 unidades.',
      idVendedor: idVendedorTeste,
      precoSugerido: 1.80,
      quantidadeDisponivelNestaOferta: 20,
      dataCriacaoAnuncio: DateTime.now().subtract(const Duration(hours: 2)),
      estadoAnuncio: 'Disponível',
      tipoProdutoAnuncio: tipoProdutoAgricolaParaString(
        TipoProdutoAgricola.vegetal,
      ),
    );

    try {
      await adicionarOferta(oferta1);
      await adicionarOferta(oferta2);
      await adicionarOferta(oferta3);
      // ignore: empty_catches
    } catch (e) {}
  }
}
