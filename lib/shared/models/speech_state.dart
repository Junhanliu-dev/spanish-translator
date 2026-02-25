/// States for the speech translation flow.
enum SpeechState {
  /// Ready to record.
  idle,

  /// Currently recording audio.
  recording,

  /// Transcribing and translating.
  processing,

  /// Translation complete, result available.
  success,

  /// An error occurred during the pipeline.
  error,
}
