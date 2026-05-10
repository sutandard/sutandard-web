// Fetches the OpenAPI schema from the Sutandard backend and saves it under docs/.
// Also reports drift between the schema and lib/core/constants/api_constants.dart.
//
// Usage:
//   dart run tool/sync_api.dart
//   API_URL=http://127.0.0.1:8000 dart run tool/sync_api.dart
//
// Exit codes:
//   0  ok
//   1  drift detected (schema and api_constants.dart disagree)
//   2  network/parse failure

import 'dart:convert';
import 'dart:io';

const _defaultApiUrl = 'https://api.sutandard.kr';
const _yamlPath = 'docs/openapi.yaml';
const _jsonPath = 'docs/openapi.json';
const _constantsPath = 'lib/core/constants/api_constants.dart';

Future<void> main() async {
  final apiUrl =
      (Platform.environment['API_URL'] ?? _defaultApiUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      );
  stdout.writeln('Fetching OpenAPI schema from $apiUrl');

  Directory('docs').createSync(recursive: true);
  Directory('tool').createSync(recursive: true);

  final String yaml;
  final String json;
  try {
    yaml = await _httpGet('$apiUrl/api/schema/');
    json = await _httpGet('$apiUrl/api/schema/?format=json');
  } catch (e) {
    stderr.writeln('Fetch failed: $e');
    exit(2);
  }

  File(_yamlPath).writeAsStringSync(yaml);
  stdout.writeln('  -> $_yamlPath (${yaml.length} bytes)');
  File(_jsonPath).writeAsStringSync(json);
  stdout.writeln('  -> $_jsonPath (${json.length} bytes)');

  final Map<String, dynamic> spec;
  try {
    spec = jsonDecode(json) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('Parse failed: $e');
    exit(2);
  }

  final info = (spec['info'] as Map?)?.cast<String, dynamic>() ?? const {};
  final paths = (spec['paths'] as Map?)?.cast<String, dynamic>() ?? const {};
  stdout.writeln(
    'Schema: ${info['title']} v${info['version']}, ${paths.length} paths',
  );

  final drift = _checkDrift(paths.keys.cast<String>().toSet());
  if (drift) exitCode = 1;
}

Future<String> _httpGet(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    req.headers.add(HttpHeaders.acceptHeader, '*/*');
    final res = await req.close();
    if (res.statusCode != 200) {
      throw 'GET $url -> ${res.statusCode}';
    }
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

bool _checkDrift(Set<String> schemaPaths) {
  final dartFile = File(_constantsPath);
  if (!dartFile.existsSync()) {
    stdout.writeln('Drift check skipped: $_constantsPath not found');
    return false;
  }
  final content = dartFile.readAsStringSync();
  final dartPaths = RegExp(r"'(/api/v1/[^']+)'")
      .allMatches(content)
      .map((m) => _normalize(m.group(1)!))
      .toSet();

  final normalizedSchema = schemaPaths.map(_normalize).toSet();
  final missingInDart = normalizedSchema.difference(dartPaths);
  final stale = dartPaths.difference(normalizedSchema);

  if (missingInDart.isEmpty && stale.isEmpty) {
    stdout.writeln('Drift: api_constants.dart matches schema (no changes).');
    return false;
  }
  stdout.writeln('Drift detected:');
  if (missingInDart.isNotEmpty) {
    stdout.writeln('  Missing in api_constants.dart:');
    final list = missingInDart.toList()..sort();
    for (final p in list) stdout.writeln('    + $p');
  }
  if (stale.isNotEmpty) {
    stdout.writeln('  Stale in api_constants.dart (not in schema):');
    final list = stale.toList()..sort();
    for (final p in list) stdout.writeln('    - $p');
  }
  return true;
}

// Normalize so that `{id}`, `{course_code}`, `$id`, `${id}`, `$courseCode` all
// collapse to `{}` for comparison.
String _normalize(String path) {
  var p = path.replaceAll(RegExp(r'\$\{[^}]+\}'), '{}');
  p = p.replaceAll(RegExp(r'\{[^}]+\}'), '{}');
  p = p.replaceAll(RegExp(r'\$\w+'), '{}');
  return p;
}
