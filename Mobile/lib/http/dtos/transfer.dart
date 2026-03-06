import 'dart:core';

import 'package:json_annotation/json_annotation.dart';
import 'package:municipalgo/generated/l10n.dart';
import 'package:flutter/services.dart';
import '../../models/intervention_type_enum.dart';

part 'transfer.g.dart';

// ============== Text Input Formatters ==============
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    // Remove non-digit characters
    final digits = text.replaceAll(RegExp(r'\D'), '');

    // Format: (###) ###-####
    if (digits.length <= 3) {
      return newValue.copyWith(
        text: digits.isEmpty ? '' : '($digits',
        selection: TextSelection.collapsed(
          offset: digits.length + (digits.isEmpty ? 0 : 1),
        ),
      );
    } else if (digits.length <= 6) {
      final part1 = digits.substring(0, 3);
      final part2 = digits.substring(3);
      return newValue.copyWith(
        text: '($part1) $part2',
        selection: TextSelection.collapsed(
          offset: part1.length + part2.length + 3,
        ),
      );
    } else {
      final part1 = digits.substring(0, 3);
      final part2 = digits.substring(3, 6);
      final part3 = digits.substring(6, 10.clamp(0, digits.length));
      return newValue.copyWith(
        text: '($part1) $part2-$part3',
        selection: TextSelection.collapsed(
          offset: part1.length + part2.length + part3.length + 4,
        ),
      );
    }
  }
}

// ============== Regex Patterns ==============
final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final passwordRegex = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{5,}$',
);
final postalRegex = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');

// ============== Validation ==============
class ValidationResult {
  final String? fieldKey;
  final String? message;

  const ValidationResult(this.fieldKey, this.message);

  static ValidationResult ok() => const ValidationResult(null, null);

  bool get isOk => message == null;
}

// ============== DTOs ==============
class SubscriptionInfo {
  final bool isSubscribed;
  final bool isMandatory;

  SubscriptionInfo({required this.isSubscribed, required this.isMandatory});

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      isMandatory: json['isMandatory'] as bool? ?? false,
    );
  }
}

class ChangePasswordDto {
  ChangePasswordDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmNewPassword': confirmNewPassword,
  };
}

class EditUserDto {
  EditUserDto({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.roadNumber,
    this.roadName,
    this.postalCode,
    this.city,
    this.isAnonymous,
  });

  String? id;
  String? email;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  int? roadNumber;
  String? roadName;
  String? postalCode;
  String? city;
  bool? isAnonymous;

  factory EditUserDto.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) => v == null ? null : v.toString();
    int? i(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    bool? b(dynamic v) => v == null ? null : (v is bool ? v : v.toString().toLowerCase() == 'true');

    return EditUserDto(
      id: s(json['id'] ?? json['Id']),
      email: s(json['email'] ?? json['Email']),
      firstName: s(json['firstName'] ?? json['FirstName']),
      lastName: s(json['lastName'] ?? json['LastName']),
      phoneNumber: s(json['phoneNumber'] ?? json['PhoneNumber']),
      roadNumber: i(json['roadNumber'] ?? json['RoadNumber']),
      roadName: s(json['roadName'] ?? json['RoadName']),
      postalCode: s(json['postalCode'] ?? json['PostalCode']),
      city: s(json['city'] ?? json['City']),
      isAnonymous: b(json['isAnonymous'] ?? json['IsAnonymous']),
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'roadNumber': roadNumber,
    'roadName': roadName,
    'postalCode': postalCode,
    'city': city,
    'isAnonymous': isAnonymous,
  };
}

@JsonSerializable()
class RequeteProblemeAvecPhotos {
  RequeteProblemeAvecPhotos(
      this.title,
      this.location,
      this.description,
      this.category,
      this.imagesUrl,
      this.latitude,
      this.longitude,
      this.quartier
      );

  String title;
  String location;
  String description;
  int category;
  List<String> imagesUrl;
  double latitude;
  double longitude;
  String? quartier;
  factory RequeteProblemeAvecPhotos.fromJson(Map<String, dynamic> json) =>
      _$RequeteProblemeAvecPhotosFromJson(json);

  Map<String, dynamic> toJson() => _$RequeteProblemeAvecPhotosToJson(this);
}

