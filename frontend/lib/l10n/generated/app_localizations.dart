import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// App name, shown on the landing screen and app bar
  ///
  /// In en, this message translates to:
  /// **'NIKAT'**
  String get appName;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'The Operating System for Every Indian Locality'**
  String get landingTagline;

  /// No description provided for @landingDescription.
  ///
  /// In en, this message translates to:
  /// **'One verified digital space for every apartment, society, colony, and locality in India - replacing WhatsApp groups, paper notices, and phone calls with a single AI-powered community platform.'**
  String get landingDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @enterPhoneToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to continue'**
  String get enterPhoneToContinue;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @enterCodeSentToPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your phone'**
  String get enterCodeSentToPhone;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @didntReceiveCodeResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? Resend'**
  String get didntReceiveCodeResend;

  /// No description provided for @cancelBackToMainPage.
  ///
  /// In en, this message translates to:
  /// **'Cancel and go back to main page'**
  String get cancelBackToMainPage;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navReels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get navReels;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get actionComment;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get languageHindi;

  /// No description provided for @pillarsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Everything your locality needs, in one app'**
  String get pillarsHeadline;

  /// No description provided for @pillarsSubheadline.
  ///
  /// In en, this message translates to:
  /// **'A growing set of modules built for Indian communities.'**
  String get pillarsSubheadline;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get badgeLive;

  /// No description provided for @badgeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get badgeComingSoon;

  /// No description provided for @pillarSocietyTitle.
  ///
  /// In en, this message translates to:
  /// **'Society Management'**
  String get pillarSocietyTitle;

  /// No description provided for @pillarSocietyDesc.
  ///
  /// In en, this message translates to:
  /// **'Notices, complaints, and verified membership approval for your society.'**
  String get pillarSocietyDesc;

  /// No description provided for @pillarSocietyFeature1.
  ///
  /// In en, this message translates to:
  /// **'Notices & announcements'**
  String get pillarSocietyFeature1;

  /// No description provided for @pillarSocietyFeature2.
  ///
  /// In en, this message translates to:
  /// **'Complaint tracking'**
  String get pillarSocietyFeature2;

  /// No description provided for @pillarSocietyFeature3.
  ///
  /// In en, this message translates to:
  /// **'Member approval workflow'**
  String get pillarSocietyFeature3;

  /// No description provided for @pillarCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get pillarCommunityTitle;

  /// No description provided for @pillarCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Posts, questions, recommendations, polls, events, lost & found.'**
  String get pillarCommunityDesc;

  /// No description provided for @pillarCommunityFeature1.
  ///
  /// In en, this message translates to:
  /// **'Posts & discussions'**
  String get pillarCommunityFeature1;

  /// No description provided for @pillarCommunityFeature2.
  ///
  /// In en, this message translates to:
  /// **'Polls & events'**
  String get pillarCommunityFeature2;

  /// No description provided for @pillarCommunityFeature3.
  ///
  /// In en, this message translates to:
  /// **'Lost & found'**
  String get pillarCommunityFeature3;

  /// No description provided for @pillarMarketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Hyperlocal Marketplace'**
  String get pillarMarketplaceTitle;

  /// No description provided for @pillarMarketplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy, sell, rent, donate and exchange within your locality.'**
  String get pillarMarketplaceDesc;

  /// No description provided for @pillarMarketplaceFeature1.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell'**
  String get pillarMarketplaceFeature1;

  /// No description provided for @pillarMarketplaceFeature2.
  ///
  /// In en, this message translates to:
  /// **'Rent & donate'**
  String get pillarMarketplaceFeature2;

  /// No description provided for @pillarMarketplaceFeature3.
  ///
  /// In en, this message translates to:
  /// **'Second-hand goods'**
  String get pillarMarketplaceFeature3;

  /// No description provided for @pillarCommerceTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Commerce'**
  String get pillarCommerceTitle;

  /// No description provided for @pillarCommerceDesc.
  ///
  /// In en, this message translates to:
  /// **'Every local business gets a page - residents book directly.'**
  String get pillarCommerceDesc;

  /// No description provided for @pillarCommerceFeature1.
  ///
  /// In en, this message translates to:
  /// **'Business directory'**
  String get pillarCommerceFeature1;

  /// No description provided for @pillarCommerceFeature2.
  ///
  /// In en, this message translates to:
  /// **'Direct booking'**
  String get pillarCommerceFeature2;

  /// No description provided for @pillarCommerceFeature3.
  ///
  /// In en, this message translates to:
  /// **'Ratings & reviews'**
  String get pillarCommerceFeature3;

  /// No description provided for @pillarAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get pillarAiTitle;

  /// No description provided for @pillarAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask instead of searching - \"Find me a trusted plumber.\"'**
  String get pillarAiDesc;

  /// No description provided for @pillarAiFeature1.
  ///
  /// In en, this message translates to:
  /// **'Natural-language search'**
  String get pillarAiFeature1;

  /// No description provided for @pillarAiFeature2.
  ///
  /// In en, this message translates to:
  /// **'Trusted recommendations'**
  String get pillarAiFeature2;

  /// No description provided for @pillarAiFeature3.
  ///
  /// In en, this message translates to:
  /// **'Availability lookup'**
  String get pillarAiFeature3;

  /// No description provided for @pillarFestivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Festival Module'**
  String get pillarFestivalTitle;

  /// No description provided for @pillarFestivalDesc.
  ///
  /// In en, this message translates to:
  /// **'Digitize festival donations, volunteering, and schedules.'**
  String get pillarFestivalDesc;

  /// No description provided for @pillarFestivalFeature1.
  ///
  /// In en, this message translates to:
  /// **'Donation tracking'**
  String get pillarFestivalFeature1;

  /// No description provided for @pillarFestivalFeature2.
  ///
  /// In en, this message translates to:
  /// **'Volunteer sign-up'**
  String get pillarFestivalFeature2;

  /// No description provided for @pillarFestivalFeature3.
  ///
  /// In en, this message translates to:
  /// **'Event schedules'**
  String get pillarFestivalFeature3;

  /// No description provided for @pillarEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get pillarEmergencyTitle;

  /// No description provided for @pillarEmergencyDesc.
  ///
  /// In en, this message translates to:
  /// **'One button to alert family, neighbors, and security.'**
  String get pillarEmergencyDesc;

  /// No description provided for @pillarEmergencyFeature1.
  ///
  /// In en, this message translates to:
  /// **'One-tap SOS'**
  String get pillarEmergencyFeature1;

  /// No description provided for @pillarEmergencyFeature2.
  ///
  /// In en, this message translates to:
  /// **'Neighbor alerts'**
  String get pillarEmergencyFeature2;

  /// No description provided for @pillarEmergencyFeature3.
  ///
  /// In en, this message translates to:
  /// **'Security notification'**
  String get pillarEmergencyFeature3;

  /// No description provided for @pillarHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Domestic Help'**
  String get pillarHelpTitle;

  /// No description provided for @pillarHelpDesc.
  ///
  /// In en, this message translates to:
  /// **'Find trusted cooks, drivers, maids, and more.'**
  String get pillarHelpDesc;

  /// No description provided for @pillarHelpFeature1.
  ///
  /// In en, this message translates to:
  /// **'Verified helpers'**
  String get pillarHelpFeature1;

  /// No description provided for @pillarHelpFeature2.
  ///
  /// In en, this message translates to:
  /// **'Availability status'**
  String get pillarHelpFeature2;

  /// No description provided for @pillarHelpFeature3.
  ///
  /// In en, this message translates to:
  /// **'Direct contact'**
  String get pillarHelpFeature3;

  /// No description provided for @pillarJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Jobs'**
  String get pillarJobsTitle;

  /// No description provided for @pillarJobsDesc.
  ///
  /// In en, this message translates to:
  /// **'Hire and get hired within your locality.'**
  String get pillarJobsDesc;

  /// No description provided for @pillarJobsFeature1.
  ///
  /// In en, this message translates to:
  /// **'Post a need'**
  String get pillarJobsFeature1;

  /// No description provided for @pillarJobsFeature2.
  ///
  /// In en, this message translates to:
  /// **'Local hiring'**
  String get pillarJobsFeature2;

  /// No description provided for @pillarJobsFeature3.
  ///
  /// In en, this message translates to:
  /// **'Quick responses'**
  String get pillarJobsFeature3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
