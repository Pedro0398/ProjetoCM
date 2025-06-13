// ficheiro: lib/views/common_pages/reclamacoes_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ReclamacoesPage extends StatefulWidget {
  const ReclamacoesPage({super.key});

  @override
  State<ReclamacoesPage> createState() => _ReclamacoesPageState();
}

class _ReclamacoesPageState extends State<ReclamacoesPage> {
  String _status = 'A calcular a sua distância até à sede...';
  final TextEditingController _reclamacaoController = TextEditingController();

  // Coordenadas da sede da empresa em Setúbal
  static const LatLng _sedeCoordenadas = LatLng(38.5245, -8.8908);

  // Estado do mapa
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicializar o mapa primeiro, depois tentar obter localização
    _initializeMap();
  }

  /// Inicializa o mapa com o marcador da sede
  void _initializeMap() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('sede'),
          position: _sedeCoordenadas,
          infoWindow: const InfoWindow(
              title: 'Sede da Empresa', snippet: 'Estefanilha, Setúbal'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      _status =
          'Mapa carregado. Toque em "Obter Localização" para calcular a distância.';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _reclamacaoController.dispose();
    super.dispose();
  }

  /// Verifica se os serviços de localização estão habilitados
  Future<bool> _checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status =
            'Os serviços de localização estão desabilitados. Por favor, habilite-os nas configurações.';
        _isLoading = false;
      });
      return false;
    }
    return true;
  }

  /// Pede permissão, obtém a localização do utilizador, calcula a distância
  /// e atualiza o mapa com os marcadores.
  Future<void> _getUserLocationAndDistance() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'A inicializar mapa...';
      });

      // Define o marcador da sede, que estará sempre visível
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('sede'),
            position: _sedeCoordenadas,
            infoWindow: const InfoWindow(
                title: 'Sede da Empresa', snippet: 'Estefanilha, Setúbal'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });

      setState(() {
        _status = 'A verificar serviços de localização...';
      });

      // Verificar se os serviços de localização estão habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status =
              'GPS desabilitado. Habilite o GPS nas configurações para calcular a distância.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'A verificar permissões...';
      });

      // Verificação de permissões de localização com tratamento seguro
      LocationPermission permission;
      try {
        permission = await Geolocator.checkPermission();
      } catch (e) {
        setState(() {
          _status =
              'Erro ao verificar permissões. Funcionalidade de GPS não disponível.';
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          setState(() {
            _status = 'Não foi possível solicitar permissões de localização.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _status = "Permissão de localização negada. GPS não disponível.";
          _isLoading = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status =
              "Permissão de localização negada permanentemente. Altere nas configurações.";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'A obter a sua localização...';
      });

      // Obter a posição atual do utilizador com timeout e tratamento seguro
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } on TimeoutException {
        setState(() {
          _status = 'Timeout ao obter localização. Tente novamente.';
          _isLoading = false;
        });
        return;
      } catch (e) {
        setState(() {
          _status =
              'Não foi possível obter a localização. Verifique se o GPS está ativo.';
          _isLoading = false;
        });
        return;
      }

      // Adicionar o marcador da posição do utilizador ao mapa
      final userMarker = Marker(
        markerId: const MarkerId('user'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'A sua Localização'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Calcular a distância em metros
      final double distanciaEmMetros = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _sedeCoordenadas.latitude,
        _sedeCoordenadas.longitude,
      );

      setState(() {
        _status =
            "Localização obtida! Distância até à sede: ${(distanciaEmMetros / 1000).toStringAsFixed(2)} km";
        _markers.add(userMarker);
        _isLoading = false;
      });

      // Animar a câmara para mostrar ambos os pontos
      await _animateCameraToShowAllMarkers();
    } catch (e) {
      // Captura qualquer erro não tratado
      if (mounted) {
        setState(() {
          _status = "Mapa carregado. GPS não disponível neste momento.";
          _isLoading = false;
        });
      }
    }
  }

  /// Anima a câmara do mapa para enquadrar todos os marcadores visíveis.
  Future<void> _animateCameraToShowAllMarkers() async {
    if (_currentPosition == null || !_mapController.isCompleted) return;

    try {
      final GoogleMapController controller = await _mapController.future;

      // Calcular os limites para incluir ambos os pontos
      double minLat = _currentPosition!.latitude < _sedeCoordenadas.latitude
          ? _currentPosition!.latitude
          : _sedeCoordenadas.latitude;
      double maxLat = _currentPosition!.latitude > _sedeCoordenadas.latitude
          ? _currentPosition!.latitude
          : _sedeCoordenadas.latitude;
      double minLng = _currentPosition!.longitude < _sedeCoordenadas.longitude
          ? _currentPosition!.longitude
          : _sedeCoordenadas.longitude;
      double maxLng = _currentPosition!.longitude > _sedeCoordenadas.longitude
          ? _currentPosition!.longitude
          : _sedeCoordenadas.longitude;

      // Adicionar margem aos limites
      double latMargin = (maxLat - minLat) * 0.1;
      double lngMargin = (maxLng - minLng) * 0.1;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - latMargin, minLng - lngMargin),
        northeast: LatLng(maxLat + latMargin, maxLng + lngMargin),
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Erro ao animar câmara: $e');
    }
  }

  /// Abre a aplicação de mapas (Google Maps, Apple Maps) com a rota traçada.
  Future<void> _abrirDirecoesNoMapa() async {
    try {
      final String origin = _currentPosition != null
          ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
          : 'My+Location';

      final String destination =
          '${_sedeCoordenadas.latitude},${_sedeCoordenadas.longitude}';
      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir a aplicação de mapas';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir mapas: $e")),
        );
      }
    }
  }

  /// Simula o envio de uma reclamação.
  void _enviarReclamacao() {
    if (_reclamacaoController.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Reclamação enviada"),
          content: const Text(
            "A sua reclamação foi enviada com sucesso para análise.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      _reclamacaoController.clear();
    } else {
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
      appBar: AppBar(title: const Text("Contactos e Reclamações")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pode deslocar-se pessoalmente à sede da empresa em:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Estefanilha, 2910-761 Setúbal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Status com indicador de carregamento
            Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_isLoading) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style:
                        const TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Widget do Mapa Real
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: const CameraPosition(
                    target: _sedeCoordenadas,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _markers,
                  zoomControlsEnabled: true,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getUserLocationAndDistance,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label:
                        Text(_isLoading ? "A obter..." : "Obter Localização"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _currentPosition != null ? _abrirDirecoesNoMapa : null,
                    icon: const Icon(Icons.directions),
                    label: const Text("Ver Direções"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPosition != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      foregroundColor: _currentPosition != null
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 48),

            const Text(
              "Ou envie a sua reclamação por escrito:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reclamacaoController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Digite a sua reclamação aqui...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviarReclamacao,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Enviar Reclamação"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
