import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FreeBay'**
  String get appName;

  /// No description provided for @commonGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get commonGetStarted;

  /// No description provided for @splashEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THE MARKETPLACE REBUILT'**
  String get splashEyebrow;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'TRADE YOUR WORLD'**
  String get splashTagline;

  /// No description provided for @splashTradingFees.
  ///
  /// In en, this message translates to:
  /// **'Trading fees'**
  String get splashTradingFees;

  /// No description provided for @splashInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get splashInstant;

  /// No description provided for @splashVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get splashVerification;

  /// No description provided for @splashGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get splashGlobal;

  /// No description provided for @splashReach.
  ///
  /// In en, this message translates to:
  /// **'Reach access'**
  String get splashReach;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonOkay.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOkay;

  /// No description provided for @commonUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonUnderstand;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonViewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get commonViewMore;

  /// No description provided for @commonNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get commonNoResults;

  /// No description provided for @commonOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get commonOffline;

  /// No description provided for @commonTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get commonTryAgainLater;

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

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogin;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUp;

  /// No description provided for @authLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get authLogout;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get authSessionExpired;

  /// No description provided for @authSessionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again to continue.'**
  String get authSessionExpiredBody;

  /// No description provided for @authUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get authUseBiometrics;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedTitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Follow people to see their posts here.'**
  String get feedEmptyBody;

  /// No description provided for @feedCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get feedCreatePost;

  /// No description provided for @feedLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get feedLike;

  /// No description provided for @feedUnlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get feedUnlike;

  /// No description provided for @feedComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get feedComment;

  /// No description provided for @feedComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get feedComments;

  /// No description provided for @feedSavePost.
  ///
  /// In en, this message translates to:
  /// **'Save post'**
  String get feedSavePost;

  /// No description provided for @feedUnsavePost.
  ///
  /// In en, this message translates to:
  /// **'Remove saved post'**
  String get feedUnsavePost;

  /// No description provided for @feedRepost.
  ///
  /// In en, this message translates to:
  /// **'Repost'**
  String get feedRepost;

  /// No description provided for @feedPostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get feedPostUnavailable;

  /// No description provided for @profileFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profileFollowers;

  /// No description provided for @profileFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profileFollowing;

  /// No description provided for @profilePosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profilePosts;

  /// No description provided for @profileSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get profileSales;

  /// No description provided for @profileReputation.
  ///
  /// In en, this message translates to:
  /// **'Reputation'**
  String get profileReputation;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get profileFollow;

  /// No description provided for @profileUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get profileUnfollow;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSaved;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileBlocked.
  ///
  /// In en, this message translates to:
  /// **'This profile is unavailable.'**
  String get profileBlocked;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// No description provided for @chatArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived conversations'**
  String get chatArchivedTitle;

  /// No description provided for @chatNewConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get chatNewConversation;

  /// No description provided for @chatUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get chatUnarchive;

  /// No description provided for @chatArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get chatArchive;

  /// No description provided for @chatConversationArchived.
  ///
  /// In en, this message translates to:
  /// **'Conversation archived'**
  String get chatConversationArchived;

  /// No description provided for @chatConversationRestored.
  ///
  /// In en, this message translates to:
  /// **'Conversation restored'**
  String get chatConversationRestored;

  /// No description provided for @chatDeleteUndoExplanation.
  ///
  /// In en, this message translates to:
  /// **'The conversation will be hidden for you. You can undo this for a few seconds.'**
  String get chatDeleteUndoExplanation;

  /// No description provided for @chatDeleteCancelled.
  ///
  /// In en, this message translates to:
  /// **'Deletion cancelled'**
  String get chatDeleteCancelled;

  /// No description provided for @chatOrderModifyRule.
  ///
  /// In en, this message translates to:
  /// **'Actions are available only after the order is completed or cancelled.'**
  String get chatOrderModifyRule;

  /// No description provided for @chatGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Discuss products, ask questions, and chat securely with buyers and sellers in real time.'**
  String get chatGuestDescription;

  /// No description provided for @chatArchivedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe a conversation left to archive it.'**
  String get chatArchivedEmptyBody;

  /// No description provided for @chatMessageToSeller.
  ///
  /// In en, this message translates to:
  /// **'Message the seller'**
  String get chatMessageToSeller;

  /// No description provided for @chatPurchaseOffer.
  ///
  /// In en, this message translates to:
  /// **'PURCHASE OFFER'**
  String get chatPurchaseOffer;

  /// No description provided for @chatChooseProduct.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE PRODUCT'**
  String get chatChooseProduct;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get chatMessageHint;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatEmptyTitle;

  /// No description provided for @chatNoConversations.
  ///
  /// In en, this message translates to:
  /// **'NO CONVERSATIONS'**
  String get chatNoConversations;

  /// No description provided for @chatNoConversationsBody.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation or receive a message to see it here.'**
  String get chatNoConversationsBody;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your conversations. Check your connection.'**
  String get chatLoadFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent.'**
  String get chatSendFailed;

  /// No description provided for @chatAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get chatAttachment;

  /// No description provided for @chatVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessage;

  /// No description provided for @chatLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get chatLocation;

  /// No description provided for @locationServiceRequired.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to continue.'**
  String get locationServiceRequired;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. Enable it in settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to get your location. Try again.'**
  String get locationUnavailable;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get locationUseCurrent;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Provider accuracy: {meters} m'**
  String locationAccuracy(String meters);

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productTitle;

  /// No description provided for @productSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get productSearchHint;

  /// No description provided for @productAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get productAddToCart;

  /// No description provided for @productOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productOutOfStock;

  /// No description provided for @productCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get productCondition;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productDescription;

  /// No description provided for @productUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This product is no longer available.'**
  String get productUnavailable;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Continue to checkout'**
  String get cartCheckout;

  /// No description provided for @cartQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity}'**
  String cartQuantity(int quantity);

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed.'**
  String get paymentFailed;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get ordersDetails;

  /// No description provided for @ordersAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get ordersAllStatuses;

  /// No description provided for @ordersActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get ordersActions;

  /// No description provided for @ordersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get ordersCancel;

  /// No description provided for @ordersConfirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt'**
  String get ordersConfirmReceipt;

  /// No description provided for @ordersConfirmReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'Confirming receipt releases the payment to the seller.'**
  String get ordersConfirmReceiptBody;

  /// No description provided for @ordersRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing orders…'**
  String get ordersRefreshing;

  /// No description provided for @ordersShowingCached.
  ///
  /// In en, this message translates to:
  /// **'Showing saved orders.'**
  String get ordersShowingCached;

  /// No description provided for @ordersEndOfList.
  ///
  /// In en, this message translates to:
  /// **'END OF LIST'**
  String get ordersEndOfList;

  /// No description provided for @ordersNumber.
  ///
  /// In en, this message translates to:
  /// **'ORDER #{orderId}'**
  String ordersNumber(String orderId);

  /// No description provided for @ordersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get ordersNotFound;

  /// No description provided for @ordersInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get ordersInformation;

  /// No description provided for @ordersOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get ordersOrderId;

  /// No description provided for @ordersOrderDate.
  ///
  /// In en, this message translates to:
  /// **'Order date'**
  String get ordersOrderDate;

  /// No description provided for @ordersItemNumber.
  ///
  /// In en, this message translates to:
  /// **'Item #{shortId}'**
  String ordersItemNumber(String shortId);

  /// No description provided for @ordersOtherParty.
  ///
  /// In en, this message translates to:
  /// **'{role}: {name}'**
  String ordersOtherParty(String role, String name);

  /// No description provided for @orderStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Order status'**
  String get orderStatusHeading;

  /// No description provided for @escrowStatusHeld.
  ///
  /// In en, this message translates to:
  /// **'Held in escrow'**
  String get escrowStatusHeld;

  /// No description provided for @escrowStatusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get escrowStatusReleased;

  /// No description provided for @escrowStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get escrowStatusRefunded;

  /// No description provided for @ordersTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get ordersTotalAmount;

  /// No description provided for @ordersPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform fee (10%)'**
  String get ordersPlatformFee;

  /// No description provided for @ordersSellerReceives.
  ///
  /// In en, this message translates to:
  /// **'You receive'**
  String get ordersSellerReceives;

  /// No description provided for @escrowHeldBuyer.
  ///
  /// In en, this message translates to:
  /// **'Payment is held in escrow until you confirm receipt of the product.'**
  String get escrowHeldBuyer;

  /// No description provided for @escrowHeldSeller.
  ///
  /// In en, this message translates to:
  /// **'Payment is held in escrow until the buyer confirms receipt.'**
  String get escrowHeldSeller;

  /// No description provided for @escrowReleasedBuyer.
  ///
  /// In en, this message translates to:
  /// **'Payment released to the seller.'**
  String get escrowReleasedBuyer;

  /// No description provided for @escrowReleasedSeller.
  ///
  /// In en, this message translates to:
  /// **'Payment released! The amount will be credited to your wallet.'**
  String get escrowReleasedSeller;

  /// No description provided for @escrowRefundedBuyer.
  ///
  /// In en, this message translates to:
  /// **'Amount refunded to your wallet.'**
  String get escrowRefundedBuyer;

  /// No description provided for @escrowRefundedSeller.
  ///
  /// In en, this message translates to:
  /// **'Amount refunded to the buyer.'**
  String get escrowRefundedSeller;

  /// No description provided for @ordersConfirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancellation'**
  String get ordersConfirmCancellation;

  /// No description provided for @ordersConfirmCancellationBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?\n\nReason: {reason}\n\nThe amount will be refunded if it has already been paid.'**
  String ordersConfirmCancellationBody(String reason);

  /// No description provided for @ordersCancelReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a reason for cancellation:'**
  String get ordersCancelReasonPrompt;

  /// No description provided for @ordersCancelReasonChangedMind.
  ///
  /// In en, this message translates to:
  /// **'I changed my mind'**
  String get ordersCancelReasonChangedMind;

  /// No description provided for @ordersCancelReasonBetterPrice.
  ///
  /// In en, this message translates to:
  /// **'I found a better price'**
  String get ordersCancelReasonBetterPrice;

  /// No description provided for @ordersCancelReasonWrongProduct.
  ///
  /// In en, this message translates to:
  /// **'Incorrect product'**
  String get ordersCancelReasonWrongProduct;

  /// No description provided for @ordersCancelReasonConfirmationDelay.
  ///
  /// In en, this message translates to:
  /// **'Confirmation is taking too long'**
  String get ordersCancelReasonConfirmationDelay;

  /// No description provided for @ordersCancelReasonSellerIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue with the seller'**
  String get ordersCancelReasonSellerIssue;

  /// No description provided for @ordersCancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get ordersCancelReasonOther;

  /// No description provided for @ordersRefundPending.
  ///
  /// In en, this message translates to:
  /// **'Refund requested. Please wait for payment confirmation.'**
  String get ordersRefundPending;

  /// No description provided for @ordersCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get ordersCancelledSuccess;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusDisputed.
  ///
  /// In en, this message translates to:
  /// **'In dispute'**
  String get orderStatusDisputed;

  /// No description provided for @ordersDispute.
  ///
  /// In en, this message translates to:
  /// **'Open a dispute'**
  String get ordersDispute;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get walletBalance;

  /// No description provided for @walletHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletHistory;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @storiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get storiesTitle;

  /// No description provided for @storiesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This story is no longer available.'**
  String get storiesUnavailable;

  /// No description provided for @storiesSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip story'**
  String get storiesSkip;

  /// No description provided for @closeFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Friends'**
  String get closeFriendsTitle;

  /// No description provided for @closeFriendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your Close Friends list is empty.'**
  String get closeFriendsEmpty;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountTitle;

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get authCompleteProfileTitle;

  /// No description provided for @authDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authDisplayName;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authCityOptional.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get authCityOptional;

  /// No description provided for @authCityHint.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get authCityHint;

  /// No description provided for @authDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name on FreeBay'**
  String get authDisplayNameHint;

  /// No description provided for @authEmailExample.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailExample;

  /// No description provided for @authPasswordMask.
  ///
  /// In en, this message translates to:
  /// **'*********'**
  String get authPasswordMask;

  /// No description provided for @authRepeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get authRepeatPassword;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authNoAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'DON\'T HAVE AN ACCOUNT?'**
  String get authNoAccountQuestion;

  /// No description provided for @authContinueProfile.
  ///
  /// In en, this message translates to:
  /// **'Continue profile'**
  String get authContinueProfile;

  /// No description provided for @authExitToLogin.
  ///
  /// In en, this message translates to:
  /// **'Exit to sign in'**
  String get authExitToLogin;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToLogin;

  /// No description provided for @authCompleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your username and complete your details.'**
  String get authCompleteProfileBody;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'@ Username'**
  String get authUsernameLabel;

  /// No description provided for @authSwitchAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out and choose another account'**
  String get authSwitchAccount;

  /// No description provided for @authCreateNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get authCreateNewPassword;

  /// No description provided for @authStrongPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password with at least 8 characters.'**
  String get authStrongPasswordHint;

  /// No description provided for @authNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get authNewPasswordRequired;

  /// No description provided for @authConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmNewPassword;

  /// No description provided for @authRepeatNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password again'**
  String get authRepeatNewPassword;

  /// No description provided for @authConfirmNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get authConfirmNewPasswordRequired;

  /// No description provided for @authResetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset your password. Please try again.'**
  String get authResetPasswordFailed;

  /// No description provided for @authRecoveryRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the code. Check your email address.'**
  String get authRecoveryRequestFailed;

  /// No description provided for @authRecoveryCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The code is invalid or expired. Please try again.'**
  String get authRecoveryCodeInvalid;

  /// No description provided for @authCodeSixDigitsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authCodeSixDigitsRequired;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authVerificationCode;

  /// No description provided for @authEnterAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get authEnterAccount;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSignUpGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get authSignUpGoogle;

  /// No description provided for @authFinishRegistration.
  ///
  /// In en, this message translates to:
  /// **'Finish registration'**
  String get authFinishRegistration;

  /// No description provided for @authCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get authCompleteProfile;

  /// No description provided for @authCancelRegistrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration?'**
  String get authCancelRegistrationTitle;

  /// No description provided for @authCancelRegistrationBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile details will not be saved.'**
  String get authCancelRegistrationBody;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authNameRequired;

  /// No description provided for @authNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get authNameTooShort;

  /// No description provided for @authNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name contains invalid characters'**
  String get authNameInvalid;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authRecoveryCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get authRecoveryCodeRequired;

  /// No description provided for @authBiometryNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are not enabled.'**
  String get authBiometryNotEnabled;

  /// No description provided for @authBiometryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are unavailable on this device.'**
  String get authBiometryUnavailable;

  /// No description provided for @authBiometryCredentialsMissing.
  ///
  /// In en, this message translates to:
  /// **'Biometric credentials were not found.'**
  String get authBiometryCredentialsMissing;

  /// No description provided for @authBiometryAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Biometrics belong to another account.'**
  String get authBiometryAccountMismatch;

  /// No description provided for @authBiometryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication was cancelled.'**
  String get authBiometryCancelled;

  /// No description provided for @authBiometryTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Biometric token was not found.'**
  String get authBiometryTokenMissing;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create your account. Please try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authRecoverySent.
  ///
  /// In en, this message translates to:
  /// **'If the account exists, recovery instructions will be sent.'**
  String get authRecoverySent;

  /// No description provided for @authPasswordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed.'**
  String get authPasswordResetSuccess;

  /// No description provided for @authGoogleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is currently unavailable.'**
  String get authGoogleUnavailable;

  /// No description provided for @authPermissionBiometry.
  ///
  /// In en, this message translates to:
  /// **'Enable biometrics'**
  String get authPermissionBiometry;

  /// No description provided for @authPermissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get authPermissionNotifications;

  /// No description provided for @authOnboardingBiometry.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH BIOMETRICS'**
  String get authOnboardingBiometry;

  /// No description provided for @authOnboardingNotifications.
  ///
  /// In en, this message translates to:
  /// **'STAY IN THE LOOP'**
  String get authOnboardingNotifications;

  /// No description provided for @authOnboardingReady.
  ///
  /// In en, this message translates to:
  /// **'YOU\'RE ALL SET'**
  String get authOnboardingReady;

  /// No description provided for @onboardingShopAndSell.
  ///
  /// In en, this message translates to:
  /// **'BUY AND SELL'**
  String get onboardingShopAndSell;

  /// No description provided for @onboardingSocialFeed.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL FEED & LISTINGS'**
  String get onboardingSocialFeed;

  /// No description provided for @onboardingChatAndEscrow.
  ///
  /// In en, this message translates to:
  /// **'CHAT & ESCROW'**
  String get onboardingChatAndEscrow;

  /// No description provided for @onboardingProtection.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED PAYMENTS'**
  String get onboardingProtection;

  /// No description provided for @onboardingPayouts.
  ///
  /// In en, this message translates to:
  /// **'FAST PAYOUTS'**
  String get onboardingPayouts;

  /// No description provided for @onboardingMoneyControl.
  ///
  /// In en, this message translates to:
  /// **'YOU\'RE IN CONTROL'**
  String get onboardingMoneyControl;

  /// No description provided for @onboardingStepSocial.
  ///
  /// In en, this message translates to:
  /// **'STEP 01 // SOCIAL COMMERCE'**
  String get onboardingStepSocial;

  /// No description provided for @onboardingStepNegotiation.
  ///
  /// In en, this message translates to:
  /// **'STEP 02 // DIRECT NEGOTIATION'**
  String get onboardingStepNegotiation;

  /// No description provided for @onboardingStepWallet.
  ///
  /// In en, this message translates to:
  /// **'STEP 03 // WALLET & REPUTATION'**
  String get onboardingStepWallet;

  /// No description provided for @onboardingSocialBody.
  ///
  /// In en, this message translates to:
  /// **'Discover products in your social feed, follow your favorite creators, and list items in seconds.'**
  String get onboardingSocialBody;

  /// No description provided for @onboardingHighlightListings.
  ///
  /// In en, this message translates to:
  /// **'LIST YOUR PRODUCTS'**
  String get onboardingHighlightListings;

  /// No description provided for @onboardingHighlightFeed.
  ///
  /// In en, this message translates to:
  /// **'PERSONALIZED FEED'**
  String get onboardingHighlightFeed;

  /// No description provided for @onboardingHighlightReach.
  ///
  /// In en, this message translates to:
  /// **'LOCAL & GLOBAL REACH'**
  String get onboardingHighlightReach;

  /// No description provided for @onboardingNegotiationBody.
  ///
  /// In en, this message translates to:
  /// **'Negotiate offers in real time through direct chat, share photos, and use payment escrow.'**
  String get onboardingNegotiationBody;

  /// No description provided for @onboardingHighlightChat.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE CHAT'**
  String get onboardingHighlightChat;

  /// No description provided for @onboardingHighlightHeldPayment.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT HELD SECURELY'**
  String get onboardingHighlightHeldPayment;

  /// No description provided for @onboardingHighlightDisputes.
  ///
  /// In en, this message translates to:
  /// **'DISPUTE SUPPORT'**
  String get onboardingHighlightDisputes;

  /// No description provided for @onboardingWalletBody.
  ///
  /// In en, this message translates to:
  /// **'Receive sales proceeds transparently, withdraw when eligible, and build a reputation with verified reviews.'**
  String get onboardingWalletBody;

  /// No description provided for @onboardingHighlightPayout.
  ///
  /// In en, this message translates to:
  /// **'PIX / STRIPE PAYOUTS'**
  String get onboardingHighlightPayout;

  /// No description provided for @onboardingHighlightReviews.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED REVIEWS'**
  String get onboardingHighlightReviews;

  /// No description provided for @onboardingHighlightStatement.
  ///
  /// In en, this message translates to:
  /// **'LIVE STATEMENT'**
  String get onboardingHighlightStatement;

  /// No description provided for @onboardingConfirmBiometry.
  ///
  /// In en, this message translates to:
  /// **'Confirm to enable biometric sign-in'**
  String get onboardingConfirmBiometry;

  /// No description provided for @onboardingBiometryEnableFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to enable biometrics.'**
  String get onboardingBiometryEnableFailed;

  /// No description provided for @onboardingBackToStart.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get onboardingBackToStart;

  /// No description provided for @onboardingNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// No description provided for @onboardingBiometryBody.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or Face ID to sign in quickly without entering your password.'**
  String get onboardingBiometryBody;

  /// No description provided for @onboardingBiometryUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Your device does not support biometrics. You can continue without it.'**
  String get onboardingBiometryUnavailableBody;

  /// No description provided for @onboardingUnavailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get onboardingUnavailableOnDevice;

  /// No description provided for @onboardingBiometryAlreadyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometrics are already enabled'**
  String get onboardingBiometryAlreadyEnabled;

  /// No description provided for @onboardingNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Get real-time alerts about sales, chat messages, and order updates.'**
  String get onboardingNotificationsBody;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. You can change biometrics and the animated background anytime in Profile > Settings.'**
  String get onboardingReadyBody;

  /// No description provided for @onboardingStepCount.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String onboardingStepCount(int step, int total);

  /// No description provided for @feedCreatePublication.
  ///
  /// In en, this message translates to:
  /// **'Create post'**
  String get feedCreatePublication;

  /// No description provided for @feedNoPosts.
  ///
  /// In en, this message translates to:
  /// **'NO POSTS YET'**
  String get feedNoPosts;

  /// No description provided for @feedRefreshFailedShowingPosts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh the feed. Showing the posts already loaded.'**
  String get feedRefreshFailedShowingPosts;

  /// No description provided for @feedPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get feedPostTitle;

  /// No description provided for @feedLoginToLike.
  ///
  /// In en, this message translates to:
  /// **'Sign in to like this post.'**
  String get feedLoginToLike;

  /// No description provided for @feedLoginToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save this post.'**
  String get feedLoginToSave;

  /// No description provided for @feedLoginToRepost.
  ///
  /// In en, this message translates to:
  /// **'Sign in to repost this.'**
  String get feedLoginToRepost;

  /// No description provided for @feedLoginToShare.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share this post.'**
  String get feedLoginToShare;

  /// No description provided for @feedShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to share this post.'**
  String get feedShareFailed;

  /// No description provided for @feedShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post shared successfully.'**
  String get feedShareSuccess;

  /// No description provided for @feedReplyingHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply…'**
  String get feedReplyingHint;

  /// No description provided for @feedRepostedBy.
  ///
  /// In en, this message translates to:
  /// **'Reposted by {userName}'**
  String feedRepostedBy(String userName);

  /// No description provided for @feedNoPostsBody.
  ///
  /// In en, this message translates to:
  /// **'Follow people or create your first post.'**
  String get feedNoPostsBody;

  /// No description provided for @feedNoResults.
  ///
  /// In en, this message translates to:
  /// **'NO RESULTS'**
  String get feedNoResults;

  /// No description provided for @feedNoResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Change the filters or search for another term.'**
  String get feedNoResultsBody;

  /// No description provided for @feedNoLikedPosts.
  ///
  /// In en, this message translates to:
  /// **'NO LIKED POSTS'**
  String get feedNoLikedPosts;

  /// No description provided for @feedLikedPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Posts you like will appear here.'**
  String get feedLikedPostsEmpty;

  /// No description provided for @feedNoComments.
  ///
  /// In en, this message translates to:
  /// **'NO COMMENTS'**
  String get feedNoComments;

  /// No description provided for @feedFirstComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get feedFirstComment;

  /// No description provided for @feedPostNotFound.
  ///
  /// In en, this message translates to:
  /// **'Post not found'**
  String get feedPostNotFound;

  /// No description provided for @feedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search posts'**
  String get feedSearchHint;

  /// No description provided for @feedMentionUser.
  ///
  /// In en, this message translates to:
  /// **'Mention a user (optional)'**
  String get feedMentionUser;

  /// No description provided for @feedFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get feedFilterAll;

  /// No description provided for @feedFilterFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFilterFollowing;

  /// No description provided for @feedFilterFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get feedFilterFollowers;

  /// No description provided for @feedFilterSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get feedFilterSocial;

  /// No description provided for @feedFilterSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get feedFilterSales;

  /// No description provided for @feedLogOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get feedLogOutTitle;

  /// No description provided for @feedLogOutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your account.'**
  String get feedLogOutBody;

  /// No description provided for @feedDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get feedDeletePost;

  /// No description provided for @feedDeletePostUndo.
  ///
  /// In en, this message translates to:
  /// **'Post deleted.'**
  String get feedDeletePostUndo;

  /// No description provided for @feedReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get feedReportProblem;

  /// No description provided for @feedSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get feedSettings;

  /// No description provided for @feedSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get feedSignOut;

  /// No description provided for @feedInspectImage.
  ///
  /// In en, this message translates to:
  /// **'Zoom in / inspect image'**
  String get feedInspectImage;

  /// No description provided for @feedRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get feedRemoveImage;

  /// No description provided for @feedCreateStory.
  ///
  /// In en, this message translates to:
  /// **'Create story'**
  String get feedCreateStory;

  /// No description provided for @feedNoStories.
  ///
  /// In en, this message translates to:
  /// **'NO STORIES'**
  String get feedNoStories;

  /// No description provided for @feedNoStoriesBody.
  ///
  /// In en, this message translates to:
  /// **'There are no stories available right now.'**
  String get feedNoStoriesBody;

  /// No description provided for @feedCreateFirstStory.
  ///
  /// In en, this message translates to:
  /// **'Create your first story!'**
  String get feedCreateFirstStory;

  /// No description provided for @feedStoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This story is unavailable.'**
  String get feedStoryUnavailable;

  /// No description provided for @feedStoryCreateHighlight.
  ///
  /// In en, this message translates to:
  /// **'Create a story to start a highlight.'**
  String get feedStoryCreateHighlight;

  /// No description provided for @feedSelectStories.
  ///
  /// In en, this message translates to:
  /// **'SELECT STORIES'**
  String get feedSelectStories;

  /// No description provided for @feedHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlight title'**
  String get feedHighlightTitle;

  /// No description provided for @feedNewHighlight.
  ///
  /// In en, this message translates to:
  /// **'New highlight'**
  String get feedNewHighlight;

  /// No description provided for @feedEditHighlight.
  ///
  /// In en, this message translates to:
  /// **'Edit highlight'**
  String get feedEditHighlight;

  /// No description provided for @feedDeleteHighlight.
  ///
  /// In en, this message translates to:
  /// **'Delete highlight'**
  String get feedDeleteHighlight;

  /// No description provided for @feedHighlightDeleted.
  ///
  /// In en, this message translates to:
  /// **'Highlight deleted.'**
  String get feedHighlightDeleted;

  /// No description provided for @feedDeleteStory.
  ///
  /// In en, this message translates to:
  /// **'Story deleted.'**
  String get feedDeleteStory;

  /// No description provided for @feedAudiencePublic.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC'**
  String get feedAudiencePublic;

  /// No description provided for @feedAudienceCloseFriends.
  ///
  /// In en, this message translates to:
  /// **'CLOSE FRIENDS'**
  String get feedAudienceCloseFriends;

  /// No description provided for @feedEditCloseFriends.
  ///
  /// In en, this message translates to:
  /// **'EDIT CLOSE FRIENDS'**
  String get feedEditCloseFriends;

  /// No description provided for @feedAddText.
  ///
  /// In en, this message translates to:
  /// **'ADD TEXT'**
  String get feedAddText;

  /// No description provided for @feedRemoveText.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get feedRemoveText;

  /// No description provided for @feedTextStyle.
  ///
  /// In en, this message translates to:
  /// **'STYLE'**
  String get feedTextStyle;

  /// No description provided for @feedTextColor.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get feedTextColor;

  /// No description provided for @feedTextLayer.
  ///
  /// In en, this message translates to:
  /// **'LAYER'**
  String get feedTextLayer;

  /// No description provided for @feedComposerSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social post'**
  String get feedComposerSocialTitle;

  /// No description provided for @feedComposerSocialBody.
  ///
  /// In en, this message translates to:
  /// **'Posts, opinions, and conversations for the feed.'**
  String get feedComposerSocialBody;

  /// No description provided for @feedComposerListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell a product'**
  String get feedComposerListingTitle;

  /// No description provided for @feedComposerListingBody.
  ///
  /// In en, this message translates to:
  /// **'A catalog item with price, category, and image.'**
  String get feedComposerListingBody;

  /// No description provided for @feedCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to use the camera.'**
  String get feedCameraUnavailable;

  /// No description provided for @feedMediaPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to select media.'**
  String get feedMediaPickFailed;

  /// No description provided for @feedImageEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to edit the image.'**
  String get feedImageEditFailed;

  /// No description provided for @feedStoryUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload the story.'**
  String get feedStoryUploadFailed;

  /// No description provided for @profileNoPosts.
  ///
  /// In en, this message translates to:
  /// **'NO POSTS YET'**
  String get profileNoPosts;

  /// No description provided for @profileNoPostsBody.
  ///
  /// In en, this message translates to:
  /// **'Posts created by this person will appear here.'**
  String get profileNoPostsBody;

  /// No description provided for @profileRepostsTab.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get profileRepostsTab;

  /// No description provided for @profileListingsTab.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileListingsTab;

  /// No description provided for @profileNoReposts.
  ///
  /// In en, this message translates to:
  /// **'NO REPOSTS YET'**
  String get profileNoReposts;

  /// No description provided for @profileNoRepostsBody.
  ///
  /// In en, this message translates to:
  /// **'Reposts shared by this person will appear here.'**
  String get profileNoRepostsBody;

  /// No description provided for @profileNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get profileNoReviews;

  /// No description provided for @profileReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} =1{1 review} other{{count} reviews}}'**
  String profileReviewCount(int count);

  /// No description provided for @profileLoginToFollow.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow this person.'**
  String get profileLoginToFollow;

  /// No description provided for @profileNoFollowers.
  ///
  /// In en, this message translates to:
  /// **'NO FOLLOWERS'**
  String get profileNoFollowers;

  /// No description provided for @profileNoFollowersBody.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any followers yet.'**
  String get profileNoFollowersBody;

  /// No description provided for @profileNoConnections.
  ///
  /// In en, this message translates to:
  /// **'NO CONNECTIONS'**
  String get profileNoConnections;

  /// No description provided for @profileNoFollowingBody.
  ///
  /// In en, this message translates to:
  /// **'You aren\'t following anyone yet.'**
  String get profileNoFollowingBody;

  /// No description provided for @profileNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'NO PURCHASES YET'**
  String get profileNoPurchases;

  /// No description provided for @profileNoSavedPosts.
  ///
  /// In en, this message translates to:
  /// **'NO SAVED POSTS'**
  String get profileNoSavedPosts;

  /// No description provided for @profileSavedPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your saved posts will appear here.'**
  String get profileSavedPostsEmpty;

  /// No description provided for @profilePurchasesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your purchases will appear here.'**
  String get profilePurchasesEmpty;

  /// No description provided for @profileNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'NO FAVORITES'**
  String get profileNoFavorites;

  /// No description provided for @profileFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on products to save them here.'**
  String get profileFavoritesEmpty;

  /// No description provided for @profileHelpIntro.
  ///
  /// In en, this message translates to:
  /// **'If you have questions or problems, visit the help center:'**
  String get profileHelpIntro;

  /// No description provided for @profileWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FreeBay!'**
  String get profileWelcome;

  /// No description provided for @profileGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to access the full app.'**
  String get profileGuestDescription;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get profileChangePhoto;

  /// No description provided for @profileStorySharePrompt.
  ///
  /// In en, this message translates to:
  /// **'Share a photo or video'**
  String get profileStorySharePrompt;

  /// No description provided for @profileOpenMyStories.
  ///
  /// In en, this message translates to:
  /// **'View my stories'**
  String get profileOpenMyStories;

  /// No description provided for @profileVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile verification'**
  String get profileVerifyTitle;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with area code.'**
  String get profilePhoneInvalid;

  /// No description provided for @profileVerificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent by SMS.'**
  String get profileVerificationCodeSent;

  /// No description provided for @profileVerificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Verify your account to receive a verified badge and build trust on the platform.'**
  String get profileVerificationIntro;

  /// No description provided for @profileEnterPhoneCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}.'**
  String profileEnterPhoneCode(String phone);

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Profile verified!'**
  String get profileVerified;

  /// No description provided for @profileVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your account now has the official verification badge, helping you trade with greater confidence.'**
  String get profileVerifiedBody;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get profilePhoneNumber;

  /// No description provided for @profileSendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send code by SMS'**
  String get profileSendSmsCode;

  /// No description provided for @profileVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get profileVerificationCode;

  /// No description provided for @profileVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get profileVerifyAction;

  /// No description provided for @profileFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get profileFinish;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileNameHint;

  /// No description provided for @profileNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get profileNameMinLength;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about yourself'**
  String get profileBioHint;

  /// No description provided for @profileCityHint.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get profileCityHint;

  /// No description provided for @profileStateHint.
  ///
  /// In en, this message translates to:
  /// **'Your state'**
  String get profileStateHint;

  /// No description provided for @profileTaxIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your CPF (11 digits) or CNPJ (14 digits)'**
  String get profileTaxIdHint;

  /// No description provided for @profileTaxIdLengthInvalid.
  ///
  /// In en, this message translates to:
  /// **'CPF must have 11 digits, CNPJ 14 digits'**
  String get profileTaxIdLengthInvalid;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get profileState;

  /// No description provided for @profileTaxId.
  ///
  /// In en, this message translates to:
  /// **'CPF / CNPJ'**
  String get profileTaxId;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get profileHelpSupport;

  /// No description provided for @profileHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get profileHelpCenter;

  /// No description provided for @profileLoginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get profileLoginToContinue;

  /// No description provided for @profileCloseFriendsFollowers.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWERS'**
  String get profileCloseFriendsFollowers;

  /// No description provided for @profileCloseFriendsInList.
  ///
  /// In en, this message translates to:
  /// **'IN LIST'**
  String get profileCloseFriendsInList;

  /// No description provided for @profileSearchFollowers.
  ///
  /// In en, this message translates to:
  /// **'Search followers'**
  String get profileSearchFollowers;

  /// No description provided for @profileCloseFriendsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'LIST IS EMPTY'**
  String get profileCloseFriendsEmptyTitle;

  /// No description provided for @profileCloseFriendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add followers to share private stories with them.'**
  String get profileCloseFriendsEmpty;

  /// No description provided for @profileSwitchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get profileSwitchToLight;

  /// No description provided for @profileSwitchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get profileSwitchToDark;

  /// No description provided for @profileCacheRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing your profile…'**
  String get profileCacheRefreshing;

  /// No description provided for @profileCacheRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh your profile. Showing saved information.'**
  String get profileCacheRefreshFailed;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile.'**
  String get profileLoadError;

  /// No description provided for @profileLoadMore.
  ///
  /// In en, this message translates to:
  /// **'LOAD MORE'**
  String get profileLoadMore;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the list.'**
  String get profileLoadFailed;

  /// No description provided for @productNoProducts.
  ///
  /// In en, this message translates to:
  /// **'NO PRODUCTS'**
  String get productNoProducts;

  /// No description provided for @productNoProductsBody.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get productNoProductsBody;

  /// No description provided for @productNoCategories.
  ///
  /// In en, this message translates to:
  /// **'NO CATEGORIES'**
  String get productNoCategories;

  /// No description provided for @productNoCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'No categories are available.'**
  String get productNoCategoriesBody;

  /// No description provided for @productNoListings.
  ///
  /// In en, this message translates to:
  /// **'NO LISTINGS YET'**
  String get productNoListings;

  /// No description provided for @productMyListings.
  ///
  /// In en, this message translates to:
  /// **'My listings'**
  String get productMyListings;

  /// No description provided for @productListingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load listings'**
  String get productListingsLoadFailed;

  /// No description provided for @productEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get productEditListing;

  /// No description provided for @productStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productStatusActive;

  /// No description provided for @productStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get productStatusLabel;

  /// No description provided for @productStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get productStatusPaused;

  /// No description provided for @productStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get productStatusSold;

  /// No description provided for @productStatusDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get productStatusDeleted;

  /// No description provided for @productConditionNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get productConditionNew;

  /// No description provided for @productConditionUsed.
  ///
  /// In en, this message translates to:
  /// **'USED'**
  String get productConditionUsed;

  /// No description provided for @productForSaleBadge.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT FOR SALE'**
  String get productForSaleBadge;

  /// No description provided for @productFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get productFavoriteRemove;

  /// No description provided for @productFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get productFavoriteAdd;

  /// No description provided for @productShareMessage.
  ///
  /// In en, this message translates to:
  /// **'{productName} — see it on FreeBay: {url}'**
  String productShareMessage(String productName, String url);

  /// No description provided for @productSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get productSeller;

  /// No description provided for @productNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get productNoDescription;

  /// No description provided for @productClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get productClearFilters;

  /// No description provided for @productClearFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Try clearing the filters'**
  String get productClearFiltersHint;

  /// No description provided for @productListingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Listings from this person will appear here.'**
  String get productListingsEmpty;

  /// No description provided for @productCreateListing.
  ///
  /// In en, this message translates to:
  /// **'Create listing'**
  String get productCreateListing;

  /// No description provided for @productPublishListing.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH LISTING'**
  String get productPublishListing;

  /// No description provided for @productGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get productGallery;

  /// No description provided for @productCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get productCamera;

  /// No description provided for @productFilters.
  ///
  /// In en, this message translates to:
  /// **'FILTERS'**
  String get productFilters;

  /// No description provided for @productAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productAll;

  /// No description provided for @productClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get productClear;

  /// No description provided for @productApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get productApply;

  /// No description provided for @productTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get productTryAgain;

  /// No description provided for @productBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get productBuyNow;

  /// No description provided for @productChatWithSeller.
  ///
  /// In en, this message translates to:
  /// **'Message seller'**
  String get productChatWithSeller;

  /// No description provided for @productCartLabel.
  ///
  /// In en, this message translates to:
  /// **'Cart, {count} items'**
  String productCartLabel(int count);

  /// No description provided for @productConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get productConditionLabel;

  /// No description provided for @productUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get productUnavailableLabel;

  /// No description provided for @productListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get productListingTitle;

  /// No description provided for @productPhotoNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No photo selected'**
  String get productPhotoNotSelected;

  /// No description provided for @productPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get productPhotoSelected;

  /// No description provided for @productNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid title.'**
  String get productNameInvalid;

  /// No description provided for @productDescriptionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Add a more complete description.'**
  String get productDescriptionIncomplete;

  /// No description provided for @productPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get productPriceInvalid;

  /// No description provided for @productCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a category.'**
  String get productCategoryRequired;

  /// No description provided for @productImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a product image.'**
  String get productImageRequired;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Listing created!'**
  String get productCreated;

  /// No description provided for @productTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get productTitleLabel;

  /// No description provided for @productTitleExample.
  ///
  /// In en, this message translates to:
  /// **'Example: iPhone 13 Pro Max 256GB'**
  String get productTitleExample;

  /// No description provided for @productDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Condition, accessories, and usage details…'**
  String get productDescriptionHint;

  /// No description provided for @productPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (R\$)'**
  String get productPriceLabel;

  /// No description provided for @productPriceHint.
  ///
  /// In en, this message translates to:
  /// **'0,00'**
  String get productPriceHint;

  /// No description provided for @productNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get productNew;

  /// No description provided for @productUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get productUsed;

  /// No description provided for @productSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get productSortBy;

  /// No description provided for @productSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get productSortRecent;

  /// No description provided for @productSortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get productSortPriceLowHigh;

  /// No description provided for @productSortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get productSortPriceHighLow;

  /// No description provided for @productSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get productSortPopular;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @productSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get productSelectCategory;

  /// No description provided for @productCategoriesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load categories right now.'**
  String get productCategoriesLoadFailed;

  /// No description provided for @productActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productActive;

  /// No description provided for @productPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get productPaused;

  /// No description provided for @productSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get productSaveChanges;

  /// No description provided for @productFormInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid title, description, and price.'**
  String get productFormInvalid;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Listing updated successfully.'**
  String get productUpdated;

  /// No description provided for @productChooseCategory.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE CATEGORY'**
  String get productChooseCategory;

  /// No description provided for @productLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load product'**
  String get productLoadError;

  /// No description provided for @productLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load'**
  String get productLoadFailed;

  /// No description provided for @productLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get productLoadFailedBody;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add products to continue.'**
  String get cartEmptyBody;

  /// No description provided for @cartTitleCount.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count})'**
  String cartTitleCount(int count);

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @cartProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{productName} (unavailable)'**
  String cartProductUnavailable(String productName);

  /// No description provided for @cartInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'{productName} (insufficient stock)'**
  String cartInsufficientStock(String productName);

  /// No description provided for @accessibilityDecreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity of {productName}'**
  String accessibilityDecreaseQuantity(String productName);

  /// No description provided for @accessibilityIncreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity of {productName}'**
  String accessibilityIncreaseQuantity(String productName);

  /// No description provided for @accessibilityRemoveCartItem.
  ///
  /// In en, this message translates to:
  /// **'Remove {productName} from cart'**
  String accessibilityRemoveCartItem(String productName);

  /// No description provided for @cartContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get cartContinue;

  /// No description provided for @cartGenerateCheckout.
  ///
  /// In en, this message translates to:
  /// **'CREATE CHECKOUT'**
  String get cartGenerateCheckout;

  /// No description provided for @cartCheckoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckoutTitle;

  /// No description provided for @cartCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create checkout.'**
  String get cartCheckoutFailed;

  /// No description provided for @cartCheckoutGenerated.
  ///
  /// In en, this message translates to:
  /// **'CHECKOUT CREATED'**
  String get cartCheckoutGenerated;

  /// No description provided for @cartTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total ({count, plural, =1{1 item} other{{count} items}})'**
  String cartTotalItems(int count);

  /// No description provided for @cartTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String cartTotalAmount(String amount);

  /// No description provided for @ordersCreatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order created} other{{count} orders created}}'**
  String ordersCreatedCount(int count);

  /// No description provided for @cartPayNow.
  ///
  /// In en, this message translates to:
  /// **'PAY NOW'**
  String get cartPayNow;

  /// No description provided for @cartPayByCard.
  ///
  /// In en, this message translates to:
  /// **'PAY BY CARD'**
  String get cartPayByCard;

  /// No description provided for @cartViewOrders.
  ///
  /// In en, this message translates to:
  /// **'VIEW MY ORDERS'**
  String get cartViewOrders;

  /// No description provided for @cartItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart.'**
  String get cartItemRemoved;

  /// No description provided for @paymentPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get paymentPayNow;

  /// No description provided for @paymentPayByCard.
  ///
  /// In en, this message translates to:
  /// **'Pay by card'**
  String get paymentPayByCard;

  /// No description provided for @paymentViewOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get paymentViewOrder;

  /// No description provided for @paymentFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get paymentFullName;

  /// No description provided for @paymentPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentPageTitle;

  /// No description provided for @paymentProductMissing.
  ///
  /// In en, this message translates to:
  /// **'Product was not specified.'**
  String get paymentProductMissing;

  /// No description provided for @paymentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get paymentNameRequired;

  /// No description provided for @paymentStripeCheckout.
  ///
  /// In en, this message translates to:
  /// **'Stripe checkout'**
  String get paymentStripeCheckout;

  /// No description provided for @paymentGenerated.
  ///
  /// In en, this message translates to:
  /// **'Payment created'**
  String get paymentGenerated;

  /// No description provided for @paymentExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at {date}'**
  String paymentExpiresAt(String date);

  /// No description provided for @paymentCpfCnpj.
  ///
  /// In en, this message translates to:
  /// **'CPF or CNPJ'**
  String get paymentCpfCnpj;

  /// No description provided for @paymentInvalidCpfCnpj.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid CPF or CNPJ'**
  String get paymentInvalidCpfCnpj;

  /// No description provided for @paymentPayWithStripe.
  ///
  /// In en, this message translates to:
  /// **'PAY WITH STRIPE'**
  String get paymentPayWithStripe;

  /// No description provided for @paymentCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to start checkout. Please try again.'**
  String get paymentCheckoutFailed;

  /// No description provided for @paymentOrderPending.
  ///
  /// In en, this message translates to:
  /// **'Your order is awaiting payment confirmation.'**
  String get paymentOrderPending;

  /// No description provided for @paymentProviderConfirmationNote.
  ///
  /// In en, this message translates to:
  /// **'Payment is confirmed only after the provider responds.'**
  String get paymentProviderConfirmationNote;

  /// No description provided for @paymentInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid payment link'**
  String get paymentInvalidLink;

  /// No description provided for @paymentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open payment'**
  String get paymentOpenFailed;

  /// No description provided for @paymentSubmittedPending.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted! Awaiting confirmation.'**
  String get paymentSubmittedPending;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @ordersNoDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes'**
  String get ordersNoDisputes;

  /// No description provided for @ordersNoDisputesBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t opened a dispute yet.'**
  String get ordersNoDisputesBody;

  /// No description provided for @ordersSendEvidence.
  ///
  /// In en, this message translates to:
  /// **'Send evidence'**
  String get ordersSendEvidence;

  /// No description provided for @ordersEvidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your evidence…'**
  String get ordersEvidenceHint;

  /// No description provided for @ordersEvidenceSent.
  ///
  /// In en, this message translates to:
  /// **'Evidence sent successfully'**
  String get ordersEvidenceSent;

  /// No description provided for @ordersDescribeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get ordersDescribeProblem;

  /// No description provided for @ordersDescribeReason.
  ///
  /// In en, this message translates to:
  /// **'Describe the reason for the dispute'**
  String get ordersDescribeReason;

  /// No description provided for @ordersDisputeOpened.
  ///
  /// In en, this message translates to:
  /// **'Dispute opened successfully'**
  String get ordersDisputeOpened;

  /// No description provided for @ordersServerConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server'**
  String get ordersServerConnectionError;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @commonUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get commonUnknownUser;

  /// No description provided for @reviewTypeBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get reviewTypeBuyer;

  /// No description provided for @reviewTypeSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get reviewTypeSeller;

  /// No description provided for @reviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'NO REVIEWS YET'**
  String get reviewsEmptyTitle;

  /// No description provided for @reviewsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This user hasn\'t received reviews yet.'**
  String get reviewsEmptyBody;

  /// No description provided for @reviewsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get reviewsCreateTitle;

  /// No description provided for @reviewsSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Select a rating from 1 to 5 stars.'**
  String get reviewsSelectRating;

  /// No description provided for @reviewsSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully!'**
  String get reviewsSubmitSuccess;

  /// No description provided for @reviewsSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get reviewsSeller;

  /// No description provided for @reviewsBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get reviewsBuyer;

  /// No description provided for @reviewsYourRating.
  ///
  /// In en, this message translates to:
  /// **'YOUR RATING'**
  String get reviewsYourRating;

  /// No description provided for @reviewsCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'COMMENT (OPTIONAL)'**
  String get reviewsCommentOptional;

  /// No description provided for @reviewsCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your experience…'**
  String get reviewsCommentHint;

  /// No description provided for @reviewsPhotosOptional.
  ///
  /// In en, this message translates to:
  /// **'PHOTOS (OPTIONAL)'**
  String get reviewsPhotosOptional;

  /// No description provided for @reviewsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get reviewsSubmit;

  /// No description provided for @walletEmptyTransactions.
  ///
  /// In en, this message translates to:
  /// **'NO TRANSACTIONS'**
  String get walletEmptyTransactions;

  /// No description provided for @walletTransactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your transactions will appear here.'**
  String get walletTransactionsEmpty;

  /// No description provided for @walletRetry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get walletRetry;

  /// No description provided for @walletLoadMore.
  ///
  /// In en, this message translates to:
  /// **'LOAD MORE'**
  String get walletLoadMore;

  /// No description provided for @walletTitleBrutalist.
  ///
  /// In en, this message translates to:
  /// **'WALLET'**
  String get walletTitleBrutalist;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalanceLabel;

  /// No description provided for @walletTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get walletTotalBalance;

  /// No description provided for @walletAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get walletAvailable;

  /// No description provided for @walletPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get walletPending;

  /// No description provided for @walletGuestDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your balance and set up your payouts.'**
  String get walletGuestDescription;

  /// No description provided for @walletStripeOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Stripe.'**
  String get walletStripeOpenFailed;

  /// No description provided for @notificationsNone.
  ///
  /// In en, this message translates to:
  /// **'NO NOTIFICATIONS'**
  String get notificationsNone;

  /// No description provided for @notificationsHeading.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsHeading;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all notifications as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications. Pull to refresh or try again shortly.'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified about orders, messages, and more.'**
  String get notificationsEmptyBody;

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get bugReportTitle;

  /// No description provided for @bugReportWhatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get bugReportWhatHappened;

  /// No description provided for @bugReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get bugReportSubmitted;

  /// No description provided for @bugReportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem before sending.'**
  String get bugReportDescriptionRequired;

  /// No description provided for @bugReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you!'**
  String get bugReportThanks;

  /// No description provided for @disputeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open dispute'**
  String get disputeOpen;

  /// No description provided for @disputeDescribeProblem.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem'**
  String get disputeDescribeProblem;

  /// No description provided for @disputeDescribeProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Explain in detail what went wrong with the order.'**
  String get disputeDescribeProblemHint;

  /// No description provided for @disputeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'For example: the item differs from the listing, or I didn\'t receive it…'**
  String get disputeReasonHint;

  /// No description provided for @disputeReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Describe the reason for the dispute'**
  String get disputeReasonRequired;

  /// No description provided for @disputeOpenedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute opened successfully'**
  String get disputeOpenedSuccess;

  /// No description provided for @disputeOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the dispute.'**
  String get disputeOpenFailed;

  /// No description provided for @disputeSendEvidence.
  ///
  /// In en, this message translates to:
  /// **'Send evidence'**
  String get disputeSendEvidence;

  /// No description provided for @disputeEvidenceHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your evidence…'**
  String get disputeEvidenceHint;

  /// No description provided for @disputeEvidenceSent.
  ///
  /// In en, this message translates to:
  /// **'Evidence sent successfully'**
  String get disputeEvidenceSent;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'NO MESSAGES'**
  String get chatNoMessages;

  /// No description provided for @chatFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send the first message to start the conversation.'**
  String get chatFirstMessage;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations…'**
  String get chatSearchHint;

  /// No description provided for @chatSearchPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Search people…'**
  String get chatSearchPeopleHint;

  /// No description provided for @chatSearchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get chatSearchProductHint;

  /// No description provided for @chatForwardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations or contacts…'**
  String get chatForwardSearchHint;

  /// No description provided for @chatNoArchived.
  ///
  /// In en, this message translates to:
  /// **'NO ARCHIVED CONVERSATIONS'**
  String get chatNoArchived;

  /// No description provided for @chatArchivedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load archived conversations'**
  String get chatArchivedLoadError;

  /// No description provided for @chatNoConversation.
  ///
  /// In en, this message translates to:
  /// **'NO CONVERSATIONS'**
  String get chatNoConversation;

  /// No description provided for @chatNoForwardResults.
  ///
  /// In en, this message translates to:
  /// **'No conversations found to forward to.'**
  String get chatNoForwardResults;

  /// No description provided for @chatFollowedPeople.
  ///
  /// In en, this message translates to:
  /// **'People you follow'**
  String get chatFollowedPeople;

  /// No description provided for @chatFollowNobodyTitle.
  ///
  /// In en, this message translates to:
  /// **'NO FOLLOWING'**
  String get chatFollowNobodyTitle;

  /// No description provided for @chatSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get chatSuggestions;

  /// No description provided for @chatNoSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'NO SUGGESTIONS'**
  String get chatNoSuggestionsTitle;

  /// No description provided for @chatNoUsers.
  ///
  /// In en, this message translates to:
  /// **'NO USERS'**
  String get chatNoUsers;

  /// No description provided for @chatTryAnotherName.
  ///
  /// In en, this message translates to:
  /// **'Try searching for another name.'**
  String get chatTryAnotherName;

  /// No description provided for @chatFollowNobody.
  ///
  /// In en, this message translates to:
  /// **'You aren\'t following anyone yet.'**
  String get chatFollowNobody;

  /// No description provided for @chatNoSuggestions.
  ///
  /// In en, this message translates to:
  /// **'There are no user suggestions right now.'**
  String get chatNoSuggestions;

  /// No description provided for @chatNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'NO FAVORITES'**
  String get chatNoFavorites;

  /// No description provided for @chatFavoriteHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a message and tap the star to save it.'**
  String get chatFavoriteHint;

  /// No description provided for @chatRemoveStarred.
  ///
  /// In en, this message translates to:
  /// **'Remove message from saved'**
  String get chatRemoveStarred;

  /// No description provided for @chatConversationTheme.
  ///
  /// In en, this message translates to:
  /// **'Conversation theme'**
  String get chatConversationTheme;

  /// No description provided for @chatNotificationsMuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications muted'**
  String get chatNotificationsMuted;

  /// No description provided for @chatNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get chatNotificationsEnabled;

  /// No description provided for @chatBlockConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {userName}? You won\'t receive any more messages from this person.'**
  String chatBlockConfirmation(String userName);

  /// No description provided for @chatConfirmBlock.
  ///
  /// In en, this message translates to:
  /// **'Confirm block'**
  String get chatConfirmBlock;

  /// No description provided for @chatUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get chatUserBlocked;

  /// No description provided for @chatDeleteAllMessagesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete all messages in this conversation?'**
  String get chatDeleteAllMessagesConfirmation;

  /// No description provided for @chatConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm and delete'**
  String get chatConfirmDelete;

  /// No description provided for @chatThemeDefault.
  ///
  /// In en, this message translates to:
  /// **'FreeBay magenta'**
  String get chatThemeDefault;

  /// No description provided for @chatThemeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean blue'**
  String get chatThemeOcean;

  /// No description provided for @chatBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get chatBlockUser;

  /// No description provided for @chatDeleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get chatDeleteConversation;

  /// No description provided for @chatDeleteConversationUndo.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted.'**
  String get chatDeleteConversationUndo;

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get chatOptions;

  /// No description provided for @chatCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get chatCustomize;

  /// No description provided for @chatPrivateMessages.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE MESSAGES'**
  String get chatPrivateMessages;

  /// No description provided for @chatAddAttachment.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get chatAddAttachment;

  /// No description provided for @chatImageGif.
  ///
  /// In en, this message translates to:
  /// **'IMAGE / GIF'**
  String get chatImageGif;

  /// No description provided for @chatVideo.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get chatVideo;

  /// No description provided for @chatProduct.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT'**
  String get chatProduct;

  /// No description provided for @chatMakeOffer.
  ///
  /// In en, this message translates to:
  /// **'MAKE AN OFFER'**
  String get chatMakeOffer;

  /// No description provided for @chatOfferProduct.
  ///
  /// In en, this message translates to:
  /// **'PRODUCT / ITEM'**
  String get chatOfferProduct;

  /// No description provided for @chatOfferProductHint.
  ///
  /// In en, this message translates to:
  /// **'Listed product name'**
  String get chatOfferProductHint;

  /// No description provided for @chatOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original price: {amount}'**
  String chatOriginalPrice(String amount);

  /// No description provided for @chatYourOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'YOUR OFFER (R\$)'**
  String get chatYourOfferPrice;

  /// No description provided for @chatOfferPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 250,00'**
  String get chatOfferPriceHint;

  /// No description provided for @chatOfferMessage.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE (OPTIONAL)'**
  String get chatOfferMessage;

  /// No description provided for @chatOfferMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Example: I can pick it up today…'**
  String get chatOfferMessageHint;

  /// No description provided for @chatOfferSend.
  ///
  /// In en, this message translates to:
  /// **'SEND OFFER'**
  String get chatOfferSend;

  /// No description provided for @chatOfferAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT'**
  String get chatOfferAccept;

  /// No description provided for @chatSendText.
  ///
  /// In en, this message translates to:
  /// **'SEND MESSAGE'**
  String get chatSendText;

  /// No description provided for @chatConfirmSendLocation.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM AND SEND LOCATION'**
  String get chatConfirmSendLocation;

  /// No description provided for @chatSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get chatSelectLocation;

  /// No description provided for @chatForwardTitle.
  ///
  /// In en, this message translates to:
  /// **'FORWARD MESSAGE'**
  String get chatForwardTitle;

  /// No description provided for @chatForwardSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message forwarded successfully!} other{{count} messages forwarded successfully!}}'**
  String chatForwardSuccessCount(int count);

  /// No description provided for @chatForwardSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 message selected} other{{count} messages selected}}'**
  String chatForwardSelectedCount(int count);

  /// No description provided for @chatConversationOptions.
  ///
  /// In en, this message translates to:
  /// **'CONVERSATION OPTIONS'**
  String get chatConversationOptions;

  /// No description provided for @chatThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get chatThemeTitle;

  /// No description provided for @chatBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'BLOCK USER'**
  String get chatBlockTitle;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE CONVERSATION'**
  String get chatDeleteTitle;

  /// No description provided for @chatCancelSelection.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get chatCancelSelection;

  /// No description provided for @chatCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopy;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get chatFavorite;

  /// No description provided for @chatSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String chatSelectedCount(int count);

  /// No description provided for @chatDeletedMessages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Message deleted.} other{{count} messages deleted.}}'**
  String chatDeletedMessages(int count);

  /// No description provided for @chatDeleteSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete some messages.'**
  String get chatDeleteSomeFailed;

  /// No description provided for @chatForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatForward;

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDelete;

  /// No description provided for @chatReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get chatReport;

  /// No description provided for @chatViewOnce.
  ///
  /// In en, this message translates to:
  /// **'View once'**
  String get chatViewOnce;

  /// No description provided for @chatImageCaption.
  ///
  /// In en, this message translates to:
  /// **'ADD CAPTION'**
  String get chatImageCaption;

  /// No description provided for @chatVideoCaption.
  ///
  /// In en, this message translates to:
  /// **'ADD CAPTION'**
  String get chatVideoCaption;

  /// No description provided for @chatVideoSend.
  ///
  /// In en, this message translates to:
  /// **'SEND VIDEO'**
  String get chatVideoSend;

  /// No description provided for @chatDiscardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get chatDiscardChanges;

  /// No description provided for @chatDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get chatDiscardConfirm;

  /// No description provided for @chatEditorCrop.
  ///
  /// In en, this message translates to:
  /// **'CROP'**
  String get chatEditorCrop;

  /// No description provided for @chatEditorAdjust.
  ///
  /// In en, this message translates to:
  /// **'ADJUST'**
  String get chatEditorAdjust;

  /// No description provided for @chatEditorFilter.
  ///
  /// In en, this message translates to:
  /// **'FILTER'**
  String get chatEditorFilter;

  /// No description provided for @chatEditorText.
  ///
  /// In en, this message translates to:
  /// **'TEXT'**
  String get chatEditorText;

  /// No description provided for @chatEditorDraw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get chatEditorDraw;

  /// No description provided for @chatEditorPreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get chatEditorPreview;

  /// No description provided for @chatAspectFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get chatAspectFree;

  /// No description provided for @chatEditorAddText.
  ///
  /// In en, this message translates to:
  /// **'ADD TEXT'**
  String get chatEditorAddText;

  /// No description provided for @chatEditorTitleCrop.
  ///
  /// In en, this message translates to:
  /// **'CROP'**
  String get chatEditorTitleCrop;

  /// No description provided for @chatEditorTitleAdjust.
  ///
  /// In en, this message translates to:
  /// **'ADJUSTMENTS'**
  String get chatEditorTitleAdjust;

  /// No description provided for @chatEditorTitleFilters.
  ///
  /// In en, this message translates to:
  /// **'FILTERS'**
  String get chatEditorTitleFilters;

  /// No description provided for @chatEditorTitleText.
  ///
  /// In en, this message translates to:
  /// **'TEXT'**
  String get chatEditorTitleText;

  /// No description provided for @chatEditorTitleDraw.
  ///
  /// In en, this message translates to:
  /// **'DRAW'**
  String get chatEditorTitleDraw;

  /// No description provided for @chatEditorTextDefault.
  ///
  /// In en, this message translates to:
  /// **'NEW TEXT'**
  String get chatEditorTextDefault;

  /// No description provided for @chatEditorProcessingError.
  ///
  /// In en, this message translates to:
  /// **'Unable to process the image'**
  String get chatEditorProcessingError;

  /// No description provided for @chatEditorFilterNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get chatEditorFilterNormal;

  /// No description provided for @chatEditorFilterClarendon.
  ///
  /// In en, this message translates to:
  /// **'Clarendon'**
  String get chatEditorFilterClarendon;

  /// No description provided for @chatEditorFilterGingham.
  ///
  /// In en, this message translates to:
  /// **'Gingham'**
  String get chatEditorFilterGingham;

  /// No description provided for @chatEditorFilterMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get chatEditorFilterMoon;

  /// No description provided for @chatEditorFilterLark.
  ///
  /// In en, this message translates to:
  /// **'Lark'**
  String get chatEditorFilterLark;

  /// No description provided for @chatEditorFilterReyes.
  ///
  /// In en, this message translates to:
  /// **'Reyes'**
  String get chatEditorFilterReyes;

  /// No description provided for @chatEditorFilterJuno.
  ///
  /// In en, this message translates to:
  /// **'Juno'**
  String get chatEditorFilterJuno;

  /// No description provided for @chatRotateMinus90.
  ///
  /// In en, this message translates to:
  /// **'-90°'**
  String get chatRotateMinus90;

  /// No description provided for @chatRotatePlus90.
  ///
  /// In en, this message translates to:
  /// **'+90°'**
  String get chatRotatePlus90;

  /// No description provided for @chatImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatImageLabel;

  /// No description provided for @chatImageEditorLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit image'**
  String get chatImageEditorLabel;

  /// No description provided for @chatVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get chatVideoLabel;

  /// No description provided for @chatVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceLabel;

  /// No description provided for @chatLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Shared location'**
  String get chatLocationLabel;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get commonUndo;

  /// No description provided for @commonPublish.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get commonPublish;

  /// No description provided for @commonUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get commonUpload;

  /// No description provided for @commonSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get commonSelect;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get commonVerify;

  /// No description provided for @commonFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get commonFinish;

  /// No description provided for @commonChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get commonChoose;

  /// No description provided for @commonCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get commonCamera;

  /// No description provided for @commonGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get commonGallery;

  /// No description provided for @commonPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get commonPublic;

  /// No description provided for @commonPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get commonPrivate;

  /// No description provided for @commonYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// No description provided for @imagePickerOptions.
  ///
  /// In en, this message translates to:
  /// **'IMAGE OPTIONS'**
  String get imagePickerOptions;

  /// No description provided for @safeLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get safeLinkCopied;

  /// No description provided for @safeLinkDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get safeLinkDestination;

  /// No description provided for @safeLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get safeLinkCopy;

  /// No description provided for @commonOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get commonOptionalLabel;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'There was a problem communicating with the server.'**
  String get errorServer;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorCache.
  ///
  /// In en, this message translates to:
  /// **'Unable to read local data.'**
  String get errorCache;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'The information is invalid.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item was not found.'**
  String get errorNotFound;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorForbidden;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this action.'**
  String get errorConflict;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get errorTooManyRequests;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The service is unavailable. Please try again later.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get errorRequestCancelled;

  /// No description provided for @errorConnectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'A connection security error occurred.'**
  String get errorConnectionSecurity;

  /// No description provided for @errorConnectionServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server.'**
  String get errorConnectionServer;

  /// No description provided for @errorUploadInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'The server returned an invalid file URL.'**
  String get errorUploadInvalidUrl;

  /// No description provided for @errorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload the file.'**
  String get errorUploadFailed;

  /// No description provided for @errorUploadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large. Maximum size: {maxSizeMb} MB'**
  String errorUploadTooLarge(int maxSizeMb);

  /// No description provided for @errorUploadConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection error while uploading the file.'**
  String get errorUploadConnection;

  /// No description provided for @errorImageProcessing.
  ///
  /// In en, this message translates to:
  /// **'Unable to process the image.'**
  String get errorImageProcessing;

  /// No description provided for @errorScreenLoad.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading this screen.'**
  String get errorScreenLoad;

  /// No description provided for @dateSeparatorToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get dateSeparatorToday;

  /// No description provided for @dateSeparatorYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get dateSeparatorYesterday;

  /// No description provided for @dateSeparatorLong.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String dateSeparatorLong(int day, String month, int year);

  /// No description provided for @dateMonthJanuary.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get dateMonthJanuary;

  /// No description provided for @dateMonthFebruary.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get dateMonthFebruary;

  /// No description provided for @dateMonthMarch.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get dateMonthMarch;

  /// No description provided for @dateMonthApril.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get dateMonthApril;

  /// No description provided for @dateMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get dateMonthMay;

  /// No description provided for @dateMonthJune.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get dateMonthJune;

  /// No description provided for @dateMonthJuly.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get dateMonthJuly;

  /// No description provided for @dateMonthAugust.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get dateMonthAugust;

  /// No description provided for @dateMonthSeptember.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get dateMonthSeptember;

  /// No description provided for @dateMonthOctober.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get dateMonthOctober;

  /// No description provided for @dateMonthNovember.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get dateMonthNovember;

  /// No description provided for @dateMonthDecember.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dateMonthDecember;

  /// No description provided for @timeAgoNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeAgoWeeks(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String timeAgoMonths(int count);

  /// No description provided for @timeAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String timeAgoYears(int count);

  /// No description provided for @timeCompactMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String timeCompactMinutes(int count);

  /// No description provided for @timeCompactHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String timeCompactHours(int count);

  /// No description provided for @timeCompactDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String timeCompactDays(int count);

  /// No description provided for @timeCompactWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w'**
  String timeCompactWeeks(int count);

  /// No description provided for @timeCompactMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}mo'**
  String timeCompactMonths(int count);

  /// No description provided for @timeFormat24Hour.
  ///
  /// In en, this message translates to:
  /// **'HH:mm'**
  String get timeFormat24Hour;

  /// No description provided for @dateFormatShort.
  ///
  /// In en, this message translates to:
  /// **'MM/dd/yyyy'**
  String get dateFormatShort;

  /// No description provided for @platformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get platformAndroid;

  /// No description provided for @platformIos.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get platformIos;

  /// No description provided for @accessibilityClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get accessibilityClose;

  /// No description provided for @accessibilityBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get accessibilityBack;

  /// No description provided for @accessibilityOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open {name}\'s profile'**
  String accessibilityOpenProfile(String name);

  /// No description provided for @accessibilityLikeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No likes} =1{1 like} other{{count} likes}}'**
  String accessibilityLikeCount(int count);

  /// No description provided for @accessibilityCommentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No comments} =1{1 comment} other{{count} comments}}'**
  String accessibilityCommentCount(int count);

  /// No description provided for @accessibilitySelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get accessibilitySelected;

  /// No description provided for @accessibilityNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get accessibilityNotSelected;

  /// No description provided for @accessibilityLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get accessibilityLoading;

  /// No description provided for @accessibilityRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get accessibilityRetry;

  /// No description provided for @accessibilityRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get accessibilityRemove;

  /// No description provided for @accessibilityPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get accessibilityPlayVideo;

  /// No description provided for @accessibilityReplayVideo.
  ///
  /// In en, this message translates to:
  /// **'Replay video'**
  String get accessibilityReplayVideo;

  /// No description provided for @accessibilityVideoPosition.
  ///
  /// In en, this message translates to:
  /// **'Video position'**
  String get accessibilityVideoPosition;

  /// No description provided for @accessibilityPauseVideo.
  ///
  /// In en, this message translates to:
  /// **'Pause video'**
  String get accessibilityPauseVideo;

  /// No description provided for @accessibilityMuteVideo.
  ///
  /// In en, this message translates to:
  /// **'Mute video'**
  String get accessibilityMuteVideo;

  /// No description provided for @accessibilityUnmuteVideo.
  ///
  /// In en, this message translates to:
  /// **'Unmute video'**
  String get accessibilityUnmuteVideo;

  /// No description provided for @accessibilityOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Open image'**
  String get accessibilityOpenImage;

  /// No description provided for @accessibilityExpandImage.
  ///
  /// In en, this message translates to:
  /// **'Expand image'**
  String get accessibilityExpandImage;

  /// No description provided for @accessibilityCollapseImage.
  ///
  /// In en, this message translates to:
  /// **'Collapse image'**
  String get accessibilityCollapseImage;

  /// No description provided for @accessibilityMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get accessibilityMoreOptions;

  /// No description provided for @accessibilitySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get accessibilitySearch;

  /// No description provided for @accessibilitySend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get accessibilitySend;

  /// No description provided for @accessibilityAttach.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get accessibilityAttach;

  /// No description provided for @accessibilityCamera.
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get accessibilityCamera;

  /// No description provided for @accessibilityGallery.
  ///
  /// In en, this message translates to:
  /// **'Open gallery'**
  String get accessibilityGallery;

  /// No description provided for @accessibilityTabSelected.
  ///
  /// In en, this message translates to:
  /// **'{label}, selected tab'**
  String accessibilityTabSelected(String label);

  /// No description provided for @accessibilityProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent complete'**
  String accessibilityProgress(int percent);

  /// No description provided for @accessibilityItemPosition.
  ///
  /// In en, this message translates to:
  /// **'Item {position} of {total}'**
  String accessibilityItemPosition(int position, int total);

  /// No description provided for @accessibilityCartCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Cart is empty} =1{1 item in cart} other{{count} items in cart}}'**
  String accessibilityCartCount(int count);

  /// No description provided for @accessibilityUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread messages} =1{1 unread message} other{{count} unread messages}}'**
  String accessibilityUnreadCount(int count);

  /// No description provided for @accessibilityStoryPosition.
  ///
  /// In en, this message translates to:
  /// **'Story {position} of {total}'**
  String accessibilityStoryPosition(int position, int total);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// No description provided for @profileBiometry.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get profileBiometry;

  /// No description provided for @profileBiometryLogin.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics to sign in'**
  String get profileBiometryLogin;

  /// No description provided for @profileBiometryUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update biometrics.'**
  String get profileBiometryUpdateFailed;

  /// No description provided for @profileBiometryRevocationPending.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in is disabled on this device, but server revocation could not be confirmed. Retry while online.'**
  String get profileBiometryRevocationPending;

  /// No description provided for @stepUpConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it’s you'**
  String get stepUpConfirmTitle;

  /// No description provided for @stepUpPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get stepUpPassword;

  /// No description provided for @stepUpGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get stepUpGoogle;

  /// No description provided for @stepUpApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get stepUpApple;

  /// No description provided for @stepUpBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Confirm with biometrics'**
  String get stepUpBiometrics;

  /// No description provided for @profileConfirmBiometry.
  ///
  /// In en, this message translates to:
  /// **'Confirm to enable biometric sign-in'**
  String get profileConfirmBiometry;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileThemeSystem;

  /// No description provided for @profileCloseFriendsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose who can see your private stories'**
  String get profileCloseFriendsDescription;

  /// No description provided for @profileAnimatedBackground.
  ///
  /// In en, this message translates to:
  /// **'Animated background'**
  String get profileAnimatedBackground;

  /// No description provided for @profileStaticBackgroundDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn off to use a static background'**
  String get profileStaticBackgroundDescription;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Account verification'**
  String get profileVerification;

  /// No description provided for @profileRequestVerification.
  ///
  /// In en, this message translates to:
  /// **'Request a verification badge'**
  String get profileRequestVerification;

  /// No description provided for @profileAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Your profile is already verified!'**
  String get profileAlreadyVerified;

  /// No description provided for @reviewsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this review.'**
  String get reviewsOpenFailed;

  /// No description provided for @safeLinkBlocked.
  ///
  /// In en, this message translates to:
  /// **'This link was blocked for security reasons.'**
  String get safeLinkBlocked;

  /// No description provided for @safeLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid address.'**
  String get safeLinkInvalid;

  /// No description provided for @safeLinkBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the browser.'**
  String get safeLinkBrowserFailed;

  /// No description provided for @safeLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the link.'**
  String get safeLinkOpenFailed;

  /// No description provided for @safeLinkBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ BLOCKED LINK'**
  String get safeLinkBlockedTitle;

  /// No description provided for @safeLinkSuspiciousTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ SUSPICIOUS LINK WARNING'**
  String get safeLinkSuspiciousTitle;

  /// No description provided for @safeLinkExternalTitle.
  ///
  /// In en, this message translates to:
  /// **'EXTERNAL LINK WARNING'**
  String get safeLinkExternalTitle;

  /// No description provided for @safeLinkDangerBadge.
  ///
  /// In en, this message translates to:
  /// **'DANGEROUS / NOT ALLOWED'**
  String get safeLinkDangerBadge;

  /// No description provided for @safeLinkUnverifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'CAUTION: UNVERIFIED'**
  String get safeLinkUnverifiedBadge;

  /// No description provided for @safeLinkExternalBadge.
  ///
  /// In en, this message translates to:
  /// **'EXTERNAL LINK'**
  String get safeLinkExternalBadge;

  /// No description provided for @safeLinkDangerExplanation.
  ///
  /// In en, this message translates to:
  /// **'This link was classified as dangerous and cannot be opened directly by FreeBay to protect your account and device.'**
  String get safeLinkDangerExplanation;

  /// No description provided for @safeLinkExternalExplanation.
  ///
  /// In en, this message translates to:
  /// **'You are leaving FreeBay. Never share your passwords or card details, or make payments outside our escrow protection.'**
  String get safeLinkExternalExplanation;

  /// No description provided for @safeLinkReturnSafely.
  ///
  /// In en, this message translates to:
  /// **'RETURN SAFELY'**
  String get safeLinkReturnSafely;

  /// No description provided for @safeLinkContinueExternal.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO EXTERNAL SITE'**
  String get safeLinkContinueExternal;

  /// No description provided for @ordersMyOrders.
  ///
  /// In en, this message translates to:
  /// **'MY ORDERS'**
  String get ordersMyOrders;

  /// No description provided for @ordersPurchasesTab.
  ///
  /// In en, this message translates to:
  /// **'PURCHASES'**
  String get ordersPurchasesTab;

  /// No description provided for @ordersSalesTab.
  ///
  /// In en, this message translates to:
  /// **'SALES'**
  String get ordersSalesTab;

  /// No description provided for @disputesMyTitle.
  ///
  /// In en, this message translates to:
  /// **'MY DISPUTES'**
  String get disputesMyTitle;

  /// No description provided for @disputeDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'DISPUTE DETAILS'**
  String get disputeDetailTitle;

  /// No description provided for @disputeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Dispute not found'**
  String get disputeNotFound;

  /// No description provided for @disputeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get disputeStatusLabel;

  /// No description provided for @disputeReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get disputeReasonLabel;

  /// No description provided for @disputeOpenedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get disputeOpenedAtLabel;

  /// No description provided for @disputeResolvedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get disputeResolvedAtLabel;

  /// No description provided for @disputeResolutionLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get disputeResolutionLabel;

  /// No description provided for @profileFollowersTitle.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWERS'**
  String get profileFollowersTitle;

  /// No description provided for @profileFollowingTitle.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWING'**
  String get profileFollowingTitle;

  /// No description provided for @profileSavedPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'SAVED POSTS'**
  String get profileSavedPostsTitle;

  /// No description provided for @profileBlockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED USERS'**
  String get profileBlockedUsersTitle;

  /// No description provided for @profileNoBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone'**
  String get profileNoBlockedUsers;

  /// No description provided for @profileUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get profileUnblock;

  /// No description provided for @profileFavoritesHeading.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get profileFavoritesHeading;

  /// No description provided for @profileEditLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile'**
  String get profileEditLoadError;

  /// No description provided for @chatNewTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW CONVERSATION'**
  String get chatNewTitle;

  /// No description provided for @chatMessageProductAvailability.
  ///
  /// In en, this message translates to:
  /// **'Hi, is this still available?'**
  String get chatMessageProductAvailability;

  /// No description provided for @closeFriendsPrivacyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this list. Removing someone immediately ends their access to private stories and highlights.'**
  String get closeFriendsPrivacyExplanation;

  /// No description provided for @closeFriendsRemove.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get closeFriendsRemove;

  /// No description provided for @closeFriendsAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get closeFriendsAdd;

  /// No description provided for @chatProductContactTitle.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE ABOUT PRODUCT'**
  String get chatProductContactTitle;

  /// No description provided for @chatStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to start conversation'**
  String get chatStartFailed;

  /// No description provided for @chatDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get chatDetailsTitle;

  /// No description provided for @chatMediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get chatMediaTab;

  /// No description provided for @chatFavoritesTab.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get chatFavoritesTab;

  /// No description provided for @chatActionsTab.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get chatActionsTab;

  /// No description provided for @chatThemeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get chatThemeUpdated;

  /// No description provided for @chatOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get chatOnlineNow;

  /// No description provided for @chatLastSeenNow.
  ///
  /// In en, this message translates to:
  /// **'Seen just now'**
  String get chatLastSeenNow;

  /// No description provided for @chatLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Seen {count}m ago'**
  String chatLastSeenMinutes(int count);

  /// No description provided for @chatLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'Seen {count}h ago'**
  String chatLastSeenHours(int count);

  /// No description provided for @chatLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'Seen {count}d ago'**
  String chatLastSeenDays(int count);

  /// No description provided for @chatOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'ORDER'**
  String get chatOrderLabel;

  /// No description provided for @chatDirectLabel.
  ///
  /// In en, this message translates to:
  /// **'DIRECT'**
  String get chatDirectLabel;

  /// No description provided for @chatLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'LOAD ERROR • TAP TO RETRY'**
  String get chatLoadRetry;

  /// No description provided for @chatConversationInfo.
  ///
  /// In en, this message translates to:
  /// **'Conversation information'**
  String get chatConversationInfo;

  /// No description provided for @chatConversationOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversation options'**
  String get chatConversationOptionsLabel;

  /// No description provided for @chatCancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get chatCancelRecording;

  /// No description provided for @chatSendAudio.
  ///
  /// In en, this message translates to:
  /// **'Send audio'**
  String get chatSendAudio;

  /// No description provided for @chatFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ / HELP'**
  String get chatFaqTitle;

  /// No description provided for @faqAccountProfile.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT AND PROFILE'**
  String get faqAccountProfile;

  /// No description provided for @faqPurchasesPayments.
  ///
  /// In en, this message translates to:
  /// **'PURCHASES AND PAYMENTS'**
  String get faqPurchasesPayments;

  /// No description provided for @faqSalesWallet.
  ///
  /// In en, this message translates to:
  /// **'SALES AND WALLET'**
  String get faqSalesWallet;

  /// No description provided for @faqCancellationRefunds.
  ///
  /// In en, this message translates to:
  /// **'CANCELLATION AND REFUNDS'**
  String get faqCancellationRefunds;

  /// No description provided for @faqDisputesSecurity.
  ///
  /// In en, this message translates to:
  /// **'DISPUTES AND SECURITY'**
  String get faqDisputesSecurity;

  /// No description provided for @faqCreateAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I create an account?'**
  String get faqCreateAccountQuestion;

  /// No description provided for @faqCreateAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Download FreeBay and select Create account. Enter your email and display name, then create a password with at least 8 characters. Confirm your email to finish setup.'**
  String get faqCreateAccountAnswer;

  /// No description provided for @faqEditProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I edit my profile?'**
  String get faqEditProfileQuestion;

  /// No description provided for @faqEditProfileAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open Profile from the bottom menu and select Edit profile. You can update your avatar, bio, location, and Pix keys.'**
  String get faqEditProfileAnswer;

  /// No description provided for @faqForgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password. What should I do?'**
  String get faqForgotPasswordQuestion;

  /// No description provided for @faqForgotPasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'On the sign-in screen, select Forgot password. Enter your registered email to receive a six-digit password reset code.'**
  String get faqForgotPasswordAnswer;

  /// No description provided for @faqBiometryQuestion.
  ///
  /// In en, this message translates to:
  /// **'How does biometric sign-in work?'**
  String get faqBiometryQuestion;

  /// No description provided for @faqBiometryAnswer.
  ///
  /// In en, this message translates to:
  /// **'After signing in with your email and password, enable Face ID or fingerprint authentication for faster, secure future sign-ins.'**
  String get faqBiometryAnswer;

  /// No description provided for @faqBuyProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I buy a product?'**
  String get faqBuyProductQuestion;

  /// No description provided for @faqBuyProductAnswer.
  ///
  /// In en, this message translates to:
  /// **'Browse the Feed or Explore, open a product, then select Buy. You will go to secure checkout to pay by card through Stripe.'**
  String get faqBuyProductAnswer;

  /// No description provided for @faqEscrowQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is escrow?'**
  String get faqEscrowQuestion;

  /// No description provided for @faqEscrowAnswer.
  ///
  /// In en, this message translates to:
  /// **'For your protection, payment is held in escrow until you receive the product and confirm delivery. The funds are then released to the seller.'**
  String get faqEscrowAnswer;

  /// No description provided for @faqCartQuestion.
  ///
  /// In en, this message translates to:
  /// **'How does the cart work?'**
  String get faqCartQuestion;

  /// No description provided for @faqCartAnswer.
  ///
  /// In en, this message translates to:
  /// **'Add products from different sellers and manage quantities. Checkout creates a separate escrow order for each item.'**
  String get faqCartAnswer;

  /// No description provided for @faqPaymentMethodsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which payment methods are accepted?'**
  String get faqPaymentMethodsQuestion;

  /// No description provided for @faqPaymentMethodsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Credit cards processed securely by Stripe are accepted.'**
  String get faqPaymentMethodsAnswer;

  /// No description provided for @faqInstallmentsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How can I pay in installments?'**
  String get faqInstallmentsQuestion;

  /// No description provided for @faqInstallmentsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Installments are offered on Stripe\'s payment screen according to the configured order amount terms.'**
  String get faqInstallmentsAnswer;

  /// No description provided for @faqListProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I list a product?'**
  String get faqListProductQuestion;

  /// No description provided for @faqListProductAnswer.
  ///
  /// In en, this message translates to:
  /// **'Select the plus button in the bottom menu, add photos, title, description, price in reais, and a category. Your listing will be visible immediately.'**
  String get faqListProductAnswer;

  /// No description provided for @faqSellingFeeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What fee is charged per sale?'**
  String get faqSellingFeeQuestion;

  /// No description provided for @faqSellingFeeAnswer.
  ///
  /// In en, this message translates to:
  /// **'A fixed 10% fee is charged when a sale is completed successfully and the buyer confirms delivery.'**
  String get faqSellingFeeAnswer;

  /// No description provided for @faqPayoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'When do I receive sale proceeds?'**
  String get faqPayoutQuestion;

  /// No description provided for @faqPayoutAnswer.
  ///
  /// In en, this message translates to:
  /// **'Funds remain in your Wallet as held balance until the buyer confirms receipt. They then become available for withdrawal.'**
  String get faqPayoutAnswer;

  /// No description provided for @faqPixWithdrawalQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I request a Pix withdrawal?'**
  String get faqPixWithdrawalQuestion;

  /// No description provided for @faqPixWithdrawalAnswer.
  ///
  /// In en, this message translates to:
  /// **'In your Wallet, select Request withdrawal, enter at least R\$ 5.00, and confirm your registered Pix key. Processing depends on provider confirmation.'**
  String get faqPixWithdrawalAnswer;

  /// No description provided for @faqCancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel an order?'**
  String get faqCancelOrderQuestion;

  /// No description provided for @faqCancelOrderAnswer.
  ///
  /// In en, this message translates to:
  /// **'The buyer or seller can cancel while the order is Pending or Confirmed, before shipping. After shipping, use a dispute instead.'**
  String get faqCancelOrderAnswer;

  /// No description provided for @faqRefundQuestion.
  ///
  /// In en, this message translates to:
  /// **'How does a refund after cancellation work?'**
  String get faqRefundQuestion;

  /// No description provided for @faqRefundAnswer.
  ///
  /// In en, this message translates to:
  /// **'If the order was paid, a refund is requested from Stripe. Processing waits for confirmation; the time to appear depends on the card issuer.'**
  String get faqRefundAnswer;

  /// No description provided for @faqStockQuestion.
  ///
  /// In en, this message translates to:
  /// **'What happens to the product after cancellation?'**
  String get faqStockQuestion;

  /// No description provided for @faqStockAnswer.
  ///
  /// In en, this message translates to:
  /// **'After cancellation is confirmed, product stock is restored and becomes available again.'**
  String get faqStockAnswer;

  /// No description provided for @faqCancelReasonQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do I need to provide a cancellation reason?'**
  String get faqCancelReasonQuestion;

  /// No description provided for @faqCancelReasonAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Select a reason from the list. The other party will be notified of the cancellation and reason.'**
  String get faqCancelReasonAnswer;

  /// No description provided for @faqMissingProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'I did not receive the product. What should I do?'**
  String get faqMissingProductQuestion;

  /// No description provided for @faqMissingProductAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open My Orders, select the order, and choose Open dispute. Our mediation team will review the case and issue a refund when appropriate.'**
  String get faqMissingProductAnswer;

  /// No description provided for @faqDefectiveProductQuestion.
  ///
  /// In en, this message translates to:
  /// **'The product is defective or differs from its listing. What should I do?'**
  String get faqDefectiveProductQuestion;

  /// No description provided for @faqDefectiveProductAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open a dispute in the app and attach photos or videos showing the issue. The seller can respond and we may mediate a return.'**
  String get faqDefectiveProductAnswer;

  /// No description provided for @faqSecureChatQuestion.
  ///
  /// In en, this message translates to:
  /// **'How does secure chat work?'**
  String get faqSecureChatQuestion;

  /// No description provided for @faqSecureChatAnswer.
  ///
  /// In en, this message translates to:
  /// **'Chat with buyers and sellers in real time in the app. The conversation history is retained to support both parties.'**
  String get faqSecureChatAnswer;

  /// No description provided for @faqBankDataQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is my payment information safe?'**
  String get faqBankDataQuestion;

  /// No description provided for @faqBankDataAnswer.
  ///
  /// In en, this message translates to:
  /// **'Payment details are processed by Stripe. FreeBay does not store card details.'**
  String get faqBankDataAnswer;

  /// No description provided for @feedAddStory.
  ///
  /// In en, this message translates to:
  /// **'Add story'**
  String get feedAddStory;

  /// No description provided for @feedHighlightEditAction.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get feedHighlightEditAction;

  /// No description provided for @feedHighlightCreateAction.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get feedHighlightCreateAction;

  /// No description provided for @feedHighlightSelectStory.
  ///
  /// In en, this message translates to:
  /// **'Select story {storyId}'**
  String feedHighlightSelectStory(String storyId);

  /// No description provided for @feedStoryPublish.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get feedStoryPublish;

  /// No description provided for @feedStoryCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption'**
  String get feedStoryCaptionHint;

  /// No description provided for @feedStoryRemoveText.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get feedStoryRemoveText;

  /// No description provided for @feedStoryTextStyle.
  ///
  /// In en, this message translates to:
  /// **'STYLE'**
  String get feedStoryTextStyle;

  /// No description provided for @feedStoryTextColor.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get feedStoryTextColor;

  /// No description provided for @feedStoryTextLayer.
  ///
  /// In en, this message translates to:
  /// **'LAYER'**
  String get feedStoryTextLayer;

  /// No description provided for @feedStoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete story?'**
  String get feedStoryDeleteTitle;

  /// No description provided for @feedStoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get feedStoryDeleteConfirm;

  /// No description provided for @feedStoryCloseFriendsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose who can view this story'**
  String get feedStoryCloseFriendsPrompt;

  /// No description provided for @feedMyStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'MY STORIES'**
  String get feedMyStoriesTitle;

  /// No description provided for @feedStoryDeleteUndoBody.
  ///
  /// In en, this message translates to:
  /// **'You can undo this for a few seconds.'**
  String get feedStoryDeleteUndoBody;

  /// No description provided for @feedStoryDeletePending.
  ///
  /// In en, this message translates to:
  /// **'Story will be deleted.'**
  String get feedStoryDeletePending;

  /// No description provided for @accessibilitySwitchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get accessibilitySwitchCamera;

  /// No description provided for @accessibilityTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get accessibilityTakePhoto;

  /// No description provided for @feedHighlightDeletePending.
  ///
  /// In en, this message translates to:
  /// **'Highlight will be deleted.'**
  String get feedHighlightDeletePending;

  /// No description provided for @feedHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'HIGHLIGHTS'**
  String get feedHighlightsTitle;

  /// No description provided for @feedHighlightRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Choose a title, stories, and a cover.'**
  String get feedHighlightRequiredFields;

  /// No description provided for @feedHighlightCoverSelected.
  ///
  /// In en, this message translates to:
  /// **'COVER ✓'**
  String get feedHighlightCoverSelected;

  /// No description provided for @feedHighlightUseCover.
  ///
  /// In en, this message translates to:
  /// **'Use as cover'**
  String get feedHighlightUseCover;

  /// No description provided for @feedCreateHighlight.
  ///
  /// In en, this message translates to:
  /// **'CREATE HIGHLIGHT'**
  String get feedCreateHighlight;

  /// No description provided for @feedSaveHighlight.
  ///
  /// In en, this message translates to:
  /// **'SAVE HIGHLIGHT'**
  String get feedSaveHighlight;

  /// No description provided for @chatEditorDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get chatEditorDiscardChangesTitle;

  /// No description provided for @chatEditorDiscardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get chatEditorDiscardChangesBody;

  /// No description provided for @chatEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get chatEditorDiscard;

  /// No description provided for @chatEditorCropFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get chatEditorCropFree;

  /// No description provided for @chatEditorBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get chatEditorBrightness;

  /// No description provided for @chatEditorContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get chatEditorContrast;

  /// No description provided for @chatEditorSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get chatEditorSaturation;

  /// No description provided for @chatEditorRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get chatEditorRotation;

  /// No description provided for @chatEditorChooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose color'**
  String get chatEditorChooseColor;

  /// No description provided for @chatEditorChooseCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Choose custom color'**
  String get chatEditorChooseCustomColor;

  /// No description provided for @chatEditorPenMarker.
  ///
  /// In en, this message translates to:
  /// **'Marker pen'**
  String get chatEditorPenMarker;

  /// No description provided for @chatEditorPenHighlighter.
  ///
  /// In en, this message translates to:
  /// **'Highlighter pen'**
  String get chatEditorPenHighlighter;

  /// No description provided for @chatEditorPenEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get chatEditorPenEraser;

  /// No description provided for @chatEditorStrokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke width {width}'**
  String chatEditorStrokeWidth(int width);

  /// No description provided for @feedPostContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Add text or an image.'**
  String get feedPostContentRequired;

  /// No description provided for @feedCloseFriendsPostDescription.
  ///
  /// In en, this message translates to:
  /// **'Only people on your Close Friends list can see this post.'**
  String get feedCloseFriendsPostDescription;

  /// No description provided for @feedPostContentHint.
  ///
  /// In en, this message translates to:
  /// **'Share an update, idea, or behind-the-scenes moment…'**
  String get feedPostContentHint;

  /// No description provided for @feedMyPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'MY POSTS'**
  String get feedMyPostsTitle;

  /// No description provided for @feedPostDeletePending.
  ///
  /// In en, this message translates to:
  /// **'Post will be deleted.'**
  String get feedPostDeletePending;

  /// No description provided for @feedRepostedBadge.
  ///
  /// In en, this message translates to:
  /// **'Reposted'**
  String get feedRepostedBadge;

  /// No description provided for @feedLikedPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'LIKED POSTS'**
  String get feedLikedPostsTitle;

  /// No description provided for @socialPeopleSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'SEARCH PEOPLE'**
  String get socialPeopleSearchTitle;

  /// No description provided for @socialPeopleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or @username…'**
  String get socialPeopleSearchHint;

  /// No description provided for @socialPeopleSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Search for people…'**
  String get socialPeopleSearchEmpty;

  /// No description provided for @feedExplore.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE'**
  String get feedExplore;

  /// No description provided for @accessibilityOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get accessibilityOpenMenu;

  /// No description provided for @imageDoubleTapToZoom.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE TAP TO ZOOM'**
  String get imageDoubleTapToZoom;

  /// No description provided for @imageReplaceFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Replace — gallery'**
  String get imageReplaceFromGallery;

  /// No description provided for @imageAddFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Add from gallery'**
  String get imageAddFromGallery;

  /// No description provided for @imageReplaceFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Replace — camera'**
  String get imageReplaceFromCamera;

  /// No description provided for @imageAddFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Add from camera'**
  String get imageAddFromCamera;

  /// No description provided for @profileFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'FAVORITES'**
  String get profileFavoritesTitle;

  /// No description provided for @profilePurchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'PURCHASES'**
  String get profilePurchasesTitle;

  /// No description provided for @paymentWalletUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay or Google Pay is unavailable on this device or not configured.'**
  String get paymentWalletUnavailable;

  /// No description provided for @authSignInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authSignInApple;

  /// No description provided for @authSignUpApple.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Apple'**
  String get authSignUpApple;

  /// No description provided for @paymentContinueToWallet.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE TO APPLE PAY OR GOOGLE PAY'**
  String get paymentContinueToWallet;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data'**
  String get privacyTitle;

  /// No description provided for @privacyScope.
  ///
  /// In en, this message translates to:
  /// **'You can request a copy of account data returned by FreeBay. The export may contain personal information; share it only with people you trust.'**
  String get privacyScope;

  /// No description provided for @privacyExportAction.
  ///
  /// In en, this message translates to:
  /// **'EXPORT MY DATA'**
  String get privacyExportAction;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @privacyTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get privacyTerms;

  /// No description provided for @privacyDeletionPolicy.
  ///
  /// In en, this message translates to:
  /// **'Account deletion details'**
  String get privacyDeletionPolicy;

  /// No description provided for @privacyDeletionExplanation.
  ///
  /// In en, this message translates to:
  /// **'Deletion starts a 30-day pending period. Open orders, disputes, or wallet balances can prevent the request. Listings may be paused. Some financial records may be retained where legally required; this is not a promise that every record is immediately erased.'**
  String get privacyDeletionExplanation;

  /// No description provided for @privacyDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'REQUEST ACCOUNT DELETION'**
  String get privacyDeleteAction;

  /// No description provided for @privacyDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion?'**
  String get privacyDeleteConfirmTitle;

  /// No description provided for @privacyDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your sessions will be revoked and deletion will remain pending for 30 days. Open orders, disputes, or a wallet balance may block the request. Listings may be paused. Some financial records may be retained where legally required.'**
  String get privacyDeleteConfirmBody;

  /// No description provided for @privacyDeletionPending.
  ///
  /// In en, this message translates to:
  /// **'Deletion requested on {date}. Sign in again to cancel while it is pending.'**
  String privacyDeletionPending(String date);

  /// No description provided for @privacyCancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'CANCEL DELETION'**
  String get privacyCancelDeletion;

  /// No description provided for @privacyCancelDeletionRelogin.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel deletion. Sign in again and retry if the request is still pending.'**
  String get privacyCancelDeletionRelogin;

  /// No description provided for @privacyDeletionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Deletion request cancelled.'**
  String get privacyDeletionCancelled;

  /// No description provided for @privacyLegalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This legal page could not be opened.'**
  String get privacyLegalUnavailable;

  /// No description provided for @profileReportUser.
  ///
  /// In en, this message translates to:
  /// **'REPORT PROFILE'**
  String get profileReportUser;

  /// No description provided for @profileReportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get profileReportSpam;

  /// No description provided for @profileReportFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get profileReportFraud;

  /// No description provided for @profileReportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get profileReportHarassment;

  /// No description provided for @profileReportFakeAccount.
  ///
  /// In en, this message translates to:
  /// **'Fake account'**
  String get profileReportFakeAccount;

  /// No description provided for @profileReportImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get profileReportImpersonation;

  /// No description provided for @profileReportNudity.
  ///
  /// In en, this message translates to:
  /// **'Nudity'**
  String get profileReportNudity;

  /// No description provided for @profileReportBlackmail.
  ///
  /// In en, this message translates to:
  /// **'Blackmail'**
  String get profileReportBlackmail;

  /// No description provided for @profileReportFalseAdvertising.
  ///
  /// In en, this message translates to:
  /// **'False advertising'**
  String get profileReportFalseAdvertising;

  /// No description provided for @profileReportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileReportOther;

  /// No description provided for @profileReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted for review.'**
  String get profileReportSubmitted;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
