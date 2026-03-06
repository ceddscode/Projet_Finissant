// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequeteProblemeAvecPhotos _$RequeteProblemeAvecPhotosFromJson(
  Map<String, dynamic> json,
) => RequeteProblemeAvecPhotos(
  json['title'] as String,
  json['location'] as String,
  json['description'] as String,
  (json['category'] as num).toInt(),
  (json['imagesUrl'] as List<dynamic>).map((e) => e as String).toList(),
  (json['latitude'] as num).toDouble(),
  (json['longitude'] as num).toDouble(),
  json['quartier'] as String?,
);

Map<String, dynamic> _$RequeteProblemeAvecPhotosToJson(
  RequeteProblemeAvecPhotos instance,
) => <String, dynamic>{
  'title': instance.title,
  'location': instance.location,
  'description': instance.description,
  'category': instance.category,
  'imagesUrl': instance.imagesUrl,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'quartier': instance.quartier,
};

RequeteConfirmIncident _$RequeteConfirmIncidentFromJson(
  Map<String, dynamic> json,
) => RequeteConfirmIncident(
  (json['incidentId'] as num).toInt(),
  json['description'] as String,
  (json['imagesUrl'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$RequeteConfirmIncidentToJson(
  RequeteConfirmIncident instance,
) => <String, dynamic>{
  'incidentId': instance.incidentId,
  'description': instance.description,
  'imagesUrl': instance.imagesUrl,
};

Incident _$IncidentFromJson(Map<String, dynamic> json) => Incident(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  isLiked: json['isLiked'] as bool? ?? false,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  imagesUrl: (json['imagesUrl'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  location: json['location'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  category: (json['category'] as num).toInt(),
  status: (json['status'] as num).toInt(),
  assignedAt: json['assignedAt'] == null
      ? null
      : DateTime.parse(json['assignedAt'] as String),
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  distance: (json['distance'] as num?)?.toInt(),
  quartier: json['quartier'] as String?,
);

Map<String, dynamic> _$IncidentToJson(Incident instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'imagesUrl': instance.imagesUrl,
  'location': instance.location,
  'createdAt': instance.createdAt.toIso8601String(),
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'distance': instance.distance,
  'quartier': instance.quartier,
  'isLiked': instance.isLiked,
  'likeCount': instance.likeCount,
  'category': instance.category,
  'status': instance.status,
  'assignedAt': instance.assignedAt?.toIso8601String(),
};

Register _$RegisterFromJson(Map<String, dynamic> json) => Register(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  passwordConfirm: json['passwordConfirm'] as String,
  phoneNumber: json['phoneNumber'] as String,
  roadNumber: (json['roadNumber'] as num).toInt(),
  roadName: json['roadName'] as String,
  postalCode: json['postalCode'] as String,
  city: json['city'] as String,
);

Map<String, dynamic> _$RegisterToJson(Register instance) => <String, dynamic>{
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'password': instance.password,
  'passwordConfirm': instance.passwordConfirm,
  'phoneNumber': instance.phoneNumber,
  'roadNumber': instance.roadNumber,
  'roadName': instance.roadName,
  'postalCode': instance.postalCode,
  'city': instance.city,
};

CommentDTO _$CommentDTOFromJson(Map<String, dynamic> json) => CommentDTO(
  id: (json['id'] as num).toInt(),
  message: json['message'] as String,
  likeCount: (json['likeCount'] as num).toInt(),
  citizenName: json['citizenName'] as String,
  isLiked: json['isLiked'] as bool,
  repliesCount: (json['repliesCount'] as num).toInt(),
  isOwner: json['isOwner'] as bool,
  isReported: json['isReported'] as bool,
);

Map<String, dynamic> _$CommentDTOToJson(CommentDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'likeCount': instance.likeCount,
      'citizenName': instance.citizenName,
      'isLiked': instance.isLiked,
      'repliesCount': instance.repliesCount,
      'isOwner': instance.isOwner,
      'isReported': instance.isReported,
    };

Login _$LoginFromJson(Map<String, dynamic> json) => Login(
  username: json['username'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginToJson(Login instance) => <String, dynamic>{
  'username': instance.username,
  'password': instance.password,
};

IncidentDetailsDTO _$IncidentDetailsDTOFromJson(Map<String, dynamic> json) =>
    IncidentDetailsDTO(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      status: (json['status'] as num).toInt(),
      imagesUrl: (json['imagesUrl'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: (json['category'] as num).toInt(),
      isLiked: json['isLiked'] as bool? ?? false,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      citizenId: json['citizenId'] as String?,
      confirmationDescription: json['confirmationDescription'] as String?,
      confirmationImagesUrl: (json['confirmationImagesUrl'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$IncidentDetailsDTOToJson(IncidentDetailsDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'createdDate': instance.createdDate.toIso8601String(),
      'imagesUrl': instance.imagesUrl,
      'citizenId': instance.citizenId,
      'confirmationDescription': instance.confirmationDescription,
      'confirmationImagesUrl': instance.confirmationImagesUrl,
      'isLiked': instance.isLiked,
      'likeCount': instance.likeCount,
      'status': instance.status,
      'category': instance.category,
    };

IncidentHistoryDTO _$IncidentHistoryDTOFromJson(Map<String, dynamic> json) =>
    IncidentHistoryDTO(
      json['nomUtilisateur'] as String?,
      json['roleUtilisateur'] as String?,
      json['isAnonymous'] as bool?,
      (json['interventionType'] as num?)?.toInt(),
      DateTime.parse(json['updatedAt'] as String),
      json['refusDescription'] as String?,
      (json['confirmationImgUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      json['titreIncident'] as String?,
      (json['incidentId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$IncidentHistoryDTOToJson(IncidentHistoryDTO instance) =>
    <String, dynamic>{
      'nomUtilisateur': instance.nomUtilisateur,
      'roleUtilisateur': instance.roleUtilisateur,
      'isAnonymous': instance.isAnonymous,
      'titreIncident': instance.titreIncident,
      'interventionType': instance.interventionType,
      'incidentId': instance.incidentId,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'refusDescription': instance.refusDescription,
      'confirmationImgUrls': instance.confirmationImgUrls,
    };
