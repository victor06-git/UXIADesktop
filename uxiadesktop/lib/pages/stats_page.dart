import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tag_stats.dart';
import '../widgets/bar_chart_painter.dart';
import '../main.dart'; // Importamos main para usar SettingsManager

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<TagStats> allTags = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final host = await SettingsManager().loadUrl();
      final token = await SettingsManager()
          .loadToken(); // Obtenemos el token del XML

      // Cambiamos a http o https según tu configuración (en el log vi uxia5.ieti.site)
      final url = Uri.parse('https://$host/api/admin/estadistiques/etiquetes');

      print("DEBUG: Intentando conexión con Bearer Token a: $url");

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      print("DEBUG: Respuesta del servidor: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Verificamos que 'data' no sea nulo
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];

          List<Color> palette = [
            Colors.blueAccent,
            Colors.redAccent,
            Colors.greenAccent,
            Colors.orangeAccent,
            Colors.purpleAccent,
            Colors.tealAccent,
            Colors.pinkAccent,
            Colors.amberAccent,
          ];

          setState(() {
            allTags = List.generate(data.length, (i) {
              return TagStats.fromJson(data[i], palette[i % palette.length]);
            });
            isLoading = false;
          });
        } else {
          print("DEBUG: La API devolvió OK pero data es nulo");
          setState(() => isLoading = false);
        }
      } else {
        print("DEBUG: Fallo en la petición. Código: ${response.statusCode}");
        print("DEBUG: Cuerpo del error: ${response.body}");
        setState(() => isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error ${response.statusCode}: No autorizado o endpoint no encontrado",
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("DEBUG: Error excepcional -> $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo mandamos al pintor las que estén marcadas en el Checkbox
    final selectedTags = allTags.where((t) => t.isSelected).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Estadístiques d'Etiquetes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // BARRA LATERAL
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Filtre d'Etiquetes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allTags.length,
                          itemBuilder: (context, i) {
                            final tag = allTags[i];
                            return CheckboxListTile(
                              title: Text(
                                tag.name,
                                style: TextStyle(
                                  color: tag.color,
                                  fontSize: 14,
                                ),
                              ),
                              value: tag.isSelected,
                              activeColor: tag.color,
                              onChanged: (val) =>
                                  setState(() => tag.isSelected = val!),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // ÁREA DE GRÁFICA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: allTags.isEmpty
                        ? const Center(
                            child: Text("No hi ha dades disponibles"),
                          )
                        : CustomPaint(
                            size: Size.infinite,
                            painter: BarChartPainter(selectedTags),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
