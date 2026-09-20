class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.isAnonymous,
  });

  final String uid;
  final String displayName;
  final bool isAnonymous;
}
