import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  // Yêu cầu quyền tổng hợp
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        var status = await Permission.audio.status;
        if (status.isGranted) return true;
        status = await Permission.audio.request();
        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (status.isGranted) return true;
        status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  // Giữ lại các hàm cũ để không làm lỗi HomeScreen
  Future<bool> requestStoragePermission() => requestPermissions();
  Future<bool> requestAudioPermission() => requestPermissions();

  // Kiểm tra trạng thái quyền hiện tại
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.audio.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  // Hàm phụ để kiểm tra phiên bản Android (không cần thư viện ngoài)
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Cách đơn giản nhất để check API level mà không cần device_info_plus
    // là thử gọi một permission chỉ có ở API 33+
    return await Permission.audio.status != PermissionStatus.restricted;
  }
}