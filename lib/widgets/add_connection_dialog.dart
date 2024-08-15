import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/connection_manager.dart';
import '../services/ssh_manager.dart';
import 'dart:io';

void showAddConnectionDialog(BuildContext context, Function refreshCallback) {
  final formKey = GlobalKey<FormState>();
  String? name;
  String? username;
  String? hostId;
  String? selectedFilePath;
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: true, // Allow dismissing by tapping outside
    builder: (BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      return WillPopScope(
        onWillPop: () async {
          // Close the dialog completely when back button is pressed
          Navigator.of(context).pop();
          return false;
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 400,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Add Connection',
                        style: TextStyle(color: colorScheme.onSecondary, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Body
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Connection Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a Connection Name' : null,
                                  onSaved: (value) => name = value,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a Username' : null,
                                  onSaved: (value) => username = value,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Host ID',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Please enter a Host ID' : null,
                                  onSaved: (value) => hostId = value,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: isLoading ? null : () async {
                                    FilePickerResult? result = await FilePicker.platform.pickFiles();
                                    if (result != null) {
                                      setState(() {
                                        selectedFilePath = result.files.single.path;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(selectedFilePath != null ? 'File: ${selectedFilePath!.split('/').last}' : 'Upload Private Key File'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary, // Set the desired color here
                            ),
                          )
                          : ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() && selectedFilePath != null) {
                            setState(() {
                              isLoading = true;
                            });
                            formKey.currentState!.save();
                            final privateKeyContent = await File(selectedFilePath!).readAsString();

                            final newConnection = SSHConnection(
                              name: name!,
                              username: username!,
                              hostId: hostId!,
                              privateKeyContent: privateKeyContent,
                            );

                            // Test connection
                            final sshManager = SSHManager.getInstance();
                            try {
                              //first check if host id is already present
                              final conman= await ConnectionManager.getInstance();
                              if(await conman.isHostIdExists(hostId!))
                                {
                                  throw Exception('The host id already exists check existing connections');
                                }
                              final isConnected = await sshManager.testConnection(newConnection);

                              if (isConnected) {
                                await ConnectionManager.getInstance().addConnection(newConnection);
                                Navigator.of(context).pop();
                                refreshCallback();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Connection added successfully')),
                                );
                              } else {
                                throw Exception('Connection test failed check you data properly');
                              }
                            } catch (e) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.onSecondary,
                          foregroundColor: colorScheme.secondary,
                        ),
                        child: const Text('Add Connection'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}