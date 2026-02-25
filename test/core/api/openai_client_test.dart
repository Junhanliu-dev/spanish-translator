import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_viaje/core/api/openai_client.dart';
import 'package:lingua_viaje/core/error/app_exception.dart';

void main() {
  group('OpenAIClient', () {
    group('_requireApiKey()', () {
      test('throws ApiKeyException when key is empty string', () {
        final client = OpenAIClient(apiKey: '');

        expect(
          () => client.transcribe(audioFilePath: '/fake/path.m4a'),
          throwsA(isA<ApiKeyException>()),
        );
      });

      test('throws ApiKeyException on translate when key is empty', () {
        final client = OpenAIClient(apiKey: '');

        expect(
          () => client.translate(
            text: 'hello',
            sourceLanguage: 'en',
            targetLanguage: 'es',
          ),
          throwsA(isA<ApiKeyException>()),
        );
      });

      test('does not throw ApiKeyException when valid key is provided',
          () async {
        final client = OpenAIClient(apiKey: 'sk-test-valid-key');

        // transcribe is synchronous up to _requireApiKey, then fails on
        // file I/O (not network), avoiding the 401 → ApiKeyException path.
        try {
          await client.transcribe(audioFilePath: '/nonexistent/path.m4a');
        } on ApiKeyException {
          fail('Should not throw ApiKeyException with a valid key');
        } catch (_) {
          // Expected: file not found or other non-ApiKey error.
        }
      });
    });

    group('updateApiKey()', () {
      test('changes the authorization header', () async {
        final client = OpenAIClient(apiKey: '');

        // Initially empty -- should throw ApiKeyException.
        expect(
          () => client.transcribe(audioFilePath: '/fake/path.m4a'),
          throwsA(isA<ApiKeyException>()),
        );

        // After updating with a real key, should not throw ApiKeyException.
        client.updateApiKey('sk-new-valid-key-12345');
        try {
          await client.transcribe(audioFilePath: '/nonexistent/path.m4a');
        } on ApiKeyException {
          fail('Should not throw ApiKeyException after updateApiKey');
        } catch (_) {
          // Expected: file not found or other non-ApiKey error.
        }
      });

      test('setting key back to empty re-triggers ApiKeyException', () {
        final client = OpenAIClient(apiKey: 'sk-initial-key');

        // Should not throw ApiKeyException with a valid key.
        // (Just test the guard via transcribe which is synchronous up to
        // _requireApiKey.)
        client.updateApiKey('');

        // Should now throw ApiKeyException.
        expect(
          () => client.translate(
            text: 'hello',
            sourceLanguage: 'en',
            targetLanguage: 'es',
          ),
          throwsA(isA<ApiKeyException>()),
        );
      });
    });
  });
}