@JsonSerializable()
class RequeteConfirmIncident {
  RequeteConfirmIncident(this.incidentId, this.description, this.imagesUrl);

  int incidentId;
  String description;
  List<String> imagesUrl;

  factory RequeteConfirmIncident.fromJson(Map<String, dynamic> json) =>
      _$RequeteConfirmIncidentFromJson(json);

  Map<String, dynamic> toJson() => _$RequeteConfirmIncidentToJson(this);
}

@JsonSerializable()
class Incident {
  final int id;
  final String title;
  final String? description;
  final List<String>? imagesUrl;
  final String location;
  final DateTime createdAt;
  final double latitude;
  final double longitude;
  final int? distance;
  final String? quartier;
  @JsonKey(name: 'isLiked', defaultValue: false)
  bool isLiked;

  @JsonKey(name: 'likeCount', defaultValue: 0)
  int likeCount;

  @JsonKey(name: 'category')
  final int category;

  @JsonKey(name: 'status')
  final int status;

  final DateTime? assignedAt;

  @JsonKey(ignore: true)
  final String? citizen;

  Incident({
    required this.id,
    required this.title,
    this.description,
    required this.isLiked,
    required this.likeCount,

    required this.imagesUrl,
    required this.location,
    required this.createdAt,
    required this.category,
    required this.status,
    this.assignedAt,
    this.citizen,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.quartier,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    final distanceValue = json['distance'];
    int? parsedDistance;
    if (distanceValue is int) {
      parsedDistance = distanceValue;
    } else if (distanceValue is String) {
      parsedDistance = int.tryParse(distanceValue);
    }

    return Incident(
      id: (json['id'] ?? json['Id']) as int,
      title: (json['title'] ?? json['Title']) as String,
      description: json['description'] as String? ?? '',
      imagesUrl: (json['imagesUrl'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      location: (json['location'] ?? json['Location']) as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as int,
      status: json['status'] as int,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: parsedDistance,
      isLiked: json['isLiked'] as bool? ?? false,
      likeCount: json['likeCount'] as int? ?? 0,
      quartier: (json['quartier'] ?? json['Quartier']) as String?,
    );
  }

  Map<String, dynamic> toJson() => _$IncidentToJson(this);

  dynamic get(String key) => toJson()[key];
}

@JsonSerializable()
class Register {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String passwordConfirm;
  final String phoneNumber;
  final int roadNumber;
  final String roadName;
  final String postalCode;
  final String city;

  Register({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.phoneNumber,
    required this.roadNumber,
    required this.roadName,
    required this.postalCode,
    required this.city,
  });

  factory Register.fromJson(Map<String, dynamic> json) =>
      _$RegisterFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterToJson(this);
}

@JsonSerializable()
class CommentDTO {
  final int id;
  final String message;
  final int likeCount;
  final String citizenName;
  final bool isLiked;
  final int repliesCount;
  final bool isOwner;
  final bool isReported;

  CommentDTO({
    required this.id,
    required this.message,
    required this.likeCount,
    required this.citizenName,
    required this.isLiked,
    required this.repliesCount,
    required this.isOwner,
    required this.isReported
  });

  factory CommentDTO.fromJson(Map<String, dynamic> json) => _$CommentDTOFromJson(json);
  Map<String, dynamic> toJson() => _$CommentDTOToJson(this);
}

@JsonSerializable()
class Login {
  final String username;
  final String password;

  Login({required this.username, required this.password});

  factory Login.fromJson(Map<String, dynamic> json) => _$LoginFromJson(json);

  Map<String, dynamic> toJson() => _$LoginToJson(this);
}

@JsonSerializable()
class IncidentDetailsDTO {
  final int id;
  final String title;
  final String? description;
  final String location;
  final DateTime createdDate;
  final List<String> imagesUrl;
  final String? citizenId;
  final String? confirmationDescription;
  final List<String>? confirmationImagesUrl;

  @JsonKey(defaultValue: false)
  bool isLiked;

  @JsonKey(defaultValue: 0)
  int likeCount;

  @JsonKey(name: 'status')
  final int status;

  @JsonKey(name: 'category')
  final int category;

  IncidentDetailsDTO({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.createdDate,
    required this.status,
    required this.imagesUrl,
    required this.category,
    required this.isLiked,
    required this.likeCount,
    this.citizenId,
    this.confirmationDescription,
    this.confirmationImagesUrl,
  });

  factory IncidentDetailsDTO.fromJson(Map<String, dynamic> json) =>
      _$IncidentDetailsDTOFromJson(json);

  Map<String, dynamic> toJson() => _$IncidentDetailsDTOToJson(this);
}
class BadgeDTO {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int minPointsRequired;

  BadgeDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.minPointsRequired,
  });

  factory BadgeDTO.fromJson(Map<String, dynamic> json) {
    return BadgeDTO(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      imageUrl: (json['imageUrl'] ?? '') as String,
      minPointsRequired: (json['minPointsRequired'] ?? 0) as int,
    );
  }
}

class CitizenBadgeProfileDTO {
  final int points;
  final String currentLevelName;
  final double progressPercentage;
  final List<BadgeDTO> badges;

