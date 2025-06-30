import 'package:json_annotation/json_annotation.dart';

part 'salary_form_field_config.g.dart';

abstract class FormFieldConfig {
  String get fieldName;
}

@JsonSerializable()
class TextFieldConfig implements FormFieldConfig {
  final String label;
  @override
  final String fieldName;
  final String initialValue;
  @JsonKey(defaultValue: false)
  final bool isNumber;
  @JsonKey(defaultValue: false)
  final bool readonly;

  TextFieldConfig({
    required this.label,
    required this.fieldName,
    required this.initialValue,
    this.isNumber = false,
    this.readonly = false,
  });

  factory TextFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$TextFieldConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TextFieldConfigToJson(this);
}

@JsonSerializable()
class DropdownConfig implements FormFieldConfig {
  final String label;
  @override
  final String fieldName;

  DropdownConfig({required this.label, required this.fieldName});

  factory DropdownConfig.fromJson(Map<String, dynamic> json) =>
      _$DropdownConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DropdownConfigToJson(this);
}

@JsonSerializable()
class ButtonConfig implements FormFieldConfig {
  final String label;
  @override
  final String fieldName;

  ButtonConfig({required this.label, required this.fieldName});

  factory ButtonConfig.fromJson(Map<String, dynamic> json) =>
      _$ButtonConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ButtonConfigToJson(this);
}

@JsonSerializable()
class RadioOptionConfig {
  final String label;
  final String value;
  final String hint;

  RadioOptionConfig({required this.label, required this.value, required this.hint});

  factory RadioOptionConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioOptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RadioOptionConfigToJson(this);
}

@JsonSerializable()
class RadioGroupConfig implements FormFieldConfig {
  final String label;
  @override
  final String fieldName;
  final String initialValue;
  final List<RadioOptionConfig> options;

  RadioGroupConfig({
    required this.label, 
    required this.fieldName, 
    required this.initialValue,
    required this.options
  });

  factory RadioGroupConfig.fromJson(Map<String, dynamic> json) =>
      _$RadioGroupConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RadioGroupConfigToJson(this);
}


@JsonSerializable()
class SalaryFormFieldConfig {
  final List<TextFieldConfig> textFields;
  final List<DropdownConfig> dropdowns;
  final List<ButtonConfig> buttons;
  final List<RadioGroupConfig> radios;

  SalaryFormFieldConfig({
    required this.textFields, 
    required this.dropdowns,
    required this.buttons,
    required this.radios,
  });

  factory SalaryFormFieldConfig.fromJson(Map<String, dynamic> json) =>
      _$SalaryFormFieldConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SalaryFormFieldConfigToJson(this);
}