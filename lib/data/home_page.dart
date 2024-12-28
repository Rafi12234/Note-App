import 'package:database/data/local/db_helper.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  List<Map<String, dynamic>> allNotes = [];
  DBHelper? dbRef;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDbAndFetchNotes();
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _initializeDbAndFetchNotes() async {
    dbRef = DBHelper.getIstance;
    await getNotes();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> getNotes() async {
    if (dbRef != null) {
      allNotes = await dbRef!.getAllNotes();
      setState(() {});
    } else {
      print("Error: dbRef is null");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allNotes.isNotEmpty
          ? ListView.builder(
          itemCount: allNotes.length,
          itemBuilder: (_, index) {
            return ListTile(
              leading: Text('${index+1}'),
              title: Text(allNotes[index][DBHelper.COLUMN_NOTE_TITLE]),
              subtitle: Text(allNotes[index][DBHelper.COLUMN_NOTE_DESC]),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        titleController.text = allNotes[index][DBHelper.COLUMN_NOTE_TITLE];
                        descController.text = allNotes[index][DBHelper.COLUMN_NOTE_DESC];
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => getBottomSheet(
                            isUpdate: true,
                            sno: allNotes[index][DBHelper.COLUMN_NOTE_SNO],
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (dbRef != null) {
                          int snoToDelete = allNotes[index][DBHelper.COLUMN_NOTE_SNO];
                          bool deleted = await dbRef!.deleteNotes(sno: snoToDelete);
                          if (deleted) {
                            getNotes();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error deleting note.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          })
          : const Center(child: Text("No Notes Yet")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          titleController.clear();
          descController.clear();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => getBottomSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Container getBottomSheet({bool isUpdate = false, int sno = 0}) {
    return Container(
      height: 500,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isUpdate ? "Update Note" : "Add Note",
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 21),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Enter Title",
                label: Text("Title"),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 21),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Enter Description",
                label: Text("Description"),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final title = titleController.text;
                      final desc = descController.text;
                      if (title.isNotEmpty && desc.isNotEmpty) {
                        if (dbRef != null) {
                          final check = isUpdate
                              ? await dbRef!.updateNotes(mTitle: title, mDesc: desc, sno: sno)
                              : await dbRef!.addNote(mTitle: title, mDesc: desc);
                          if (check) {
                            getNotes();
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the blanks'),));
                      }
                      titleController.clear();
                      descController.clear();

                      Navigator.pop(context);
                    },
                    child: Text(isUpdate ? "Update Note" : "Add Note"),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      titleController.clear();
                      descController.clear();
                    },
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}