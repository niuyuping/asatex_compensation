import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:asatex_compensation/services/config_service.dart';
import 'package:asatex_compensation/models/salary_form_field_config.dart';
import 'package:provider/provider.dart';
import 'package:asatex_compensation/services/settings_service.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class SalaryCalculatorScreen extends StatefulWidget {
  const SalaryCalculatorScreen({super.key, required this.title});
  final String title;

  @override
  State<SalaryCalculatorScreen> createState() => _SalaryCalculatorScreenState();
}

class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
  final ConfigService _configService = ConfigService.instance;
  late final WebViewController _controller;
  bool _isPageLoaded = false;
  bool _isUpdatingFromWeb = false;
  bool _isResultsExpanded = false;
  bool _isSensitiveDataVisible = true;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, List<Map<String, String>>> _dropdownOptions = {};
  final Map<String, String?> _selectedDropdownValues = {};
  final Map<String, String> _selectedRadioValues = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeStateFromConfig(_configService.config);
    _initController();
  }

  void _initializeStateFromConfig(SalaryFormFieldConfig config) {
    // Define the IDs for fields that need to trigger UI updates for calculations.
    const fieldsForRebuild = [1, 2]; // 1: 単価, 2: 控除率

    // Initialize controllers for text fields and add listeners
    for (final field in config.textFields) {
      final controller = TextEditingController(text: field.initialValue);
      controller.addListener(() {
        if (!_isUpdatingFromWeb) {
          _syncField(field.fieldName, controller.text);
        }
        // If this field is one that affects calculations, rebuild the UI.
        if (fieldsForRebuild.contains(field.id)) {
          setState(() {});
        }
      });
      _textControllers[field.fieldName] = controller;
      _focusNodes[field.fieldName] = FocusNode();
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
    final settings = Provider.of<SettingsService>(context, listen: false);
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
      ..loadRequest(Uri.parse(settings.url));
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
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _buildSalaryCalculator(_configService.config),
    );
  }

  Widget _buildSalaryCalculator(SalaryFormFieldConfig config) {
    // Separate fields into editable and readonly lists
    final editableFields = config.textFields.where((f) => !f.readonly).toList();
    final readonlyFields = config.textFields.where((f) => f.readonly).toList();

    return Scaffold(
      body: Stack(
        children: [
          // This WebView runs in the background. It's not visible and doesn't
          // receive pointer events, but it's active for JS communication.
          Opacity(
            opacity: 0.0,
            child: IgnorePointer(child: WebViewWidget(controller: _controller)),
          ),

          // This is the visible and interactive UI layer.
          KeyboardActions(
            config: _buildKeyboardActionsConfig(),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // New dedicated section for readonly fields
                    if (readonlyFields.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          // Pass ALL text fields to the results widget for calculation purposes.
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildReadonlyResults(config.textFields)]),
                        ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _triggerWebButton('calc'),
        child: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildReadonlyResults(List<TextFieldConfig> allTextFields) {
    // Helper to safely get numeric value from ANY text field by its ID.
    double getNumericValue(int id) {
      try {
        final field = allTextFields.firstWhere((f) => f.id == id);
        final controller = _textControllers[field.fieldName];
        final valueString = controller?.text ?? '0';
        return double.tryParse(valueString.replaceAll(',', '')) ?? 0.0;
      } catch (e) {
        return 0.0; // Field not found, which is okay.
      }
    }

    // --- All Calculations Happen Here ---
    final companyFieldIds = [10, 11, 12, 13]; // 10:健康保険, 11:介護保険, 12:厚生年金, 13:雇用保険
    final tanka = getNumericValue(1); // 1: 単価
    final koujoritsu = getNumericValue(2); // 2: 控除率
    final uriage = tanka * (1 - koujoritsu / 100);
    final sashihikiShikyugaku = getNumericValue(8); // 8: 差引支給額
    final koujoKei = getNumericValue(9); // 9: 控除計
    final salaryTotal = getNumericValue(3) + getNumericValue(4) + getNumericValue(5) - getNumericValue(6); // 15: 給与計
    final kanrihi = getNumericValue(1) * getNumericValue(2) / 100; // 1: 単価, 2: 管理費率

    final companyFieldsForTotal = allTextFields.where((f) => f.readonly && companyFieldIds.contains(f.id));
    final companyTotal = companyFieldsForTotal.fold<double>(0.0, (sum, field) {
      final rawValue = _textControllers[field.fieldName]?.text ?? field.initialValue;
      final numericValue = double.tryParse(rawValue.replaceAll(',', '')) ?? 0.0;
      if (field.id == 13) {
        // 13: 雇用保険
        return sum + (numericValue * 3);
      }
      return sum + numericValue;
    });

    final buai = (uriage - companyTotal - sashihikiShikyugaku - koujoKei) * getNumericValue(15) / 100;
    final rieki = uriage - companyTotal - sashihikiShikyugaku - koujoKei - buai;

    // Helper to format a string value if it's a valid number.
    String formatIfNumber(String rawValue) {
      if (rawValue.trim().isEmpty) return rawValue;
      final numericValue = double.tryParse(rawValue.replaceAll(',', ''));
      if (numericValue != null) {
        return NumberFormat('#,###').format(numericValue.round());
      }
      return rawValue; // Return original if not a number.
    }

    // --- Prepare Display Lists ---
    final personalItems = allTextFields.where((f) => f.readonly).map((field) {
      final rawValue = _textControllers[field.fieldName]?.text ?? field.initialValue;
      return {'id': field.id, 'label': field.label, 'value': field.isNumber ? formatIfNumber(rawValue) : rawValue};
    }).toList();

    final companyItems = allTextFields.where((f) => f.readonly && companyFieldIds.contains(f.id)).map((field) {
      final rawValue = _textControllers[field.fieldName]?.text ?? field.initialValue;
      String value;

      if (field.id == 13) {
        // Special calculation for '雇用保険' (id: 13).
        final numericValue = double.tryParse(rawValue.replaceAll(',', '')) ?? 0.0;
        value = NumberFormat('#,###').format((numericValue * 3).round());
      } else {
        // Standard formatting for other numeric fields.
        value = field.isNumber ? formatIfNumber(rawValue) : rawValue;
      }
      return {'id': field.id, 'label': field.label, 'value': _isSensitiveDataVisible ? value : '******'};
    }).toList();

    personalItems.insert(0, {'id': null, 'label': '給与計', 'value': formatIfNumber(salaryTotal.toString())});
    // --- Mask sensitive totals ---
    final maskedUriage = _isSensitiveDataVisible ? NumberFormat('#,###').format(uriage.round()) : '******';
    final maskedRieki = _isSensitiveDataVisible ? NumberFormat('#,###').format(rieki.round()) : '******';
    final maskedCompanyTotal = _isSensitiveDataVisible ? NumberFormat('#,###').format(companyTotal.round()) : '******';
    final maskedKanrihi = _isSensitiveDataVisible ? NumberFormat('#,###').format(kanrihi.round()) : '******';
    final maskedBuai = _isSensitiveDataVisible ? NumberFormat('#,###').format(buai.round()) : '******';

    companyItems.insert(0, {'id': null, 'label': '売上', 'value': maskedUriage});
    companyItems.add({'id': null, 'label': '会社負担計', 'value': maskedCompanyTotal});
    companyItems.add({'id': null, 'label': '管理費', 'value': maskedKanrihi});
    companyItems.add({'id': null, 'label': '歩合', 'value': maskedBuai});
    companyItems.add({'id': null, 'label': '利益', 'value': maskedRieki});

    // Use a custom Column layout for full control over alignment.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isResultsExpanded = !_isResultsExpanded;
              });
            },
            child: Column(
              children: [
                // Only show the summary row when the tile is collapsed.
                if (!_isResultsExpanded)
                  _buildSummaryRow(formatIfNumber(sashihikiShikyugaku.toString()), maskedRieki),
                Transform.rotate(
                  angle: _isResultsExpanded ? math.pi : 0,
                  child: const Icon(Icons.expand_more, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          // The collapsible content.
          if (_isResultsExpanded)
            Column(
              children: [
                const Divider(height: 1),
                // Centered titles for the expanded view
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(child: Center(child: Text('個人', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('会社', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Row(
      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildResultList(personalItems)),
                    Expanded(child: _buildResultList(companyItems)),
                  ],
                ),
                
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String sashihikiValue, String riekiValue) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: const Text("支給", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
            trailing: Text(
              sashihikiValue,
              style: TextStyle(fontSize: 14, color: (double.tryParse(sashihikiValue.replaceAll(',', '')) ?? 0.0) > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: ListTile(
              dense: true,
            visualDensity: VisualDensity.compact,
            title: const Text("利益", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
              trailing: Text(
              riekiValue,
              style: TextStyle(fontSize: 14, color: (double.tryParse(riekiValue.replaceAll(',', '')) ?? 0.0) > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
              ),
        ),
      ],
    );
  }

  Widget _buildResultList(List<Map<String, Object?>> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'] as int?;
        final label = item['label'] as String;
        final value = item['value'] as String;
        final isImportant = (id == 8) || label == '売上' || label == '利益' || label == '給与計'; // 8: 差引支給額

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(label, style: const TextStyle(fontSize: 14.0)),
          trailing: Text(value, style: TextStyle(fontSize: 14, color: isImportant && (double.tryParse(value.replaceAll(',', '')) ?? 0.0) > 0 ? Colors.green : Colors.red)),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 0),
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
                child: Text(group.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14.0)),
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
                        Text(option.label, style: const TextStyle(fontSize: 14.0)),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14.0),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          isDense: true,
          items: options.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option['value'],
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                option['text']!.trim(),
                style: const TextStyle(fontSize: 14.0),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, TextFieldConfig config) {
    final isSensitive = [1, 2, 15].contains(config.id); // 1: 単価, 2: 控除率
    return TextField(
      controller: controller,
      focusNode: _focusNodes[config.fieldName],
      readOnly: config.readonly,
      obscureText: isSensitive && !_isSensitiveDataVisible,
      obscuringCharacter: '*',
      keyboardType: config.isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: config.isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      style: const TextStyle(fontSize: 14.0),
      decoration: InputDecoration(
        labelText: config.label,
        labelStyle: const TextStyle(fontSize: 14.0),
        border: const OutlineInputBorder(),
        fillColor: config.readonly ? Colors.grey[200] : null,
        filled: config.readonly,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      ),
      textInputAction: TextInputAction.done,
      onEditingComplete: () => FocusScope.of(context).unfocus(),
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

  void _showInfoDialog(BuildContext context) {
    // Implementation of _showInfoDialog method
  }

  KeyboardActionsConfig _buildKeyboardActionsConfig() {
    return KeyboardActionsConfig(
      actions: _focusNodes.entries.map((entry) {
        return KeyboardActionsItem(
          focusNode: entry.value,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () {
                  // 先同步当前字段到WebView，再收起键盘
                  final fieldName = entry.key;
                  if (_textControllers.containsKey(fieldName)) {
                    _syncField(fieldName, _textControllers[fieldName]!.text);
                  }
                  node.unfocus();
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("完成"),
                ),
              );
            }
          ],
        );
      }).toList(),
    );
  }
}
