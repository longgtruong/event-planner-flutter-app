import 'package:app/db/database.dart';
import 'package:app/models/Party.dart';
import 'package:app/widgets/contact_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:app/models/ContactUser.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';

class PartyScreen extends StatefulWidget {
  Party party;
  PartyScreen({Key? key, required this.party}) : super(key: key);

  @override
  _PartyScreenState createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final _partyFormKey = GlobalKey<FormState>();
  final format = DateFormat("yyyy-MM-dd");

  String _title = "";
  String _description = "";
  DateTime? _startDate = DateTime.tryParse("");
  DateTime? _endDate = DateTime.tryParse("");

  List<Contact> contacts = [];
  List<ContactUser> participants = [];

  bool _edittingEvent = false;

  @override
  initState() {
    super.initState();
    getContacts();
    getParticipants();
  }

  getContacts() async {
    if (await Permission.contacts.isGranted) {
      List<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        this.contacts = contacts;
      });
    }
  }

  getParticipants() async {
    List<ContactUser> results =
        await EventDatabase.instance.getUsersOfEvents(widget.party.id!);
    setState(() {
      participants = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    String _formattedStartDate =
        DateFormat.yMMMMEEEEd().format(widget.party.startDate);
    String _formattedEndDate =
        DateFormat.yMMMMEEEEd().format(widget.party.endDate);

    sendInvites() async {
      String emailBody = '''
      Hello,
      We would like to invite you to $_title event ($_description). It will start on $_formattedStartDate and end $_formattedEndDate.
      Hope to you see you there!
      Kind regards,
      ''';
      List<String> _emails = participants.map((e) => e.email).toList();
      _emails.removeWhere((element) => element == '');
      if (_emails.isNotEmpty) {
        final mailToLink =
            Mailto(to: _emails, subject: "Invitation email", body: emailBody);
        await launch(mailToLink.toString());
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text("No participants to email."),
              );
            });
      }
    }

    saveEvent() async {
      if (_startDate != null &&
          _title != null &&
          _description != null &&
          _endDate != null) {
        Party party = new Party(
            id: widget.party.id,
            title: _title,
            description: _description,
            startDate: _startDate!,
            endDate: _endDate!);
        await EventDatabase.instance.updateEvent(party, widget.party.id!);
      }
      Navigator.pop(context, "event updated");
    }

    void _showDialogAndAddUsers(BuildContext context, Widget child) {
      showDialog<Contact>(context: context, builder: (context) => child)
          .then((Contact? value) async {
        if (value != null) {
          await EventDatabase.instance.addUserToParty(value, widget.party.id!);
          setState(() {
            participants.add(ContactUser.userFromContact(value));
          });
        }
      });
    }

    void _removeParticipant(ContactUser participant) async {
      setState(() {
        participants.remove(participant);
      });
      await EventDatabase.instance
          .removeUserFromEvent(participant.id!, widget.party.id!);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Event details"),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
        child: Column(
          children: [
            !_edittingEvent
                ? Container(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.party.title,
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                                onPressed: () => {
                                      setState(() {
                                        _edittingEvent = true;
                                        _title = widget.party.title;
                                        _description =
                                            widget.party.description.toString();
                                        _startDate = widget.party.startDate;
                                        _endDate = widget.party.endDate;
                                      })
                                    },
                                icon: Icon(Icons.edit))
                          ],
                        ),
                        SizedBox(height: 20.0),
                        Container(
                          alignment: Alignment.topLeft,
                          child: Text(widget.party.description.toString(),
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Container(
                            child: Text("Date",
                                style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold)),
                            alignment: Alignment.topLeft),
                        SizedBox(
                          height: 20.0,
                        ),
                        Row(
                          children: [
                            Text("From"),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(right: 40.0),
                                    child: Text(
                                        DateFormat.yMMMMEEEEd()
                                            .format(widget.party.startDate),
                                        style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey)))),
                          ],
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        Row(
                          children: [
                            Text("From"),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                                child: Container(
                                    margin: EdgeInsets.only(right: 40.0),
                                    child: Text(
                                        DateFormat.yMMMMEEEEd()
                                            .format(widget.party.endDate),
                                        style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey)))),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    child: Form(
                      child: Column(
                        children: [
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Title event required";
                              }
                              return null;
                            },
                            initialValue: widget.party.title,
                            onChanged: (value) {
                              _title = value;
                            },
                            decoration: InputDecoration(
                                hintText: "Title event",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                contentPadding: EdgeInsets.all(15.0)),
                          ),
                          SizedBox(height: 20.0),
                          TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Title event required";
                              }
                              return null;
                            },
                            initialValue: widget.party.description,
                            onChanged: (value) {
                              _description = value;
                            },
                            decoration: InputDecoration(
                                hintText: "Title event",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.0)),
                                contentPadding: EdgeInsets.all(15.0)),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          Row(
                            children: [
                              Text("From"),
                              SizedBox(
                                width: 10.0,
                              ),
                              Expanded(
                                child: Container(
                                    child: DateTimeField(
                                  format: format,
                                  initialValue: widget.party.startDate,
                                  onChanged: (value) {
                                    setState(() {
                                      _startDate = value;
                                    });
                                  },
                                  onShowPicker: (context, currentValue) {
                                    return showDatePicker(
                                        context: context,
                                        firstDate: DateTime.now(),
                                        initialDate:
                                            currentValue ?? DateTime.now(),
                                        lastDate: DateTime(2100));
                                  },
                                )),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text("To"),
                              SizedBox(
                                width: 10.0,
                              ),
                              Expanded(
                                child: Container(
                                    child: DateTimeField(
                                  format: format,
                                  initialValue: widget.party.endDate,
                                  onChanged: (value) {
                                    setState(() {
                                      _endDate = value;
                                    });
                                  },
                                  onShowPicker: (context, currentValue) {
                                    return showDatePicker(
                                        context: context,
                                        firstDate: DateTime.now(),
                                        initialDate:
                                            currentValue ?? DateTime.now(),
                                        lastDate: DateTime(2100));
                                  },
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            SizedBox(
              height: 30.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Invite friends",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                IconButton(
                    onPressed: () => {
                          _showDialogAndAddUsers(
                              context, AddParticipantDialog(contacts: contacts))
                        },
                    icon: Icon(Icons.add))
              ],
            ),
            SizedBox(height: 25.0),
            Expanded(
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: participants.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: EdgeInsets.only(left: 10.0),
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              "assets/images/default_profile.png",
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            children: [
                              Container(
                                child:
                                    Text(participants[index].name.toString()),
                              ),
                              IconButton(
                                  onPressed: () =>
                                      {_removeParticipant(participants[index])},
                                  icon: Icon(Icons.delete))
                            ],
                          )
                        ],
                      ),
                    );
                  }),
            ),
            ElevatedButton(
                onPressed: () => {sendInvites()},
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Center(child: Text("Send invites")),
                  ),
                )),
            SizedBox(height: 15.0),
            ElevatedButton(
                onPressed: () => {saveEvent()},
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Center(child: Text("Submit")),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
