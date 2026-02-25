/// OpenAI API endpoint paths.
class OpenAIEndpoints {
  OpenAIEndpoints._();

  static const String transcriptions = '/audio/transcriptions';
  static const String chatCompletions = '/chat/completions';
  static const String textToSpeech = '/audio/speech';
}

/// OpenAI model identifiers.
class OpenAIModels {
  OpenAIModels._();

  static const String whisper = 'whisper-1';
  static const String gpt4o = 'gpt-4o';
  static const String tts = 'tts-1';
}
