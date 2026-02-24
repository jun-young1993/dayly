import 'package:flutter/foundation.dart';

String get GOOGLE_CLIENT_ID {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return '227758929265-agtf7em291p7nuldf1u6basvl17q694n.apps.googleusercontent.com';
  } else {
    return '227758929265-fhcmgklrkuqml3hpgp0dp6o83ur1vi2f.apps.googleusercontent.com';
  }
}
