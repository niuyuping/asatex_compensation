import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:asatex_compensation/services/config_service.dart';
import 'package:asatex_compensation/models/salary_form_field_config.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key, required this.title});
  final String title;

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final ConfigService _configService = ConfigService.instance;
  Future<SalaryFormFieldConfig>? _configFuture;
  late final WebViewController _controller;
  bool _isPageLoaded = false;
  bool _isUpdatingFromWeb = false;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, List<Map<String, String>>> _dropdownOptions = {};
  final Map<String, String?> _selectedDropdownValues = {};
  final Map<String, String> _selectedRadioValues = {};

  @override
  void initState() {
    super.initState();
    _configFuture = _loadInitialData();
  }

  Future<SalaryFormFieldConfig> _loadInitialData() async {
    final config = await _configService.loadConfig();
    _initializeStateFromConfig(config);
    _initController();
    return config;
  }

  void _initializeStateFromConfig(SalaryFormFieldConfig config) {
    // Initialize controllers for text fields and add listeners
    for (final field in config.textFields) {
      final controller = TextEditingController(text: field.initialValue);
      controller.addListener(() {
        if (!_isUpdatingFromWeb) {
          _syncField(field.fieldName, controller.text);
        }
      });
      _textControllers[field.fieldName] = controller;
    }

    // Initialize radio buttons
    for (final radioGroup in config.radios) {
      if (radioGroup.options.isNotEmpty) {
        _selectedRadioValues[radioGroup.fieldName] = radioGroup.initialValue;
      }
    }

    // Initialize dropdowns
    for (final dropdownConfig in config.dropdowns) {
      _selectedDropdownValues[dropdownConfig.fieldName] = null;
      _dropdownOptions[dropdownConfig.fieldName] = [];
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            _updateAppFromWeb();
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://kyuyo.net/2/kyuyo.htm'));
  }

  Future<void> _fetchDropdownOptions(String fieldName) async {
    final jsTemplate = """
    (function() {
      var select = document.getElementsByName('FIELD_NAME')[0];
      if (!select) return '[]';
      var options = [];
      for (var i = 0; i < select.options.length; i++) {
        options.push({ value: select.options[i].value, text: select.options[i].text });
      }
      return JSON.stringify(options);
    })();
    """;
    final js = jsTemplate.replaceAll('FIELD_NAME', fieldName);

    try {
      final result = await _controller.runJavaScriptReturningResult(js);
      final decodedResult = jsonDecode(result.toString());

      if (decodedResult is List && mounted) {
        final newOptions = List<Map<String, String>>.from(decodedResult.map((item) => {'value': item['value'].toString(), 'text': item['text'].toString()}));
        setState(() {
          _dropdownOptions[fieldName] = newOptions;
          if (newOptions.isNotEmpty && _selectedDropdownValues[fieldName] == null) {
            _selectedDropdownValues[fieldName] = newOptions.first['value'];
            _syncField(fieldName, _selectedDropdownValues[fieldName]!);
          }
        });
      }
    } catch (e) {
      print('Error fetching dropdown options for $fieldName: $e');
    }
  }

  void _triggerWebButton(String fieldName) {
    if (!_isPageLoaded) return;

    // Sync UI to web, then set loading state, then click the button in web.
    _syncAllFields();
    setState(() => _isPageLoaded = false);
    _controller.runJavaScript("document.getElementsByName('$fieldName')[0].click();");
  }

  void _syncField(String fieldName, String value) {
    if (!_isPageLoaded) return;
    if (_isPageLoaded) {
      final escapedValue = value.replaceAll("'", "\\'");
      final js =
          """
      var elements = document.getElementsByName('$fieldName');
      if (elements.length > 0) {
        elements[0].value = '$escapedValue';
      }
      """;
      _controller.runJavaScript(js);
    }
  }

  void _syncRadioField(String fieldName, String value) {
    if (!_isPageLoaded) return;
    final js =
        """
    var radios = document.getElementsByName('$fieldName');
    for (var i = 0; i < radios.length; i++) {
      if (radios[i].value == '$value') {
        radios[i].checked = true;
        break;
      }
    }
    """;
    _controller.runJavaScript(js);
  }

  void _syncAllFields() {
    _textControllers.forEach((fieldName, controller) {
      _syncField(fieldName, controller.text);
    });
    _selectedDropdownValues.forEach((fieldName, value) {
      if (value != null) {
        _syncField(fieldName, value);
      }
    });
    _selectedRadioValues.forEach((fieldName, value) {
      if (value != null) {
        _syncRadioField(fieldName, value);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: FutureBuilder<SalaryFormFieldConfig>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _textControllers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading config: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _buildSalaryCalculator(snapshot.data!);
          } else {
            return const Center(child: Text('No config data.'));
          }
        },
      ),
    );
  }

  Widget _buildSalaryCalculator(SalaryFormFieldConfig config) {
    // Separate fields into editable and readonly lists
    final editableFields = config.textFields.where((f) => !f.readonly).toList();
    final readonlyFields = config.textFields.where((f) => f.readonly).toList();

    return Stack(
      children: [
        // This WebView runs in the background. It's not visible and doesn't
        // receive pointer events, but it's active for JS communication.
        Opacity(
          opacity: 0.0,
          child: IgnorePointer(child: WebViewWidget(controller: _controller)),
        ),

        // This is the visible and interactive UI layer.
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // New dedicated section for readonly fields
                if (readonlyFields.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildReadonlyResults(readonlyFields)]),
                  ),
                Divider(thickness: 1),
                _buildTextFields(editableFields),
                Divider(thickness: 1),
                _buildDropdowns(config.dropdowns),
                Divider(thickness: 1),
                _buildRadioGroups(config.radios),
                Divider(thickness: 1),
                _buildButtons(config.buttons),
              ],
            ),
          ),
        ),

        // Loading indicator overlay
        if (!_isPageLoaded)
          Positioned.fill(
            child: Container(
              color: Colors.black.withAlpha(77),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildReadonlyResults(List<TextFieldConfig> readonlyFields) {
    final companyFieldLabels = ['健康保険', '介護保険', '厚生年金', '雇用保険'];

    // Prepare items for the "Personal" list (all readonly fields)
    final personalItems = readonlyFields.map((field) {
      final controller = _textControllers[field.fieldName];
      final value = controller?.text ?? field.initialValue;
      return MapEntry(field.label, value);
    }).toList();

    // Prepare items for the "Company" list, with transformation for '雇用保険'
    final companyItems = readonlyFields
        .where((field) => companyFieldLabels.contains(field.label.trim()))
        .map((field) {
      final controller = _textControllers[field.fieldName];
      String value = controller?.text ?? field.initialValue;

      if (field.label.trim() == '雇用保険') {
        // Remove commas for safe parsing, calculate new value, and format back to string.
        final numericValue = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
        value = (numericValue * 3).round().toString();
      }
      return MapEntry(field.label, value);
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildResultList('個人', personalItems)),
        Expanded(child: _buildResultList('会社', companyItems)),
      ],
    );
  }

  Widget _buildResultList(String title, List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              dense: true,
              title: Text(item.key),
              trailing: Text(item.value, style: const TextStyle(fontSize: 16, color: Colors.red)),
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 0),
        ),
      ],
    );
  }

  Widget _buildRadioGroups(List<RadioGroupConfig> radioGroups) {
    if (radioGroups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: radioGroups.map((group) {
        final selectedValue = _selectedRadioValues[group.fieldName];
        // It's safe to assume a value is selected due to initialization logic.
        final selectedOption = group.options.firstWhere((opt) => opt.value == selectedValue, orElse: () => group.options.first);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                child: Text(group.label, style: Theme.of(context).textTheme.titleMedium),
              ),
            Wrap(
              children: group.options.map((option) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: () {
                      if (selectedValue != option.value) {
                        setState(() {
                          _selectedRadioValues[group.fieldName] = option.value;
                        });
                        _syncField(group.fieldName, option.value);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: option.value,
                          groupValue: selectedValue,
                          onChanged: (String? value) {
                            if (value != null && selectedValue != value) {
                              setState(() {
                                _selectedRadioValues[group.fieldName] = value;
                              });
                              _syncRadioField(group.fieldName, value);
                            }
                          },
                        ),
                        Text(option.label),
                        const SizedBox(width: 8.0),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(selectedOption.hint.replaceAll('<br>', '\n'), style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDropdowns(List<DropdownConfig> dropdowns) {
    if (dropdowns.isEmpty) return const SizedBox.shrink();

    final List<Widget> rows = [];
    for (var i = 0; i < dropdowns.length; i += 2) {
      // First dropdown in the row
      final dropdownConfig1 = dropdowns[i];
      final fieldName1 = dropdownConfig1.fieldName;
      final firstDropdown = Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildDropdown(dropdownConfig1.label, _dropdownOptions[fieldName1] ?? [], _selectedDropdownValues[fieldName1], (newValue) {
            if (newValue != null) {
              setState(() => _selectedDropdownValues[fieldName1] = newValue);
              _syncField(fieldName1, newValue);
            }
          }),
        ),
      );

      // Second dropdown in the row (if it exists)
      Widget secondDropdown;
      if (i + 1 < dropdowns.length) {
        final dropdownConfig2 = dropdowns[i + 1];
        final fieldName2 = dropdownConfig2.fieldName;
        secondDropdown = Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildDropdown(dropdownConfig2.label, _dropdownOptions[fieldName2] ?? [], _selectedDropdownValues[fieldName2], (newValue) {
              if (newValue != null) {
                setState(() => _selectedDropdownValues[fieldName2] = newValue);
                _syncField(fieldName2, newValue);
              }
            }),
          ),
        );
      } else {
        // Placeholder if there's no second dropdown
        secondDropdown = Expanded(child: Container());
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [firstDropdown, secondDropdown]),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildTextFields(List<TextFieldConfig> textFields) {
    if (textFields.isEmpty) return const SizedBox.shrink();

    final List<Widget> rows = [];
    for (var i = 0; i < textFields.length; i += 2) {
      final firstField = Expanded(
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: _buildTextField(_textControllers[textFields[i].fieldName]!, textFields[i])),
      );

      final secondField = i + 1 < textFields.length
          ? Expanded(
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: _buildTextField(_textControllers[textFields[i + 1].fieldName]!, textFields[i + 1])),
            )
          : Expanded(child: Container());

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [firstField, secondField]),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildButtons(List<ButtonConfig> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: buttons.map((buttonConfig) {
          return ElevatedButton(onPressed: () => _triggerWebButton(buttonConfig.fieldName), child: Text(buttonConfig.label));
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown(String label, List<Map<String, String>> options, String? selectedValue, ValueChanged<String?> onChanged) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          isDense: true,
          items: options.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(value: option['value'], alignment: AlignmentDirectional.centerStart, child: Text(option['text']!.trim()));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, TextFieldConfig config) {
    return TextField(
      controller: controller,
      readOnly: config.readonly,
      keyboardType: config.isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: config.isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(labelText: config.label, border: const OutlineInputBorder(), fillColor: config.readonly ? Colors.grey[200] : null, filled: config.readonly),
    );
  }

  Future<void> _updateAppFromWeb() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isUpdatingFromWeb = true;

    // Fetch all text fields and dropdown selected values
    final List<FormFieldConfig> allFields = [..._configService.config.textFields, ..._configService.config.dropdowns];

    for (final field in allFields) {
      final value = await _fetchFieldValueFromWeb(field.fieldName);
      if (value == null) continue;

      if (_textControllers.containsKey(field.fieldName)) {
        if (value == "" || _textControllers[field.fieldName]!.text != value) {
          _textControllers[field.fieldName]!.text = value.isEmpty ? _configService.config.textFields.firstWhere((f) => f.fieldName == field.fieldName).initialValue : value;
        }
      } else if (_selectedDropdownValues.containsKey(field.fieldName)) {
        if (_selectedDropdownValues[field.fieldName] != value) {
          _selectedDropdownValues[field.fieldName] = value;
        }
      }
    }

    // Fetch options for all dropdowns in parallel
    await Future.wait(_configService.config.dropdowns.map((d) => _fetchDropdownOptions(d.fieldName)));

    // Fetch radio button values
    for (final radioGroup in _configService.config.radios) {
      final value = await _fetchRadioValueFromWeb(radioGroup.fieldName);
      if (value != null && _selectedRadioValues[radioGroup.fieldName] != value) {
        _selectedRadioValues[radioGroup.fieldName] = value;
      }
    }

    if (mounted) {
      setState(() {
        _isUpdatingFromWeb = false;
        _isPageLoaded = true;
      });
    }
  }

  Future<String?> _fetchRadioValueFromWeb(String fieldName) async {
    try {
      final js =
          """
      var radios = document.getElementsByName('$fieldName');
      var value = '';
      for (var i = 0; i < radios.length; i++) {
          if (radios[i].checked) {
              value = radios[i].value;
              break;
          }
      }
      return value;
      """;
      final jsResult = await _controller.runJavaScriptReturningResult(js);
      // It might return an empty string if nothing is selected.
      final resultString = jsResult.toString();
      return resultString.isEmpty ? null : resultString;
    } catch (e) {
      print("Could not fetch value for radio group $fieldName: $e");
      return null;
    }
  }

  Future<String?> _fetchFieldValueFromWeb(String fieldName) async {
    try {
      final jsResult = await _controller.runJavaScriptReturningResult("document.getElementsByName('$fieldName')[0].value");
      return jsResult.toString();
    } catch (e) {
      print("Could not fetch value for field $fieldName: $e");
      return null;
    }
  }
}
