import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminSmtpScreen extends StatefulWidget {
  const AdminSmtpScreen({super.key});

  @override
  State<AdminSmtpScreen> createState() => _AdminSmtpScreenState();
}

class _AdminSmtpScreenState extends State<AdminSmtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '587');
  final _usernameCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _useSSL = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await ApiService.getSmtpConfig();
    setState(() {
      _hostCtrl.text = cfg['host']?.toString() ?? 'smtp.gmail.com';
      _portCtrl.text = cfg['port']?.toString() ?? '587';
      _usernameCtrl.text = cfg['username']?.toString() ?? '';
      _fromCtrl.text = cfg['from']?.toString() ?? cfg['username']?.toString() ?? '';
      _useSSL = cfg['ssl'] == true || cfg['useSSL'] == true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final config = {
      'host': _hostCtrl.text.trim(),
      'port': int.tryParse(_portCtrl.text.trim()) ?? 587,
      'username': _usernameCtrl.text.trim(),
      'from': _fromCtrl.text.trim(),
      'ssl': _useSSL,
    };
    await ApiService.setSmtpConfig(config, password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMTP settings saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMTP Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _hostCtrl,
                decoration: const InputDecoration(labelText: 'SMTP Host'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter host' : null,
              ),
              TextFormField(
                controller: _portCtrl,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter port' : null,
              ),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null,
              ),
              TextFormField(
                controller: _fromCtrl,
                decoration: const InputDecoration(labelText: 'From address'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter from address' : null,
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password (leave blank to keep existing)'),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gmail users: use smtp.gmail.com and port 587 with TLS. Enter your Gmail App Password here, not your normal login password.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hostCtrl.text = 'smtp.gmail.com';
                    _portCtrl.text = '587';
                    _useSSL = false;
                  });
                },
                child: const Text('Use Gmail SMTP defaults'),
              ),
              SwitchListTile(
                title: const Text('Use SSL'),
                value: _useSSL,
                onChanged: (v) => setState(() => _useSSL = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save SMTP Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
