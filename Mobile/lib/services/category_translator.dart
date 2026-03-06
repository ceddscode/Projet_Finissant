import '../generated/l10n.dart';
import '../models/category_enum.dart';

class CategoryTranslator {
  static String translate(int categoryIndex, S s) {
    CategoryEnum category;

    try {
      category = CategoryEnum.values[categoryIndex];
    } catch (_) {
      return "Unknown";
    }

    switch (category) {
      case CategoryEnum.Proprete:
        return s.Proprete;
      case CategoryEnum.Mobilier:
        return s.Mobilier;
      case CategoryEnum.Signalisation:
        return s.Signalisation;
      case CategoryEnum.EspacesVerts:
        return s.EspacesVerts;
      case CategoryEnum.Saisonnier:
        return s.Saisonnier;
      case CategoryEnum.Social:
        return s.Social;
    }
  }
}