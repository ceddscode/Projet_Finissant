import 'package:flutter/material.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:municipalgo/generated/l10n.dart';

import '../http/dtos/transfer.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _roadNumber = TextEditingController();
  final _roadName = TextEditingController();
  final _postal = TextEditingController();
  final _city = TextEditingController();

  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _changingPw = false;
  bool _showPassword = false;
  bool _isAnonymous = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _roadNumber.dispose();
    _roadName.dispose();
    _postal.dispose();
    _city.dispose();
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final me = await getMe();
      _first.text = me.firstName ?? '';
      _last.text = me.lastName ?? '';
      _email.text = me.email ?? '';
      _phone.text = me.phoneNumber ?? '';
      _roadNumber.text = me.roadNumber?.toString() ?? '';
      _roadName.text = me.roadName ?? '';
      _postal.text = me.postalCode ?? '';
      _city.text = me.city ?? '';
      _isAnonymous = me.isAnonymous ?? true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await patchMe(EditUserDto(
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        firstName: _first.text.trim().isEmpty ? null : _first.text.trim(),
        lastName: _last.text.trim().isEmpty ? null : _last.text.trim(),
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        roadNumber: _roadNumber.text.trim().isEmpty ? null : int.tryParse(_roadNumber.text.trim()),
        roadName: _roadName.text.trim().isEmpty ? null : _roadName.text.trim(),
        postalCode: _postal.text.trim().isEmpty ? null : _postal.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        isAnonymous: _isAnonymous,
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = _currentPw.text;
    final nw = _newPw.text;
    final cf = _confirmPw.text;

    if (cur.isEmpty || nw.isEmpty || cf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all password fields')));
      return;
    }
    if (nw != cf) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _changingPw = true);
    try {
      await changeMyPassword(ChangePasswordDto(
        currentPassword: cur,
        newPassword: nw,
        confirmNewPassword: cf,
      ));

      _currentPw.clear();
      _newPw.clear();
      _confirmPw.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.account, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            children: [
              _section(
                context,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      _field(_first, 'First name'),
                      const SizedBox(height: 10),
                      _field(_last, 'Last name'),
                      const SizedBox(height: 10),
                      _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 10),
                      _field(_phone, 'Phone', keyboard: TextInputType.phone),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _field(_roadNumber, 'Road #', keyboard: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(_postal, 'Postal code')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _field(_roadName, 'Road name'),
                      const SizedBox(height: 10),
                      _field(_city, 'City'),
                      const SizedBox(height: 10),
                      _AnonymousCheckbox(
                        value: _isAnonymous,
                        onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _section(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change password', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        _showPassword ? 'Fill the fields below' : 'Update your password',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(_showPassword ? Icons.expand_less : Icons.expand_more),
                      onTap: () => setState(() => _showPassword = !_showPassword),
                    ),
                    if (_showPassword) ...[
                      const SizedBox(height: 10),
                      _field(_currentPw, 'Current password', obscure: true),
                      const SizedBox(height: 10),
                      _field(_newPw, 'New password', obscure: true),
                      const SizedBox(height: 10),
                      _field(_confirmPw, 'Confirm new password', obscure: true),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _changingPw ? null : _changePassword,
                          child: _changingPw
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Change password'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController c,
      String label, {
        TextInputType? keyboard,
        bool obscure = false,
      }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (v) {
        if (label == 'Email') {
          final x = (v ?? '').trim();
          if (x.isEmpty) return null;
          if (!x.contains('@')) return 'Invalid email';
        }
        return null;
      },
    );
  }

  Widget _section(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _AnonymousCheckbox extends StatelessWidget {
  const _AnonymousCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contribute anonymously',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your name will not be shown on your reports',
                    style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}