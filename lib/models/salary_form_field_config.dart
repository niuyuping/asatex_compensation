import 'package:json_annotation/json_annotation.dart';

part 'salary_form_field_config.g.dart';

abstract class FormFieldConfig {
  final int? id;
  final String fieldName;

  FormFieldConfig({this.id, required this.fieldName});
}

@JsonSerializable()
class TextFieldConfig extends FormFieldConfig {
  final String label;
  final String initialValue;
  @JsonKey(defaultValue: false)
  final bool isNumber;
  @JsonKey(defaultValue: false)
  final bool readonly;

  TextFieldConfig({
    super.id,
    required super.fieldName,
    required this.label,
    required this.initialValue,
    this.isNumber = false,
    this.readonly = false,
  });

  factory TextFieldConfig.fromJson(Map<String, dynamic> json) => _$TextFieldConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TextFieldConfigToJson(this);
}

@JsonSerializable()
class DropdownConfig extends FormFieldConfig {
  final String label;
  final String initialValue;
  DropdownConfig({
    super.id,
    required super.fieldName,
    required this.label,
    this.initialValue = "",
  });

  factory DropdownConfig.fromJson(Map<String, dynamic> json) => _$DropdownConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DropdownConfigToJson(this);
}

@JsonSerializable()
class ButtonConfig extends FormFieldConfig {
  final String label;

  ButtonConfig({
    super.id,
    required super.fieldName,
    required this.label,
  });

  factory ButtonConfig.fromJson(Map<String, dynamic> json) => _$ButtonConfigFromJson(json);

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
class RadioGroupConfig extends FormFieldConfig {
  final String label;
  final String initialValue;
  final List<RadioOptionConfig> options;

  RadioGroupConfig({
    super.id,
    required super.fieldName,
    required this.label, 
    required this.initialValue,
    required this.options,
  });

  factory RadioGroupConfig.fromJson(Map<String, dynamic> json) => _$RadioGroupConfigFromJson(json);

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