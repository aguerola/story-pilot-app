import 'package:equatable/equatable.dart';

class CastMember extends Equatable {
  const CastMember({
    required this.id,
    required this.name,
    required this.characterName,
    this.profileUrl,
    required this.billingOrder,
  });

  final int id;
  final String name;
  final String characterName;
  final String? profileUrl;
  final int billingOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterName': characterName,
        'profileUrl': profileUrl,
        'billingOrder': billingOrder,
      };

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        id: json['id'] as int,
        name: json['name'] as String,
        characterName: json['characterName'] as String,
        profileUrl: json['profileUrl'] as String?,
        billingOrder: json['billingOrder'] as int,
      );

  @override
  List<Object?> get props => [id, name, characterName, profileUrl, billingOrder];
}
