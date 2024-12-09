import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';

class VideoEditingPage extends StatefulWidget {
  const VideoEditingPage({
    super.key,
    required this.videoPath,
    required this.maxDuration,
    required this.onCompleted,
  });

  final String videoPath;
  final Duration maxDuration;

  final void Function(File file) onCompleted;

  @override
  State<VideoEditingPage> createState() => _VideoEditingPageState();
}

class _VideoEditingPageState extends State<VideoEditingPage> {
  final _exportingProgress = ValueNotifier<double>(0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late final VideoEditorController _editorController;

  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();

    _initController();
  }

  Future<void> _initController() async {
    _editorController = VideoEditorController.file(
      File(widget.videoPath),
      maxDuration: widget.maxDuration,
    );

    await _editorController.initialize(aspectRatio: 9 / 16);

    setState(() {
      _controllerInitialized = true;
    });
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();

    _editorController.dispose();
    super.dispose();
  }

  Future<FFmpegSession> runFFmpegCommand(
    FFmpegVideoEditorExecute execute, {
    required void Function(File file) onCompleted,
    void Function(Object, StackTrace)? onError,
    void Function(Statistics)? onProgress,
  }) {
    log('FFmpeg start process with command = ${execute.command}');
    return FFmpegKit.executeAsync(
      execute.command,
      (session) async {
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final code = await session.getReturnCode();

        if (ReturnCode.isSuccess(code)) {
          onCompleted(File(execute.outputPath));
        } else {
          if (onError != null) {
            onError(
              Exception(
                '''FFmpeg process exited with state $state and return code $code.\n${await session.getOutput()}''',
              ),
              StackTrace.current,
            );
          }
          return;
        }
      },
      null,
      onProgress,
    );
  }

  Future<void> _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    final config = VideoFFmpegVideoEditorConfig(_editorController);

    await runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value = config.getFFmpegProgress(
          stats.getTime().toInt(),
        );
      },
      onError: (e, s) {
        log('${e.toString()} :(');
      },
      onCompleted: (file) {
        _isExporting.value = false;

        print("${file.lengthSync()}");

        if (!mounted) return;

        widget.onCompleted(file);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              // GoRouter.of(context).pop();
            },
            splashRadius: 24,
            icon: const Icon(Icons.close),
          ),
          actions: [
            IconButton(
              onPressed: _exportVideo,
              splashRadius: 24,
              icon: const Icon(Icons.done),
            ),
          ],
        ),
        body: _controllerInitialized
            ? SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CropGridViewer.preview(
                                      controller: _editorController,
                                    ),
                                    AnimatedBuilder(
                                      animation: _editorController.video,
                                      builder: (_, __) {
                                        return AnimatedOpacity(
                                          opacity: !_editorController.isPlaying
                                              ? 0
                                              : 1,
                                          duration: kThemeAnimationDuration,
                                          child: GestureDetector(
                                            onTap: _editorController.video.play,
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 200,
                                margin: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: _trimSlider(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _isExporting,
                                builder: (_, bool export, child) {
                                  return AnimatedSize(
                                    duration: kThemeAnimationDuration,
                                    child: export ? child : null,
                                  );
                                },
                                child: AlertDialog(
                                  title: ValueListenableBuilder(
                                    valueListenable: _exportingProgress,
                                    builder: (_, double value, __) {
                                      final message =
                                          "Exporting: ${(value * 100).ceil()}";

                                      // final message =
                                      //     context.l10n.exportingVideoWithValue(
                                      //   (value * 100).ceil(),
                                      // );

                                      return Text(
                                        message,
                                        style: const TextStyle(fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _editorController,
          _editorController.video,
        ]),
        builder: (_, __) {
          final duration = _editorController.videoDuration.inSeconds;
          final pos = _editorController.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(
              children: [
                Text(Duration(seconds: pos.toInt()).toMinutesSeconds()),
                const Expanded(child: SizedBox()),
                AnimatedOpacity(
                  opacity: _editorController.isTrimming ? 1 : 0,
                  duration: kThemeAnimationDuration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_editorController.startTrim.toMinutesSeconds()),
                      const SizedBox(width: 10),
                      Text(_editorController.endTrim.toMinutesSeconds()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      Container(
        width: MediaQuery.sizeOf(context).width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _editorController,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _editorController,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      ),
    ];
  }
}

extension DurationExtensions on Duration {
  String toMinutesSeconds() {
    final twoDigitSeconds = _toTwoDigits(inSeconds.remainder(60));

    return '${_toTwoDigits(inMinutes)}:$twoDigitSeconds';
  }

  String toHoursMinutesSeconds() {
    final twoDigitMinutes = _toTwoDigits(inMinutes.remainder(60));
    final twoDigitSeconds = _toTwoDigits(inSeconds.remainder(60));
    return '${_toTwoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  String _toTwoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
