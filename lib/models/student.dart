class Student {
  final int id;
  final String registrationNumber;
  final String firstName;
  final String lastName;
  final String email;
  final bool isActive;
  final int? collegeId;
  final String? collegeName;

  Student({
    required this.id,
    required this.registrationNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isActive,
    this.collegeId,
    this.collegeName,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        registrationNumber: json['registration_number'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'] ?? '',
        isActive: json['is_active'] ?? true,
        collegeId: json['college_id'],
        collegeName: json['college_name'],
      );

  Student copyWith({String? collegeName}) => Student(
        id: id,
        registrationNumber: registrationNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        isActive: isActive,
        collegeId: collegeId,
        collegeName: collegeName ?? this.collegeName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'registration_number': registrationNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'is_active': isActive,
        'college_id': collegeId,
        'college_name': collegeName,
      };

  String get fullName => '$firstName $lastName';
}
