import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class ConsentService {
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  bool _isConsentFormAvailable = false;
  bool _isConsentRequired = false;

  /// Initialize consent information and request consent if needed
  Future<void> initialize() async {
    try {
      // Create a ConsentRequestParameters object
      final params = ConsentRequestParameters();

      // Request consent information update
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback
          final consentStatus = await ConsentInformation.instance.getConsentStatus();
          _isConsentRequired = consentStatus == ConsentStatus.required;
          _isConsentFormAvailable = await ConsentInformation.instance.isConsentFormAvailable();

          debugPrint('Consent Status: $consentStatus');
          debugPrint('Consent Form Available: $_isConsentFormAvailable');

          // If consent is required and form is available, load the form
          if (_isConsentRequired && _isConsentFormAvailable) {
            _loadConsentForm();
          }
        },
        (FormError error) {
          // Error callback
          debugPrint('Consent info update error: ${error.message}');
        },
      );
    } catch (e) {
      debugPrint('Consent initialization error: $e');
    }
  }

  /// Load and show consent form if necessary
  void _loadConsentForm() {
    try {
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          // Check if we can show the form
          final consentStatus = await ConsentInformation.instance.getConsentStatus();

          if (consentStatus == ConsentStatus.required) {
            consentForm.show(
              (FormError? formError) {
                if (formError != null) {
                  debugPrint('Consent form error: ${formError.message}');
                }
                // After form is dismissed, reload if needed
                _loadConsentForm();
              },
            );
          }
        },
        (FormError formError) {
          debugPrint('Consent form load error: ${formError.message}');
        },
      );
    } catch (e) {
      debugPrint('Consent form loading error: $e');
    }
  }

  /// Show privacy options form (for settings)
  void showPrivacyOptionsForm() {
    try {
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) async {
          consentForm.show(
            (FormError? formError) {
              if (formError != null) {
                debugPrint('Privacy options form error: ${formError.message}');
              }
            },
          );
        },
        (FormError formError) {
          debugPrint('Privacy options form load error: ${formError.message}');
        },
      );
    } catch (e) {
      debugPrint('Privacy options form error: $e');
    }
  }

  /// Check if user can change privacy settings
  Future<bool> canShowPrivacyOptionsForm() async {
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Error checking privacy options requirement: $e');
      return false;
    }
  }

  /// Reset consent for testing purposes
  Future<void> resetConsent() async {
    try {
      await ConsentInformation.instance.reset();
      debugPrint('Consent information reset');
    } catch (e) {
      debugPrint('Consent reset error: $e');
    }
  }

  /// Check if ads can be served with personalization
  Future<bool> canRequestAds() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      return status == ConsentStatus.obtained || status == ConsentStatus.notRequired;
    } catch (e) {
      debugPrint('Error checking ad request permission: $e');
      return false;
    }
  }
}
