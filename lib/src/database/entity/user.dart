import 'entity.dart'; // Assuming you have a base Entity class

class User extends Entity<User> {
  User({
    required super.id,
    required this.username,
    required this.description,
    required this.password,
    required this.isAdministrator,
    required super.createdDate,
    required super.modifiedDate,
    this.securityToken,
    this.tokenExpiryDate,
    this.tokenLivesFor,
    this.emailAddress,
  }) : super();

  User.forInsert({
    required this.username,
    required this.description,
    required this.password,
    required this.isAdministrator,
    this.securityToken,
    this.tokenExpiryDate,
    this.tokenLivesFor,
    this.emailAddress,
  }) : super.forInsert();

  User.forUpdate({
    required super.entity,
    required this.username,
    required this.description,
    required this.password,
    required this.isAdministrator,
    this.securityToken,
    this.tokenExpiryDate,
    this.tokenLivesFor,
    this.emailAddress,
  }) : super.forUpdate();

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int,
        username: map['username'] as String,
        description: map['description'] as String,
        password: map['password'] as String,
        isAdministrator: map['is_administrator'] == 1,
        securityToken: map['security_token'] as String?,
        tokenExpiryDate: map['token_expiry_date'] != null
            ? DateTime.parse(map['token_expiry_date'] as String)
            : null,
        tokenLivesFor: map['token_lives_for'] != null
            ? Duration(seconds: map['token_lives_for'] as int)
            : null,
        emailAddress: map['email_address'] as String?,
        createdDate: DateTime.parse(map['created_date'] as String),
        modifiedDate: DateTime.parse(map['modified_date'] as String),
      );

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'description': description,
        'password': password,
        'is_administrator': isAdministrator ? 1 : 0,
        'security_token': securityToken,
        'token_expiry_date': tokenExpiryDate?.toIso8601String(),
        'token_lives_for': tokenLivesFor?.inSeconds,
        'email_address': emailAddress,
        'created_date': createdDate.toIso8601String(),
        'modified_date': modifiedDate.toIso8601String(),
      };

  String username;
  String description;
  String password;
  bool isAdministrator;
  String? securityToken;
  DateTime? tokenExpiryDate;
  Duration? tokenLivesFor;
  String? emailAddress;
}
