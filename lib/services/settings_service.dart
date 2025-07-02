import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService with ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  String _url = 'https://kyuyo.net/2/kyuyo.htm';
  double _taxRate = 10.0;

  String get url => _url;
  double get taxRate => _taxRate;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _url = _prefs.getString('settings_url') ?? _url;
    _taxRate = _prefs.getDouble('settings_tax_rate') ?? _taxRate;
    notifyListeners();
  }

  Future<void> setUrl(String newUrl) async {
    _url = newUrl;
    await _prefs.setString('settings_url', newUrl);
    notifyListeners();
  }

  Future<void> setTaxRate(double newRate) async {
    _taxRate = newRate;
    await _prefs.setDouble('settings_tax_rate', newRate);
    notifyListeners();
  }
} 