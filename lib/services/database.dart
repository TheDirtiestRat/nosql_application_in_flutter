import 'dart:convert';

import 'package:http/http.dart' as http;

class NoSQLService {
  final String baseUrl = 'http://127.0.0.1:5984';
  final String database = 'nosql_db';

  final String username = 'admin';
  final String password = 'admin';

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$username:$password'))}',
  };

  Future<void> connect() async {
    try {
      final url = Uri.parse('$baseUrl/$database');
      final response = await http.get(url, headers: headers);

      print('Status: ${response.statusCode}');
      print('Respons: ${response.body}');

      //if it connected
      if (response.statusCode == 200) {
        print('Successufully connected to CouchDB or Any NoSQL Database!');
      } else {
        print('Authenticatin or Connection Failed.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> addRecord() async {
    final url = Uri.parse('$baseUrl/$database');

    final person = {
      'first_name': 'Mar Louise',
      'last_name': 'Leal',
      'age': 20,
      'year_born': 2002,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(person),
    );

    print(response.body);
  }

  Future<void> getRecord() async {
    final url = Uri.parse('$baseUrl/$database/_all_docs?include_docs=true');

    final response = await http.get(url, headers: headers);

    //the record after being processed
    final data = jsonDecode(response.body);

    //better way to present it
    final records = data['rows'];
    for (var row in records) {
      final person = row['doc'];

      print('=====================================');
      print('First Name: ${person['first_name']}');
      print('Last Name: ${person['last_name']}');
      print('Age: ${person['age']}');
      print('Year Born: ${person['year_born']}');
    }
  }

  Future<void> findRecord() async {
    final url = Uri.parse('$baseUrl/$database/_find');

    /* Possible queries
    Operator	Meaning
    $eq	      Equal
    $gt	      Greater than
    $gte	    Greater than or equal
    $lt	      Less than
    $lte	    Less than or equal
    $ne	      Not equal
    $in	      Matches any value in an array
     */

    /*Example queries : Find products in a specific category
    {
      "selector": {
        "category": "Accessories"
      }
    }
     */

    final query = {
      'selector': {
        'age': {'\$gt': 20},
      },
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(query),
    );

    final data = jsonDecode(response.body);

    final records = data['docs'];

    for (var person in records) {
      print('=== What found =================');
      print('First Name: ${person['first_name']}');
      print('Last Name: ${person['last_name']}');
      print('Age: ${person['age']}');
      print('Year Born: ${person['year_born']}');
    }
  }

  Future<void> updateRecord(String id, String new_firstName) async {
    //step 1
    final getUrl = Uri.parse('$baseUrl/$database/$id');

    final getResponse = await http.get(getUrl, headers: headers);

    if (getResponse.statusCode != 200) {
      print('Failed to retrieve document');
      return;
    }

    //step 2
    final person = jsonDecode(getResponse.body);
    // I can add more attributes to update
    person['first_name'] = new_firstName;

    //step 3
    final putUrl = Uri.parse('$baseUrl/$database/$id');

    final putResponse = await http.put(
      putUrl,
      headers: headers,
      body: jsonEncode(person),
    );

    print(putResponse.body);
  }

  Future<void> deleteRecord(String id) async {
    final getUrl = Uri.parse('$baseUrl/$database/$id');

    final getResponse = await http.get(getUrl, headers: headers);

    if (getResponse.statusCode != 200) {
      print('Cannot find the document! either Id does not exist');
      return;
    }

    final person = jsonDecode(getResponse.body);

    final revision = person['_rev'];

    final deleteUrl = Uri.parse('$baseUrl/$database/$id?rev=$revision');

    final response = await http.delete(deleteUrl, headers: headers);

    print(response.body);
  }
}
