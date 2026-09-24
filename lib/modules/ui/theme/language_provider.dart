import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Supported application languages.
enum AppLanguage {
  vi('VI', 'Tiếng Việt', '🇻🇳'),
  en('EN', 'English', '🇬🇧'),
  zh('ZH', '中文', '🇨🇳');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'vi':
        return AppLanguage.vi;
      case 'en':
        return AppLanguage.en;
      case 'zh':
      case 'cn':
        return AppLanguage.zh;
      default:
        return AppLanguage.vi;
    }
  }
}

/// Language and localization provider for instant 1-click language switching.
class LanguageProvider extends ChangeNotifier {
  late AppLanguage _currentLanguage;

  LanguageProvider({String? initialCode}) {
    if (initialCode != null && initialCode.isNotEmpty) {
      _currentLanguage = AppLanguage.fromCode(initialCode);
    } else {
      _currentLanguage = _detectSystemLanguage();
    }
  }

  AppLanguage get currentLanguage => _currentLanguage;

  static AppLanguage _detectSystemLanguage() {
    try {
      final locale = Platform.localeName.toLowerCase();
      if (locale.startsWith('zh') || locale.contains('cn')) {
        return AppLanguage.zh;
      } else if (locale.startsWith('en')) {
        return AppLanguage.en;
      } else if (locale.startsWith('vi')) {
        return AppLanguage.vi;
      }
    } catch (_) {}
    return AppLanguage.vi;
  }

