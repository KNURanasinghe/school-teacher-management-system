import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import 'package:teacher_management_system/main.dart';

class AllTeachersScreen extends StatefulWidget {
  const AllTeachersScreen({super.key});

  @override
  _AllTeachersScreenState createState() => _AllTeachersScreenState();
}

class _AllTeachersScreenState extends State<AllTeachersScreen> {
  List<dynamic> _allTeachers = [];
  bool _isLoading = true;
  bool _downloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchAllTeachers();
  }

  Future<void> _fetchAllTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:9000/api/teachers/search'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allTeachers = data['data'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to fetch teachers');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _downloadAllTeachersPdf() async {
    if (_downloadingPdf) return;

    setState(() {
      _downloadingPdf = true;
    });

    try {
      // Check for storage permission
      if (!await _checkPermission()) {
        setState(() {
          _downloadingPdf = false;
        });
        _showErrorSnackBar('Storage permission denied');
        return;
      }

      // Show download starting notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading All Teachers PDF...')),
      );

      // Download URL for all teachers PDF
      final downloadUrl = 'http://145.223.21.62:9000/api/teacher/all/pdf';
      print('Requesting PDF from: $downloadUrl');

      // Try to use the standard Download directory first
      Directory? saveDir;
      String dirName = "TeacherPDFs";

      if (Platform.isAndroid) {
        try {
          // Try standard Downloads folder first (most accessible)
          saveDir = Directory('/storage/emulated/0/Download/$dirName');
          if (!await saveDir.exists()) {
            await saveDir.create(recursive: true);
          }
        } catch (e) {
          print('Could not use Downloads directory: $e');

          // Fall back to external storage
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            saveDir = Directory('${externalDir.path}/$dirName');
            if (!await saveDir.exists()) {
              await saveDir.create(recursive: true);
            }
          }
        }
      } else {
        // For iOS, use documents directory
        final docsDir = await getApplicationDocumentsDirectory();
        saveDir = Directory('${docsDir.path}/$dirName');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      }

      if (saveDir == null) {
        _showErrorSnackBar('Could not create download directory');
        setState(() {
          _downloadingPdf = false;
        });
        return;
      }

      // Create a filename with the current date
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'All_Teachers_$dateStr.pdf';
      final filePath = '${saveDir.path}/$fileName';

      print('Download URL: $downloadUrl');
      print('Save directory: ${saveDir.path}');
      print('File will be saved as: $filePath');

      // Direct HTTP download with better error handling
      try {
        final response = await http.get(Uri.parse(downloadUrl), headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        }).timeout(const Duration(seconds: 60)); // Add timeout

        print('Response status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Verify the response is actually a PDF
          if (response.headers['content-type']?.contains('application/pdf') ==
                  true ||
              response.bodyBytes.length > 1000) {
            // Basic check if it's a substantial file

            // Save the file
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);

            // Show success with file location
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF saved to $dirName folder in Downloads'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OPEN',
                  onPressed: () async {
                    try {
                      final result = await OpenFile.open(filePath);
                      if (result.type != ResultType.done) {
                        _showErrorSnackBar(
                            'Could not open PDF: ${result.message}');
                      }
                    } catch (e) {
                      _showErrorSnackBar('Error opening file: $e');
                    }
                  },
                ),
              ),
            );
          } else {
            // Response isn't a PDF
            print(
                'Response is not a PDF. Content-Type: ${response.headers['content-type']}');
            print(
                'Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
            _showErrorSnackBar(
                'Server didn\'t return a PDF. Check server logs.');
          }
        } else if (response.statusCode == 404) {
          // Handle 404 specifically
          print('404 Error. Response body: ${response.body}');
          _showErrorSnackBar('No teachers found to generate PDF');
        } else {
          // Handle other status codes
          print(
              'HTTP Error ${response.statusCode}. Response body: ${response.body}');
          _showErrorSnackBar(
              'Failed to download PDF: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Download error: $e');
        _showErrorSnackBar('Error downloading PDF: $e');
      }
    } catch (e) {
      print('Download error: $e');
      _showErrorSnackBar('Error downloading PDF: $e');
    } finally {
      setState(() {
        _downloadingPdf = false;
      });
    }
  }

  // Update permission check for Android 13+
  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      // For Android 13 (API level 33) and above
      if (await Permission.storage.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        return true;
      } else {
        // Request permission
        var storageStatus = await Permission.storage.request();

        // On newer Android versions, might need additional permissions
        if (storageStatus.isGranted) {
          return true;
        } else {
          return false;
        }
      }
    } else {
      // For iOS, we don't need explicit permission for downloads to app documents
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download All Teachers PDF',
            onPressed: _downloadAllTeachersPdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTeachers.isEmpty
              ? const Center(child: Text('No teachers found'))
              : ListView.builder(
                  itemCount: _allTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _allTeachers[index];
                    final birthDate = teacher['birthDate'] != null
                        ? DateFormat('yyyy-MM-dd')
                            .format(DateTime.parse(teacher['birthDate']))
                        : 'Not available';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: teacher['photo'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                    'http://145.223.21.62:9000${teacher['photo']}'),
                                onBackgroundImageError: (_, __) =>
                                    const Icon(Icons.person),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${teacher['nameWithInitials']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIC: ${teacher['nicNo'] ?? 'Not available'}'),
                            Text('DOB: $birthDate'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherDetailScreen(
                                  teacherId: teacher['teacherId']),
                            ),
                          ).then((result) {
                            if (result == true) {
                              // Refresh the list if teacher data was updated
                              _fetchAllTeachers();
                            }
                          });
                        },
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
