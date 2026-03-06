import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
final storage = supabase.storage.from('imageBucket');

/// Upload une liste de fichiers locaux vers le bucket `imageBucket` de Supabase
/// Retourne la liste des URLs publiques (dans le même ordre que `localPaths`).
Future<List<String>> ajouterImages(List<String> localPaths) async {
  final List<String> uploadedUrls = [];

  for (final localPath in localPaths) {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Fichier introuvable: $localPath');
    }

    // Génère un nom de fichier unique en utilisant un timestamp + nom d'origine
    final originalName = localPath.split(Platform.pathSeparator).last;
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';
    // final storagePath = uniqueName;

    // Upload
    await storage.upload(uniqueName, file);

    // Après upload, obtenir l'URL publique
    final publicUrl = storage.getPublicUrl(uniqueName);
    uploadedUrls.add(publicUrl);
  }

  return uploadedUrls;
}

/// Supprime plusieurs images à partir de leurs URLs publiques retournées par `getPublicUrl`.
/// Lance une exception si la suppression échoue.
Future<void> supprimerImagesParPublicUrls(List<String> publicUrls) async
{
  if (publicUrls.isEmpty) return;
  try {
    final List<FileObject> objects = await storage.remove(publicUrls);
    print(objects);
  }
  catch (e) {
    print(e);
    throw Exception('Échec de la suppression des images: $e');
  }
}
