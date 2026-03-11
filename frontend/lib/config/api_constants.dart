class ApiConstants {
  static const String baseUrl = "https://dt-pro-two.onrender.com/api";

  // -- Auth ----------------------
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String getAllUser = '/auth/users';
  static const String getMyTeam = '/auth/my-team';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // -- Delegations (Tasks) --------
  static const String delegations = '/delegations';

  // -- Categories -----------------
  static const String categories = '/categories';

  // -- Groups ---------------------
  static const String groups = '/groups';

  // -- Tickets --------------------
  static const String tickets = '/tickets';

  // -- Notifications --------------
  static const String notifications = '/notifications';

  // -- Reports --------------------
  static const String dashboardStats = '/dashboard/stats';
  static const String reportDaily = '/reports/daily';
  static const String reportTeam = '/reports/team';
  static const String reportMemberProfile = '/reports/member';

  static const Duration requestTimeout = Duration(seconds: 45);
  static const Duration connectTimeout = Duration(seconds: 45);
}
