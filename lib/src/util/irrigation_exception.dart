/// A custom exception class for irrigation-related errors.
class IrrigationException implements Exception {
  /// Creates an [IrrigationException] with an optional underlying [cause].
  IrrigationException([this.cause]);

  /// The underlying exception that caused this error.
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'IrrigationException: $cause';
    }
    return 'IrrigationException';
  }
}

class BackupException extends IrrigationException {
  BackupException(super.cause);
}

class InvoiceException extends IrrigationException {
  InvoiceException(super.cause);
}

class XeroException extends IrrigationException {
  XeroException(super.cause);
}

class InvalidPathException extends IrrigationException {
  InvalidPathException(super.cause);
}
