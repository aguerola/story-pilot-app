import 'package:equatable/equatable.dart';

class CrewMember extends Equatable {
  const CrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    this.profileUrl,
  });

  final int id;
  final String name;
  final String job;
  final String department;
  final String? profileUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'job': job,
        'department': department,
        'profileUrl': profileUrl,
      };

  factory CrewMember.fromJson(Map<String, dynamic> json) => CrewMember(
        id: json['id'] as int,
        name: json['name'] as String,
        job: json['job'] as String,
        department: json['department'] as String,
        profileUrl: json['profileUrl'] as String?,
      );

  @override
  List<Object?> get props => [id, name, job, department, profileUrl];
}
