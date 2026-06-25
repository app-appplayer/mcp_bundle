/// Datastore port contracts — the data-interface layer.
///
/// A datastore is a persistent, addressable store queried / CRUD-ed over an
/// address (a path, a table, a key). Every backend implements
/// [DatasourceAdapter]; the two families — filesystem and database — extend
/// [FsAdapter] / [DbAdapter] with their own verbs (a single forced verb set
/// would leak over byte-paths versus SQL rows). Implementations live in the
/// datastore capability packages.
library;

/// Raised when an adapter operation is rejected for a structural reason
/// (e.g. a path that escapes the allowed root). Authorization denials are a
/// separate, policy-layer concern.
class DatastoreException implements Exception {
  const DatastoreException(this.message);
  final String message;
  @override
  String toString() => 'DatastoreException: $message';
}

/// One entry from a filesystem listing.
class FsEntry {
  const FsEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'path': path,
        'isDirectory': isDirectory,
        if (size != null) 'size': size,
      };
}

/// File metadata (`fs.stat`).
class FsStat {
  const FsStat({
    required this.path,
    required this.exists,
    required this.isDirectory,
    this.size,
    this.modified,
  });

  final String path;
  final bool exists;
  final bool isDirectory;
  final int? size;
  final DateTime? modified;

  Map<String, Object?> toJson() => <String, Object?>{
        'path': path,
        'exists': exists,
        'isDirectory': isDirectory,
        if (size != null) 'size': size,
        if (modified != null) 'modified': modified!.toIso8601String(),
      };
}

/// A single database row.
typedef DbRow = Map<String, Object?>;

/// One statement within a [DbAdapter.tx] batch.
class DbStatement {
  const DbStatement(this.statement, {this.params = const <Object?>[]});
  final String statement;
  final List<Object?> params;
}

/// Base contract for any datastore backend.
abstract class DatasourceAdapter {
  /// Namespace-local instance id (e.g. `workspace`, `main_db`).
  String get id;

  /// Backend family — `fs` | `sql` | `nosql` | ….
  String get kind;

  /// Open / connect. No-op for stateless backends.
  Future<void> open();

  /// Release resources / close connections.
  Future<void> close();
}

/// Filesystem-family adapter — the `fs.*` verbs.
abstract class FsAdapter extends DatasourceAdapter {
  @override
  String get kind => 'fs';

  Future<String> readText(String path);
  Future<List<int>> readBytes(String path);
  Future<void> write(String path,
      {String? text, List<int>? bytes, bool createParents = true});
  Future<List<FsEntry>> list(String path, {bool recursive = false});
  Future<List<String>> glob(String pattern);
  Future<FsStat> stat(String path);

  /// Replace [oldString] with [newString]; returns the number of
  /// replacements (0 when not found, so callers can detect a no-op).
  Future<int> edit(String path,
      {required String oldString, required String newString, bool all = false});

  Future<void> mkdir(String path, {bool recursive = true});
  Future<void> move(String from, String to);
  Future<void> remove(String path, {bool recursive = false});
}

/// Database-family adapter — the `db.*` verbs. Concrete backends ship as
/// separate adapter packages.
abstract class DbAdapter extends DatasourceAdapter {
  @override
  String get kind => 'sql';

  Future<List<DbRow>> query(String statement,
      {List<Object?> params = const <Object?>[]});

  /// Execute a non-query statement; returns affected row count.
  Future<int> exec(String statement,
      {List<Object?> params = const <Object?>[]});

  /// Run [statements] in a single transaction.
  Future<void> tx(List<DbStatement> statements);
}
