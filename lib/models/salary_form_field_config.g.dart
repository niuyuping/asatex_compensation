// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_form_field_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextFieldConfig _$TextFieldConfigFromJson(Map<String, dynamic> json) =>
    TextFieldConfig(
      label: json['label'] as String,
      fieldName: json['fieldName'] as String,
      initialValue: json['initialValue'] as String,
      isNumber: json['isNumber'] as bool? ?? false,
      readonly: json['readonly'] as bool? ?? false,
    );

Map<String, dynamic> _$TextFieldConfigToJson(TextFieldConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'fieldName': instance.fieldName,
      'initialValue': instance.initialValue,
      'isNumber': instance.isNumber,
      'readonly': instance.readonly,
    };

DropdownConfig _$DropdownConfigFromJson(Map<String, dynamic> json) =>
    DropdownConfig(
      label: json['label'] as String,
      fieldName: json['fieldName'] as String,
    );

Map<String, dynamic> _$DropdownConfigToJson(DropdownConfig instance) =>
    <String, dynamic>{'label': instance.label, 'fieldName': instance.fieldName};

ButtonConfig _$ButtonConfigFromJson(Map<String, dynamic> json) => ButtonConfig(
  label: json['label'] as String,
  fieldName: json['fieldName'] as String,
);

Map<String, dynamic> _$ButtonConfigToJson(ButtonConfig instance) =>
    <String, dynamic>{'label': instance.label, 'fieldName': instance.fieldName};

RadioOptionConfig _$RadioOptionConfigFromJson(Map<String, dynamic> json) =>
    RadioOptionConfig(
      label: json['label'] as String,
      value: json['value'] as String,
      hint: json['hint'] as String,
    );

Map<String, dynamic> _$RadioOptionConfigToJson(RadioOptionConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'value': instance.value,
      'hint': instance.hint,
    };

RadioGroupConfig _$RadioGroupConfigFromJson(Map<String, dynamic> json) =>
    RadioGroupConfig(
      label: json['label'] as String,
      fieldName: json['fieldName'] as String,
      initialValue: json['initialValue'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => RadioOptionConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RadioGroupConfigToJson(RadioGroupConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'fieldName': instance.fieldName,
      'initialValue': instance.initialValue,
      'options': instance.options,
    };

SalaryFormFieldConfig _$SalaryFormFieldConfigFromJson(
  Map<String, dynamic> json,
) => SalaryFormFieldConfig(
  textFields: (json['textFields'] as List<dynamic>)
      .map((e) => TextFieldConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  dropdowns: (json['dropdowns'] as List<dynamic>)
      .map((e) => DropdownConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  buttons: (json['buttons'] as List<dynamic>)
      .map((e) => ButtonConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  radios: (json['radios'] as List<dynamic>)
      .map((e) => RadioGroupConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SalaryFormFieldConfigToJson(
  SalaryFormFieldConfig instance,
) => <String, dynamic>{
  'textFields': instance.textFields,
  'dropdowns': instance.dropdowns,
  'buttons': instance.buttons,
  'radios': instance.radios,
};
