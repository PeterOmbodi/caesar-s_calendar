class FirestorePaths {
  static const String users = 'users';
  static const String publicUsers = 'publicUsers';
  static const String leaderboards = 'leaderboards';

  static String userDoc(final String uid) => '$users/$uid';
  static String userSessions(final String uid) => '${userDoc(uid)}/sessions';
  static String userConfigs(final String uid) => '${userDoc(uid)}/configs';
  static String userSolvedSolutions(final String uid) => '${userDoc(uid)}/solvedSolutions';

  static String publicUserDoc(final String uid) => '$publicUsers/$uid';
}

