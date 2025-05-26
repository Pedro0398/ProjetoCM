// Em: flutter_application_1/data_class/user.dart (ou o seu caminho)
import 'package:cloud_firestore/cloud_firestore.dart';

class Utilizador {
  final String uid; // UID do Firebase Authentication
  final String nome;
  final String email;
  final String tipoUtilizador; // "Comprador" ou "Vendedor"
  final Timestamp dataRegisto;
  double saldo; // NOVO CAMPO para os fundos do utilizador

  Utilizador({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipoUtilizador,
    required this.dataRegisto,
    this.saldo = 0.0, // Saldo inicial por defeito é 0.0
  });

  factory Utilizador.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return Utilizador(
      uid: documentId,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      tipoUtilizador: data['tipoUtilizador'] ?? 'Comprador',
      dataRegisto: data['dataRegisto'] ?? Timestamp.now(),
      saldo: (data['saldo'] ?? 0.0).toDouble(), // Ler o saldo do Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'tipoUtilizador': tipoUtilizador,
      'dataRegisto': dataRegisto,
      'saldo': saldo, // Guardar o saldo no Firestore
    };
  }
}
