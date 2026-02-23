import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'pages/stats_page.dart';
import 'pages/users_page.dart';

class SettingsManager {
  // 1. Obtener la ruta del archivo
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/settings.xml');
  }

  // 2. Crear y guardar el archivo XML
  Future<void> saveUrl(String url, String token) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element(
      'settings',
      nest: () {
        builder.element('url', nest: url);
        builder.element('token', nest: token);
      },
    );

    final xmlDocument = builder.buildDocument();
    final file = await _localFile;

    // Escribir el archivo como string
    await file.writeAsString(xmlDocument.toXmlString(pretty: true));
    print("Ajustes guardados en: ${file.path}");
  }

  Future<void> deleteToken() async {
    final file = await _localFile;
    if (await file.exists()) {
      String contents = await file.readAsString();
      final document = XmlDocument.parse(contents);

      // Eliminar el nodo de token
      final tokenElement = document.findAllElements('token').first;
      tokenElement.parent?.children.remove(tokenElement);

      // Guardar el archivo actualizado
      await file.writeAsString(document.toXmlString(pretty: true));
      print("Token eliminado del archivo de configuración.");
    } else {
      print("Archivo de configuración no encontrado para eliminar el token.");
    }
  }

  Future<String> loadUrl() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      final document = XmlDocument.parse(contents);

      final url = document.findAllElements('url').first.innerText;

      print("URL Cargada: $url");
      return url;
    } catch (e) {
      print("Aún no hay archivo de configuración o error al leer.");
      return "";
    }
  }

  Future<String> loadToken() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      final document = XmlDocument.parse(contents);

      final token = document.findAllElements('token').first.innerText;

      print("Token Cargado: $token");
      return token;
    } catch (e) {
      print("Aún no hay archivo de configuración o error al leer.");
      return "";
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Desktop Admin App'),
    );
  }
}

Future<bool> logoutPetition() async {
  final host = await SettingsManager().loadUrl();
  final url = Uri.parse('https://$host/api/admin/usuaris/logout');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': await SettingsManager().loadToken()}),
  );

  final jsonResponse = jsonDecode(response.body);
  print(jsonResponse);

  if (jsonResponse['status'] == "OK") {
    print('Logout successful: ${response.body}');
    SettingsManager().deleteToken();
    return true;
  } else {
    print('Logout failed: ${response.body}');
    return false;
  }
}

Future<bool> testImageAnalysis() async {
  final host = await SettingsManager().loadUrl();
  final url = Uri.parse('https://$host/api/admin/image-analysis/test');

  return false;
}

Future<bool> testToken() async {
  final host = await SettingsManager().loadUrl();
  final url = Uri.parse('https://$host/api/admin/usuaris/testtoken');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': await SettingsManager().loadToken()}),
  );

  final jsonResponse = jsonDecode(response.body);
  print(jsonResponse);

  if (jsonResponse['status'] == "OK") {
    print('Token válido: ${response.body}');
    return true;
  } else {
    print('Token inválido: ${response.body}');
    return false;
  }
}

Future<void> sendPetition(urlHost) async {
  final url = Uri.parse('http://$urlHost:3000/admin/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'prompt': 'Hola desde Flutter!', 'stream': false}),
  );

  if (response.statusCode == 201) {
    print('Éxito: ${response.body}');
  } else {
    print('Error: ${response.statusCode}');
  }
}

Future<bool> sendLoginPetition(
  String urlHost,
  String email,
  String password,
) async {
  final url = Uri.parse('https://$urlHost/api/admin/usuaris/login');
  print("Intentando login en $url con $email y $password");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  final jsonResponse = jsonDecode(response.body);

  print(jsonResponse);

  if (jsonResponse['status'] == "OK") {
    SettingsManager().saveUrl(urlHost, jsonResponse['data']['token']);
    print('Éxito: ${response.body}');

    return true;
  } else {
    print('Error: ${response.body}');
    return false;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String url = "";
  String user = "";
  String password = "";

  @override
  void initState() {
    super.initState();
    SettingsManager().loadUrl().then((loadedUrl) {
      setState(() {
        url = loadedUrl;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Admin Desktop App",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),

            SizedBox(
              width: 300,
              child: TextField(
                controller: TextEditingController(text: url),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'URL',
                ),
                onChanged: (value) {
                  url = value;
                },
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User (E-mail)',
                ),
                onChanged: (value) {
                  user = value;
                },
              ),
            ),

            SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
                onChanged: (value) {
                  password = value;
                },
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(300, 48)),
              onPressed: () {
                sendLoginPetition(url, user, password).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login successful!')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyMainPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Login failed. Please check your credentials.',
                        ),
                      ),
                    );
                  }
                });
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyMainPageState();
  }
}

class _MyMainPageState extends State<MyMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin App")),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                testToken().then((isValid) {
                  if (isValid) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Token válido')));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Token no válido')));
                  }
                });
              },
              child: Text("Test token"),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                logoutPetition().then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout successful!')),
                    );
                    //Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed. Please try again.'),
                      ),
                    );
                  }
                });
              },
              child: Text('Logout'),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
              },
              child: const Text("Estadístiques"),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersPage()),
                );
              },
              child: const Text("Usuaris"),
            ),
          ],
        ),
      ),
    );
  }
}
