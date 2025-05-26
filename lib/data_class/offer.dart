// Em: flutter_application_1/data_class/offer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OfertaProduto {
  final String id;
  final String idProdutoGenerico;
  final String tituloAnuncio;
  final String descricaoAnuncio;
  final String idVendedor;
  final double precoSugerido;
  final int quantidadeDisponivelNestaOferta;
  final DateTime dataCriacaoAnuncio;
  String estadoAnuncio;
  final String? tipoProdutoAnuncio;
  String?
  imageUrl; // NOVO CAMPO para a URL da imagem (denormalizado do Produto)

  String? idComprador;
  DateTime? dataTransacaoFinalizada;
  double? precoFinalTransacao;
  int? quantidadeTransacionada;

  OfertaProduto({
    required this.id,
    required this.idProdutoGenerico,
    required this.tituloAnuncio,
    this.descricaoAnuncio = '',
    required this.idVendedor,
    required this.precoSugerido,
    this.quantidadeDisponivelNestaOferta = 1,
    required this.dataCriacaoAnuncio,
    this.estadoAnuncio = "Disponível",
    this.tipoProdutoAnuncio,
    this.imageUrl, // Adicionado ao construtor
    this.idComprador,
    this.dataTransacaoFinalizada,
    this.precoFinalTransacao,
    this.quantidadeTransacionada,
  });

  // ... (método marcarComoVendido como antes) ...
  void marcarComoVendido({
    required String compradorId,
    DateTime? dataVenda,
    double? precoPago,
  }) {
    if (estadoAnuncio == "Disponível" || estadoAnuncio == "Reservado") {
      idComprador = compradorId;
      dataTransacaoFinalizada = dataVenda ?? DateTime.now();
      precoFinalTransacao = precoPago ?? precoSugerido;
      quantidadeTransacionada = quantidadeDisponivelNestaOferta;
      estadoAnuncio = "Vendido";
    } else {}
  }

  factory OfertaProduto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return OfertaProduto(
      id: doc.id,
      idProdutoGenerico: data['idProdutoGenerico'] ?? '',
      tituloAnuncio: data['tituloAnuncio'] ?? '',
      descricaoAnuncio: data['descricaoAnuncio'] ?? '',
      idVendedor: data['idVendedor'] ?? '',
      precoSugerido: (data['precoSugerido'] ?? 0.0).toDouble(),
      quantidadeDisponivelNestaOferta:
          (data['quantidadeDisponivelNestaOferta'] ?? 1).toInt(),
      dataCriacaoAnuncio:
          (data['dataCriacaoAnuncio'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      estadoAnuncio: data['estadoAnuncio'] ?? 'Disponível',
      tipoProdutoAnuncio: data['tipoProdutoAnuncio'] as String?,
      imageUrl: data['imageUrl'] as String?, // Ler imageUrl
      idComprador: data['idComprador'],
      dataTransacaoFinalizada:
          (data['dataTransacaoFinalizada'] as Timestamp?)?.toDate(),
      precoFinalTransacao: (data['precoFinalTransacao'] as double?),
      quantidadeTransacionada: (data['quantidadeTransacionada'] as int?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'idProdutoGenerico': idProdutoGenerico,
      'tituloAnuncio': tituloAnuncio,
      'descricaoAnuncio': descricaoAnuncio,
      'idVendedor': idVendedor,
      'precoSugerido': precoSugerido,
      'quantidadeDisponivelNestaOferta': quantidadeDisponivelNestaOferta,
      'dataCriacaoAnuncio': Timestamp.fromDate(dataCriacaoAnuncio),
      'estadoAnuncio': estadoAnuncio,
      if (tipoProdutoAnuncio != null) 'tipoProdutoAnuncio': tipoProdutoAnuncio,
      if (imageUrl != null) 'imageUrl': imageUrl, // Guardar imageUrl se existir
      // ... (campos de transação como antes) ...
      if (idComprador != null) 'idComprador': idComprador,
      if (dataTransacaoFinalizada != null)
        'dataTransacaoFinalizada': Timestamp.fromDate(dataTransacaoFinalizada!),
      if (precoFinalTransacao != null)
        'precoFinalTransacao': precoFinalTransacao,
      if (quantidadeTransacionada != null)
        'quantidadeTransacionada': quantidadeTransacionada,
    };
  }
}
