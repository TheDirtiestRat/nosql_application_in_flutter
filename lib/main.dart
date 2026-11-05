import 'package:flutter/material.dart';
import 'package:nosql_application/pages/configuration_screen.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  // final nosqlDB = NoSQLService();

  // //testing the connection
  // await nosqlDB.connect();

  // //testing to insert record
  // await nosqlDB.addRecord();

  // //testing to get the record
  // await nosqlDB.getRecord();

  // //testing to find a record
  // await nosqlDB.findRecord();

  // //testing to update a record
  // await nosqlDB.updateRecord("2cf243ed624581abc684335ecc000767", "Squall Leonhart");

  // //testing to delete a record
  // await nosqlDB.deleteRecord("2cf243ed624581abc684335ecc007f6c");

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ConfigurationScreen(),
    );
  }
}
