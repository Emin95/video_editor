// import 'dart:developer';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:video_editor/video_editing_page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   Future<void> _incrementCounter() async {
//     final video = await FilePicker.platform.pickFiles(type: FileType.video);

//     if (video != null && mounted) {
//       Navigator.of(context).push(MaterialPageRoute(
//         builder: (context) {
//           return VideoEditingPage(
//             videoPath: video.files.first.xFile.path,
//             maxDuration: const Duration(seconds: 60),
//             onCompleted: (file) {
//               log("${file.lengthSync()}");
//             },
//           );
//         },
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text('You have pushed the button this many times:'),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
