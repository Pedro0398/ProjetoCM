// Em: lib/services/storage_service.dart
import 'dart:io'; // Para o tipo File
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart'; // Para gerar nomes de ficheiro únicos

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid(); // Para gerar nomes de ficheiro únicos

  // Faz upload de uma imagem para o Firebase Storage e retorna a URL de download
  // O 'pathPrefix' pode ser algo como 'imagens_produtos/' ou 'imagens_ofertas/'
  Future<String?> uploadImage({
    required File imageFile,
    required String pathPrefix, // Ex: "produtos_imagens/"
    String? existingFileName, // Para substituir uma imagem existente (opcional)
  }) async {
    try {
      // Gera um nome de ficheiro único se não estiver a substituir um existente
      String fileName =
          existingFileName ??
          '${_uuid.v4()}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      String filePath = '$pathPrefix$fileName';

      // Cria a referência para o local onde a imagem será guardada
      Reference ref = _storage.ref().child(filePath);

      // Faz o upload do ficheiro
      UploadTask uploadTask = ref.putFile(imageFile);

      // Espera o upload ser concluído
      TaskSnapshot snapshot = await uploadTask;

      // Obtém a URL de download da imagem
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // Poderia lançar uma exceção mais específica ou retornar null
      // dependendo de como quer tratar o erro na UI
      return null;
    }
  }

  // Apagar uma imagem do Storage (útil se o produto/oferta for apagado)
  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Lide com o erro, por exemplo, se o ficheiro não existir mais.
    }
  }
}
