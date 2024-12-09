import 'dart:io';

class CoverData {
  const CoverData({
    this.file,
    required this.timeMs,
  });
  final File? file;
  final int timeMs;

  bool sameTime(CoverData cover2) => timeMs == cover2.timeMs;
}
