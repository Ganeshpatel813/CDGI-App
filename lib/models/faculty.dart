class Faculty {
  final int id;
  final String employeeId;
  final String name;
  final String email;
  final String? phone;
  final String department;
  final String designation;
  final String? faceImagePath;
  final bool hasFaceRegistered;
  final String role;
  final String? createdAt;
  final bool? isActive;

  const Faculty({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    this.phone,
    required this.department,
    required this.designation,
    this.faceImagePath,
    required this.hasFaceRegistered,
    required this.role,
    this.createdAt,
    this.isActive,
  });

  bool get isAdmin => role == 'admin';

  factory Faculty.fromJson(Map<String, dynamic> j) => Faculty(
        id:               (j['id'] as num?)?.toInt() ?? 0,
        employeeId:       (j['employeeId'] as String?) ?? '',
        name:             (j['name']       as String?) ?? '',
        email:            (j['email']      as String?) ?? '',
        phone:            j['phone']       as String?,
        department:       (j['department'] as String?) ?? '',
        designation:      (j['designation'] as String?) ?? '',
        faceImagePath:    j['faceImagePath'] as String?,
        hasFaceRegistered: j['hasFaceRegistered'] as bool? ?? false,
        role:             (j['role'] as String?) ?? 'faculty',
        createdAt:        j['createdAt'] as String?,
        isActive: j['is_active'] == null
            ? null
            : (j['is_active'] == 1 || j['is_active'] == true),
      );

  Map<String, dynamic> toJson() => {
        'id':               id,
        'employeeId':       employeeId,
        'name':             name,
        'email':            email,
        'phone':            phone,
        'department':       department,
        'designation':      designation,
        'faceImagePath':    faceImagePath,
        'hasFaceRegistered': hasFaceRegistered,
        'role':             role,
        'createdAt':        createdAt,
        'is_active':        isActive,
      };
}