  CitizenBadgeProfileDTO({
    required this.points,
    required this.currentLevelName,
    required this.progressPercentage,
    required this.badges,
  });

  factory CitizenBadgeProfileDTO.fromJson(Map<String, dynamic> json) {
    final list = (json['badges'] as List?) ?? [];
    return CitizenBadgeProfileDTO(
      points: (json['points'] ?? 0) as int,
      currentLevelName: (json['currentLevelName'] ?? '') as String,
      progressPercentage: ((json['progressPercentage'] ?? 0) as num).toDouble(),
      badges: list.map((e) => BadgeDTO.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
class RegisterDraft {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirm;
  final String phoneNumber;
  final String roadNumber;
  final String roadName;
  final String city;
  final String postalCode;

  RegisterDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirm,
    required this.phoneNumber,
    required this.roadNumber,
    required this.roadName,
    required this.city,
    required this.postalCode,
  });

  String normalizedPostalCode() => postalCode.replaceAll(' ', '').toUpperCase();

  int parsedRoadNumber() => int.tryParse(roadNumber.trim()) ?? 0;

  Register toRegister() {
    return Register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password: password,
      passwordConfirm: confirm,
      phoneNumber: phoneNumber,
      roadNumber: parsedRoadNumber(),
      roadName: roadName.trim(),
      postalCode: normalizedPostalCode(),
      city: city.trim(),
    );
  }

  ValidationResult validate(S s) {
    if (firstName.trim().length < 2) {
      return ValidationResult('firstName', s.invalidFirstName);
    }
    if (lastName.trim().length < 2) {
      return ValidationResult('lastName', s.invalidLastName);
    }
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult('email', s.invalidEmail);
    }
    if (!passwordRegex.hasMatch(password)) {
      return ValidationResult('password', s.invalidPassword);
    }
    if (confirm != password) {
      return ValidationResult('confirm', s.passwordsDontMatch);
    }
    if (parsedRoadNumber() < 1) {
      return ValidationResult('roadNumber', s.invalidRoadNumber);
    }
    if (roadName.trim().length < 2) {
      return ValidationResult('roadName', s.invalidRoadName);
    }
    if (city.trim().length < 2) {
      return ValidationResult('city', s.invalidCity);
    }
    if (!postalRegex.hasMatch(normalizedPostalCode())) {
      return ValidationResult('postalCode', s.invalidPostalCode);
    }
    return ValidationResult.ok();
  }
}


@JsonSerializable()
class IncidentHistoryDTO {
  IncidentHistoryDTO(
    this.nomUtilisateur,
    this.roleUtilisateur,
    this.isAnonymous,
    this.interventionType,
    this.updatedAt,
    this.refusDescription,
    this.confirmationImgUrls,
    this.titreIncident,
    this.incidentId,
  );

  String? nomUtilisateur;
  String? roleUtilisateur;
  bool? isAnonymous;
  String? titreIncident;
  int? interventionType;
  int? incidentId;
  DateTime updatedAt;
  String? refusDescription;
  List<String>? confirmationImgUrls;

  factory IncidentHistoryDTO.fromJson(Map<String, dynamic> json) =>
      _$IncidentHistoryDTOFromJson(json);

  Map<String, dynamic> toJson() => _$IncidentHistoryDTOToJson(this);
}
