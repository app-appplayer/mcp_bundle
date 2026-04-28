/// Expression Style Types - Communication style configuration.
///
/// Canonical contract-layer types for profile expression results.
/// As per mcp_profile spec/04-expression-policy-schema.md §4-9.
library;

// =============================================================================
// ExpressionStyle (§4)
// =============================================================================

/// Complete expression style configuration.
class ExpressionStyle {
  /// Tone configuration.
  final ToneConfig tone;

  /// Format configuration.
  final FormatConfig format;

  /// Hedging configuration.
  final HedgingConfig? hedging;

  /// Audience configuration.
  final AudienceConfig? audience;

  /// Language configuration.
  final LanguageConfig? language;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const ExpressionStyle({
    required this.tone,
    required this.format,
    this.hedging,
    this.audience,
    this.language,
    this.metadata,
  });

  /// Create a merged style with overrides.
  ExpressionStyle merge(ExpressionStyle? overrides) {
    if (overrides == null) return this;
    return ExpressionStyle(
      tone: tone.merge(overrides.tone),
      format: format.merge(overrides.format),
      hedging: overrides.hedging ?? hedging,
      audience: overrides.audience ?? audience,
      language: overrides.language ?? language,
      metadata: {...?metadata, ...?overrides.metadata},
    );
  }

