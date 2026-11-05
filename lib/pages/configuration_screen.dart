import 'package:flutter/material.dart';
import 'package:nosql_application/pages/persons_list_screen.dart';
import 'package:nosql_application/services/couch_db_services.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final baseUrlController = TextEditingController(
    text: "http://127.0.0.1:5984"
  );
  final databaseController = TextEditingController(
    text: "nosql_db"
  );
  final usernameController = TextEditingController(
    text: "admin"
  );
  final passwordController = TextEditingController(
    text: "admin"
  );

  final couchDbService = CouchDBService();
  bool isConnecting = false;

  //function to use to connect to the database
  Future<void> _connect() async {
    setState(() => isConnecting = true);

    try {
      await couchDbService.connect(
        baseUrl: baseUrlController.text,
        database: databaseController.text,
        username: usernameController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PeopleScreen(couchDbService: couchDbService)
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => isConnecting = false);
      }
    }
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    databaseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: baseUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://server.example.com',
                  border: inputBorder,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: databaseController,
                decoration: InputDecoration(
                  labelText: 'Database',
                  hintText: 'inventory_db',
                  border: inputBorder,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: inputBorder,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: inputBorder,
                ),
              ),

              const Spacer(),

              FilledButton(
                onPressed: isConnecting ? null : _connect,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(isConnecting ? 'Connecting...' : 'Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
