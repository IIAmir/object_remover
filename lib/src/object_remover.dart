import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:object_remover/object_remover.dart';

class ObjectRemover {
  static const MethodChannel _channel = MethodChannel(
    'methodChannel.objectRemover',
  );

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
