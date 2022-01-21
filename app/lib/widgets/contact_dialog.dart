import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';

class AddParticipantDialog extends StatelessWidget {
  List<Contact> contacts = [];
  AddParticipantDialog({Key? key, required this.contacts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        title: Text("Add from contact list"),
        content: SizedBox(
          height: 300.0,
          width: 600.0,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () => {Navigator.pop(context, contacts[index])},
                  child: Card(
                    child: ListTile(
                      title: Text(contacts[index].givenName.toString()),
                      subtitle: Text(contacts[index]
                          .emails!
                          .map((e) => e.value)
                          .join(",")),
                    ),
                  ),
                );
              }),
        ));
  }
}
