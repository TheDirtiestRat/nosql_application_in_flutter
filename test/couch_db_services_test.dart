import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nosql_application/services/couch_db_services.dart';

void main() {
  test('uses the configured CouchDB URL for database operations', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final serverSubscription = server.listen((request) async {
      requests.add(
        '${request.method} ${request.uri.path}'
        '${request.uri.hasQuery ? '?${request.uri.query}' : ''}',
      );
      await request.drain();
      request.response.statusCode =
          request.method == 'GET' || request.method == 'DELETE'
          ? HttpStatus.ok
          : HttpStatus.created;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"rows":[]}');
      await request.response.close();
    });

    try {
      final service = CouchDBService();
      await service.connect(
        baseUrl: 'http://127.0.0.1:${server.port}/couch/',
        database: 'people',
        username: 'test-user',
        password: 'test-password',
      );

      await service.getRecord();
      await service.savePerson({'first_name': 'New'});
      await service.savePerson({
        '_id': 'person-1',
        '_rev': '1-a',
        'first_name': 'Updated',
      });
      await service.deleteRecord(id: 'person-1', rev: '1-a');

      expect(requests, [
        'GET /couch/people',
        'GET /couch/people/_all_docs?include_docs=true',
        'POST /couch/people',
        'PUT /couch/people/person-1',
        'DELETE /couch/people/person-1?rev=1-a',
      ]);
    } finally {
      await serverSubscription.cancel();
      await server.close(force: true);
    }
  });
}
