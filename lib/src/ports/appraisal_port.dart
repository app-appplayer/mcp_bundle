/// Appraisal Port - Profile dimension appraisal.
///
/// Capability-named port for appraising profile dimensions against a
/// context. This is the **standard abstract contract** per REDESIGN-PLAN.md
/// §3.4 Phase 1a (0.1.0-a2). Rich implementations (e.g., `mcp_profile`'s
/// internal `StandardAppraisalPort`) conform to this interface while
/// retaining their internal computation types.
///
/// Provider: `mcp_profile`.
library;

import '../types/appraisal_result.dart';
import '../types/period.dart';

/// Port for appraisal operations over profile dimensions.
///
/// Adapters compute metric values for requested dimensions over the
/// supplied context and return a [AppraisalResult]. Historical lookup is
/// optional (default throws [UnsupportedError]).
abstract class AppraisalPort {
  /// Appraise the requested dimensions against [context].
  ///
  /// [dimensions] is the list of dimension identifiers (metric IDs or
  /// aggregate dimension names) that should be computed. [context] is an
  /// opaque map supplied by the caller — its schema is contract-free to
  /// preserve SSOT separation (the caller's own spec defines it).
  Future<AppraisalResult> appraise(
    List<String> dimensions,
    Map<String, dynamic> context,
  );

  /// Retrieve historical appraisal results for [profileId] within [period].
  ///
  /// Optional. Default throws [UnsupportedError].
  Future<List<AppraisalResult>> getHistory(
    String profileId,
    Period period,
  ) async {
    throw UnsupportedError(
      'AppraisalPort.getHistory is not supported by this provider',
    );
  }
}

/// Stub appraisal port for testing.
class StubAppraisalPort implements AppraisalPort {
  const StubAppraisalPort();

  @override
  Future<AppraisalResult> appraise(
    List<String> dimensions,
    Map<String, dynamic> context,
  ) async {
    return AppraisalResult.empty(
      profileId: context['profileId'] as String? ?? 'stub',
    );
  }

  @override
  Future<List<AppraisalResult>> getHistory(
    String profileId,
    Period period,
  ) async {
    return [];
  }
}
