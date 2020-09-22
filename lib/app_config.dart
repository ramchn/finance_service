import 'dart:convert';
import 'package:finance_service/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppConfig extends InheritedWidget {
  final String twilioBaseUrl;
  final String twilioAccountSid;
  final String twilioAuthToken;
  final String twilioApikeySid;
  final String twilioSecret;
  final String twilioWhatsappNumber;
  final String recipientNumber;
  final String financeUrl;
  final Widget child;

  AppConfig({this.twilioBaseUrl, this.twilioAccountSid, this.twilioAuthToken, this.twilioApikeySid, this.twilioSecret, this.twilioWhatsappNumber, this.recipientNumber, this.financeUrl, this.child}): super(child: child);

  static AppConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Future<AppConfig> forEnvironment(String env) async {
    // set default to dev if nothing was passed
    env = env ?? 'dev';

    // load the json file
    final contents = await rootBundle.loadString(
      'config/$env.json',
    );

    // decode our json
    final json = jsonDecode(contents);

    // convert our JSON into an instance of our AppConfig class
    return AppConfig(twilioBaseUrl: json['twilio_base_url'], twilioAccountSid: json['twilio_account_sid'], twilioAuthToken: json['twilio_auth_token'], twilioApikeySid: json['twilio_apikey_sid'], twilioSecret: json['twilio_secret'], twilioWhatsappNumber: json['twilio_whatsapp_number'], recipientNumber: json['recipient_number'], financeUrl: json['finance_url'], child: MyApp());
  }
}