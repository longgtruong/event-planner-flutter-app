import 'package:app/db/database.dart';
import 'package:app/models/Party.dart';
import 'package:app/models/ContactUser.dart';
import 'package:app/screens/party_screen.dart';
import 'package:app/widgets/contact_dialog.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/add_party.dart';
import 'package:image_stack/image_stack.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Contact> contacts = [];
  List<Party> parties = [];
  bool isLoadingParties = false;

  @override
  initState() {
    super.initState();
    refreshEvents();
    requestPermissions();
    getContacts();
  }

  requestPermissions() async {
    await Permission.contacts.request();
    await Permission.calendar.request();
  }

  getContacts() async {
    if (await Permission.contacts.isGranted) {
      List<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        this.contacts = contacts;
      });
    }
  }

  showDialogAndAddUsers(int party_id) {
    showDialog<Contact>(
        context: context,
        builder: (BuildContext context) {
          return AddParticipantDialog(contacts: contacts);
        }).then((Contact? value) => addUsersToParty(value!, party_id));
  }

  Future<int> getUsersCount(Party party) async {
    List<ContactUser> users =
        await EventDatabase.instance.getUsersOfEvents(party.id!.toInt());
    return users.length;
  }

  addUsersToParty(Contact user, int id) async {
    await EventDatabase.instance.addUserToParty(user, id);
    await refreshEvents();
  }

  addNewEvent(BuildContext context) async {
    final received = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => AddPartyScreen()));
    if (received['title'] == "event submitted") {
      if (received['users'].length > 0) {
        received['users'].map((user) => addUsersToParty(user, received['id']));
      }
      refreshEvents();
    }
  }

  viewEvent(BuildContext context, Party party) async {
    String received = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PartyScreen(
                  party: party,
                )));
    if (received == "event updated") {
      refreshEvents();
    }
  }

  refreshEvents() async {
    setState(() {
      isLoadingParties = true;
    });
    parties = await EventDatabase.instance.getAllEvents();
    setState(() {
      isLoadingParties = false;
    });
  }

  deleteEvent(int id) async {
    await EventDatabase.instance.deleteEvent(id);
    refreshEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome!",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => {addNewEvent(context)},
                icon: Icon(Icons.add_outlined),
                iconSize: 30.0,
              )
            ],
          ),
        ),
        Container(
            margin: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
            child: Row(
              children: [
                Text(
                  "Upcoming parties",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            )),
        !isLoadingParties
            ? Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
                  child: ListView.builder(
                      itemCount: parties.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () => {viewEvent(context, parties[index])},
                          child: Card(
                            child: Column(
                              children: [
                                ListTile(
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        {deleteEvent(parties[index].id!)},
                                  ),
                                  leading: Icon(Icons.event,
                                      color: Colors.blueAccent),
                                  title: Text(parties[index].title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0)),
                                  subtitle: Text(DateFormat.yMMMMEEEEd()
                                      .format(parties[index].startDate)),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                      left: 70.0, bottom: 10.0, right: 50.0),
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                      parties[index].description.toString(),
                                      style: TextStyle(color: Colors.grey),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Container(
                                  margin: EdgeInsets.only(
                                      left: 70.0, bottom: 20.0, right: 50.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      FutureBuilder<int>(
                                          future: getUsersCount(parties[index]),
                                          initialData: 0,
                                          builder: (context, snapshot) {
                                            return ImageStack(
                                              imageList: List<String>.generate(
                                                snapshot.data!,
                                                (i) =>
                                                    "https://www.sketchappsources.com/resources/source-image/profile-illustration-gunaldi-yunus.png",
                                              ),
                                              imageBorderColor: Colors.white,
                                              extraCountTextStyle: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                              totalCount: snapshot.data!,
                                              imageCount: 4,
                                              imageRadius: 25,
                                            );
                                          }),
                                      ElevatedButton.icon(
                                        onPressed: () => {
                                          showDialogAndAddUsers(
                                              parties[index].id!)
                                        },
                                        icon: Icon(Icons.add),
                                        label: Text("Invite friends"),
                                        style: ElevatedButton.styleFrom(
                                            shape: new RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20))),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      }),
                ),
              )
            : Container(
                margin: EdgeInsets.only(top: 80.0),
                child: CircularProgressIndicator())
      ],
    );
  }
}
