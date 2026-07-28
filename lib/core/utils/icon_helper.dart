import 'package:flutter/material.dart';

class IconHelper {
  static IconData getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'phone_android':
      case 'smartphone':
        return Icons.phone_android;
      case 'web':
      case 'computer':
        return Icons.web;
      case 'analytics':
      case 'trending_up':
        return Icons.analytics_outlined;
      case 'cloud_queue':
      case 'cloud':
        return Icons.cloud_queue;
      case 'code':
        return Icons.code;
      case 'school':
      case 'class':
        return Icons.school_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'quiz':
      case 'help_outline':
        return Icons.help_outline;
      case 'security':
        return Icons.security;
      case 'database':
      case 'storage':
        return Icons.storage;
      default:
        return Icons.help_outline;
    }
  }
}
