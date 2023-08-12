import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizapplication/ppdt/ppdtscreen.dart';


class PPDT extends StatefulWidget {
  @override
  _PPDTState createState() => _PPDTState();
}

class _PPDTState extends State<PPDT> {
  List<DocumentSnapshot> questionSets = [];
  late User user;

  @override
  void initState() {
    super.initState();
    fetchQuestionSets();
    user = FirebaseAuth.instance.currentUser!;
  }

  Future<void> fetchQuestionSets() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('ppdt').get();

    setState(() {
      questionSets = snapshot.docs;
    });
  }

  Future<void> deleteQuestionSet(String setId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('ppdt').doc(setId).delete();

    fetchQuestionSets();
  }

  Future<void> createNewDocument() async {
    final firestore = FirebaseFirestore.instance;
    final newDocumentRef = firestore.collection('ppdt').doc();

    await newDocumentRef.set({
      'imageUrl': '',
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDocumentScreen(documentId: newDocumentRef.id),
      ),
    );
  }

  bool isAdmin() {
    return user.uid == 'r0Y23cmSAVWdPTeqqZ13u7YRRuq2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PPDT IMAGES SET'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: questionSets.length,
        itemBuilder: (context, index) {
          final questionSet = questionSets[index];
          final setId = questionSet.id;

          return Container(
            padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 5.0),
            child: Card(
              color: Colors.green[100],
              child: ListTile(
                title: Text('Question set ${index + 1}',style: TextStyle(fontSize: 18.0),textAlign: TextAlign.center,),
                trailing: isAdmin()
                    ? IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Set'),
                        content: Text('Are you sure you want to delete this set?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Delete the set
                              deleteQuestionSet(setId);
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('Yes'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('No'),
                          ),
                        ],
                      ),
                    );
                  },
                )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PpdtScreen(
                        setId: setId,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: isAdmin()
          ? FloatingActionButton(
        onPressed: () {
          // Create a new document in Firebase and navigate to the edit screen
          createNewDocument();
        },
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}


class EditDocumentScreen extends StatefulWidget {
  final String documentId;

  const EditDocumentScreen({required this.documentId});

  @override
  _EditDocumentScreenState createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  TextEditingController imageUrlController = TextEditingController();

  @override
  void dispose() {
    imageUrlController.dispose();
    super.dispose();
  }

  void saveDocument() async {
    final firestore = FirebaseFirestore.instance;
    final documentRef = firestore.collection('ppdt').doc(widget.documentId);

    await documentRef.update({
      'imageUrl': imageUrlController.text,
    });

    imageUrlController.clear(); // Clear the text field
  }


  void submitDocument() async {
    final firestore = FirebaseFirestore.instance;
    final documentRef = firestore.collection('ppdt').doc(widget.documentId);

    // Get the existing image URLs stored in the document
    final snapshot = await documentRef.get();
    List<String> imageUrls = [];
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      imageUrls = List<String>.from(data['imageUrls'] ?? []);
    }

    // Add the new image URL to the list
    imageUrls.add(imageUrlController.text);

    // Update the document with the updated list of image URLs
    await documentRef.update({
      'imageUrls': imageUrls,
    });

    // Clear the text field
    imageUrlController.clear();

    // Navigate to the admin home screen after submitting
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Document'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(labelText: 'Image URL'),
              enabled: true,
              autofocus: true,
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: saveDocument,
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: submitDocument,
                  child: Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

