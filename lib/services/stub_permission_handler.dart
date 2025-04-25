// Stub implementation for web platform
enum PermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  permanentlyDenied,
}

class Permission {
  static final Permission notification = Permission._();
  
  Permission._();
  
  Future<bool> get isDenied async => false;
  Future<PermissionStatus> request() async => PermissionStatus.granted;
}