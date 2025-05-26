import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe o Firestore

// ... (o seu main() e MyApp como no Passo 2) ...

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.title});
  final String title;

  // Função para adicionar um documento
  Future<void> adicionarDocumentoTeste() async {
    try {
      // Obtenha uma instância do Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Defina a coleção onde quer adicionar o documento
      // Se a coleção 'testes' não existir, será criada automaticamente
      CollectionReference colecaoTestes = firestore.collection(
        'testes',
      ); // Pode escolher outro nome, ex: 'utilizadores'

      // Adicione um novo documento com um ID gerado automaticamente
      DocumentReference docRef = await colecaoTestes.add({
        'mensagem': 'Olá Firebase!',
        'timestamp': FieldValue.serverTimestamp(), // Guarda a hora do servidor
        'valor': 123,
        'ativo': true,
      });

      if (kDebugMode) {
        print('Documento adicionado com ID: ${docRef.id}');
      }
      // Pode adicionar um feedback visual para o utilizador aqui (ex: SnackBar)
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Documento adicionado! ID: ${docRef.id}')));
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao adicionar documento: $e');
      }
      // Pode adicionar um feedback visual de erro para o utilizador aqui
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar documento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Pressione o botão para criar um documento no Firestore:',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Chama a função para adicionar o documento
                // Como o build pode ser chamado múltiplas vezes,
                // e precisamos do context para o SnackBar (opcional),
                // é comum chamar a função de uma forma que tenha acesso ao context se necessário.
                // Para este exemplo simples, chamamos diretamente.
                adicionarDocumentoTeste();
              },
              child: const Text('Criar Documento de Teste'),
            ),
          ],
        ),
      ),
    );
  }
}
