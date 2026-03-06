import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:municipalgo/http/dtos/transfer.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:municipalgo/models/category_enum.dart';
import 'package:municipalgo/pages/login.dart';
import 'package:municipalgo/pages/root_scaffold.dart';
import 'package:municipalgo/services/location_services.dart';
import 'package:municipalgo/services/quartiersService.dart';
import '../services/image_service.dart';
import 'incident_details.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  CategoryEnum? _selectedCategory;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<File> _imageFiles = [];
  final _imagesFieldKey = GlobalKey<FormFieldState<List<File>>>();
  final _picker = ImagePicker();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _categoryLabel(CategoryEnum c) {
    final s = S.of(context);
    switch (c) {
      case CategoryEnum.Proprete:      return s.cleanliness;
      case CategoryEnum.Mobilier:      return s.furniture;
      case CategoryEnum.Signalisation: return s.roadSigns;
      case CategoryEnum.EspacesVerts:  return s.greenSpaces;
      case CategoryEnum.Saisonnier:    return s.seasonal;
      case CategoryEnum.Social:        return s.social;
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _imageFiles.length) return;
    setState(() => _imageFiles.removeAt(index));
    _imagesFieldKey.currentState?.didChange(_imageFiles);
  }

  void _addImages(List<File> newFiles) {
    setState(() {
      _imageFiles.addAll(newFiles);
      if (_imageFiles.length > 10) _imageFiles.removeRange(10, _imageFiles.length);
    });
    _imagesFieldKey.currentState?.didChange(_imageFiles);
  }

  Future<void> _showPickOptions() async {
    final choice = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => const _ImagePickerSheet(),
    );
    if (choice == 0) {
      await _pickFromCamera();
    }
    else if (choice == 1){
      await _pickFromGallery();
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (picked != null) _addImages([File(picked.path)]);
    } catch (_) {
      _showErrorSnackBar(S.of(context).imageError);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 80);
      if (picked.isNotEmpty) _addImages(picked.map((x) => File(x.path)).toList());
    } catch (_) {
      _showErrorSnackBar(S.of(context).imageError);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    try {
      final position = await _getPosition();
      if (position == null) return;

      final location  = await _resolveAddress(position.latitude, position.longitude);
      final quartier  = QuartiersService.fromLatLng(position.latitude, position.longitude);
      final imageUrls = await _uploadImages();

      await _postIncident(position, location, quartier, imageUrls);
      _onSubmitSuccess();
    } on ApiException catch (e) {
      _handleApiException(e);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        _showErrorSnackBar(S.of(context).errorNoInternet);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        _showErrorSnackBar(S.of(context).errorServerCommunication);
      } else if (status == 401) {
        _redirectToLogin();
      } else if (status != null && status >= 500) {
        _showErrorSnackBar(S.of(context).errorServerUnreachable);
      } else {
        _showErrorSnackBar('${S.of(context).errorsubmit}: ${e.message}');
      }
    } on SocketException {
      _showErrorSnackBar(S.of(context).errorNoInternet);
    } catch (e) {
      _showErrorSnackBar('${S.of(context).errorsubmit}: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleApiException(ApiException e) {
    switch (e.code) {
      case 'UNAUTHORIZED':
        _redirectToLogin();
      case 'NETWORK':
        _showErrorSnackBar(S.of(context).errorNoInternet);
      case 'SERVER':
        _showErrorSnackBar(S.of(context).errorServerUnreachable);
      default:
        _showErrorSnackBar('${S.of(context).errorsubmit}: ${e.message}');
    }
  }

  Future<_LatLng?> _getPosition() async {
    final pos = await locationServices.getCurrentLocation(context);
    if (pos == null) return null;
    return _LatLng(pos.latitude, pos.longitude);
  }

  Future<String> _resolveAddress(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    final p = placemarks.first;
    return [p.street ?? ''].where((x) => x.trim().isNotEmpty).join(', ');
  }

  Future<List<String>> _uploadImages() async {
    final paths = _imageFiles.map((f) => f.path).toList();
    return ajouterImages(paths);
  }

  Future<void> _postIncident(
      _LatLng position,
      String location,
      String? quartier,
      List<String> imageUrls,
      ) async {
    final req = RequeteProblemeAvecPhotos(
      _titleController.text.trim(),
      location,
      _descriptionController.text.trim(),
      _selectedCategory!.index,
      imageUrls,
      position.latitude,
      position.longitude,
      quartier,
    );
    await postProbleme(req);
  }

  void _onSubmitSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).issueSubmitted)),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RootScaffold(initialIndex: 0)),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _redirectToLogin() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).errorSessionExpired)),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Connexion()),
    );
  }

  Future<void> _onCategoryChanged(CategoryEnum cat) async {
    setState(() => _selectedCategory = cat);
    final allIncidents = await getAllIncidents();
    final sameCategory = allIncidents.where((inc) => inc.category == cat.index).toList();
    final nearbyMap    = await locationServices.IncidentInsideZone(context, sameCategory);
    if (nearbyMap.isNotEmpty && mounted) {
      await _showNearbyIncidentsDialog(nearbyMap, sameCategory);
    }
  }

  Future<void> _showNearbyIncidentsDialog(
      Map<int, double> nearbyIncidents,
      List<Incident> allIncidents,
      ) async {
    final items        = nearbyIncidents.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final incidentById = {for (final inc in allIncidents) inc.id: inc};
    await showDialog(
      context: context,
      builder: (_) => _NearbyIncidentsDialog(items: items, incidentById: incidentById),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.reportIssue, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TitleField(controller: _titleController),
                    const SizedBox(height: 12),
                    _DescriptionField(controller: _descriptionController),
                    const SizedBox(height: 12),
                    _CategoryDropdown(
                      selected: _selectedCategory,
                      labelFor: _categoryLabel,
                      onChanged: _onCategoryChanged,
                    ),
                    const SizedBox(height: 12),
                    _ImagesField(
                      fieldKey: _imagesFieldKey,
                      imageFiles: _imageFiles,
                      onAdd: _showPickOptions,
                      onRemove: _removeImageAt,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SubmitButton(
        submitting: _submitting,
        onPressed: _submit,
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(s.title),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLength: 100,
            decoration: _fieldDecoration(s.titleHint),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return s.titleRequired;
              if (v.trim().length < 5 || v.trim().length > 100) return s.errortitle;
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(s.issueDescription),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 6,
            maxLength: 500,
            decoration: _fieldDecoration(s.descriptionHint),
            validator: (v) {
              if (v != null && v.length > 500) return s.errordesc;
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });
  final CategoryEnum? selected;
  final String Function(CategoryEnum) labelFor;
  final Future<void> Function(CategoryEnum) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _FormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(s.category),
          const SizedBox(height: 8),
          DropdownButtonFormField<CategoryEnum>(
            initialValue: selected,
            decoration: _fieldDecoration(''),
            items: CategoryEnum.values
                .map((cat) => DropdownMenuItem(value: cat, child: Text(labelFor(cat))))
                .toList(),
            onChanged: (cat) { if (cat != null) onChanged(cat); },
            validator: (cat) => cat == null ? s.categoryRequired : null,
          ),
        ],
      ),
    );
  }
}

