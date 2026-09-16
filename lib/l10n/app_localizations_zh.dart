// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get signingOut => '正在退出';

  @override
  String get restoringSession => '正在检查登录状态';

  @override
  String get signOutIncomplete => '退出未完成';

  @override
  String get retrySignOut => '重试退出';

  @override
  String get sessionUnavailableTitle => '登录状态暂不可用';

  @override
  String get sessionRetryHint => '请连接网络后重试，以确认登录状态。';

  @override
  String get sessionRejectedHint => '登录状态已失效，请退出当前设备后重新登录。';

  @override
  String get sessionUnsupportedHint => '暂不支持登录，请检查应用配置或联系支持。';

  @override
  String get retry => '重试';

  @override
  String get signOutDevice => '退出当前设备';

  @override
  String get signedIn => '已登录';

  @override
  String get emailConfirmed => '邮箱已验证';

  @override
  String get emailVerificationRequired => '需要验证邮箱';

  @override
  String get emailConfirmationUnavailable => '邮箱验证状态暂不可用';

  @override
  String get retryUsername => '重试保存用户名';

  @override
  String get createAccount => '创建账户';

  @override
  String get welcomeBack => '欢迎回来';

  @override
  String get registrationSubtitle => '创建账户，开始规划更适合你的生活。';

  @override
  String get signInSubtitle => '登录后继续查看地点、预算与房产实勘。';

  @override
  String get optionalUsername => '用户名（可选）';

  @override
  String get usernameHint => '输入用户名';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get emailRequired => '请输入邮箱。';

  @override
  String get emailInvalid => '请输入有效的邮箱地址。';

  @override
  String get passwordHint => '输入密码';

  @override
  String get hide => '隐藏';

  @override
  String get show => '显示';

  @override
  String get passwordRequired => '请输入密码。';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get confirmPasswordHint => '再次输入密码';

  @override
  String get passwordMismatch => '两次输入的密码不一致。';

  @override
  String get signIn => '登录';

  @override
  String get switchToSignIn => '已有账户？登录';

  @override
  String get switchToRegistration => '还没有账户？创建账户';

  @override
  String get confirmSignOut => '确认退出？';

  @override
  String get confirmSignOutBody => '是否结束当前设备上的登录？';

  @override
  String get cancel => '取消';

  @override
  String get signOut => '退出';

  @override
  String get signInSucceeded => '登录成功。';

  @override
  String get signInInvalidInput => '请输入邮箱和密码。';

  @override
  String get signInInvalidCredentials => '邮箱或密码不正确。';

  @override
  String get serviceUnavailable => '服务暂不可用，请重试。';

  @override
  String get signInUnsupportedClient => '当前设备暂时无法登录。';

  @override
  String get registrationAuthenticated => '账户创建成功。';

  @override
  String get registrationProfileFailed => '账户已创建，用户名保存失败，可稍后重试。';

  @override
  String get verificationEmailSent => '请查看邮件，完成邮箱验证后再登录。';

  @override
  String get verificationProfileRetryNeeded => '请验证邮箱，再登录以完成用户名设置。';

  @override
  String get registrationInvalidInput => '请检查必填项和确认密码。';

  @override
  String get registrationAccountExists => '该邮箱已注册。';

  @override
  String get registrationUnsupportedClient => '当前设备暂时无法注册。';

  @override
  String get profileRetrySucceeded => '用户名已保存。';

  @override
  String get profileRetryFailed => '用户名未保存，请检查格式或重试。';

  @override
  String get profileRetrySkipped => '当前设备没有待保存的用户名。';

  @override
  String get signOutRetryableUnavailable => '退出未完成，请连接网络后重试。';

  @override
  String get signOutRemoteRejected => '退出请求被拒绝，请重试或联系支持。';

  @override
  String get signOutUnsupportedClient => '当前设备无法完成退出，请检查应用配置。';

  @override
  String get sessionUnavailable => '暂时无法确认登录状态，请重试。';

  @override
  String get unknownError => '发生错误，请重试。';

  @override
  String get brandTagline => '找到更适合生活的地点';

  @override
  String get language => '语言';

  @override
  String get languageSaveFailed => '语言偏好未保存，请重试。';

  @override
  String get configurationMissing =>
      'LocateMY 尚未配置，请设置 Supabase 项目 URL 和 publishable key 后重启应用。';
}
