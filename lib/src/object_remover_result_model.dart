class ObjectRemoverResultModel {
  /// The [status] property indicates the outcome of the operation:
  /// - 1 for success
  /// - 0 for failure
  /// The [imageBytes] property contains the bytes of the resulting image after object removing.
  /// The [errorMessage] property holds an error message in case the operation failed.
  final int status;
  final List<int>? imageBytes;
  final String? errorMessage;

  ObjectRemoverResultModel({
    required this.status,
    required this.imageBytes,
    required this.errorMessage,
  });

  factory ObjectRemoverResultModel.fromMap(
    Map<dynamic, dynamic> result,
  ) =>
      ObjectRemoverResultModel(
        status: result['status'],
        imageBytes: (result['imageBytes'] as List<dynamic>?)?.cast<int>(),
        errorMessage: result['message'],
      );
}
