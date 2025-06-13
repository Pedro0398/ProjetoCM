// ficheiro: lib/data_class/product.dart

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
  switch (tipo) {
    case TipoProdutoAgricola.fruta:
      return 'fruta';
    case TipoProdutoAgricola.vegetal:
      return 'vegetal';
    case TipoProdutoAgricola.legume:
      return 'legume';
    case TipoProdutoAgricola.laticinio:
      return 'laticinio';
    case TipoProdutoAgricola.ovo:
      return 'ovo';
    case TipoProdutoAgricola.cereal:
      return 'cereal';
    case TipoProdutoAgricola.leguminosa:
      return 'leguminosa';
    case TipoProdutoAgricola.carne:
      return 'carne';
    case TipoProdutoAgricola.peixeDeAguaDoce:
      return 'peixeDeAguaDoce';
    case TipoProdutoAgricola.azeite:
      return 'azeite';
    case TipoProdutoAgricola.vinho:
      return 'vinho';
    case TipoProdutoAgricola.mel:
      return 'mel';
    case TipoProdutoAgricola.ervaAromatica:
      return 'ervaAromatica';
    case TipoProdutoAgricola.cogumelo:
      return 'cogumelo';
    case TipoProdutoAgricola.frutoSeco:
      return 'frutoSeco';
    case TipoProdutoAgricola.transformado:
      return 'transformado';
    case TipoProdutoAgricola.plantaOrnamental:
      return 'plantaOrnamental';
    case TipoProdutoAgricola.outro:
      return 'outro';
  }
}

String tipoProdutoAgricolaParaStringForUser(TipoProdutoAgricola tipo) {
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
      return 'Peixe De Água Doce';
    case TipoProdutoAgricola.azeite:
      return 'Azeite';
    case TipoProdutoAgricola.vinho:
      return 'Vinho';
    case TipoProdutoAgricola.mel:
      return 'Mel';
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

TipoProdutoAgricola stringParaTipoProdutoAgricola(String? valor) {
  if (valor == null || valor.isEmpty) {
    // Retornar um valor padrão mais genérico
    return TipoProdutoAgricola.outro;
  }

  // Usar um método mais robusto que não falha se um valor for adicionado ao enum
  return TipoProdutoAgricola.values.firstWhere(
    (e) => e.name.toLowerCase() == valor.toLowerCase(),
    orElse: () {
      print('Tipo de produto desconhecido: $valor, usando padrão "outro"');
      return TipoProdutoAgricola.outro;
    },
  );
}

// ****** FUNÇÃO RESTAURADA ******
String stringForUser(String? valor) {
  if (valor == null || valor.isEmpty) {
    return "Vinho"; // ou outro valor padrão apropriado
  }

  switch (valor.toLowerCase()) {
    case 'fruta':
      return "Fruta";
    case 'vegetal':
      return "Vegetal";
    case 'legume':
      return "Leguma"; // Nota: "Legume" e não "Leguma"
    case 'laticinio':
      return "Laticínio";
    case 'ovo':
      return "Ovo";
    case 'cereal':
      return "Cereal";
    case 'leguminosa':
      return "Leguminosa";
    case 'carne':
      return "Carne";
    case 'peixedeaguadoce':
      return "Peixe De Água Doce";
    case 'azeite':
      return "Azeite";
    case 'vinho':
      return "Vinho";
    case 'mel':
      return "Mel";
    case 'ervaaromatica':
      return "Erva Aromática";
    case 'cogumelo':
      return "Cogumelo";
    case 'frutoseco':
      return "Fruto Seco";
    case 'transformado':
      return "Transformado";
    case 'plantaornamental':
      return "Planta Ornamental";
    case 'outro':
      return "Outro";
    default:
      print('Tipo de produto desconhecido: $valor, usando padrão');
      return "Vinho"; // Valor padrão
  }
}

class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String idVendedor;
  int quantidadeEmStock;
  final TipoProdutoAgricola tipoProduto;
  final String? imageUrl;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.idVendedor,
    this.quantidadeEmStock = 0,
    required this.tipoProduto,
    this.imageUrl,
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
      imageUrl: data['imageUrl'] as String?,
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
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
