import 'dart:convert';

import 'package:http/http.dart' as http;

class CouchDBService {
  final String baseUrl = 'http://127.0.0.1:5984';
  final String database = 'nosql_db';
  final String username = 'admin';
  final String password = 'admin';

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$username:$password'))}',
  };

  //to be used in the system
  Future<void> connect({
    required String baseUrl,
    required String database,
    required String username,
    required String password,
  }) async {
    final serverUri = Uri.parse(baseUrl.trim());
    final cleanPath = serverUri.path.replaceFirst(RegExp(r'/$'), '');

    final databaseUri = serverUri.replace(
      path: '$cleanPath/${Uri.encodeComponent(database.trim())}',
    );

    final credentials = base64Encode(utf8.encode('$username:$password'));

    final response = await http
        .get(
          databaseUri,
          headers: {
            'Authorization': 'Basic $credentials',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Connection failed (${response.statusCode}). '
        'Check the server URL, database name, and login.',
      );
    }
  }

  Future<void> savePerson(Map<String, dynamic> person) async {
    final id = person['_id']?.toString();

    // Existing documents need PUT to their document URL.
    // New documents use POST to the database URL.
    final url = id == null
        ? Uri.parse('$baseUrl/$database')
        : Uri.parse('$baseUrl/$database/${Uri.encodeComponent(id)}');

    final response = id == null
        ? await http.post(
            url,
            headers: {
              ...headers,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(person),
          )
        : await http.put(
            url,
            headers: {
              ...headers,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(person),
          );

    if (response.statusCode != 201 && response.statusCode != 202) {
      throw Exception(
        'CouchDB returned ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRecord({String search = ''}) async {
    final url = Uri.parse('$baseUrl/$database/_all_docs?include_docs=true');

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Could not load people (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = data['rows'] as List<dynamic>;

    final people = rows
        .map((row) => row['doc'])
        .whereType<Map<String, dynamic>>()
        // Skip CouchDB design documents and other docs without person fields.
        .where(
          (person) =>
              person.containsKey('first_name') ||
              person.containsKey('last_name'),
        )
        .toList();

    final query = search.trim().toLowerCase();
    if (query.isEmpty) return people;

    return people.where((person) {
      final firstName = (person['first_name'] ?? '').toString().toLowerCase();
      final lastName = (person['last_name'] ?? '').toString().toLowerCase();

      return firstName.contains(query) || lastName.contains(query);
    }).toList();
  }

  Future<void> findRecord(String search) async {
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
        'first_name': {'\$gt': search},
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

  Future<void> deleteRecord({required String id, required String rev}) async {
    final documentUri = Uri.parse(
      '$baseUrl/$database/${Uri.encodeComponent(id)}',
    ).replace(queryParameters: {'rev': rev});

    final response = await http.delete(documentUri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception(
        'CouchDB returned ${response.statusCode}: ${response.body}',
      );
    }
  }
}
