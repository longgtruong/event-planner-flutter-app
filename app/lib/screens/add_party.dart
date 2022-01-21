import 'package:app/db/database.dart';
import 'package:app/models/Party.dart';
import 'package:app/widgets/contact_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({Key? key}) : super(key: key);

  @override
  _AddPartyScreenState createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _addPartyFormKey = GlobalKey<FormState>();
  final format = DateFormat("yyyy-MM-dd");
  List<Contact> users = [];
  List<Contact> contacts = [];

  String _title = "";
  String _description = "";
  DateTime? _startDate = DateTime.tryParse("");
  DateTime? _endDate = DateTime.tryParse("");

  @override
  initState() {
    super.initState();
    getContacts();
  }

  getContacts() async {
    if (await Permission.contacts.isGranted) {
      List<Contact> contacts = await ContactsService.getContacts();
      setState(() {
        this.contacts = contacts;
      });
    }
  }

  void _showDialogAndAddUsers(BuildContext context, Widget child) async {
    showDialog<Contact>(context: context, builder: (context) => child)
        .then((Contact? value) {
      if (value != null) {
        setState(() {
          users.add(value);
        });
      }
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      users.removeAt(index);
    });
  }

  void _createEvent() async {
    if (_addPartyFormKey.currentState!.validate()) {
      Party party = new Party(
          title: _title,
          description: _description,
          startDate: _startDate!,
          endDate: _endDate!);
      final id = await EventDatabase.instance.create(party);
      Event event = new Event(
          title: _title,
          description: _description,
          startDate: _startDate!,
          endDate: _endDate!);
      Add2Calendar.addEvent2Cal(event);
      Navigator.pop(
          context, {"title": "event submitted", "users": users, "id": id});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context, "add event cancelled");
          },
        ),
        title: Text("New event"),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _createEvent(),
        child: Container(
            margin: EdgeInsets.only(left: 30.0),
            width: MediaQuery.of(context).size.width,
            height: 50.0,
            decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(15.0)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text("Create event",
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            )),
      ),
      body: Container(
          margin: EdgeInsets.symmetric(vertical: 30.0, horizontal: 30.0),
          child: Form(
            key: _addPartyFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  onChanged: (value) => {
                    this.setState(() {
                      _title = value;
                    })
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Title event required";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      hintText: "Title event",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      contentPadding: EdgeInsets.all(15.0)),
                ),
                SizedBox(height: 20.0),
                Container(
                    child: TextFormField(
                  onChanged: (value) {
                    this.setState(() {
                      _description = value;
                    });
                  },
                  decoration: InputDecoration(
                      hintText: "Description",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      contentPadding: EdgeInsets.all(15.0)),
                )),
                SizedBox(height: 30.0),
                Container(
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.only(left: 5.0),
                  child: Text(
                    "Date",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                SizedBox(height: 30.0),
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text(
                        "From",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    DateTimeField(
                      format: format,
                      validator: (value) {
                        if (value == null) {
                          return "Start date required";
                        }
                        if (_endDate != null) {
                          if (value.isAfter(_endDate!)) {
                            return "Start date must be before end date";
                          }
                        }
                        return null;
                      },
                      onChanged: (value) {
                        this.setState(() {
                          _startDate = value;
                        });
                      },
                      onShowPicker: (context, currentValue) {
                        return showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            initialDate: currentValue ?? DateTime.now(),
                            lastDate: DateTime(2100));
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30.0),
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text(
                        "To",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    DateTimeField(
                      format: format,
                      validator: (value) {
                        if (value != null) {
                          if (value.isBefore(_startDate!)) {
                            return "End date must be after start date";
                          }
                        }
                      },
                      onChanged: (value) {
                        this.setState(() {
                          _endDate = value;
                        });
                      },
                      onShowPicker: (context, currentValue) {
                        return showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            initialDate: currentValue ?? DateTime.now(),
                            lastDate: DateTime(2100));
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left: 5.0),
                      child: Text(
                        "Invite friends",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    IconButton(
                        onPressed: () => {
                              _showDialogAndAddUsers(context,
                                  AddParticipantDialog(contacts: contacts))
                            },
                        icon: Icon(Icons.add))
                  ],
                ),
                SizedBox(height: 30.0),
                Expanded(
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
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
                                        Text(users[index].givenName.toString()),
                                  ),
                                  IconButton(
                                      onPressed: () =>
                                          {_removeParticipant(index)},
                                      icon: Icon(Icons.delete))
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                )
              ],
            ),
          )),
    );
  }
}
