import 'dart:convert';
import 'package:divinewall/services/account_storage.dart';
import 'package:divinewall/services/backend_api.dart';
import 'package:divinewall/models/content_models.dart';
import 'package:divinewall/services/content_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Testimonial review(String id, String author) => Testimonial(
    id: id,
    authorId: author,
    name: 'Example',
    profileImageUrl: '',
    rating: 5,
    review: 'Example review',
    createdAt: null);

class FakeAccounts extends BackendApi {
  bool rejectDeletion = false;
  bool deleted = false;
  @override
  Future<Map<String, dynamic>?> login(
          {required String username, required String password}) async =>
      {
        'token': 'test-token',
        'user': {
          'username': username,
          'name': 'Example',
          'email': 'test@example.com'
        }
      };
  @override
  Future<Map<String, dynamic>?> fetchMe(String token) async => null;
  @override
  Future<void> deleteAccount(String token, String password) async {
    if (rejectDeletion || password != 'correct') {
      throw Exception('Incorrect password');
    }
    deleted = true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('deletion failure preserves session; success clears account and cart',
      () async {
    final backend = FakeAccounts();
    final account = AccountStorage(api: backend);
    await account.login(username: 'example', password: 'correct');
    backend.rejectDeletion = true;
    await expectLater(account.deleteAccount('correct'), throwsException);
    expect(account.isLoggedIn, isTrue);
    expect(
        (await SharedPreferences.getInstance())
            .getString('divinewall.sessionToken.v1'),
        'test-token');
    backend.rejectDeletion = false;
    await account.deleteAccount('correct');
    expect(backend.deleted, isTrue);
    expect(account.isLoggedIn, isFalse);
    expect(account.orders, isEmpty);
    expect(account.cart, isEmpty);
    expect(
        (await SharedPreferences.getInstance())
            .getString('divinewall.sessionToken.v1'),
        isNull);
  });

  test('blocking persists and hides every review by that author only',
      () async {
    final service = ContentService();
    await service.blockAuthor(review('1', 'author-a'));
    service.dispose();
    final restarted = ContentService();
    final visible = await restarted.visibleTestimonials([
      review('1', 'author-a'),
      review('2', 'author-a'),
      review('3', 'author-b')
    ]);
    expect(visible.map((item) => item.id), ['3']);
    restarted.dispose();
  });

  test('legacy review hiding does not hide other anonymous contributors',
      () async {
    final service = ContentService();
    await service.blockAuthor(review('1', ''));
    expect(
        (await service.visibleTestimonials([review('1', ''), review('2', '')]))
            .map((item) => item.id),
        ['2']);
    service.dispose();
  });

  test('reports send credentials and reason, then persist hiding', () async {
    SharedPreferences.setMockInitialValues(
        {'divinewall.sessionToken.v1': 'test-token'});
    final service = ContentService(client: MockClient((request) async {
      expect(request.url.path, endsWith('/api/testimonials/1/report'));
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(request.body)['reason'], 'Abusive content');
      return http.Response('{"reported":true}', 200);
    }));
    await service.reportTestimonial(review('1', 'a'), 'Abusive content');
    expect(await service.visibleTestimonials([review('1', 'a')]), isEmpty);
    service.dispose();
  });

  test('failed report keeps content visible and surfaces failure', () async {
    SharedPreferences.setMockInitialValues(
        {'divinewall.sessionToken.v1': 'test-token'});
    final service = ContentService(
        client: MockClient((_) async => http.Response('{}', 500)));
    await expectLater(
        service.reportTestimonial(review('1', 'a'), 'Abusive content'),
        throwsA(isA<ContentException>()));
    expect(await service.visibleTestimonials([review('1', 'a')]), hasLength(1));
    service.dispose();
  });

  test('anonymous feedback is rejected before a network request', () async {
    final service = ContentService(client: MockClient((_) async {
      fail('Anonymous feedback must not be sent');
    }));
    await expectLater(
        service.submitFeedback(
            name: 'Example', rating: 5, review: 'Example review'),
        throwsA(isA<ContentException>()));
    service.dispose();
  });
}
