/// Test Section model for MCP Bundle.
///
/// Contains test definitions for validating bundle functionality.
library;

/// Test section containing test definitions.
class TestSection {
  /// Schema version for test section.
  final String schemaVersion;

  /// Test suites.
  final List<TestSuite> suites;

  /// Test fixtures.
  final Map<String, TestFixture> fixtures;

  /// Global test configuration.
  final TestConfig? config;

  const TestSection({
    this.schemaVersion = '1.0.0',
    this.suites = const [],
    this.fixtures = const {},
    this.config,
  });

  factory TestSection.fromJson(Map<String, dynamic> json) {
    return TestSection(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0.0',
      suites: (json['suites'] as List<dynamic>?)
              ?.map((e) => TestSuite.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fixtures: (json['fixtures'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              TestFixture.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      config: json['config'] != null
          ? TestConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (suites.isNotEmpty) 'suites': suites.map((s) => s.toJson()).toList(),
      if (fixtures.isNotEmpty)
        'fixtures': fixtures.map((k, v) => MapEntry(k, v.toJson())),
      if (config != null) 'config': config!.toJson(),
    };
  }
}

/// Test suite definition.
class TestSuite {
  /// Suite identifier.
  final String id;

  /// Suite name.
  final String name;

  /// Suite description.
  final String? description;

  /// Test cases in the suite.
  final List<TestCase> tests;

  /// Setup steps.
  final List<TestStep>? setup;

  /// Teardown steps.
  final List<TestStep>? teardown;

  /// Suite tags.
  final List<String> tags;

  /// Suite timeout in milliseconds.
  final int? timeoutMs;

  const TestSuite({
    required this.id,
    required this.name,
    this.description,
    this.tests = const [],
    this.setup,
    this.teardown,
    this.tags = const [],
    this.timeoutMs,
  });

  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      tests: (json['tests'] as List<dynamic>?)
              ?.map((e) => TestCase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      setup: (json['setup'] as List<dynamic>?)
          ?.map((e) => TestStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      teardown: (json['teardown'] as List<dynamic>?)
          ?.map((e) => TestStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timeoutMs: json['timeoutMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (tests.isNotEmpty) 'tests': tests.map((t) => t.toJson()).toList(),
      if (setup != null) 'setup': setup!.map((s) => s.toJson()).toList(),
      if (teardown != null)
        'teardown': teardown!.map((t) => t.toJson()).toList(),
      if (tags.isNotEmpty) 'tags': tags,
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
    };
  }
}

/// Test case definition.
class TestCase {
  /// Test identifier.
  final String id;

  /// Test name.
  final String name;

  /// Test description.
  final String? description;

  /// Test type.
  final TestType type;

  /// Test steps.
  final List<TestStep> steps;

  /// Expected result.
  final ExpectedResult? expected;

  /// Test input data.
  final Map<String, dynamic>? input;

  /// Test timeout in milliseconds.
  final int? timeoutMs;

  /// Whether test is skipped.
  final bool skip;

  /// Skip reason.
  final String? skipReason;

  const TestCase({
    required this.id,
    required this.name,
    this.description,
    this.type = TestType.unit,
    this.steps = const [],
    this.expected,
    this.input,
    this.timeoutMs,
    this.skip = false,
    this.skipReason,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      type: TestType.fromString(json['type'] as String? ?? 'unit'),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => TestStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expected: json['expected'] != null
          ? ExpectedResult.fromJson(json['expected'] as Map<String, dynamic>)
          : null,
      input: json['input'] as Map<String, dynamic>?,
      timeoutMs: json['timeoutMs'] as int?,
      skip: json['skip'] as bool? ?? false,
      skipReason: json['skipReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'type': type.name,
      if (steps.isNotEmpty) 'steps': steps.map((s) => s.toJson()).toList(),
      if (expected != null) 'expected': expected!.toJson(),
      if (input != null) 'input': input,
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
      if (skip) 'skip': skip,
      if (skipReason != null) 'skipReason': skipReason,
    };
  }
}

/// Test types.
enum TestType {
  /// Unit test.
  unit,

  /// Integration test.
  integration,

  /// End-to-end test.
  e2e,

  /// Snapshot test.
  snapshot,

  /// Performance test.
  performance,

  /// Unknown type.
  unknown;

  static TestType fromString(String value) {
    return TestType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TestType.unknown,
    );
  }
}

/// Test step definition.
class TestStep {
  /// Step action.
  final StepAction action;

  /// Step configuration.
  final Map<String, dynamic> config;

  /// Assertion to check.
  final TestAssertion? assertion;

  const TestStep({
    required this.action,
    this.config = const {},
    this.assertion,
  });

  factory TestStep.fromJson(Map<String, dynamic> json) {
    return TestStep(
      action: StepAction.fromString(json['action'] as String? ?? 'execute'),
      config: json['config'] as Map<String, dynamic>? ?? {},
      assertion: json['assertion'] != null
          ? TestAssertion.fromJson(json['assertion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.name,
      if (config.isNotEmpty) 'config': config,
      if (assertion != null) 'assertion': assertion!.toJson(),
    };
  }
}

/// Step actions.
enum StepAction {
  execute,
  navigate,
  click,
  input,
  wait,
  assert_,
  mock,
  restore,
  unknown;

  static StepAction fromString(String value) {
    if (value == 'assert') return StepAction.assert_;
    return StepAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StepAction.unknown,
    );
  }

  String get name {
    if (this == StepAction.assert_) return 'assert';
    return toString().split('.').last;
  }
}

/// Test assertion.
class TestAssertion {
  /// Assertion type.
  final AssertionType type;

  /// Target to check.
  final String target;

  /// Expected value.
  final dynamic expected;

  /// Operator for comparison.
  final ComparisonOperator operator;

  /// Custom message on failure.
  final String? message;

  const TestAssertion({
    required this.type,
    required this.target,
    this.expected,
    this.operator = ComparisonOperator.equals,
    this.message,
  });

  factory TestAssertion.fromJson(Map<String, dynamic> json) {
    return TestAssertion(
      type: AssertionType.fromString(json['type'] as String? ?? 'value'),
      target: json['target'] as String? ?? '',
      expected: json['expected'],
      operator: ComparisonOperator.fromString(
          json['operator'] as String? ?? 'equals'),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'target': target,
      if (expected != null) 'expected': expected,
      'operator': operator.name,
      if (message != null) 'message': message,
    };
  }
}

/// Assertion types.
enum AssertionType {
  value,
  exists,
  visible,
  enabled,
  text,
  contains,
  count,
  state,
  unknown;

  static AssertionType fromString(String value) {
    return AssertionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssertionType.unknown,
    );
  }
}

/// Comparison operators.
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  contains,
  matches,
  unknown;

  static ComparisonOperator fromString(String value) {
    return ComparisonOperator.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComparisonOperator.unknown,
    );
  }
}

/// Expected result definition.
class ExpectedResult {
  /// Result type.
  final ResultType type;

  /// Expected value.
  final dynamic value;

  /// Expected error.
  final String? error;

  /// Custom matchers.
  final Map<String, dynamic>? matchers;

  const ExpectedResult({
    required this.type,
    this.value,
    this.error,
    this.matchers,
  });

  factory ExpectedResult.fromJson(Map<String, dynamic> json) {
    return ExpectedResult(
      type: ResultType.fromString(json['type'] as String? ?? 'success'),
      value: json['value'],
      error: json['error'] as String?,
      matchers: json['matchers'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (value != null) 'value': value,
      if (error != null) 'error': error,
      if (matchers != null) 'matchers': matchers,
    };
  }
}

/// Result types.
enum ResultType {
  success,
  failure,
  error,
  timeout,
  skip,
  unknown;

  static ResultType fromString(String value) {
    return ResultType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ResultType.unknown,
    );
  }
}

/// Test fixture definition.
class TestFixture {
  /// Fixture name.
  final String name;

  /// Fixture data.
  final dynamic data;

  /// Factory expression.
  final String? factory;

  const TestFixture({
    required this.name,
    this.data,
    this.factory,
  });

  factory TestFixture.fromJson(Map<String, dynamic> json) {
    return TestFixture(
      name: json['name'] as String? ?? '',
      data: json['data'],
      factory: json['factory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (data != null) 'data': data,
      if (factory != null) 'factory': factory,
    };
  }
}

/// Global test configuration.
class TestConfig {
  /// Default timeout in milliseconds.
  final int defaultTimeoutMs;

  /// Parallel execution.
  final bool parallel;

  /// Maximum parallel tests.
  final int? maxParallel;

  /// Retry failed tests.
  final int retryCount;

  /// Coverage configuration.
  final CoverageConfig? coverage;

  /// Reporter configuration.
  final ReporterConfig? reporter;

  const TestConfig({
    this.defaultTimeoutMs = 30000,
    this.parallel = false,
    this.maxParallel,
    this.retryCount = 0,
    this.coverage,
    this.reporter,
  });

  factory TestConfig.fromJson(Map<String, dynamic> json) {
    return TestConfig(
      defaultTimeoutMs: json['defaultTimeoutMs'] as int? ?? 30000,
      parallel: json['parallel'] as bool? ?? false,
      maxParallel: json['maxParallel'] as int?,
      retryCount: json['retryCount'] as int? ?? 0,
      coverage: json['coverage'] != null
          ? CoverageConfig.fromJson(json['coverage'] as Map<String, dynamic>)
          : null,
      reporter: json['reporter'] != null
          ? ReporterConfig.fromJson(json['reporter'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultTimeoutMs': defaultTimeoutMs,
      if (parallel) 'parallel': parallel,
      if (maxParallel != null) 'maxParallel': maxParallel,
      if (retryCount > 0) 'retryCount': retryCount,
      if (coverage != null) 'coverage': coverage!.toJson(),
      if (reporter != null) 'reporter': reporter!.toJson(),
    };
  }
}

/// Coverage configuration.
class CoverageConfig {
  /// Enable coverage.
  final bool enabled;

  /// Include patterns.
  final List<String> include;

  /// Exclude patterns.
  final List<String> exclude;

  /// Minimum coverage threshold.
  final double? threshold;

  const CoverageConfig({
    this.enabled = false,
    this.include = const [],
    this.exclude = const [],
    this.threshold,
  });

  factory CoverageConfig.fromJson(Map<String, dynamic> json) {
    return CoverageConfig(
      enabled: json['enabled'] as bool? ?? false,
      include: (json['include'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      exclude: (json['exclude'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      threshold: (json['threshold'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (include.isNotEmpty) 'include': include,
      if (exclude.isNotEmpty) 'exclude': exclude,
      if (threshold != null) 'threshold': threshold,
    };
  }
}

/// Reporter configuration.
class ReporterConfig {
  /// Reporter type.
  final ReporterType type;

  /// Output path.
  final String? outputPath;

  /// Reporter options.
  final Map<String, dynamic> options;

  const ReporterConfig({
    this.type = ReporterType.console,
    this.outputPath,
    this.options = const {},
  });

  factory ReporterConfig.fromJson(Map<String, dynamic> json) {
    return ReporterConfig(
      type: ReporterType.fromString(json['type'] as String? ?? 'console'),
      outputPath: json['outputPath'] as String?,
      options: json['options'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (outputPath != null) 'outputPath': outputPath,
      if (options.isNotEmpty) 'options': options,
    };
  }
}

/// Reporter types.
enum ReporterType {
  console,
  json,
  junit,
  html,
  custom,
  unknown;

  static ReporterType fromString(String value) {
    return ReporterType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReporterType.unknown,
    );
  }
}
