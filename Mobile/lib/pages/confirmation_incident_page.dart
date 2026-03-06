import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:municipalgo/pages/root_scaffold.dart';
import 'package:municipalgo/services/image_service.dart';
import 'package:municipalgo/generated/l10n.dart';
import '../http/dtos/transfer.dart';

class ConfirmationIncidentPage extends StatefulWidget {
  final int incidentId;

  const ConfirmationIncidentPage({super.key, required this.incidentId});

  @override
  State<ConfirmationIncidentPage> createState() => _ConfirmationIncidentPageState();
}

class _ConfirmationIncidentPageState extends State<ConfirmationIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final List<File> _imageFiles = [];
  final GlobalKey<FormFieldState<List<File>>> _imagesFieldKey = GlobalKey<FormFieldState<List<File>>>();
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Lance directement la caméra pour prendre une photo et l'ajouter à la liste
  Future<void> _pickImages() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _imageFiles.add(File(picked.path));
        });
        _imagesFieldKey.currentState?.didChange(_imageFiles);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).imageError)),
        );
      }
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      if (index >= 0 && index < _imageFiles.length) {
        _imageFiles.removeAt(index);
      }
    });
    _imagesFieldKey.currentState?.didChange(_imageFiles);
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _submitting = true);

    final paths = _imageFiles.map((f) => f.path).toList();

    //UPLOAD IMAGES AU SERVEUR

    List<String> uploadedUrls = [];

    try {
      // Appel service d'upload — renvoie les URLs publiques
      uploadedUrls = await ajouterImages(paths);

      //Créer un nouveau DTO pour la confirmation d'incident
      RequeteConfirmIncident req = RequeteConfirmIncident(widget.incidentId, _descriptionController.text.trim(), uploadedUrls);

      // Appel API pour soumettre la confirmation d'incident
      await putConfirmIncident(req);

    } catch (e) {
      if (mounted) {
        //Effacage des images en cas d'erreur
        List<String> fileNames = [];
        for(var i = 0; i < uploadedUrls.length; i++) {
          fileNames.add(uploadedUrls[i].split('/').last);
        }
        supprimerImagesParPublicUrls(fileNames);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).errorsubmit + ': $e')));
        setState(() => _submitting = false);
      }
      return;
    }

    // SnackBar de confirmation
    final description = _descriptionController.text.trim();

    if (mounted) {
      final photoText = _imageFiles.isNotEmpty ? '${_imageFiles.length} photo(s)' : 'sans photo';
      final descText = description.isNotEmpty ? '\nDescription : $description' : '';
      final uploadedText = '\nImages uploadées : ${uploadedUrls.length}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).issueSubmitted)),
      );
      setState(() => _submitting = false);
      // Retourner au RootScaffold et s'assurer que l'accueil est affiché
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => RootScaffold()
          )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.issueConfirmation)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: s.optionalConfirmationDescription,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  validator: (v) {
                    // La description est optionnelle, donc pas de validation de vide
                    if (v != null && v.length > 500) {
                      return s.errordesc;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(s.photoOptional, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                // Champ de formulaire personnalisé pour gérer la validation des images
                FormField<List<File>>(
                  key: _imagesFieldKey,
                  initialValue: _imageFiles,
                  validator: (files) {
                    if (files == null || files.isEmpty) {
                      return s.photorequired;
                    }
                    return null;
                  },
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < _imageFiles.length; i++)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(_imageFiles[i], width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImageAt(i),
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        padding: const EdgeInsets.all(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (_imageFiles.length < 10)
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.add_a_photo, size: 32, color: Colors.black54),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(state.errorText ?? '', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(s.submit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
