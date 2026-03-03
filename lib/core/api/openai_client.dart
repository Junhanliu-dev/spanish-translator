import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/models/menu_item.dart';
import '../error/app_exception.dart';
import 'openai_endpoints.dart';

/// Structured response from the text/speech translation endpoint.
class TranslationResponse {
  final String translatedText;
  final String? context;
  final String? pronunciation;
  final String detectedLanguage;

  const TranslationResponse({
    required this.translatedText,
    this.context,
    this.pronunciation,
    required this.detectedLanguage,
  });
}

/// A section of a menu translation (e.g., "Starters", "Mains").
class MenuSection {
  final String originalTitle;
  final String translatedTitle;
  final List<MenuItem> items;

  const MenuSection({
    required this.originalTitle,
    required this.translatedTitle,
    required this.items,
  });
}

/// Structured response from the menu/image translation endpoint.
class MenuTranslationResponse {
  final List<MenuSection> sections;
  final String detectedLanguage;

  const MenuTranslationResponse({
    required this.sections,
    required this.detectedLanguage,
  });
}

/// Central client for all OpenAI API calls.
///
/// Requires an API key injected from [SecureStorageService].
/// All methods throw [AppException] subtypes on failure.
class OpenAIClient {
  OpenAIClient({required String apiKey})
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.openai.com/v1',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          ),
        );

  final Dio _dio;

  /// Update API key at runtime (e.g., user changes key in Settings).
  void updateApiKey(String apiKey) {
    _dio.options.headers['Authorization'] = 'Bearer $apiKey';
  }

  /// Throws [ApiKeyException] if no API key is configured.
  void _requireApiKey() {
    final auth = _dio.options.headers['Authorization'] as String?;
    if (auth == null || auth == 'Bearer ' || auth == 'Bearer') {
      throw ApiKeyException('No API key configured. Add one in Settings.');
    }
  }

  /// Transcribe audio to text using Whisper.
  /// Returns (transcribedText, detectedLanguage).
  Future<(String text, String language)> transcribe({
    required String audioFilePath,
  }) async {
    _requireApiKey();
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: p.basename(audioFilePath),
        ),
        'model': OpenAIModels.whisper,
        'response_format': 'verbose_json',
      });

      final response = await _dio.post(
        OpenAIEndpoints.transcriptions,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      final language = data['language'] as String? ?? 'en';

      return (text, language);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Translate text using GPT-4o with food/restaurant context.
  Future<TranslationResponse> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    String? contextHint,
  }) async {
    _requireApiKey();
    final systemPrompt = '''
You are a translator specializing in food and restaurant conversations in Spain
and Basque Country. Translate the following spoken text from $sourceLanguage
to $targetLanguage.

Context: This is a conversation in a restaurant setting. The speaker may be
ordering food, asking about menu items, requesting the check, or communicating
with restaurant staff.

Guidelines:
- Preserve the conversational tone and intent
- Use natural, spoken-style $targetLanguage (not formal written style)
- For food and drink items, use the local name and add a brief explanation
  in parentheses if the item is culturally specific
- For Basque (Euskara): this is a language isolate with no relation to Spanish.
  Translate carefully. When uncertain, provide the closest natural phrasing
  and note any ambiguity.
- Include a simplified pronunciation guide for key food terms in the format:
  word: PRONUNCIATION

Respond ONLY with a JSON object:
{
  "translated_text": "the translation",
  "context": "brief context note if relevant (e.g., 'pintxos are small snacks typical of Basque bars')",
  "pronunciation": "key-term: pronunciation guide (one per line)"
}''';

    try {
      final response = await _dio.post(
        OpenAIEndpoints.chatCompletions,
        data: {
          'model': OpenAIModels.gpt4o,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        },
      );

      final data = response.data as Map<String, dynamic>;
      final content =
          data['choices'][0]['message']['content'] as String;
      final parsed = json.decode(content) as Map<String, dynamic>;

      return TranslationResponse(
        translatedText:
            parsed['translated_text'] as String? ?? '',
        context: parsed['context'] as String?,
        pronunciation: parsed['pronunciation'] as String?,
        detectedLanguage: sourceLanguage,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Translate a menu image using GPT-4o Vision.
  Future<MenuTranslationResponse> translateImage({
    required String base64Image,
    required String targetLanguage,
  }) async {
    _requireApiKey();
    // Map code to full name for the prompt.
    final targetName = switch (targetLanguage) {
      'en' => 'English',
      'zh' => 'Mandarin Chinese',
      'es' => 'Spanish',
      'eu' => 'Basque',
      _ => targetLanguage,
    };
    final systemPrompt = '''
You are a specialist in translating Spanish and Basque restaurant menus for
travelers. Analyze the following menu image.

Instructions:
1. Extract ALL text from the menu image, preserving the structure (sections,
   items, prices)
2. Translate each item to $targetName
3. For each item, provide:
   - The original name exactly as written
   - A clear translation
   - A brief description of what the dish actually is (for non-obvious items)
   - A simplified pronunciation guide
   - The price if visible
4. Preserve menu sections (e.g., Starters, Mains, Desserts, Drinks)
5. If the menu is in Basque (Euskara), note this and translate with extra care
   -- Basque is a language isolate
6. For handwritten or unclear text, provide your best interpretation and mark
   uncertain items with [?]

Respond ONLY with a JSON object:
{
  "detected_language": "es" or "eu" or "es+eu",
  "sections": [
    {
      "original_title": "AURREPLATOAK",
      "translated_title": "STARTERS",
      "items": [
        {
          "original_name": "Txangurro gratinado",
          "translated_name": "Gratin of spider crab",
          "description": "Spider crab meat mixed with aromatics, topped with breadcrumbs, and baked until golden.",
          "pronunciation": "chan-GOO-rroh grah-tee-NAH-doh",
          "price": "EUR 14.00",
          "category": "STARTERS"
        }
      ]
    }
  ]
}''';

    try {
      final response = await _dio.post(
        OpenAIEndpoints.chatCompletions,
        data: {
          'model': OpenAIModels.gpt4o,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please translate this restaurant menu.',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'high',
                  },
                },
              ],
            },
          ],
          'temperature': 0.2,
          'max_tokens': 4096,
          'response_format': {'type': 'json_object'},
        },
      );

      final data = response.data as Map<String, dynamic>;
      final content =
          data['choices'][0]['message']['content'] as String;
      final parsed = json.decode(content) as Map<String, dynamic>;

      final detectedLanguage =
          parsed['detected_language'] as String? ?? 'es';
      final sectionsJson =
          parsed['sections'] as List<dynamic>? ?? [];

      final sections = sectionsJson.map((sectionJson) {
        final section = sectionJson as Map<String, dynamic>;
        final itemsJson = section['items'] as List<dynamic>? ?? [];
        final items = itemsJson.asMap().entries.map((entry) {
          final item = entry.value as Map<String, dynamic>;
          return MenuItem(
            originalName: item['original_name'] as String? ?? '',
            translatedName: item['translated_name'] as String? ?? '',
            description: item['description'] as String?,
            pronunciation: item['pronunciation'] as String?,
            price: item['price'] as String?,
            category: item['category'] as String?,
            sortOrder: entry.key,
          );
        }).toList();

        return MenuSection(
          originalTitle: section['original_title'] as String? ?? '',
          translatedTitle:
              section['translated_title'] as String? ?? '',
          items: items,
        );
      }).toList();

      return MenuTranslationResponse(
        sections: sections,
        detectedLanguage: detectedLanguage,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Generate speech audio from text using TTS API.
  /// Returns path to saved audio file.
  Future<String> textToSpeech({
    required String text,
    String voice = 'nova',
    double speed = 0.9,
  }) async {
    _requireApiKey();
    try {
      final response = await _dio.post(
        OpenAIEndpoints.textToSpeech,
        data: {
          'model': OpenAIModels.tts,
          'input': text,
          'voice': voice,
          'speed': speed,
          'response_format': 'mp3',
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(
        tempDir.path,
        'tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      final file = File(filePath);
      await file.writeAsBytes(response.data as List<int>);

      return filePath;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Lightweight API validation call.
  /// Returns true if the key is valid and has credits.
  Future<bool> validateApiKey() async {
    try {
      final response = await _dio.post(
        OpenAIEndpoints.chatCompletions,
        data: {
          'model': OpenAIModels.gpt4o,
          'messages': [
            {'role': 'user', 'content': 'Say "ok" in one word.'},
          ],
          'max_tokens': 5,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return false;
      }
      throw _mapDioException(e);
    }
  }

  /// Map [DioException] to the appropriate [AppException] subtype.
  AppException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'Request timed out',
          cause: e,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection',
          cause: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return ApiKeyException(
            'Invalid or expired API key',
            statusCode: statusCode,
            cause: e,
          );
        }
        if (statusCode == 429) {
          return RateLimitException(
            'Rate limit exceeded',
            statusCode: statusCode,
            cause: e,
          );
        }
        return ApiException(
          'API error: ${e.response?.statusMessage ?? 'Unknown'}',
          statusCode: statusCode,
          cause: e,
        );
      default:
        return NetworkException(
          'Network error',
          cause: e,
        );
    }
  }
}
