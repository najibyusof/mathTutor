/// User-facing copy kept in one place so it can be localized later.
abstract final class AppStrings {
  const AppStrings._();

  // Generic
  static const String appName = 'MathTutor';
  static const String appTagline = 'Solve math, step by step';
  static const String retry = 'Try again';
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String comingSoon = 'Coming soon';

  // Errors
  static const String genericError = 'Something went wrong.';
  static const String networkError =
      'No internet connection. Check your network and try again.';
  static const String serverError =
      'The server is not responding. Please try again later.';
  static const String unknownRoute = 'This screen could not be found.';

  // Feature titles
  static const String homeTitle = 'Home';
  static const String mathInputTitle = 'Math keyboard';
  static const String handwritingTitle = 'Handwriting';
  static const String cameraTitle = 'Scan a problem';
  static const String solverTitle = 'Solution';
  static const String historyTitle = 'History';
  static const String profileTitle = 'Profile';
  static const String authTitle = 'Sign in';

  // Feature subtitles
  static const String mathInputSubtitle = 'Type an expression with symbols';
  static const String handwritingSubtitle = 'Write the problem by hand';
  static const String cameraSubtitle = 'Take a photo of the problem';
  static const String historySubtitle = 'Your previously solved problems';
  static const String profileSubtitle = 'Account and preferences';

  // Onboarding
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingStart = 'Get started';

  // Auth
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle =
      'Sign in to keep solving and reviewing your questions.';
  static const String registerTitle = 'Create your account';
  static const String registerSubtitle =
      'Start getting step-by-step explanations in seconds.';
  static const String forgotPasswordTitle = 'Reset your password';
  static const String forgotPasswordSubtitle =
      'Enter your email and we will send you a reset link.';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm password';
  static const String nameLabel = 'Full name';
  static const String signIn = 'Sign in';
  static const String signUp = 'Create account';
  static const String signOut = 'Sign out';
  static const String sendResetLink = 'Send reset link';
  static const String forgotPasswordLink = 'Forgot password?';
  static const String noAccountPrompt = "Don't have an account?";
  static const String hasAccountPrompt = 'Already have an account?';
  static const String passwordMismatch = 'The passwords do not match.';
  static const String signOutConfirmTitle = 'Sign out?';
  static const String signOutConfirmMessage =
      'You will need to sign in again to see your history.';

  // Home
  static const String askQuestion = 'Ask a Math Question';
  static const String askQuestionSubtitle =
      'Type, write or scan a problem and get a step-by-step explanation.';
  static const String chooseInputMethod = 'Choose how to ask';
  static const String recentQuestions = 'Recent questions';
  static const String viewHistory = 'View history';
  static const String tipOfTheDay = 'Tip of the day';

  // Math input
  static const String questionInputTitle = 'Your question';
  static const String questionInputHint = 'Tap the keys to build your question';
  static const String clearQuestion = 'Clear';
  static const String solveQuestion = 'Solve';
  static const String switchInputMethod = 'Switch input method';

  // Empty states
  static const String emptyHistoryTitle = 'No solved problems yet';
  static const String emptyHistoryMessage =
      'Problems you solve will appear here.';
  static const String emptyQuestionTitle = 'Nothing here yet';
  static const String emptyQuestionMessage =
      'Your question will appear here as you build it.';
}