  factory ExpressionStyle.fromJson(Map<String, dynamic> json) {
    return ExpressionStyle(
      tone: ToneConfig.fromJson(json['tone'] as Map<String, dynamic>),
      format: FormatConfig.fromJson(json['format'] as Map<String, dynamic>),
      hedging: json['hedging'] != null
          ? HedgingConfig.fromJson(json['hedging'] as Map<String, dynamic>)
          : null,
      audience: json['audience'] != null
          ? AudienceConfig.fromJson(json['audience'] as Map<String, dynamic>)
          : null,
      language: json['language'] != null
          ? LanguageConfig.fromJson(json['language'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tone': tone.toJson(),
        'format': format.toJson(),
        if (hedging != null) 'hedging': hedging!.toJson(),
        if (audience != null) 'audience': audience!.toJson(),
        if (language != null) 'language': language!.toJson(),
        if (metadata != null) 'metadata': metadata,
      };

  /// Default neutral style.
  static const ExpressionStyle defaultStyle = ExpressionStyle(
    tone: ToneConfig.neutral,
    format: FormatConfig.defaultFormat,
  );
}

// =============================================================================
// ToneConfig (§5)
// =============================================================================

/// Configuration for communication tone.
class ToneConfig {
  /// Language register.
  final Formality formality;

  /// Certainty expression.
  final ToneConfidence confidence;

  /// Emotional acknowledgment.
  final Empathy empathy;

  /// Communication style.
  final Directness directness;

  const ToneConfig({
    required this.formality,
    required this.confidence,
    required this.empathy,
    required this.directness,
  });

  /// Merge with another config.
  ToneConfig merge(ToneConfig other) {
    return ToneConfig(
      formality: other.formality,
      confidence: other.confidence,
      empathy: other.empathy,
      directness: other.directness,
    );
  }

  factory ToneConfig.fromJson(Map<String, dynamic> json) {
    return ToneConfig(
      formality: Formality.values.firstWhere(
        (f) => f.name == json['formality'],
        orElse: () => Formality.neutral,
      ),
      confidence: ToneConfidence.values.firstWhere(
        (c) => c.name == json['confidence'],
        orElse: () => ToneConfidence.moderate,
      ),
      empathy: Empathy.values.firstWhere(
        (e) => e.name == json['empathy'],
        orElse: () => Empathy.moderate,
      ),
      directness: Directness.values.firstWhere(
        (d) => d.name == json['directness'],
        orElse: () => Directness.balanced,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'formality': formality.name,
        'confidence': confidence.name,
        'empathy': empathy.name,
        'directness': directness.name,
      };

  /// Neutral default tone.
  static const ToneConfig neutral = ToneConfig(
    formality: Formality.neutral,
    confidence: ToneConfidence.moderate,
    empathy: Empathy.moderate,
    directness: Directness.balanced,
  );
}

/// Formality levels.
enum Formality {
  formal,
  neutral,
  casual,
}

/// Tone confidence levels.
///
/// Named ToneConfidence (not Confidence) to avoid conflict with
/// mcp_bundle/types/confidence.dart Confidence utility class.
enum ToneConfidence {
  assertive,
  moderate,
  tentative,
}

/// Empathy levels.
enum Empathy {
  high,
  moderate,
  low,
}

/// Directness levels.
enum Directness {
  direct,
  balanced,
  diplomatic,
}

// =============================================================================
// FormatConfig (§6)
// =============================================================================

/// Configuration for response format.
class FormatConfig {
  /// Response structure.
  final Structure structure;

  /// Response length.
  final Length length;

  /// Whether to include evidence/sources.
  final bool includeEvidence;

  /// Whether to include caveats/disclaimers.
  final bool includeCaveats;

  /// Whether to include alternatives.
  final bool includeAlternatives;

  /// Whether to include next steps.
  final bool includeNextSteps;

  /// Maximum paragraphs (for prose).
  final int? maxParagraphs;

  /// Maximum bullets (for lists).
  final int? maxBullets;

  const FormatConfig({
    required this.structure,
    required this.length,
    this.includeEvidence = false,
    this.includeCaveats = false,
    this.includeAlternatives = false,
    this.includeNextSteps = false,
    this.maxParagraphs,
    this.maxBullets,
  });

  /// Merge with another config.
  FormatConfig merge(FormatConfig other) {
    return FormatConfig(
      structure: other.structure,
      length: other.length,
      includeEvidence: other.includeEvidence,
      includeCaveats: other.includeCaveats,
      includeAlternatives: other.includeAlternatives,
      includeNextSteps: other.includeNextSteps,
      maxParagraphs: other.maxParagraphs ?? maxParagraphs,
      maxBullets: other.maxBullets ?? maxBullets,
    );
  }

  factory FormatConfig.fromJson(Map<String, dynamic> json) {
    return FormatConfig(
      structure: Structure.values.firstWhere(
        (s) => s.name == json['structure'],
        orElse: () => Structure.prose,
      ),
      length: Length.values.firstWhere(
        (l) => l.name == json['length'],
        orElse: () => Length.standard,
      ),
      includeEvidence: json['includeEvidence'] as bool? ?? false,
      includeCaveats: json['includeCaveats'] as bool? ?? false,
      includeAlternatives: json['includeAlternatives'] as bool? ?? false,
      includeNextSteps: json['includeNextSteps'] as bool? ?? false,
      maxParagraphs: json['maxParagraphs'] as int?,
      maxBullets: json['maxBullets'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'structure': structure.name,
        'length': length.name,
        'includeEvidence': includeEvidence,
        'includeCaveats': includeCaveats,
        'includeAlternatives': includeAlternatives,
        if (includeNextSteps) 'includeNextSteps': includeNextSteps,
        if (maxParagraphs != null) 'maxParagraphs': maxParagraphs,
        if (maxBullets != null) 'maxBullets': maxBullets,
      };

  /// Standard default format.
  static const FormatConfig standard = FormatConfig(
    structure: Structure.prose,
    length: Length.standard,
  );

  /// Default format.
  static const FormatConfig defaultFormat = FormatConfig(
    structure: Structure.mixed,
    length: Length.standard,
    includeEvidence: true,
  );
}

/// Response structure types.
enum Structure {
  prose,
  bullets,
  numbered,
  table,
  mixed,
}

/// Response length types.
enum Length {
  concise,
  standard,
  detailed,
}

// =============================================================================
// HedgingConfig (§7)
// =============================================================================

/// Configuration for hedging language.
class HedgingConfig {
  /// Hedging level.
  final HedgingLevel level;

  /// Custom hedging phrases.
  final HedgingPhrases? phrases;

  /// Where to apply hedging.
  final HedgingPosition position;

  const HedgingConfig({
    this.level = HedgingLevel.none,
    this.phrases,
    this.position = HedgingPosition.inline,
  });

  factory HedgingConfig.fromJson(Map<String, dynamic> json) {
    return HedgingConfig(
      level: HedgingLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => HedgingLevel.none,
      ),
      phrases: json['phrases'] != null
          ? HedgingPhrases.fromJson(json['phrases'] as Map<String, dynamic>)
          : null,
      position: HedgingPosition.values.firstWhere(
        (p) => p.name == json['position'],
        orElse: () => HedgingPosition.inline,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level.name,
        if (phrases != null) 'phrases': phrases!.toJson(),
        'position': position.name,
      };
}

/// Hedging levels.
enum HedgingLevel {
  none,
  light,
  moderate,
  strong,
}

/// Hedging position.
enum HedgingPosition {
  start,
  inline,
  end,
}

/// Custom hedging phrases.
class HedgingPhrases {
  final List<String>? highUncertainty;
  final List<String>? moderateUncertainty;
  final List<String>? lowUncertainty;
  final List<String>? qualifying;
  final List<String>? probabilistic;

  const HedgingPhrases({
    this.highUncertainty,
    this.moderateUncertainty,
    this.lowUncertainty,
    this.qualifying,
    this.probabilistic,
  });

  factory HedgingPhrases.fromJson(Map<String, dynamic> json) {
    return HedgingPhrases(
      highUncertainty: (json['high_uncertainty'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      moderateUncertainty: (json['moderate_uncertainty'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lowUncertainty: (json['low_uncertainty'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      qualifying: (json['qualifying'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      probabilistic: (json['probabilistic'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (highUncertainty != null) 'high_uncertainty': highUncertainty,
        if (moderateUncertainty != null)
          'moderate_uncertainty': moderateUncertainty,
        if (lowUncertainty != null) 'low_uncertainty': lowUncertainty,
        if (qualifying != null) 'qualifying': qualifying,
        if (probabilistic != null) 'probabilistic': probabilistic,
      };

  /// Default hedging phrases.
  static const HedgingPhrases defaults = HedgingPhrases(
    highUncertainty: [
      'Based on limited information...',
      'It appears that...',
      'Current evidence tentatively suggests...',
      'Preliminary analysis indicates...',
    ],
    moderateUncertainty: [
      'It seems that...',
      'This likely...',
      'Evidence suggests...',
      'Analysis indicates...',
    ],
    lowUncertainty: [
      'This is...',
      'The data shows...',
      'Clearly...',
    ],
    qualifying: [
      'however',
      'although',
      'while',
      'that said',
    ],
    probabilistic: [
      'probably',
      'likely',
      'possibly',
      'potentially',
    ],
  );
}

// =============================================================================
// AudienceConfig (§8)
// =============================================================================

/// Configuration for audience adaptation.
class AudienceConfig {
  /// Audience expertise level.
  final Expertise expertise;

  /// Communication context.
  final AudienceContext context;

  /// Specific role.
  final String? role;

  /// Audience preferences.
  final AudiencePreferences? preferences;

  const AudienceConfig({
    this.expertise = Expertise.intermediate,
    this.context = AudienceContext.internal,
    this.role,
    this.preferences,
  });

  factory AudienceConfig.fromJson(Map<String, dynamic> json) {
    return AudienceConfig(
      expertise: Expertise.values.firstWhere(
        (e) => e.name == json['expertise'],
        orElse: () => Expertise.intermediate,
      ),
      context: AudienceContext.values.firstWhere(
        (c) => c.name == json['context'],
        orElse: () => AudienceContext.internal,
      ),
      role: json['role'] as String?,
      preferences: json['preferences'] != null
          ? AudiencePreferences.fromJson(
              json['preferences'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'expertise': expertise.name,
        'context': context.name,
        if (role != null) 'role': role,
        if (preferences != null) 'preferences': preferences!.toJson(),
      };
}

/// Expertise levels.
enum Expertise {
  expert,
  intermediate,
  novice,
}

/// Audience context.
enum AudienceContext {
  internal,
  external,
  public_,
}

/// Audience preferences.
class AudiencePreferences {
  final String? preferredFormat;
  final bool avoidJargon;
  final bool includeDefinitions;
  final VisualPreference visualPreference;

  const AudiencePreferences({
    this.preferredFormat,
    this.avoidJargon = false,
    this.includeDefinitions = false,
    this.visualPreference = VisualPreference.text,
  });

  factory AudiencePreferences.fromJson(Map<String, dynamic> json) {
    return AudiencePreferences(
      preferredFormat: json['preferredFormat'] as String?,
      avoidJargon: json['avoidJargon'] as bool? ?? false,
      includeDefinitions: json['includeDefinitions'] as bool? ?? false,
      visualPreference: VisualPreference.values.firstWhere(
        (v) => v.name == json['visualPreference'],
        orElse: () => VisualPreference.text,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        if (preferredFormat != null) 'preferredFormat': preferredFormat,
        'avoidJargon': avoidJargon,
        'includeDefinitions': includeDefinitions,
        'visualPreference': visualPreference.name,
      };
}

/// Visual preference.
enum VisualPreference {
  text,
  diagrams,
  mixed,
}

// =============================================================================
// LanguageConfig (§9)
// =============================================================================

/// Configuration for language and localization.
class LanguageConfig {
  /// Locale (e.g., "en-US", "ko-KR").
  final String? locale;

  /// Vocabulary configuration.
  final VocabularyConfig? vocabulary;

  /// Grammar configuration.
  final GrammarConfig? grammar;

  const LanguageConfig({
    this.locale,
    this.vocabulary,
    this.grammar,
  });

  factory LanguageConfig.fromJson(Map<String, dynamic> json) {
    return LanguageConfig(
      locale: json['locale'] as String?,
      vocabulary: json['vocabulary'] != null
          ? VocabularyConfig.fromJson(
              json['vocabulary'] as Map<String, dynamic>)
          : null,
      grammar: json['grammar'] != null
          ? GrammarConfig.fromJson(json['grammar'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (locale != null) 'locale': locale,
        if (vocabulary != null) 'vocabulary': vocabulary!.toJson(),
        if (grammar != null) 'grammar': grammar!.toJson(),
      };
}

/// Vocabulary configuration.
class VocabularyConfig {
  final List<String>? avoidWords;
  final Map<String, String>? preferredTerms;
  final JargonLevel jargonLevel;

  const VocabularyConfig({
    this.avoidWords,
    this.preferredTerms,
    this.jargonLevel = JargonLevel.standard,
  });

  factory VocabularyConfig.fromJson(Map<String, dynamic> json) {
    return VocabularyConfig(
      avoidWords: (json['avoidWords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      preferredTerms: (json['preferredTerms'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      jargonLevel: JargonLevel.values.firstWhere(
        (j) => j.name == json['jargonLevel'],
        orElse: () => JargonLevel.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        if (avoidWords != null) 'avoidWords': avoidWords,
        if (preferredTerms != null) 'preferredTerms': preferredTerms,
        'jargonLevel': jargonLevel.name,
      };
}

/// Jargon levels.
enum JargonLevel {
  none,
  minimal,
  standard,
  technical,
}

/// Grammar configuration.
class GrammarConfig {
  final VoicePreference voicePreference;
  final SentenceComplexity sentenceComplexity;
  final bool useContractions;

  const GrammarConfig({
    this.voicePreference = VoicePreference.active,
    this.sentenceComplexity = SentenceComplexity.moderate,
    this.useContractions = false,
  });

  factory GrammarConfig.fromJson(Map<String, dynamic> json) {
    return GrammarConfig(
      voicePreference: VoicePreference.values.firstWhere(
        (v) => v.name == json['voicePreference'],
        orElse: () => VoicePreference.active,
      ),
      sentenceComplexity: SentenceComplexity.values.firstWhere(
        (s) => s.name == json['sentenceComplexity'],
        orElse: () => SentenceComplexity.moderate,
      ),
      useContractions: json['useContractions'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'voicePreference': voicePreference.name,
        'sentenceComplexity': sentenceComplexity.name,
        'useContractions': useContractions,
      };
}

/// Voice preference.
enum VoicePreference {
  active,
  passive,
  mixed,
}

/// Sentence complexity.
enum SentenceComplexity {
  simple,
  moderate,
  complex,
}

// =============================================================================
// FormattedResponse
// =============================================================================

/// Formatted response from expression processing.
class FormattedResponse {
  /// Formatted content.
  final String content;

  /// Style that was applied.
  final ExpressionStyle appliedStyle;

  /// Hedging phrases that were applied.
  final List<String> hedgingApplied;

  /// Additional metadata.
  final Map<String, dynamic>? metadata;

  const FormattedResponse({
    required this.content,
    required this.appliedStyle,
    this.hedgingApplied = const [],
    this.metadata,
  });

  /// Create from JSON map.
  factory FormattedResponse.fromJson(Map<String, dynamic> json) {
    return FormattedResponse(
      content: json['content'] as String? ?? '',
      appliedStyle: json['appliedStyle'] is Map<String, dynamic>
          ? ExpressionStyle.fromJson(
              json['appliedStyle'] as Map<String, dynamic>)
          : ExpressionStyle.defaultStyle,
      hedgingApplied:
          (json['hedgingApplied'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
        'content': content,
        'appliedStyle': appliedStyle.toJson(),
        if (hedgingApplied.isNotEmpty) 'hedgingApplied': hedgingApplied,
        if (metadata != null) 'metadata': metadata,
      };
}
