// ficheiro: lib/data_class/product.dart
// O enum TipoProdutoAgricola e funções utilitárias devem estar aqui ou importados

enum TipoProdutoAgricola {
  fruta,
  vegetal,
  legume,
  laticinio,
  ovo,
  cereal,
  leguminosa,
  carne,
  peixeDeAguaDoce,
  azeite,
  vinho,
  mel,
  ervaAromatica,
  cogumelo,
  frutoSeco,
  transformado,
  plantaOrnamental,
  outro,
}

String tipoProdutoAgricolaParaString(TipoProdutoAgricola tipo) {
  /* ... (como antes) ... */
  switch (tipo) {
    case TipoProdutoAgricola.fruta:
      return 'Fruta';
    case TipoProdutoAgricola.vegetal:
      return 'Vegetal';
    case TipoProdutoAgricola.legume:
      return 'Legume';
    case TipoProdutoAgricola.laticinio:
      return 'Laticínio';
    case TipoProdutoAgricola.ovo:
      return 'Ovo';
    case TipoProdutoAgricola.cereal:
      return 'Cereal';
    case TipoProdutoAgricola.leguminosa:
      return 'Leguminosa';
    case TipoProdutoAgricola.carne:
      return 'Carne';
    case TipoProdutoAgricola.peixeDeAguaDoce:
      return 'Peixe de Água Doce';
    case TipoProdutoAgricola.azeite:
      return 'Azeite';
    case TipoProdutoAgricola.vinho:
      return 'Vinho';
    case TipoProdutoAgricola.mel:
      return 'Mel e Derivados';
    case TipoProdutoAgricola.ervaAromatica:
      return 'Erva Aromática';
    case TipoProdutoAgricola.cogumelo:
      return 'Cogumelo';
    case TipoProdutoAgricola.frutoSeco:
      return 'Fruto Seco';
    case TipoProdutoAgricola.transformado:
      return 'Produto Transformado';
    case TipoProdutoAgricola.plantaOrnamental:
      return 'Planta Ornamental';
    case TipoProdutoAgricola.outro:
      return 'Outro';
  }
}

TipoProdutoAgricola stringParaTipoProdutoAgricola(
  String? nomeDoTipoNoFirestore,
) {
  /* ... (como antes) ... */
  if (nomeDoTipoNoFirestore == null) return TipoProdutoAgricola.outro;
  for (TipoProdutoAgricola tipo in TipoProdutoAgricola.values) {
    if (tipo.name == nomeDoTipoNoFirestore) return tipo;
  }
  for (TipoProdutoAgricola tipo in TipoProdutoAgricola.values) {
    if (tipoProdutoAgricolaParaString(tipo).toLowerCase() ==
        nomeDoTipoNoFirestore.toLowerCase()) {
      return tipo;
    }
  }
  return TipoProdutoAgricola.outro;
}

class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String idVendedor;
  int quantidadeEmStock;
  final TipoProdutoAgricola tipoProduto;
  String? imageUrl; // NOVO CAMPO para a URL da imagem

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.idVendedor,
    this.quantidadeEmStock = 0,
    required this.tipoProduto,
    this.imageUrl, // Adicionado ao construtor (opcional)
  });

  factory Produto.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Produto(
      id: documentId,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0.0).toDouble(),
      idVendedor: data['idVendedor'] ?? '',
      quantidadeEmStock: (data['quantidadeEmStock'] ?? 0).toInt(),
      tipoProduto: stringParaTipoProdutoAgricola(
        data['tipoProduto'] as String?,
      ),
      imageUrl: data['imageUrl'] as String?, // Ler imageUrl
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'idVendedor': idVendedor,
      'quantidadeEmStock': quantidadeEmStock,
      'tipoProduto': tipoProduto.name,
      if (imageUrl != null) 'imageUrl': imageUrl, // Guardar imageUrl se existir
    };
  }
}
