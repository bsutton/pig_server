import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart';

import 'backup_provider.dart';

/// All photos are stored under this path in the zip file
const zipPhotoRoot = 'photos/';

Future<void> zipBackup(
    {required BackupProvider provider,
    required String pathToZip,
    required String pathToBackupFile,
    required bool includePhotos}) async {
  // Set up communication channels
  final receivePort = ReceivePort();
  final errorPort = ReceivePort();
  final exitPort = ReceivePort();

  // Start the zipping isolate
  await Isolate.spawn<_ZipParams>(
    _zipFiles,
    _ZipParams(
      sendPort: receivePort.sendPort,
      pathToZip: pathToZip,
      pathToBackupFile: pathToBackupFile,
      progressStageStart: 3,
      progressStageEnd: 5,
    ),
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );

  // Listen for progress updates from the isolate
  final completer = Completer<void>();
  errorPort.listen((error) {
    completer.completeError(error as Object);
  });
  exitPort.listen((message) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });
  receivePort.listen((message) {
    if (message is ProgressUpdate) {
      provider.emitProgress(
        message.stageDescription,
        message.stageNo,
        message.stageCount,
      );
    }
  });

  // Wait for the isolate to finish
  await completer.future;

  receivePort.close();
  errorPort.close();
  exitPort.close();
}

// _ZipParams class

// _zipFiles function
Future<void> _zipFiles(_ZipParams params) async {
  final encoder = ZipFileEncoder();
  final sendPort = params.sendPort;

  try {
    encoder.create(params.pathToZip);

    // Emit progress: Zipping database
    sendPort.send(ProgressUpdate('Zipping database ${params.pathToBackupFile}',
        params.progressStageStart, params.progressStageEnd));

    await encoder.addFile(File(params.pathToBackupFile));

    await encoder.close();

    // Notify completion
    sendPort.send(ProgressUpdate(
        'Zipping completed', params.progressStageEnd, params.progressStageEnd));
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    // Send error back to the main isolate
    sendPort.send(ProgressUpdate('Error during zipping: $e',
        params.progressStageEnd, params.progressStageEnd));
  }
}

Future<String?> extractFiles(BackupProvider provider, File backupFile,
    String tmpDir, int stageNo, int stageCount) async {
  final encoder = ZipDecoder();
  String? dbPath;
  // Extract the ZIP file contents to a temporary directory
  final archive = encoder.decodeBuffer(InputFileStream(backupFile.path));

  const restored = 0;

  for (final file in archive) {
    final filename = file.name;
    final filePath = join(tmpDir, filename);

    provider.emitProgress(
        'Restoring  $restored/${archive.length}', stageNo, stageCount);

    if (file.isFile) {
      // If the file is the database, extract it
      // to a temp dir and return the path.
      if (filename.endsWith('.db')) {
        dbPath = filePath;
        await _expandZippedFileToDisk(filePath, file);
      }
    }
  }

  return dbPath;
}

Future<void> _expandZippedFileToDisk(
    String photoDestPath, ArchiveFile file) async {
  File(photoDestPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(file.content as List<int>);
}

class _ZipParams {
  _ZipParams({
    required this.sendPort,
    required this.pathToZip,
    required this.pathToBackupFile,
    required this.progressStageStart,
    required this.progressStageEnd,
  });
  final SendPort sendPort;
  final String pathToZip;
  final String pathToBackupFile;
  final int progressStageStart;
  final int progressStageEnd;
}
