import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:math';

class ReclamacoesPage extends StatefulWidget {
  const ReclamacoesPage({super.key});

  @override
  State<ReclamacoesPage> createState() => _ReclamacoesPageState();
}

class _ReclamacoesPageState extends State<ReclamacoesPage> {
  double? _distancia;
  String _status = 'Calculando...';
  final TextEditingController _controller = TextEditingController();
  
  // Coordenadas de Setúbal
  static const double _setubalLat = 38.5245;
  static const double _setubalLng = -8.8908;
  
  Position? _currentPosition;
  
  // Controles do mapa
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;
  
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
          timeLimit: Duration(seconds: 10),
        );
        
        setState(() {
          _currentPosition = posicao;
        });
        
      } catch (e) {
        setState(() => _status = "Não foi possível obter a localização atual. Erro: $e");
        return;
      }

      // Calcular distância usando as coordenadas fixas de Setúbal
      double distancia = Geolocator.distanceBetween(
        posicao.latitude,
        posicao.longitude,
        _setubalLat,
        _setubalLng,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, escreva a sua reclamação antes de enviar."),
        ),
      );
    }
  }

  void _abrirMapa() {
    String url;
    
    if (_currentPosition != null) {
      // Se temos a localização atual, mostrar direções
      url = 'https://www.google.com/maps/dir/${_currentPosition!.latitude},${_currentPosition!.longitude}/$_setubalLat,$_setubalLng';
    } else {
      // Caso contrário, mostrar apenas a localização de Setúbal
      url = 'https://www.google.com/maps/search/?api=1&query=$_setubalLat,$_setubalLng';
    }
    
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      // Para apps móveis, usar url_launcher
      // launch(url);
    }
  }

  Widget _buildMapWidget() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Mapa incorporado do OpenStreetMap
            Container(
              width: double.infinity,
              height: double.infinity,
              child: kIsWeb 
                ? _buildWebMap()
                : _buildMobileMapPlaceholder(),
            ),
            // Botão para abrir o mapa completo
            Positioned(
              top: 8,
              right: 8,
              child: FloatingActionButton.small(
                onPressed: _abrirMapa,
                backgroundColor: Colors.white,
                child: const Icon(Icons.open_in_new, color: Colors.blue),
              ),
            ),
            // Marcador personalizado para Setúbal
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Setúbal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade100,
            Colors.green.shade100,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Fundo decorativo simples
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://tile.openstreetmap.org/13/${(((-8.8908 + 180) / 360) * (1 << 13)).floor()}/${((1 - (log(tan(38.5245 * pi / 180) + 1 / cos(38.5245 * pi / 180)) / pi)) / 2 * (1 << 13)).floor()}.png',
                  ),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {
                    // Fallback se a imagem não carregar
                  },
                ),
              ),
            ),
          ),
          // Informações centralizadas
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city,
                      size: 32,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sede da Empresa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Setúbal, Portugal',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estefanilha, 2910-761',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_setubalLat.toStringAsFixed(4)}, ${_setubalLng.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMapPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Localização: Setúbal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão para ver direções',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _buildStaticMapUrl() {
    // Usando OpenStreetMap que não precisa de API key
    String center = _currentPosition != null 
        ? '${(_setubalLat + _currentPosition!.latitude) / 2},${(_setubalLng + _currentPosition!.longitude) / 2}'
        : '$_setubalLat,$_setubalLng';
    
    int zoom = _currentPosition != null ? 10 : 13;
    
    // URL usando serviço gratuito do OpenStreetMap
    return 'https://www.openstreetmap.org/export/embed.html?'
           'bbox=${_setubalLng-0.01},${_setubalLat-0.01},${_setubalLng+0.01},${_setubalLat+0.01}&'
           'layer=mapnik&'
           'marker=$_setubalLat,$_setubalLng';
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
            
            // Mapa
            _buildMapWidget(),
            const SizedBox(height: 16),
            
            // Legenda e botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("Sede (E)"),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_currentPosition != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("Você (V)"),
                        ],
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _abrirMapa,
                  icon: const Icon(Icons.directions),
                  label: const Text("Ver Direções"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
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

// Custom painter para criar um mapa visual simples
class MapPainter extends CustomPainter {
  final double setubalLat;
  final double setubalLng;
  final Position? currentPosition;

  MapPainter(this.setubalLat, this.setubalLng, this.currentPosition);

  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar fundo tipo mapa
    final paint = Paint();
    
    // Desenhar "ruas" simuladas
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 2;
    
    // Linhas horizontais
    for (int i = 0; i < 6; i++) {
      double y = (size.height / 6) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Linhas verticais
    for (int i = 0; i < 8; i++) {
      double x = (size.width / 8) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Desenhar algumas "áreas verdes" simuladas
    paint.color = Colors.green.shade200;
    paint.style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.2),
      20,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.8),
      15,
      paint,
    );
    
    // Desenhar "água" (representando o mar perto de Setúbal)
    paint.color = Colors.blue.shade200;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.7, size.width * 0.4, size.height * 0.3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}