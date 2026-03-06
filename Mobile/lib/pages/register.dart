import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n.dart';
import '../http/dtos/transfer.dart';
import '../http/lib_http.dart';
import 'login.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  String? topError;
  bool loading = false;

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final phoneNumber = TextEditingController();
  final roadNumber = TextEditingController();
  final roadName = TextEditingController();
  final city = TextEditingController();
  final postalCode = TextEditingController();

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    phoneNumber.dispose();
    roadNumber.dispose();
    roadName.dispose();
    postalCode.dispose();
    city.dispose();
    super.dispose();
  }

  RegisterDraft _draft() {
    return RegisterDraft(
      firstName: firstName.text,
      lastName: lastName.text,
      email: email.text,
      password: password.text,
      confirm: confirm.text,
      phoneNumber: phoneNumber.text,
      roadNumber: roadNumber.text,
      roadName: roadName.text,
      city: city.text,
      postalCode: postalCode.text,
    );
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      topError = null;
      loading = true;
    });

    try {
      final msg = await register(registerInfo: _draft().toRegister());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Connexion()));
    } catch (_) {
      if (!mounted) return;
      setState(() => topError = S.of(context).registrationError);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.register, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
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
                      Text('Infos', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstName,
                              decoration: _inputDeco(s.firstName),
                              validator: (_) => _draft().validate(s).fieldKey == 'firstName' ? _draft().validate(s).message : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: lastName,
                              decoration: _inputDeco(s.lastName),
                              validator: (_) => _draft().validate(s).fieldKey == 'lastName' ? _draft().validate(s).message : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: email,
                        decoration: _inputDeco(s.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (_) => _draft().validate(s).fieldKey == 'email' ? _draft().validate(s).message : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: password,
                              decoration: _inputDeco(s.password),
                              obscureText: true,
                              validator: (_) => _draft().validate(s).fieldKey == 'password' ? _draft().validate(s).message : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: confirm,
                              decoration: _inputDeco(s.confirmPassword),
                              obscureText: true,
                              validator: (_) => _draft().validate(s).fieldKey == 'confirm' ? _draft().validate(s).message : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneNumber,
                        decoration: _inputDeco(s.phoneNumber),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          PhoneNumberFormatter(),
                          LengthLimitingTextInputFormatter(14),
                        ],
                        validator: (_) => _draft().validate(s).fieldKey == 'phoneNumber' ? _draft().validate(s).message : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adresse', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: roadNumber,
                              decoration: _inputDeco(s.roadNumber),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (_) => _draft().validate(s).fieldKey == 'roadNumber' ? _draft().validate(s).message : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: roadName,
                              decoration: _inputDeco(s.roadName),
                              validator: (_) => _draft().validate(s).fieldKey == 'roadName' ? _draft().validate(s).message : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: city,
                              decoration: _inputDeco(s.city),
                              validator: (_) => _draft().validate(s).fieldKey == 'city' ? _draft().validate(s).message : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: postalCode,
                              decoration: _inputDeco(s.postalCode),
                              inputFormatters: [
                                UpperCaseTextFormatter(),
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              validator: (_) => _draft().validate(s).fieldKey == 'postalCode' ? _draft().validate(s).message : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: loading ? null : submit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(s.register, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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