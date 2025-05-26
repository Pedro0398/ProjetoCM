// Em: lib/services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Ajuste os caminhos de importação
import 'package:flutter_application_1/data_class/item_cart.dart';
import 'package:flutter_application_1/data_class/offer.dart'; // Para OfertaProduto

class CarrinhoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _carrinhoCollection(String userId) {
    return _firestore
        .collection('utilizadores')
        .doc(userId)
        .collection('carrinho');
  }

  CollectionReference get _ofertasCollection =>
      _firestore.collection('ofertasProduto');

  Future<void> adicionarItemAoCarrinho(
    String userId,
    OfertaProduto ofertaDaLista,
    int quantidadeAAdicionar,
  ) async {
    if (quantidadeAAdicionar <= 0) {
      throw ArgumentError('A quantidade a adicionar deve ser positiva.');
    }

    final DocumentReference ofertaRef = _ofertasCollection.doc(
      ofertaDaLista.id,
    );
    // Usar o ID da oferta como ID do item no carrinho para fácil consulta e evitar duplicados do mesmo produto
    final DocumentReference itemCarrinhoRef = _carrinhoCollection(
      userId,
    ).doc(ofertaDaLista.id);

    return _firestore
        .runTransaction((transaction) async {
          // --- INÍCIO DAS LEITURAS ---
          // 1. Ler o estado atual da oferta
          DocumentSnapshot ofertaSnapshot = await transaction.get(ofertaRef);

          // 2. Ler o estado atual do item no carrinho (se existir)
          DocumentSnapshot itemCarrinhoSnapshot = await transaction.get(
            itemCarrinhoRef,
          );
          // --- FIM DAS LEITURAS ---

          if (!ofertaSnapshot.exists) {
            throw Exception("Oferta não encontrada ou já não existe mais.");
          }
          OfertaProduto ofertaAtualFirestore = OfertaProduto.fromFirestore(
            ofertaSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          );

          // Verificar se há stock suficiente na oferta (considerando o que já pode estar "reservado")
          if (ofertaAtualFirestore.estadoAnuncio != 'Disponível') {
            throw Exception(
              "Esta oferta já não está disponível (${ofertaAtualFirestore.estadoAnuncio}).",
            );
          }
          if (ofertaAtualFirestore.quantidadeDisponivelNestaOferta <
              quantidadeAAdicionar) {
            throw Exception(
              "Stock insuficiente para a quantidade desejada (${ofertaAtualFirestore.quantidadeDisponivelNestaOferta} disponíveis).",
            );
          }

          // Calcular novo stock para a oferta
          int novaQuantidadeDisponivelOferta =
              ofertaAtualFirestore.quantidadeDisponivelNestaOferta -
              quantidadeAAdicionar;
          String novoEstadoAnuncioOferta = ofertaAtualFirestore.estadoAnuncio;
          if (novaQuantidadeDisponivelOferta <= 0) {
            // Se stock chega a 0, marca como esgotado.
            // Se a intenção é reservar, pode usar um estado "Reservado".
            novoEstadoAnuncioOferta = 'Esgotado';
          }

          // --- INÍCIO DAS ESCRITAS ---
          // 3. Atualizar a oferta no Firestore
          transaction.update(ofertaRef, {
            'quantidadeDisponivelNestaOferta': novaQuantidadeDisponivelOferta,
            'estadoAnuncio': novoEstadoAnuncioOferta,
          });

          // 4. Adicionar/Atualizar o item no carrinho do utilizador
          if (itemCarrinhoSnapshot.exists) {
            // Item já existe, atualiza a quantidade
            int quantidadeExistenteNoCarrinho =
                (itemCarrinhoSnapshot.data()
                    as Map<String, dynamic>)['quantidade'] ??
                0;
            transaction.update(itemCarrinhoRef, {
              'quantidade':
                  quantidadeExistenteNoCarrinho + quantidadeAAdicionar,
              'precoUnitario':
                  ofertaDaLista
                      .precoSugerido, // Atualiza o preço caso tenha mudado na oferta original
              'adicionadoEm':
                  FieldValue.serverTimestamp(), // Atualiza o timestamp
            });
          } else {
            // Item não existe, cria um novo
            ItemCarrinho novoItem = ItemCarrinho(
              id:
                  ofertaDaLista
                      .id, // Usa o ID da oferta como ID do item no carrinho
              ofertaId: ofertaDaLista.id,
              idProdutoGenerico: ofertaDaLista.idProdutoGenerico,
              tituloAnuncio: ofertaDaLista.tituloAnuncio,
              tipoProdutoAnuncio: ofertaDaLista.tipoProdutoAnuncio,
              precoUnitario:
                  ofertaDaLista.precoSugerido, // Preço no momento da adição
              quantidade: quantidadeAAdicionar,
              idVendedor: ofertaDaLista.idVendedor,
            );
            transaction.set(itemCarrinhoRef, novoItem.toFirestore());
          }
          // --- FIM DAS ESCRITAS ---
        })
        .catchError((error) {
          throw error;
        });
  }

  // ... (resto dos métodos: removerItemDoCarrinho, atualizarQuantidadeItemCarrinho, obterItensCarrinho, limparCarrinho)
  // Certifique-se que a lógica de transação em removerItemDoCarrinho e atualizarQuantidadeItemCarrinho
  // também segue a regra de "leituras primeiro, depois escritas".

  // Exemplo para removerItemDoCarrinho (já estava correto, mas para confirmar):
  Future<void> removerItemDoCarrinho(
    String userId,
    String itemCarrinhoId,
    int quantidadeRemovidaOriginalmente,
  ) async {
    final DocumentReference ofertaRef = _ofertasCollection.doc(itemCarrinhoId);
    final DocumentReference itemCarrinhoRef = _carrinhoCollection(
      userId,
    ).doc(itemCarrinhoId);

    return _firestore
        .runTransaction((transaction) async {
          // LEITURAS PRIMEIRO
          DocumentSnapshot ofertaSnapshot = await transaction.get(ofertaRef);
          // DocumentSnapshot itemCarrinhoSnapshot = await transaction.get(itemCarrinhoRef); // Não estritamente necessário se só vamos apagar

          // Se a oferta ainda existe, devolve o stock
          if (ofertaSnapshot.exists) {
            OfertaProduto ofertaAtual = OfertaProduto.fromFirestore(
              ofertaSnapshot as DocumentSnapshot<Map<String, dynamic>>,
            );
            int novaQuantidadeDisponivelOferta =
                ofertaAtual.quantidadeDisponivelNestaOferta +
                quantidadeRemovidaOriginalmente;
            String novoEstadoAnuncioOferta = 'Disponível';

            // ESCRITA NA OFERTA
            transaction.update(ofertaRef, {
              'quantidadeDisponivelNestaOferta': novaQuantidadeDisponivelOferta,
              'estadoAnuncio': novoEstadoAnuncioOferta,
            });
          } else {}

          // ESCRITA NO CARRINHO (APAGAR)
          transaction.delete(itemCarrinhoRef);
        })
        .catchError((error) {
          throw error;
        });
  }

  // Método atualizarQuantidadeItemCarrinho precisa de revisão similar
  Future<void> atualizarQuantidadeItemCarrinho(
    String userId,
    String itemCarrinhoId,
    int novaQuantidadeNoCarrinho,
    int diferencaQuantidade,
  ) async {
    // diferencaQuantidade = novaQuantidadeNoCarrinho - quantidadeAntigaNoCarrinho
    // Se positivo, estamos a adicionar mais ao carrinho (deduzir do stock da oferta)
    // Se negativo, estamos a remover do carrinho (devolver ao stock da oferta)

    if (novaQuantidadeNoCarrinho <= 0) {
      // Se a nova quantidade for 0 ou menos, remove o item completamente.
      // A quantidade a ser devolvida ao stock é a quantidade que estava ANTES no carrinho.
      // Se diferencaQuantidade é -quantidadeAntiga, então -diferencaQuantidade é quantidadeAntiga.
      return removerItemDoCarrinho(
        userId,
        itemCarrinhoId,
        -diferencaQuantidade,
      );
    }

    final DocumentReference ofertaRef = _ofertasCollection.doc(itemCarrinhoId);
    final DocumentReference itemCarrinhoRef = _carrinhoCollection(
      userId,
    ).doc(itemCarrinhoId);

    return _firestore
        .runTransaction((transaction) async {
          // LEITURA
          DocumentSnapshot ofertaSnapshot = await transaction.get(ofertaRef);
          // Não precisamos de ler itemCarrinhoSnapshot aqui, pois vamos apenas atualizá-lo.

          if (!ofertaSnapshot.exists) {
            throw Exception("Oferta original não encontrada.");
          }
          OfertaProduto ofertaAtual = OfertaProduto.fromFirestore(
            ofertaSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          );

          if (diferencaQuantidade > 0) {
            // Adicionando mais itens ao carrinho
            if (ofertaAtual.quantidadeDisponivelNestaOferta <
                diferencaQuantidade) {
              throw Exception(
                "Stock insuficiente na oferta para adicionar mais $diferencaQuantidade unidades.",
              );
            }
          }
          // Se diferencaQuantidade < 0, estamos a remover itens do carrinho, então stock aumenta na oferta.

          int novaQuantidadeOferta =
              ofertaAtual.quantidadeDisponivelNestaOferta -
              diferencaQuantidade; // Subtrai a diferença
          String novoEstadoOferta =
              (novaQuantidadeOferta <= 0 &&
                      ofertaAtual.estadoAnuncio != 'Vendido')
                  ? 'Esgotado'
                  : 'Disponível';
          if (ofertaAtual.estadoAnuncio == 'Vendido') {
            novoEstadoOferta = 'Vendido'; // Não muda se já vendido
          }

          // ESCRITAS
          transaction.update(ofertaRef, {
            'quantidadeDisponivelNestaOferta': novaQuantidadeOferta,
            'estadoAnuncio': novoEstadoOferta,
          });
          transaction.update(itemCarrinhoRef, {
            'quantidade': novaQuantidadeNoCarrinho,
          });
        })
        .catchError((error) {
          throw error;
        });
  }

  Stream<List<ItemCarrinho>> obterItensCarrinho(String userId) {
    return _carrinhoCollection(
      userId,
    ).orderBy('adicionadoEm', descending: true).snapshots().map((snapshot) {
      // Ordena por mais recente
      return snapshot.docs.map((doc) {
        return ItemCarrinho.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        );
      }).toList();
    });
  }

  Future<void> limparCarrinho(String userId) async {
    // ... (código existente)
    final WriteBatch batch = _firestore.batch();
    try {
      QuerySnapshot snapshot = await _carrinhoCollection(userId).get();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
