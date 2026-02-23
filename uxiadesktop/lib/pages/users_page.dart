import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_stats.dart'; // Importa tu modelo desde la carpeta models
import '../main.dart'; // Para acceder a SettingsManager y la lógica global

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // --- OPERACIONES API ---

  // Obtener todos los usuarios (GET)
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      final host = await SettingsManager().loadUrl();
      final token = await SettingsManager().loadToken();

      final url = Uri.parse('https://$host/api/admin/usuaris');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        // Verificación de seguridad: ¿Es una lista o un objeto con una lista dentro?
        List<dynamic> userList = [];
        if (decodedData is List) {
          userList = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          userList = decodedData['data'];
        }

        setState(() {
          _users = userList.map((item) => User.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error de conexión: $e");
    }
  }

  // Eliminar usuario (DELETE)
  Future<void> _deleteUser(String id) async {
    try {
      final host = await SettingsManager().loadUrl();
      final token = await SettingsManager().loadToken(); // Cargamos el token

      final url = Uri.parse('https://$host/api/admin/usuaris/$id');

      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // Enviamos el token aquí
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _users.removeWhere((user) => user.id == id);
        });
        _showSnackBar("Usuari eliminat correctament");
      } else {
        _showSnackBar("Error al eliminar: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Error de red al eliminar");
    }
  }

  // Añadir usuario (POST)
  Future<void> _addUser(
    String nickname,
    String email,
    String password,
    int telefon,
    String role,
  ) async {
    try {
      final host = await SettingsManager().loadUrl();
      final token = await SettingsManager().loadToken();

      final url = Uri.parse('https://$host/api/admin/usuaris/register');

      // 1. CORRECCIÓN: La clave debe ser 'telefon', no 'telephone'
      final Map<String, dynamic> userData = {
        'nickname': nickname,
        'email': email,
        'password': password,
        'telephone': telefon,
        'role': role,
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchUsers();
        _showSnackBar("Usuari creat correctament!");
      } else {
        // Esto te dirá exactamente qué campo falta o está mal
        _showSnackBar("Error: ${response.body}");
      }
    } catch (e) {
      print("Error fatal: $e");
      _showSnackBar("Error de conexión");
    }
  }

  // --- UI HELPER ---

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddDialog() {
    final nickCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final telefonCtrl = TextEditingController();

    // 1. Quitamos el ValueNotifier si vamos a usar StatefulBuilder para simplificar
    bool isAdminValue = false;

    showDialog(
      context: context,
      // 2. AÑADIMOS EL STATEFULBUILDER AQUÍ
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Nou Usuari"),
            content: SingleChildScrollView(
              // Añadido para evitar errores de espacio
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nickCtrl,
                    decoration: const InputDecoration(labelText: "Nickname"),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                  ),
                  TextField(
                    controller: telefonCtrl,
                    decoration: const InputDecoration(labelText: "Telefon"),
                  ),

                  const SizedBox(height: 10),

                  CheckboxListTile(
                    title: const Text("Admin"),
                    value: isAdminValue,
                    // Esto lo mueve a la IZQUIERDA
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      // 3. AHORA SÍ: setDialogState refresca el diálogo
                      setDialogState(() {
                        isAdminValue = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel·lar"),
              ),
              ElevatedButton(
                onPressed: () {
                  _addUser(
                    nickCtrl.text,
                    emailCtrl.text,
                    passCtrl.text,
                    telefonCtrl.text.isNotEmpty
                        ? int.parse(telefonCtrl.text)
                        : 0,
                    isAdminValue ? 'admin' : 'normal',
                  );
                  Navigator.pop(context);
                },
                child: const Text("Crear"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panell d'Usuaris")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    title: Text(
                      user.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${user.email} (ID: ${user.id})\n"
                      "Telefon: ${user.telephone}\n"
                      "Role: ${user.role}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteUser(user.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
