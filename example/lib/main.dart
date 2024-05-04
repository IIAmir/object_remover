import 'dart:typed_data';
import 'dart:ui';

import 'package:finger_painter/finger_painter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_remover/object_remover.dart';

enum ProcessStatus {
  loading,
  success,
  failure,
  none,
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Remover',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Object Remover'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker picker = ImagePicker();
  late GlobalKey globalKey;
  late PainterController painterController;

  ProcessStatus status = ProcessStatus.none;
  String? message;
  Uint8List? imageBytes;
  Uint8List? maskedImageUint;
  bool objectRemoved = false;

  @override
  void initState() {
    super.initState();
    globalKey = GlobalKey();
    painterController = PainterController()
      ..setPenType(PenType.paintbrush)
      ..setStrokeColor(Colors.black)
      ..setMinStrokeWidth(20)
      ..setMaxStrokeWidth(20)
      ..setBlendMode(BlendMode.srcOver);
  }

  _resetAll() {
    objectRemoved = false;
    maskedImageUint = null;
    imageBytes = null;
    status = ProcessStatus.none;
    painterController.clearContent();
    setState(() {});
  }

  Future<void> _pickPhoto() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        status = ProcessStatus.loading;
      });
      Uint8List defaultImageUint = await pickedFile.readAsBytes();
      imageBytes = defaultImageUint;
      status = ProcessStatus.success;
      setState(() {});
    }
  }

  Future<void> _removeObject() async {
    maskedImageUint = painterController.getImageBytes();
    setState(() {});

    Future.delayed(const Duration(seconds: 1), () async {
      final RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      ObjectRemoverResultModel localRembgResultModel = await ObjectRemover.removeObject(
        defaultImageUint: imageBytes!,
        maskedImageUint: byteData!.buffer.asUint8List(),
      );
      message = localRembgResultModel.errorMessage;
      if (localRembgResultModel.status == 1) {
        setState(() {
          objectRemoved = true;
          imageBytes = Uint8List.fromList(localRembgResultModel.imageBytes!);
          status = ProcessStatus.success;
        });
      } else {
        setState(() {
          status = ProcessStatus.failure;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (imageBytes != null && status == ProcessStatus.success)
              RepaintBoundary(
                key: globalKey,
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.passthrough,
                  children: [
                    if (maskedImageUint != null) ...[
                      SizedBox(
                        height: screenSize.width * 0.8,
                        child: Image.memory(imageBytes!),
                      ),
                    ] else ...[
                      SizedBox(
                        height: screenSize.width * 0.8,
                        child: Painter(
                          controller: painterController,
                          child: Image.memory(imageBytes!),
                        ),
                      ),
                    ],
                    if (maskedImageUint != null && !objectRemoved)
                      SizedBox(
                        height: screenSize.width * 0.8,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcOut,
                          ),
                          child: Image.memory(
                            maskedImageUint!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (status == ProcessStatus.loading)
              const CupertinoActivityIndicator(
                color: Colors.black,
              ),
            if (status == ProcessStatus.failure)
              Text(
                message ?? 'Failed to process image',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            if (status == ProcessStatus.none)
              const Text(
                'Select your image',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: objectRemoved
            ? _resetAll
            : imageBytes != null
                ? _removeObject
                : _pickPhoto,
        child: Icon(
          objectRemoved
              ? Icons.restart_alt_rounded
              : imageBytes != null
                  ? Icons.check
                  : Icons.add_photo_alternate_outlined,
        ),
      ),
    );
  }
}
