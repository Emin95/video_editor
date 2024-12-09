import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/models/cover_data.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';

// Future<List<String>> generateThumbnails(String videoPath, int quantity) async {
//   final tempDir = (await getTemporaryDirectory()).path;

//   // Pass the required parameters to the isolate
//   return await compute(_isolateGenerateThumbnails, {
//     'videoPath': videoPath,
//     'quantity': quantity,
//     'tempDir': tempDir,
//   });
// }

Stream<List<File>> generateTrimThumbnails(
  String videoPath, {
  required int quantity,
}) async* {
  final tempDir = (await getTemporaryDirectory()).path;
  final thumbnails = <File>[];

  // Get video duration using FFmpeg
  final durationCommand = '-i "$videoPath" -hide_banner';
  final session = await FFmpegKit.execute(durationCommand);

  if (ReturnCode.isSuccess(await session.getReturnCode())) {
    final logs = await session.getOutput();
    final durationRegex = RegExp(r"Duration:\s(\d+):(\d+):(\d+)\.(\d+)");
    final match = durationRegex.firstMatch(logs ?? '');

    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final milliseconds = int.parse(match.group(4)!) * 10;

      final totalMilliseconds =
          (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds;
      final eachPart = totalMilliseconds ~/ quantity;

      for (int i = 0; i < quantity; i++) {
        final timeInMilliseconds = i * eachPart;
        final timeInSeconds = timeInMilliseconds ~/ 1000;
        final outputPath = '$tempDir/thumbnail_$i.jpg';

        final command =
            '-i "$videoPath" -ss $timeInSeconds -vframes 1 "$outputPath"';
        await FFmpegKit.execute(command);

        final file = File(outputPath);

        if (file.existsSync()) {
          thumbnails.add(file);
        }
      }
    }
  }

  yield thumbnails;
}

// Stream<List<Uint8List>> generateTrimThumbnails(
//   VideoEditorController controller, {
//   required int quantity,
// }) async* {
//   final String path = controller.file.path;
//   final double eachPart = controller.videoDuration.inMilliseconds / quantity;
//   List<Uint8List> byteList = [];

//   for (int i = 1; i <= quantity; i++) {
//     try {
//       final Uint8List? bytes = await VideoThumbnail.thumbnailData(
//         imageFormat: ImageFormat.JPEG,
//         video: path,
//         timeMs: (eachPart * i).toInt(),
//         quality: controller.trimThumbnailsQuality,
//       );
//       if (bytes != null) {
//         byteList.add(bytes);
//       }
//     } catch (e) {
//       debugPrint(e.toString());
//     }

//     yield byteList;
//   }
// }

Stream<List<CoverData>> generateCoverThumbnails(
  VideoEditorController controller, {
  required int quantity,
}) async* {
  final int duration = controller.isTrimmed
      ? controller.trimmedDuration.inMilliseconds
      : controller.videoDuration.inMilliseconds;
  final double eachPart = duration / quantity;
  List<CoverData> dataList = [];

  for (int i = 0; i < quantity; i++) {
    try {
      final CoverData data = await generateSingleCoverThumbnail(
        controller.file.path,
        timeMs: (controller.isTrimmed
                ? (eachPart * i) + controller.startTrim.inMilliseconds
                : (eachPart * i))
            .toInt(),
        quality: controller.coverThumbnailsQuality,
      );

      if (data.file != null) {
        dataList.add(data);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    yield dataList;
  }
}

/// Generate a cover at [timeMs] in video
///
/// Returns a [CoverData] depending on [timeMs] milliseconds
// Future<CoverData> generateSingleCoverThumbnail(
//   String filePath, {
//   int timeMs = 0,
//   int quality = 10,
// }) async {
//   final Uint8List? thumbData = await VideoThumbnail.thumbnailData(
//     imageFormat: ImageFormat.JPEG,
//     video: filePath,
//     timeMs: timeMs,
//     quality: quality,
//   );

//   return CoverData(thumbData: thumbData, timeMs: timeMs);
// }

Future<CoverData> generateSingleCoverThumbnail(
  String videoPath, {
  int timeMs = 0,
  int quality = 10,
}) async {
  final tempDir = (await getTemporaryDirectory()).path;

  final outputPath =
      '$tempDir/thumbnail_${videoPath.split(Platform.pathSeparator).last}}.jpg';

  final command = '-i "$videoPath" -ss $timeMs -vframes 1 "$outputPath"';
  await FFmpegKit.execute(command);

  final file = File(outputPath);

  return CoverData(file: file, timeMs: timeMs);
}