  /// Cycles to the next language: VI -> EN -> ZH -> VI
  void cycleLanguage() {
    switch (_currentLanguage) {
      case AppLanguage.vi:
        _currentLanguage = AppLanguage.en;
        break;
      case AppLanguage.en:
        _currentLanguage = AppLanguage.zh;
        break;
      case AppLanguage.zh:
        _currentLanguage = AppLanguage.vi;
        break;
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  void setLanguageCode(String code) {
    final lang = AppLanguage.fromCode(code);
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  void syncWithConfig(String code) {
    final lang = AppLanguage.fromCode(code);
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
    }
  }

  /// Localized Tab Labels for JA_Route
  List<String> get tabLabels {
    switch (_currentLanguage) {
      case AppLanguage.vi:
        return const [
          'Tổng quan',
          'Cấu hình',
          'Chẩn đoán',
          'Nhật ký',
          'Thông tin',
        ];
      case AppLanguage.en:
        return const ['Overview', 'Config', 'Diagnostics', 'Logs', 'About'];
      case AppLanguage.zh:
        return const ['概览', '配置', '诊断', '日志', '关于'];
    }
  }

  /// Localized String dictionary lookup with parameter substitution
  String t(String key, [List<dynamic>? args]) {
    final entry = _translations[key];
    if (entry == null) return key;
    final langKey = _currentLanguage.code.toLowerCase();
    var str =
        entry[langKey] ??
        (langKey == 'zh' ? entry['cn'] : null) ??
        entry['vi'] ??
        key;
    if (args != null && args.isNotEmpty) {
      for (final arg in args) {
        if (str.contains('%s')) {
          str = str.replaceFirst('%s', arg.toString());
        } else if (str.contains('%d')) {
          str = str.replaceFirst('%d', arg.toString());
        }
      }
    }
    return str;
  }

  /// Backward-compatible alias for shared JA modules
  String tr(String key, [List<dynamic>? args]) => t(key, args);

  static const Map<String, Map<String, String>> _translations = {
    'perf_tooltip': {
      'vi': 'Chế độ đồ họa & Hiệu năng máy',
      'en': 'Graphic Tier & Hardware Profile',
      'cn': '图形档位与硬件配置',
    },
    'lang_tooltip': {
      'vi': 'Chuyển ngôn ngữ nhanh (EN/VI/CN)',
      'en': 'Quick Language Switch (EN/VI/CN)',
      'cn': '快速切换语言 (EN/VI/CN)',
    },
    'theme_tooltip': {
      'vi': 'Chuyển giao diện Sáng / Tối',
      'en': 'Toggle Light / Dark Theme',
      'cn': '切换深色/浅色主题',
    },
    'settings_tooltip': {
      'vi': 'Cài đặt hiệu ứng kính mờ',
      'en': 'Glass Tuning Settings',
      'cn': '毛玻璃微调设置',
    },
    'status_live': {
      'vi': 'DUAL ROUTE ACTIVE',
      'en': 'DUAL ROUTE ACTIVE',
      'cn': '双路由已激活',
    },
    'status_standby': {'vi': 'STANDBY', 'en': 'STANDBY', 'cn': '待机'},
    'status_fixing': {
      'vi': 'ĐANG TỐI ƯU...',
      'en': 'OPTIMIZING...',
      'cn': '正在优化...',
    },
    'status_ready': {'vi': 'SẴN SÀNG', 'en': 'READY', 'cn': '准备就绪'},
    'home_btn_fix': {'vi': 'BẮT ĐẦU FIX', 'en': 'START FIX', 'cn': '开始修复'},
    'lang_changed_msg': {
      'vi': '🌐 Đã chuyển ngôn ngữ: Tiếng Việt',
      'en': '🌐 Language switched: English',
      'cn': '🌐 语言已切换: 中文',
    },
    'settings_dialog_title': {
      'vi': 'Cài đặt Glassmorphism & Giao diện',
      'en': 'Glassmorphism & UI Settings',
      'cn': '毛玻璃效果与界面设置',
    },
    'settings_card_header': {
      'vi': 'Điều chỉnh Liquid Glass & Bento Card',
      'en': 'Liquid Glass & Bento Card Tuning',
      'cn': '液体玻璃与 Bento 卡片微调',
    },
    'settings_default': {'vi': 'Mặc định', 'en': 'Default', 'cn': '默认'},
    'settings_card_blur': {
      'vi': 'Độ mờ khối Bento (Card Blur)',
      'en': 'Bento Card Blur',
      'cn': 'Bento 卡片模糊度',
    },
    'settings_card_opacity': {
      'vi': 'Độ đục khối Bento (Card Opacity)',
      'en': 'Bento Card Opacity',
      'cn': 'Bento 卡片不透明度',
    },
    'settings_dialog_blur': {
      'vi': 'Độ mờ Hộp thoại (Dialog Blur)',
      'en': 'Dialog Blur',
      'cn': '弹窗模糊度',
    },
    'settings_dialog_opacity': {
      'vi': 'Độ đục Hộp thoại (Dialog Opacity)',
      'en': 'Dialog Opacity',
      'cn': '弹窗不透明度',
    },
    'settings_dropdown_blur': {
      'vi': 'Độ mờ Bảng chọn (Dropdown Blur)',
      'en': 'Dropdown Blur',
      'cn': '下拉菜单模糊度',
    },
    'settings_dropdown_opacity': {
      'vi': 'Độ đục Bảng chọn (Dropdown Opacity)',
      'en': 'Dropdown Opacity',
      'cn': '下拉菜单不透明度',
    },
    'action_cancel': {'vi': 'Hủy', 'en': 'Cancel', 'cn': '取消'},
    'action_save': {'vi': 'Lưu Cài Đặt', 'en': 'Save Settings', 'cn': '保存设置'},
    'theme_light': {'vi': 'Sáng', 'en': 'Light', 'cn': '浅色'},
    'theme_dark': {'vi': 'Tối', 'en': 'Dark', 'cn': '深色'},
    'settings_btn_label': {'vi': 'Cài đặt', 'en': 'Settings', 'cn': '设置'},
    'tab_settings_ui': {
      'vi': 'Kính mờ & Giao diện',
      'en': 'Glass & UI',
      'cn': '界面与毛玻璃',
    },
    'tab_ota_update': {
      'vi': 'Cập nhật OTA',
      'en': 'OTA Update',
      'cn': 'OTA 更新',
    },
    'tab_user_guide': {
      'vi': 'Hướng dẫn sử dụng',
      'en': 'User Guide',
      'cn': '使用指南',
    },
    'tab_about': {'vi': 'Giới thiệu', 'en': 'About', 'cn': '关于应用'},
    'badge_dual_routing': {
      'vi': 'ĐỊNH TUYẾN KÉP',
      'en': 'DUAL ROUTING',
      'cn': '双网路由',
    },
    'auto_heal_badge': {
      'vi': 'TỰ ĐỘNG KHẮC PHỤC KHI MẤT MẠNG',
      'en': 'AUTO HEAL ON NETWORK DROP',
      'cn': '断网自动修复',
    },
    'home_welcome': {
      'vi': 'Tối ưu hóa định tuyến mạng Dual-NIC',
      'en': 'Optimize Dual-NIC Network Routing',
      'cn': '优化双网卡网络路由',
    },
    'home_welcome_sub': {
      'vi':
          'Tự động tách luồng lưu lượng: Internet tốc độ cao và mạng LAN nội bộ ổn định.',
      'en':
          'Automatically segregates traffic: High-speed Internet and stable internal LAN.',
      'cn': '自动分流网络流量：高速公网与稳定内部局域网。',
    },
    'node_internet_gw': {
      'vi': 'Cổng Internet GW',
      'en': 'Internet Gateway',
      'cn': '公网网关',
    },
    'node_this_pc': {
      'vi': 'Máy trạm Workstation',
      'en': 'This Workstation',
      'cn': '本机工作站',
    },
    'node_company_lan': {
      'vi': 'Mạng Nội Bộ LAN',
      'en': 'Company LAN',
      'cn': '公司局域网',
    },
    'not_configured': {
      'vi': 'Chưa cấu hình',
      'en': 'Not configured',
      'cn': '未配置',
    },
    'home_steps_title': {
      'vi': 'Quy trình các bước thực hiện',
      'en': 'Optimization Workflow Steps',
      'cn': '优化执行流程',
    },
    'config_title': {
      'vi': 'Cấu hình thông số định tuyến',
      'en': 'Routing Parameters Configuration',
      'cn': '网络路由参数配置',
    },
    'config_desc': {
      'vi': 'Thiết lập các gateway IP và subnet cho Windows.',
      'en': 'Configure IP gateways and subnets for Windows routing.',
      'cn': '配置 Windows 系统的网关 IP 和子网路由。',
    },
    'config_internet_gw': {
      'vi': 'Gateway Internet chính',
      'en': 'Primary Internet Gateway',
      'cn': '主公网网关',
    },
    'config_backup_gw': {
      'vi': 'Gateway Internet dự phòng',
      'en': 'Backup Internet Gateway',
      'cn': '备用公网网关',
    },
    'config_lan_gw': {
      'vi': 'Gateway mạng LAN nội bộ',
      'en': 'Internal LAN Gateway',
      'cn': '局域网网关',
    },
    'config_lan_net': {
      'vi': 'Dải mạng LAN đích',
      'en': 'Target LAN Network',
      'cn': '目标局域网段',
    },
    'config_lan_mask': {
      'vi': 'Subnet Mask của LAN',
      'en': 'LAN Subnet Mask',
      'cn': '局域网子网掩码',
    },
    'config_log_path': {
      'vi': 'Đường dẫn tệp nhật ký logs',
      'en': 'Log File Storage Path',
      'cn': '日志文件存储路径',
    },
    'config_btn_detect': {
      'vi': 'Tự động nhận diện Gateway',
      'en': 'Auto Detect Gateways',
      'cn': '自动检测网关',
    },
    'config_detect_success': {
      'vi': 'Đã tự động nhận diện và cập nhật gateway thành công!',
      'en': 'Successfully detected and updated network gateways!',
      'cn': '已成功自动检测并更新网络网关！',
    },
    'config_detect_fail': {
      'vi': 'Không thể tự động nhận diện gateway.',
      'en': 'Could not detect active gateways.',
      'cn': '无法自动检测活动网关。',
    },
    'config_btn_save': {
      'vi': 'Lưu cấu hình',
      'en': 'Save Configuration',
      'cn': '保存配置',
    },
    'config_btn_reset': {
      'vi': 'Khôi phục mặc định',
      'en': 'Reset Defaults',
      'cn': '恢复默认',
    },
    'config_custom_routes': {
      'vi': 'Các dải định tuyến bổ sung',
      'en': 'Custom Route Specifications',
      'cn': '附加自定义路由',
    },
    'config_lan_dest': {
      'vi': 'Dải mạng LAN nội bộ (IP/Mask)',
      'en': 'Internal LAN Routes (IP/Mask)',
      'cn': '内网专用路由 (IP/Mask)',
    },
    'config_internet_dest': {
      'vi': 'Dải Internet bypass (IP/Mask)',
      'en': 'Internet Bypass Routes (IP/Mask)',
      'cn': '公网直连路由 (IP/Mask)',
    },
    'config_add_route': {
      'vi': 'Thêm dải mạng',
      'en': 'Add Route',
      'cn': '添加网段',
    },
    'config_recovery_title': {
      'vi': 'Điểm khôi phục & Sao lưu cấu hình',
      'en': 'Restore Points & Profile Backup',
      'cn': '还原点与配置备份',
    },
    'config_btn_create': {
      'vi': 'Tạo điểm khôi phục',
      'en': 'Create Restore Point',
      'cn': '创建还原点',
    },
    'config_btn_restore': {
      'vi': 'Khôi phục Windows Route',
      'en': 'Restore Windows Route',
      'cn': '还原 Windows 路由',
    },
    'config_btn_export': {
      'vi': 'Xuất cấu hình JSON',
      'en': 'Export JSON Profile',
      'cn': '导出 JSON 配置',
    },
    'config_btn_import': {
      'vi': 'Nhập cấu hình JSON',
      'en': 'Import JSON Profile',
      'cn': '导入 JSON 配置',
    },
    'diag_title': {
      'vi': 'Trình chẩn đoán mạng & Lệnh nhanh',
      'en': 'Network Diagnostics & Quick Tools',
      'cn': '网络诊断与快捷工具',
    },
    'diag_desc': {
      'vi': 'Kiểm tra độ trễ, xóa cache mạng, xem bảng route hiện thời.',
      'en': 'Test latency, clear network cache, inspect active route table.',
      'cn': '测试延迟、清理网络缓存、检查活动路由表。',
    },
    'diag_btn_route': {
      'vi': 'Bảng Route hiện tại',
      'en': 'Active Route Table',
      'cn': '查看当前路由表',
    },
    'diag_btn_flush': {
      'vi': 'Xóa DNS & ARP Cache',
      'en': 'Flush DNS & ARP Cache',
      'cn': '刷新 DNS/ARP 缓存',
    },
    'diag_btn_tailscale': {
      'vi': 'Trạng thái Tailscale',
      'en': 'Tailscale Status',
      'cn': 'Tailscale 状态',
    },
    'diag_ping': {'vi': 'Kiểm tra Ping:', 'en': 'Ping Test:', 'cn': 'Ping 测试:'},
    'diag_terminal': {
      'vi': 'TERMINAL OUTPUT',
      'en': 'TERMINAL OUTPUT',
      'cn': '终端输出',
    },
    'diag_table_title': {
      'vi': 'BẢNG ĐỊNH TUYẾN IPv4 CHI TIẾT',
      'en': 'DETAILED IPv4 ROUTING TABLE',
      'cn': 'IPv4 路由表详情',
    },
    'logs_title': {
      'vi': 'Nhật ký hoạt động hệ thống',
      'en': 'System Activity Logs',
      'cn': '系统运行日志',
    },
    'logs_desc': {
      'vi': 'Theo dõi và lọc các dòng nhật ký thời gian thực của ứng dụng.',
      'en': 'Monitor and filter real-time application runtime logs.',
      'cn': '实时监控与筛选应用程序运行日志。',
    },
    'logs_btn_clear': {'vi': 'Xóa màn hình', 'en': 'Clear Logs', 'cn': '清空日志'},
    'logs_btn_copy': {
      'vi': 'Sao chép nhật ký',
      'en': 'Copy Logs',
      'cn': '复制日志',
    },
    'about_title': {
      'vi': 'Giới thiệu JA_Route',
      'en': 'About JA_Route',
      'cn': '关于 JA_Route',
    },
    'about_desc': {
      'vi':
          'Công cụ tối ưu hóa định tuyến mạng kép (Dual-NIC) tự động trên Windows Desktop.',
      'en': 'Automated Dual-NIC Network Routing Optimizer for Windows Desktop.',
      'cn': 'Windows 桌面端双网卡智能路由优化工具。',
    },
    'about_tech': {
      'vi': 'Flutter 3.44 • Dart 3.12 • Native DWM Mica/Acrylic C++',
      'en': 'Flutter 3.44 • Dart 3.12 • Native DWM Mica/Acrylic C++',
      'cn': 'Flutter 3.44 • Dart 3.12 • Native DWM Mica/Acrylic C++',
    },
    'about_managed': {
      'vi': 'Quản lý bởi JATech Automation Solutions',
      'en': 'Managed by JATech Automation Solutions',
      'cn': '由 JATech Automation Solutions 维护',
    },
    'ota_title': {
      'vi': 'Cập nhật tự động qua mạng LAN (OTA)',
      'en': 'Over-The-Air LAN Updates (OTA)',
      'cn': '局域网自动更新 (OTA)',
    },
    'ota_check_now': {
      'vi': 'Kiểm tra bản cập nhật ngay',
      'en': 'Check for Updates Now',
      'cn': '立即检查更新',
    },
    'ota_no_updates': {
      'vi': 'Bạn đang sử dụng phiên bản mới nhất (%s)',
      'en': 'You are using the latest version (%s)',
      'cn': '当前已是最新版本 (%s)',
    },
    'ota_current_version': {
      'vi': 'Phiên bản hiện tại:',
      'en': 'Current version:',
      'cn': '当前版本:',
    },
    'ota_last_checked': {
      'vi': 'Kiểm tra lần cuối:',
      'en': 'Last checked:',
      'cn': '最后检查时间:',
    },
    'guide_shortcuts_title': {
      'vi': 'Phím tắt toàn cục',
      'en': 'Global Shortcuts',
      'cn': '全局快捷键',
    },
    'guide_shortcuts_desc': {
      'vi':
          '• Ctrl+K: Mở Command Palette. Dùng ↑/↓ chọn lệnh, Enter thực thi.\n• Ctrl+1…5: Overview, Config, Diagnostics, Logs, About.\n• Ctrl+,: Mở Cài đặt giao diện & Glass Tuning.\n• Shift+L: Đổi giao diện Sáng / Tối.\n• Esc: Đóng các hộp thoại dialog.',
      'en':
          '• Ctrl+K: Open Command Palette. Use ↑/↓ to select, Enter to run.\n• Ctrl+1…5: Overview, Config, Diagnostics, Logs, About.\n• Ctrl+,: Open UI & Glass Tuning Settings.\n• Shift+L: Toggle Light / Dark Theme.\n• Esc: Close dialogs.',
      'cn':
          '• Ctrl+K：打开命令面板。↑/↓ 选择，Enter 执行。\n• Ctrl+1…5：Overview、Config、Diagnostics、Logs、About。\n• Ctrl+,：打开界面与毛玻璃设置。\n• Shift+L：切换浅色/深色主题。\n• Esc：关闭弹窗。',
    },
    'steps_done_badge': {
      'vi': 'Hoàn thành (%s/%s)',
      'en': 'Done (%s/%s)',
      'zh': '已完成 (%s/%s)',
      'cn': '已完成 (%s/%s)',
    },
    'steps_running_badge': {
      'vi': 'Đang chạy (%s/%s)',
      'en': 'Running (%s/%s)',
      'zh': '正在执行 (%s/%s)',
      'cn': '正在执行 (%s/%s)',
    },
    'steps_total_badge': {
      'vi': '%s Bước Tối Ưu',
      'en': '%s Optimization Steps',
      'zh': '%s 个优化步骤',
      'cn': '%s 个优化步骤',
    },
    'step_status_idle': {
      'vi': 'CHỜ XỬ LÝ',
      'en': 'PENDING',
      'zh': '待处理',
      'cn': '待处理',
    },
    'step_status_running': {
      'vi': 'ĐANG CHẠY...',
      'en': 'RUNNING...',
      'zh': '正在执行...',
      'cn': '正在执行...',
    },
    'step_status_success': {
      'vi': 'THÀNH CÔNG',
      'en': 'SUCCESS',
      'zh': '成功',
      'cn': '成功',
    },
    'step_status_warning': {
      'vi': 'CẢNH BÁO',
      'en': 'WARNING',
      'zh': '警告',
      'cn': '警告',
    },
    'step_status_error': {'vi': 'LỖI', 'en': 'ERROR', 'zh': '错误', 'cn': '错误'},
    'profile_default': {
      'vi': 'Mặc định',
      'en': 'Default',
      'zh': '默认',
      'cn': '默认',
    },
    'profile_title': {
      'vi': 'Hồ sơ cấu hình:',
      'en': 'Active Profile:',
      'zh': '当前配置方案:',
      'cn': '当前配置方案:',
    },
  };
}

extension LanguageExtension on BuildContext {
  LanguageProvider get language => watch<LanguageProvider>();
  String t(String key) => watch<LanguageProvider>().t(key);
}
