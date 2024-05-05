import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:object_remover/object_remover.dart';

class ObjectRemover {
  static const MethodChannel _channel = MethodChannel(
    'methodChannel.objectRemover',
  );

  /// [defaultImageUint] Original image without any editing
  /// [maskedImageUint] represents a mask image where specific pixels indicate
  /// the areas of the image to be removed. The object removal process will
  /// use this mask to identify which parts of the image should be retained
  /// and which should be removed.
  static Future<ObjectRemoverResultModel> removeObject({
    required Uint8List defaultImageUint,
    required Uint8List maskedImageUint,
  }) async {
    Map<dynamic, dynamic> methodChannelResult = await _channel.invokeMethod(
      'removeObject',
      {
        'defaultImage': defaultImageUint,
        'maskedImage': maskedImageUint,
      },
    );
    if (kDebugMode) {
      print(methodChannelResult);
    }
    return ObjectRemoverResultModel.fromMap(
      methodChannelResult,
    );
  }
}
