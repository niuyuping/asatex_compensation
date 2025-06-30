import 'package:asatex_compensation/models/salary_form_field_config.dart';
import 'package:flutter/rendering.dart';

class ConfigService {
  // Singleton pattern to ensure a single instance throughout the app.
  ConfigService._privateConstructor();
  static final ConfigService instance = ConfigService._privateConstructor();

  SalaryFormFieldConfig? _config;

  Future<SalaryFormFieldConfig> loadConfig() async {
    if (_config == null) {
      final configJson = {
        "textFields": [
          {"label": "会社名", "fieldName": "comp", "initialValue": ""},
          {"label": "氏名", "fieldName": "name", "initialValue": ""},
          {"label": "基本給", "fieldName": "kingaku1", "initialValue": "0", "isNumber": true},
          {"label": "時間外手当", "fieldName": "kingaku7", "initialValue": "0", "isNumber": true},
          {"label": "通勤手当", "fieldName": "kingaku8", "initialValue": "0", "isNumber": true},
          {"label": "不就労控除", "fieldName": "kingaku9", "initialValue": "0", "isNumber": true},
          {"label": "住民税", "fieldName": "kingaku17", "initialValue": "0", "isNumber": true},
          {"label": "健康保険", "fieldName": "kingaku11", "initialValue": "0", "isNumber": true, "readonly": true},
          {"label": "介護保険", "fieldName": "kingaku12", "initialValue": "0", "isNumber": true, "readonly": true},
          {"label": "厚生年金", "fieldName": "kingaku13", "initialValue": "0", "isNumber": true, "readonly": true},
          {"label": "雇用保険", "fieldName": "kingaku14", "initialValue": "0", "isNumber": true, "readonly": true},
          // {"label": "社会保険計", "fieldName": "kingaku15", "initialValue": "0", "isNumber": true, "readonly": true},
          {"label": "所得税", "fieldName": "kingaku16", "initialValue": "0", "isNumber": true, "readonly": true},
          {"label": "控除計", "fieldName": "kingaku20", "initialValue": "0", "isNumber": true, "readonly": true},
        ],
        "dropdowns": [
          {"label": "社会保険", "fieldName": "syaho"},
          {"label": "地域", "fieldName": "kenpo"},
          {"label": "支払月", "fieldName": "tuki"},
          {"label": "雇用保険", "fieldName": "koyou"},
          {"label": "給与支払", "fieldName": "kyusyo"},
          {"label": "支払方法", "fieldName": "shiharai"},
          {"label": "扶養人数", "fieldName": "fuyou"},
        ],
        "buttons": [
          {"label": "計算実行", "fieldName": "calc"},
          {"label": "金額クリア", "fieldName": "clear"},
          {"label": "全てクリア", "fieldName": "all_clear"},
        ],
        "radios": [
          {
            "label": "",
            "fieldName": "hantei",
            "initialValue": "0",
            "options": [
              {"label": "介護保険あり", "value": "40", "hint": "40歳の誕生月の翌月より<br>65歳の誕生月まで"},
              {"label": "厚生年金なし", "value": "70", "hint": "70歳の誕生月の翌月より<br>厚生年金の資格喪失"},
              {"label": "その他", "value": "0", "hint": "介護保険あり・厚生年金なし<br>以外の場合に選択"},
              // {"label": "金額指定", "value": "99", "hint": "政府管掌以外の場合(医師国保等)に選択<br>健康保険・介護保険・厚生年金を手入力"},
            ],
          },
        ],
      };
      _config = SalaryFormFieldConfig.fromJson(configJson);
    }
    return _config!;
  }

  SalaryFormFieldConfig get config {
    if (_config == null) {
      throw Exception("Config not loaded. Call loadConfig() first.");
    }
    return _config!;
  }

  // Example of a future method to fetch config from a server.
  // Future<void> fetchConfig() async {
  //   try {
  //     final response = await ApiService.instance.get('/config');
  //     _formFieldConfig = FormFieldConfig.fromJson(response.data);
  //   } catch (e) {
  //     // Handle error, maybe use default config
  //     logger.e('Failed to fetch config: $e');
  //   }
  // }
}
