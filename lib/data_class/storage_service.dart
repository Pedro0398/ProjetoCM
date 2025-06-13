// ficheiro: lib/data_class/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p; // <-- LINHA QUE FALTAVA

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Faz o upload de um ficheiro de imagem para o Firebase Storage.
  /// Retorna o URL de download da imagem.
  Future<String> uploadImagemProduto({
    required File ficheiro,
    required String idVendedor,
  }) async {
    try {
      // Cria um nome de ficheiro único para evitar colisões
      // A função p.extname() agora será reconhecida
      String nomeFicheiro =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(ficheiro.path)}';
      // Cria uma referência para o caminho no Storage onde a imagem será guardada
      Reference ref = _storage.ref().child(
        'imagens_produtos/$idVendedor/$nomeFicheiro',
      );

      // Faz o upload do ficheiro
      UploadTask uploadTask = ref.putFile(
        ficheiro,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Aguarda a conclusão do upload
      TaskSnapshot snapshot = await uploadTask;

      // Obtém e retorna o URL de download
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print("Erro no upload da imagem (Firebase): ${e.message}");
      }
      throw Exception(
        "Falha ao carregar a imagem. Verifique a sua conexão e permissões.",
      );
    } catch (e) {
      if (kDebugMode) {
        print("Erro desconhecido no upload da imagem: $e");
      }
      throw Exception("Ocorreu um erro inesperado ao carregar a imagem.");
    }
  }

  /// Remove uma imagem do Storage usando o seu URL de download.
  Future<void> removerImagem(String urlImagem) async {
    // Ignora se o URL estiver vazio
    if (urlImagem.isEmpty) return;

    try {
      // Converte o URL de volta para uma referência do Storage
      Reference ref = _storage.refFromURL(urlImagem);
      await ref.delete();
    } catch (e) {
      // É comum ocorrer um erro se o ficheiro já foi apagado ou o URL é inválido.
      // Para a app, podemos simplesmente registar o erro e continuar.
      if (kDebugMode) {
        print("Info: Erro ao remover imagem antiga (pode ser ignorado): $e");
      }
    }
  }
}
