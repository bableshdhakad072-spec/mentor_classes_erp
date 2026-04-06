/// Local staff credentials for MENTOR CLASSES ERP.
///
/// **Security:** Passwords are embedded for the MVP so you can hand emails/passwords
/// to teachers. Replace values before any production deployment; prefer a secure
/// backend or remote config for real workloads.
abstract final class AppConfig {
  /// Lowercase email → password (2 admins: Yogesh Udawat + desk admin).
  static const Map<String, String> adminAccounts = {
    'yogesh.udawat@mentorclasses.in': 'Yogesh@Mentor2026',
    'desk.admin@mentorclasses.in': 'MentorDesk@2026',
  };

  /// Lowercase email → password (3 teachers — distinct emails from admins).
  static const Map<String, String> teacherAccounts = {
    'vinita.sharma@mentorclasses.in': 'TeacherVinita@2026',
    'aadesh.dangi@mentorclasses.in': 'TeacherAadesh@2026',
    'neha.joshi@mentorclasses.in': 'TeacherNeha@2026',
  };

  /// Display names shown in the app after staff login.
  static String staffDisplayName(String emailLowercase) {
    return switch (emailLowercase) {
      'yogesh.udawat@mentorclasses.in' => 'Yogesh Udawat',
      'desk.admin@mentorclasses.in' => 'Front Office Admin',
      'vinita.sharma@mentorclasses.in' => 'Vinita Sharma',
      'aadesh.dangi@mentorclasses.in' => 'Aadesh Dangi',
      _ => emailLowercase.split('@').first.replaceAll('.', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' '),
    };
  }
}
