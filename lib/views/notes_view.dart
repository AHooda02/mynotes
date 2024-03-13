import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/auth_servcie.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import '../constants/routes.dart';
import '../enums/menu_action.dart';
import '../services/auth/bloc/auth_bloc.dart';
import '../services/cloud/cloud_note.dart';
import '../utilities/dialogs/logout_dialog.dart';
import 'notes/notes_list_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  late final FirebaseCloudStorage _notesService;
  String get userId => AuthService.firebase().currentUser!.id;

  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 63, 62, 62),
        appBar: AppBar(
            shadowColor: null,
            backgroundColor: const Color.fromARGB(255, 63, 62, 62),
            title: const Text(
              'NOTES',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
                  },
                  color: Colors.black,
                  icon: const Icon(Icons.add)),
              PopupMenuButton<MenuAction>(
                color: Colors.black,
                onSelected: (value) async {
                  switch (value) {
                    case MenuAction.logout:
                      final shouldLogout = await showLogOutDialog(context);
                      if (shouldLogout) {
                        context.read<AuthBloc>().add(
                              const AuthEventLogOut(),
                            );
                      }
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem<MenuAction>(
                      value: MenuAction.logout,
                      child: Center(
                        child: Text(
                          'Log Out',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.yellow),
                        ),
                      ),
                    )
                  ];
                },
              )
            ]),
        body: StreamBuilder(
          stream: _notesService.allNotes(ownerUserId: userId),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.active:
                if (snapshot.data != null) {
                  final allNotes = snapshot.data as Iterable<CloudNote>;
                  return NotesListView(
                    notes: allNotes,
                    onDeleteNote: (note) async {
                      await _notesService.deleteNote(
                          documentId: note.documentId);
                    },
                    onTap: (note) {
                      Navigator.of(context).pushNamed(
                        createOrUpdateNoteRoute,
                        arguments: note,
                      );
                    },
                  );
                } else {
                  return CircularProgressIndicator();
                }
              default:
                return const CircularProgressIndicator();
            }
          },
        ));
  }
}
