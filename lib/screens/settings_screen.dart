import 'package:asatex_compensation/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.title});
  final String title;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _taxRateController;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsService>(context, listen: false);
    _urlController = TextEditingController(text: settings.url);
    _taxRateController = TextEditingController(text: settings.taxRate.toString());
  }

  @override
  void dispose() {
    _urlController.dispose();
    _taxRateController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = Provider.of<SettingsService>(context, listen: false);
      settings.setUrl(_urlController.text);
      settings.setTaxRate(double.tryParse(_taxRateController.text) ?? 10.0);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました。')),
      );
      FocusScope.of(context).unfocus();
    }
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      actions: [
        KeyboardActionsItem(
          focusNode: _focusNode,
          toolbarButtons: [
            (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("完成"),
                ),
              );
            }
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: KeyboardActions(
          config: _buildConfig(context),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: '网页网址',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URLを入力してください。';
                  }
                  if (!Uri.parse(value).isAbsolute) {
                    return '有効なURLを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxRateController,
                decoration: const InputDecoration(
                  labelText: '税率 (%)',
                  border: OutlineInputBorder(),
                  hintText: '10.0',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '税率を入力してください。';
                  }
                  if (double.tryParse(value) == null) {
                    return '有効な数値を入力してください。';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                focusNode: _focusNode,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 