# Object Remover (IOS)

<img src="https://i.ibb.co/K9Bs4Wp/befor-after.png"/>

## Overview

Object Remover is a powerful image processing library designed specifically for iOS devices.
It provides developers with an intuitive interface to seamlessly remove objects from images,
enhancing user experience and enabling a wide range of creative possibilities.

## System requirements

- iOS: 15+

## Features

- Offline Support: Remove Objects without internet for quick performance offline.
- Remove Object and Person: Easily remove object and person from both objects and people.

## Getting started

Add the plugin package to the `pubspec.yaml` file in your project:

```yaml
dependencies:
  object_remover: ^0.0.1
```

Install the new dependency:

```sh
flutter pub get
```

Call the `removeObject` function in your code:

```dart
Future<ObjectRemoverResultModel> removeObject() async {
  ObjectRemoverResultModel objectRemoverResultModel = await ObjectRemover.removeObject(
      defaultImageUint: // Provide original image data ,
      maskedImageUint: // Provide mask image data ,
  );
  return objectRemoverResultModel;
}
```

## Example

Explore our [Example Project](./example) to see how the Object Remover SDK can be used in a Flutter
application.

## License Terms

This library is provided under the [Apache License](LICENSE).
