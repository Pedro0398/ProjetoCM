import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ReclamacoesPage extends StatefulWidget {
  const ReclamacoesPage({super.key});

  @override
  State<ReclamacoesPage> createState() => _ReclamacoesPageState();
}

class _ReclamacoesPageState extends State<ReclamacoesPage> {
  double? _distancia;
  String _status = 'Calculando...';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _calcularDistancia();
  }

  Future<void> _calcularDistancia() async {
    try {
      // Verificar se o serviço de localização está ativo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _status = "Serviço de localização desativado.");
        return;
      }

      // Verificar e solicitar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        setState(() => _status = "Permissão de localização negada.");
        return;
      }

      // Obter posição atual
      Position posicao;
      try {
        posicao = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // Timeout para evitar travamentos
        );
      } catch (e) {
        setState(() => _status = "Não foi possível obter a localização atual. Erro: $e");
        return;
      }

      // Coordenadas fixas para Setúbal (mais confiável que geocodificação)
      // Estefanilha, Setúbal - coordenadas aproximadas
      double destinoLat = 38.5245; // Latitude de Setúbal
      double destinoLng = -8.8908; // Longitude de Setúbal
      
      // Tentar geocodificação primeiro, mas usar coordenadas fixas como fallback
      try {
        List<Location> locais = await locationFromAddress("Setúbal, Portugal");
        if (locais.isNotEmpty) {
          destinoLat = locais[0].latitude;
          destinoLng = locais[0].longitude;
        }
      } catch (e) {
        // Se a geocodificação falhar, usar as coordenadas fixas
        print("Geocodificação falhou, usando coordenadas fixas: $e");
      }

      // Calcular distância
      double distancia = Geolocator.distanceBetween(
        posicao.latitude,
        posicao.longitude,
        destinoLat,
        destinoLng,
      );

      setState(() {
        _distancia = distancia;
        _status = "Distância até Setúbal: ${(distancia / 1000).toStringAsFixed(2)} km";
      });
    } catch (e) {
      setState(() => _status = "Erro inesperado: $e");
    }
  }

  void _enviarReclamacao() {
    if (_controller.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Reclamação enviada"),
          content: const Text("A sua reclamação foi enviada com sucesso."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      _controller.clear();
    } else {
      // Mostrar mensagem se o campo estiver vazio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, escreva a sua reclamação antes de enviar."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reclamações"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Se desejar, pode deslocar-se pessoalmente à sede da empresa:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Estefanilha, 2910-761 Setúbal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text(
              "Escreva a sua reclamação abaixo:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Digite a sua reclamação aqui...",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enviarReclamacao,
              child: const Text("Enviar"),
            ),
          ],
        ),
      ),
    );
  }
}