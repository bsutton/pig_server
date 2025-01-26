import 'package:dcli/dcli.dart';

import '../../dcli/resource/generated/resource_registry.g.dart';
import 'script_source.dart';

class ResourceScriptSource implements ScriptSource {
  ResourceScriptSource();
  @override
  Future<String> loadSQL(PackedResource packedScript) async =>
      withTempFileAsync((unpackedFile) async {
        packedScript.unpack(unpackedFile);
        return read(unpackedFile).toParagraph();
      });

  @override

  /// Returns a list of all resources under the 'upgrade_scripts' directory.
  Future<List<PackedResource>> upgradeScripts() async {
    final upgradeScripts = <PackedResource>[];
    for (final entry in ResourceRegistry.resources.entries) {
      if (entry.key.startsWith('sql/upgrade_scripts/')) {
        upgradeScripts.add(entry.value);
      }
    }
    return upgradeScripts;
  }
}