class _ImagesField extends StatelessWidget {
  const _ImagesField({
    required this.fieldKey,
    required this.imageFiles,
    required this.onAdd,
    required this.onRemove,
  });
  final GlobalKey<FormFieldState<List<File>>> fieldKey;
  final List<File> imageFiles;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final s = S.of(context);
    return _FormSection(
      child: FormField<List<File>>(
        key: fieldKey,
        initialValue: imageFiles,
        validator: (files) => (files == null || files.isEmpty) ? s.photorequired : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _FieldLabel(s.photoOptional)),
              Text(
                '${imageFiles.length}/10',
                style: TextStyle(fontWeight: FontWeight.w700, color: baseColor.withValues(alpha: 0.55)),
              ),
            ]),
            const SizedBox(height: 10),
            _ImagesGrid(imageFiles: imageFiles, onAdd: onAdd, onRemove: onRemove),
            if (state.hasError) ...[
              const SizedBox(height: 8),
              Text(
                state.errorText ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  const _ImagesGrid({
    required this.imageFiles,
    required this.onAdd,
    required this.onRemove,
  });
  final List<File> imageFiles;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int i = 0; i < imageFiles.length; i++)
          _ImageThumbnail(file: imageFiles[i], onRemove: () => onRemove(i)),
        if (imageFiles.length < 10)
          _AddImageButton(onTap: onAdd),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.file, required this.onRemove});
  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file, width: 104, height: 104, fit: BoxFit.cover),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          color: Colors.black.withValues(alpha: 0.02),
        ),
        child: const Center(child: Icon(Icons.add_a_photo, size: 28)),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.submitting, required this.onPressed});
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: submitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: submitting
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(s.submit, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
    );
  }
}

class _NearbyIncidentsDialog extends StatelessWidget {
  const _NearbyIncidentsDialog({required this.items, required this.incidentById});
  final List<MapEntry<int, double>> items;
  final Map<int, Incident> incidentById;

  static const double _rowH  = 78;
  static const double _sepH  = 1;
  static const double _baseH = 24;
  static const double _maxH  = 520;

  double get _listHeight {
    final n = items.length;
    if (n == 0) return 90;
    return ((n * _rowH) + ((n - 1) * _sepH) + _baseH).clamp(90, _maxH);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: const Row(
        children: [
          Icon(Icons.near_me, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text("Incidents à proximité")),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: _listHeight,
        child: items.isEmpty
            ? const Center(child: Text("Aucun incident", style: TextStyle(color: Colors.grey)))
            : _IncidentList(items: items, incidentById: incidentById),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Fermer"),
        ),
      ],
    );
  }
}

class _IncidentList extends StatelessWidget {
  const _IncidentList({required this.items, required this.incidentById});
  final List<MapEntry<int, double>> items;
  final Map<int, Incident> incidentById;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final entry    = items[i];
        final incident = incidentById[entry.key];
        return _IncidentListTile(id: entry.key, incident: incident);
      },
    );
  }
}

class _IncidentListTile extends StatelessWidget {
  const _IncidentListTile({required this.id, this.incident});
  final int id;
  final Incident? incident;

  @override
  Widget build(BuildContext context) {
    final title    = (incident?.title.trim().isNotEmpty ?? false) ? incident!.title : "Incident #$id";
    final location = (incident?.location.trim().isNotEmpty ?? false) ? incident!.location : null;
    final firstImg = (incident?.imagesUrl?.isNotEmpty ?? false) ? incident!.imagesUrl!.first : null;

    return SizedBox(
      height: 78,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => IncidentDetailsPage(incidentId: id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IncidentThumbnail(imageUrl: firstImg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (location != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncidentThumbnail extends StatelessWidget {
  const _IncidentThumbnail({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl == null
            ? Container(
          alignment: Alignment.center,
          color: Colors.grey.shade200,
          child: const Icon(Icons.photo, size: 22),
        )
            : Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 22),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              alignment: Alignment.center,
              color: Colors.grey.shade200,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImagePickerSheet extends StatelessWidget {
  const _ImagePickerSheet();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(s.takePhoto),
            onTap: () => Navigator.of(context).pop(0),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(s.chooseFromGallery),
            onTap: () => Navigator.of(context).pop(1),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14));
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.03),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

class _LatLng {
  const _LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}