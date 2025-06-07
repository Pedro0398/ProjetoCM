// Em: services/auth_service.dart (ou data_class/auth_service.dart)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ajuste o caminho para a sua classe Utilizador atualizada
import 'package:flutter_application_1/data_class/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> registerWithEmailAndPassword({
    required String nome,
    required String email,
    required String password,
    required String tipoUtilizador,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        app_user.Utilizador novoUtilizador = app_user.Utilizador(
          uid: firebaseUser.uid,
          nome: nome,
          email: email,
          tipoUtilizador: tipoUtilizador,
          dataRegisto: Timestamp.now(),
          saldo: 0.0, // Saldo inicial definido como 0.0
        );

        await _firestore
            .collection('utilizadores')
            .doc(firebaseUser.uid)
            .set(novoUtilizador.toFirestore());

        await firebaseUser.updateDisplayName(nome);
        return firebaseUser;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // ... (código existente)
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    // ... (código existente)
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<app_user.Utilizador?> getUserData(String uid) async {
    // ... (código existente, agora buscará o saldo também)
    try {
      DocumentSnapshot doc =
          await _firestore.collection('utilizadores').doc(uid).get();
      if (doc.exists) {
        return app_user.Utilizador.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      // ignore: empty_catches
    } catch (e) {}
    return null;
  }

  // NOVO MÉTODO: Adicionar fundos ao saldo de um utilizador
  Future<void> adicionarFundos(String uid, double valorAdicionar) async {
    if (valorAdicionar <= 0) {
      // Lançar um erro ou retornar sem fazer nada
      throw ArgumentError("O valor a adicionar deve ser positivo.");
    }
    final userDocRef = _firestore.collection('utilizadores').doc(uid);
    try {
      // FieldValue.increment() é atómico e seguro para operações concorrentes
      await userDocRef.update({'saldo': FieldValue.increment(valorAdicionar)});
    } catch (e) {
      rethrow;
    }
  }

  // NOVO MÉTODO: Debitar fundos do saldo de um utilizador (com verificação de saldo)
  Future<void> debitarFundos(String uid, double valorDebitar) async {
    if (valorDebitar <= 0) {
      throw ArgumentError("O valor a debitar deve ser positivo.");
    }
    final userDocRef = _firestore.collection('utilizadores').doc(uid);

    try {
      // Usar uma transação para garantir que a leitura do saldo e a atualização
      // sejam atómicas, prevenindo condições de corrida.
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          throw Exception("Utilizador não encontrado!");
        }

        // O '?' e '??' são para segurança, caso o campo saldo não exista ou seja nulo.
        double saldoAtual =
            (snapshot.data() as Map<String, dynamic>)['saldo']?.toDouble() ??
            0.0;

        if (saldoAtual < valorDebitar) {
          throw Exception(
            "Saldo insuficiente!",
          ); // Pode querer um tipo de exceção mais específico
        }

        double novoSaldo = saldoAtual - valorDebitar;
        transaction.update(userDocRef, {'saldo': novoSaldo});
        // Alternativamente, para subtrair: FieldValue.increment(-valorDebitar)
        // transaction.update(userDocRef, {'saldo': FieldValue.increment(-valorDebitar)});
      });
    } catch (e) {
      rethrow; // Re-lança para a UI tratar (ex: mostrar mensagem de saldo insuficiente)
    }
  }

  Future<void> atualizarNome({
  required String uid,
  required String novoNome,
  }) async {
  try {
    // Atualiza no Firestore
    await _firestore.collection('utilizadores').doc(uid).update({
      'nome': novoNome,
    });

    // Atualiza no Firebase Auth (ex: displayName)
    await _firebaseAuth.currentUser?.updateDisplayName(novoNome);
  } catch (e) {
    rethrow;
  }
}

}
