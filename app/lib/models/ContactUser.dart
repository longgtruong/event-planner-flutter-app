import 'package:contacts_service/contacts_service.dart';

class ContactUser {
  final int? id;
  final String name;
  final String email;

  ContactUser({this.id, required this.name, required this.email});

  static ContactUser parseJson(Map<String, Object?> json) => ContactUser(
      id: json['id'] as int?,
      name: json['name'].toString(),
      email: json['email'].toString());

  static Map<String, Object?> toJson(ContactUser user, int? event_id) => ({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'event_id': event_id
      });

  static ContactUser userFromContact(Contact contact) => ContactUser(
      name: contact.givenName.toString(),
      email: contact.emails!.map((e) => e.value).join(","));
}
