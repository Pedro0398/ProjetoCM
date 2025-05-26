// ficheiro: services/produto_service.dart (ou similar)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// Ajuste o caminho de importação para a sua classe Produto
import 'package:flutter_application_1/data_class/product.dart';

class ProdutoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'produtos';

  Future<DocumentReference> adicionarProdutoComStock(Produto produto) async {
    // O objeto 'produto' já deve vir com 'tipoProduto' definido pela UI
    try {
      return await _firestore
          .collection(_collectionName)
          .add(produto.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao adicionar produto: $e');
      }
      rethrow;
    }
  }

  Stream<List<Produto>> obterProdutosDoVendedor(String idVendedor) {
    return _firestore
        .collection(_collectionName)
        .where('idVendedor', isEqualTo: idVendedor)
        .orderBy('nome')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Produto.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Novo método fetch (já adicionado antes, mantido)
  Future<List<Produto>> fetchProdutosDoVendedor(String idVendedor) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collectionName)
              .where('idVendedor', isEqualTo: idVendedor)
              .orderBy('nome')
              .get();
      return snapshot.docs
          .map(
            (doc) => Produto.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar produtos do vendedor (fetch): $e');
      }
      rethrow;
    }
  }

  Future<void> atualizarProdutoCompleto(Produto produto) async {
    // O objeto 'produto' já deve vir com 'tipoProduto' atualizado pela UI
    try {
      await _firestore
          .collection(_collectionName)
          .doc(produto.id)
          .update(produto.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removerProdutoDoStock(String produtoId) async {
    try {
      await _firestore.collection(_collectionName).doc(produtoId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Método de teste manual atualizado para incluir tipoProduto
  Future<void> criarProdutoDeTesteManual(String idVendedorParaTeste) async {
    Produto produtoTeste1 = Produto(
      id: '',
      nome: 'Maçãs Fuji (Stock)',
      descricao: 'Frescas e crocantes, produção local.',
      preco: 2.99, // Exigido pela classe
      idVendedor: idVendedorParaTeste,
      quantidadeEmStock: 100,
      tipoProduto: TipoProdutoAgricola.fruta, // Tipo adicionado
    );
    Produto produtoTeste2 = Produto(
      id: '',
      nome: 'Queijo Curado Ovelha (Stock)',
      descricao: 'Artesanal, cura de 6 meses.',
      preco: 15.50,
      idVendedor: idVendedorParaTeste,
      quantidadeEmStock: 20,
      tipoProduto: TipoProdutoAgricola.laticinio, // Tipo adicionado
    );

    try {
      await adicionarProdutoComStock(produtoTeste1);
      await adicionarProdutoComStock(produtoTeste2);
      // ignore: empty_catches
    } catch (e) {}
  }
}
