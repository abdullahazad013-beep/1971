class AppConstants {
  AppConstants._();

  static const scrollDelayShort  = Duration(milliseconds: 100);
  static const scrollDelayMedium = Duration(milliseconds: 200);

  static const double inputBottomMargin = 88.0;
  static const double avatarSize        = 28.0;
  static const double borderRadius      = 16.0;
  static const double imageHeight       = 220.0;

  static const animationDuration = Duration(milliseconds: 300);
  static const apiTimeout        = Duration(seconds: 60);
  static const apiImageTimeout   = Duration(seconds: 120);

  static const String chatHistoryKey = 'bdai_chat_history';
  static const String allChatsKey    = 'bdai_all_chats';
  static const String themeModeKey   = 'theme_mode';
  static const String isLoggedInKey  = 'is_logged_in';

  static const String defaultPlaceholder = 'thinking...';
  static const String imagePlaceholder   = 'generating image...';

  static const String appVersion  = '1.0.0';
  static const String packageName = 'com.bdai.app';
}
