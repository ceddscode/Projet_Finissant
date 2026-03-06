import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';
import '../http/lib_http.dart';
import 'package:municipalgo/pages/root_scaffold.dart';
import '../services/firebase_service.dart';
import '../services/roleProvider.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final _formKey = GlobalKey<FormState>();
  String? topError;
  bool loading = false;

  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    final roleProvider = context.read<RoleProvider>();
    setState(() {
      topError = null;
      loading = true;
    });

    try {
      final dto = Login(
        username: email.text.trim(),
        password: password.text,
      );

      await login(loginInfo: dto, roleProvider: roleProvider);
      roleProvider.setUser(
        token: roleProvider.token!,
        role: roleProvider.role,
        userId: roleProvider.userId!,
        email: email.text.trim(),
      );
      if (AuthStore.token == null || AuthStore.token!.isEmpty) {
        throw Exception('Missing token');
      }

      await FirebaseService.initialize();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RootScaffold()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        topError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.login, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (topError != null) _errorBox(topError!),
                _section(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MunicipaliGo', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        s.loginToContinue,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco(s.email),
                        validator: (v) {
                          final x = (v ?? '').trim();
                          if (x.isEmpty) return s.invalidEmail;
                          final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
                          return ok ? null : s.invalidEmail;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: _inputDeco(s.password),
                        validator: (v) {
                          if ((v ?? '').isEmpty) return s.invalidPassword;
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: loading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(s.login, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _errorBox(String text) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.red.withValues(alpha: 0.06),
      border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
    ),
    child: Text(text, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
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

InputDecoration _inputDeco(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.03),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}