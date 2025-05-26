// Em: lib/data_class/cart_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemCarrinho {
  final String
  id; // ID do documento do item no carrinho (pode ser o mesmo que ofertaId se cada oferta é única no carrinho)
  final String ofertaId; // ID da OfertaProduto original
  final String idProdutoGenerico;
  final String tituloAnuncio;
  final String? tipoProdutoAnuncio; // Tipo do produto base (denormalizado)
  final double precoUnitario; // Preço no momento da adição ao carrinho
  int quantidade; // Quantidade deste item no carrinho
  final String idVendedor;
  // Poderia adicionar um campo para a imagem do produto aqui também (imageUrl)

  ItemCarrinho({
    required this.id,
    required this.ofertaId,
    required this.idProdutoGenerico,
    required this.tituloAnuncio,
    this.tipoProdutoAnuncio,
    required this.precoUnitario,
    required this.quantidade,
    required this.idVendedor,
  });

  // Construtor para criar a partir de um DocumentSnapshot do Firestore
  factory ItemCarrinho.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    Map<String, dynamic> data = doc.data()!;
    return ItemCarrinho(
      id: doc.id,
      ofertaId: data['ofertaId'] ?? '',
      idProdutoGenerico: data['idProdutoGenerico'] ?? '',
      tituloAnuncio: data['tituloAnuncio'] ?? 'Produto sem título',
      tipoProdutoAnuncio: data['tipoProdutoAnuncio'] as String?,
      precoUnitario: (data['precoUnitario'] ?? 0.0).toDouble(),
      quantidade: (data['quantidade'] ?? 0).toInt(),
      idVendedor: data['idVendedor'] ?? '',
    );
  }

  // Método para converter para um Map para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ofertaId': ofertaId,
      'idProdutoGenerico': idProdutoGenerico,
      'tituloAnuncio': tituloAnuncio,
      if (tipoProdutoAnuncio != null) 'tipoProdutoAnuncio': tipoProdutoAnuncio,
      'precoUnitario': precoUnitario,
      'quantidade': quantidade,
      'idVendedor': idVendedor,
      'adicionadoEm':
          FieldValue.serverTimestamp(), // Timestamp de quando foi adicionado
    };
  }
}
