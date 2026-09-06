import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// 视频保存服务 - 负责将当前正在播放的视频保存到本地
/// 通过调用原生层的 crypto_stream API 来读取解密后的视频数据
class VideoSaveService {
  static const _channel = MethodChannel('shortplay/video_save');

  /// 保存当前正在播放的视频到本地文件
  /// 
  /// [cdnUrl]: CDN视频地址
  /// [keyHex]: 加密密钥（32位十六进制字符串），为空表示未加密
  /// [dramaName]: 剧名
  /// [episodeName]: 集名（如："第1集" 或 "1"）
  /// 
  /// 返回保存成功的文件路径，失败返回 null
  static Future<String?> saveVideo({
    required String cdnUrl,
    required String keyHex,
    required String dramaName,
    required String episodeName,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('saveVideo', {
        'cdnUrl': cdnUrl,
        'keyHex': keyHex,
        'dramaName': dramaName,
        'episodeName': episodeName,
      });
      return result;
    } on PlatformException catch (e) {
      print('保存视频失败: ${e.message}');
      return null;
    }
  }

  /// 获取已保存的视频列表
  static Future<List<String>> getSavedVideos() async {
    try {
      final result = await _channel.invokeListMethod<String>('getSavedVideos');
      return result ?? [];
    } on PlatformException catch (e) {
      print('获取保存的视频列表失败: ${e.message}');
      return [];
    }
  }

  /// 删除已保存的视频
  static Future<bool> deleteVideo(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteVideo', {
        'filePath': filePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('删除视频失败: ${e.message}');
      return false;
    }
  }

  /// 获取视频文件大小（字节）
  static Future<int> getVideoFileSize(String filePath) async {
    try {
      final result = await _channel.invokeMethod<int>('getVideoFileSize', {
        'filePath': filePath,
      });
      return result ?? 0;
    } on PlatformException catch (e) {
      print('获取视频文件大小失败: ${e.message}');
      return 0;
    }
  }

  /// 获取保存视频的目录路径
  static Future<String> getSaveDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/SavedVideos';
  }

  /// 获取格式化的文件大小字符串
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length / 3).floor();
    return ((bytes / (1 << (i * 10))).toStringAsFixed(2)) + " ${suffixes[i]}";
  }
}
