import 'dart:convert';

import 'package:http/http.dart' as http;

class CouchDBService {
  Uri? _databaseUri;
  String? _username;
  String? _password;

  Map<String, String> get headers {
    final username = _username;
    final password = _password;
    if (username == null || password == null) {
      throw StateError('Connect to CouchDB before making database requests.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    };
  }

  Uri _uriFor(
    List<String> pathSegments, {
    Map<String, String>? queryParameters,
  }) {
    final databaseUri = _databaseUri;
    if (databaseUri == null) {
      throw StateError('Connect to CouchDB before making database requests.');
    }

    return databaseUri.replace(
      pathSegments: [...databaseUri.pathSegments, ...pathSegments],
      queryParameters: queryParameters,
    );
  }

  //to be used in the system
  Future<void> connect({
    required String baseUrl,
    required String database,
    required String username,
    required String password,
  }) async {
    final serverUri = Uri.parse(baseUrl.trim());
    final databaseName = database.trim();
    if ((serverUri.scheme != 'http' && serverUri.scheme != 'https') ||
        serverUri.host.isEmpty ||
        serverUri.hasQuery ||
        serverUri.hasFragment ||
        databaseName.isEmpty) {
      throw ArgumentError(
        'Enter a valid HTTP or HTTPS base URL and a database name. '
        'The URL must not include a query or fragment.',
      );
    }

    final databaseUri = serverUri.replace(
      pathSegments: [
        ...serverUri.pathSegments.where((segment) => segment.isNotEmpty),
        databaseName,
      ],
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

    _databaseUri = databaseUri;
    _username = username;
    _password = password;
  }

  Future<void> savePerson(Map<String, dynamic> person) async {
    final id = person['_id']?.toString();

    // Existing documents need PUT to their document URL.
    // New documents use POST to the database URL.
    final url = id == null ? _uriFor([]) : _uriFor([id]);

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
    final url = _uriFor(
      ['_all_docs'],
      queryParameters: {'include_docs': 'true'},
    );

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
    final url = _uriFor(['_find']);

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
    final getUrl = _uriFor([id]);

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
    final putUrl = _uriFor([id]);

    final putResponse = await http.put(
      putUrl,
      headers: headers,
      body: jsonEncode(person),
    );

    print(putResponse.body);
  }

  Future<void> deleteRecord({required String id, required String rev}) async {
    final documentUri = _uriFor([id], queryParameters: {'rev': rev});

    final response = await http.delete(documentUri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception(
        'CouchDB returned ${response.statusCode}: ${response.body}',
      );
    }
  }
}
