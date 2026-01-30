import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


Future<void> sendPetition(urlHost) async {
  final url = Uri.parse('http://$urlHost:3000/admin/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'prompt': 'Hola desde Flutter!',
      'stream': false,
      
    }),
  );

  if (response.statusCode == 201) {
    print('Éxito: ${response.body}');
  } else {
    print('Error: ${response.statusCode}');
  }
}

Future<void> sendLoginPetition(String urlHost, String email, String password) async {
  final url = Uri.parse('http://$urlHost:3000/api/admin/usuaris/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  final jsonResponse = jsonDecode(response.body);

  if (jsonResponse['status'] == "OK" ) {
    print('Éxito: ${response.body}');
  } else {
    print('Error: ${response.body}');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Desktop Admin App'),
    );
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
            Text("Admin Desktop App", style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 16,),

            SizedBox(
              width: 300,
              child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL',
                ),
              onChanged: (value) {
                url = value;
              },
              ),
            )
            ,
            SizedBox(height: 16,),
            SizedBox(
              width: 300,
              child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'User (E-mail)',
                ),
              onChanged:(value) {
                user = value;
              },
              ),
            ),
            
            SizedBox(height: 16,),
            SizedBox(
              width: 300,
              child: TextField(
              obscureText: true,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              onChanged:(value) {
                password = value;
              },
              ),
            ),
          
            SizedBox(height: 16,),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(300, 48),
              ),
              onPressed: () {
        
                sendLoginPetition(url, user, password);
              },
              child: Text('Login'),
            ),
          ],
      ),
      ),
    );
  }
}
