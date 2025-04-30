// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import 'package:teacher_management_system/add_teacher.dart';
import 'package:teacher_management_system/all_teachers.dart';
import 'package:teacher_management_system/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize();

  // Register callback for download progress tracking
  FlutterDownloader.registerCallback(downloadCallback);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // This callback handles download progress updates
  // It must be a top-level or static function
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teacher Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class TeacherSearchScreen extends StatefulWidget {
  const TeacherSearchScreen({super.key});

  @override
  _TeacherSearchScreenState createState() => _TeacherSearchScreenState();
}

class _TeacherSearchScreenState extends State<TeacherSearchScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _appointmentDateController =
      TextEditingController();
  DateTime? _selectedDate;
  List<dynamic> _teachers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllTeachers(); // Load all teachers initially
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _appointmentDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _fetchAllTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://151.106.125.212:9000/api/teachers/search'),
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}'); // Debugging line
        final data = json.decode(response.body);
        setState(() {
          _teachers = data['data'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to fetch teachers');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e'); // Debugging line
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchTeachers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String queryString = '?';
      if (_idController.text.isNotEmpty) {
        queryString += 'nicNo=${_idController.text}&';
      }
      if (_nameController.text.isNotEmpty) {
        queryString += 'name=${_nameController.text}&';
      }
      if (_appointmentDateController.text.isNotEmpty) {
        queryString += 'appointmentDate=${_appointmentDateController.text}';
      }

      final response = await http.get(
        Uri.parse(
            'http://151.106.125.212:9000/api/teachers/search$queryString'),
      );

      if (response.statusCode == 200) {
        print('Search Response: ${response.body}'); // Debugging line
        final data = json.decode(response.body);
        setState(() {
          _teachers = data['data'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Search failed');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Search Error: $e'); // Debugging line
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

  void _clearSearch() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      _appointmentDateController.clear();
      _selectedDate = null;
    });
    _fetchAllTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management System'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'getAllTeachers') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllTeachersScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    _fetchAllTeachers();
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'getAllTeachers',
                child: Text('Get All Teachers'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Teachers',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Teacher Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _appointmentDateController,
                          decoration: const InputDecoration(
                            labelText: 'Appointment Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _searchTeachers,
                          icon: const Icon(Icons.search),
                          label: const Text('Search'),
                        ),
                        TextButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _teachers.isEmpty
                    ? const Center(child: Text('No teachers found'))
                    : ListView.builder(
                        itemCount: _teachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _teachers[index];
                          return TeacherListItem(
                            teacher: teacher,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherDetailScreen(
                                      teacherId: teacher['teacherId']),
                                ),
                              );
                              if (result == true) {
                                // Call your refresh method here, e.g.:
                                setState(() {
                                  _fetchAllTeachers();
                                });
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add teacher screen and wait for result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTeacherScreen(),
            ),
          );

          // If result is true (teacher was added successfully), refresh the teacher list
          if (result == true) {
            _fetchAllTeachers();
          }
        },
        tooltip: 'Add New Teacher',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TeacherListItem extends StatelessWidget {
  final dynamic teacher;
  final VoidCallback onTap;

  const TeacherListItem({
    super.key,
    required this.teacher,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: teacher['photo'] != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(
                    'http://151.106.125.212:9000${teacher['photo']}'),
                onBackgroundImageError: (_, __) => const Icon(Icons.person),
              )
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text('${teacher['nameWithInitials']}'),
        subtitle: Text('ID: ${teacher['teacherId']}'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class TeacherDetailScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
  });

  @override
  _TeacherDetailScreenState createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _teacherData = {};
  bool _downloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://151.106.125.212:9000/api/teachers/${widget.teacherId}'),
      );

      if (response.statusCode == 200) {
        print('Teacher Details Response: ${response.body}'); // Debugging line
        final data = json.decode(response.body);
        setState(() {
          _teacherData = data['data'];
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to fetch teacher details');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e'); // Debugging line
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

  Future<void> _downloadPdf() async {
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
        const SnackBar(content: Text('Downloading PDF...')),
      );

      // Properly encode the teacher ID in the URL
      final teacherId = Uri.encodeComponent(widget.teacherId);
      final downloadUrl =
          'http://151.106.125.212:9000/api/teachers/$teacherId/pdf';

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

      // Create a more meaningful filename
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fileName = 'Teacher_${widget.teacherId}_$dateStr.pdf';
      final filePath = '${saveDir.path}/$fileName';

      print('Download URL: $downloadUrl');
      print('Save directory: ${saveDir.path}');
      print('File will be saved as: $filePath');

      // Direct HTTP download
      try {
        final response = await http.get(Uri.parse(downloadUrl), headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        });

        if (response.statusCode == 200) {
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

  Future<void> _deleteTeacher() async {
    // Ask for confirmation before deleting
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Teacher'),
            content: const Text(
                'Are you sure you want to delete this teacher? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(
            'http://151.106.125.212:9000/api/teachers/${widget.teacherId}'),
      );

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with result to refresh list
        Navigator.of(context).pop(true);
      } else {
        // Show error message
        final responseData = json.decode(response.body);
        _showErrorSnackBar(
            'Failed to delete teacher: ${responseData['message'] ?? 'Unknown error'}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
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
        title: _isLoading
            ? const Text('Teacher Details')
            : Text('${_teacherData['personal']['nameWithInitials']}'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Download PDF',
              onPressed: _downloadPdf,
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Teacher',
              onPressed: _deleteTeacher,
              color: Colors.red,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Card
                  _buildSectionCard(
                    'Personal Information',
                    [
                      _buildInfoRow(
                          'Teacher ID', _teacherData['personal']['teacherId']),
                      _buildInfoRow(
                          'NIC Number', _teacherData['personal']['nicNo']),
                      _buildInfoRow(
                          'Full Name', _teacherData['personal']['fullName']),
                      _buildInfoRow(
                          'Gender', _teacherData['personal']['gender']),
                      _buildInfoRow(
                        'Date of Birth',
                        DateFormat('yyyy-MM-dd').format(
                          DateTime.parse(_teacherData['personal']['birthDate']),
                        ),
                      ),
                      _buildInfoRow(
                        'Marital Status',
                        _teacherData['personal']['isMarried']
                            ? 'Married'
                            : 'Single',
                      ),
                      _buildInfoRow(
                          'Address', _teacherData['personal']['address']),
                      _buildInfoRow(
                          'Mobile', _teacherData['personal']['mobileNumber']),
                      if (_teacherData['personal']['whatsappNumber'] != null)
                        _buildInfoRow(
                          'WhatsApp',
                          _teacherData['personal']['whatsappNumber'],
                        ),
                    ],
                    photoUrl: _teacherData['personal']['photo'] != null
                        ? 'http://151.106.125.212:9000${_teacherData['personal']['photo']}'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Career Information Card
                  _buildSectionCard(
                    'Career Information',
                    [
                      _buildInfoRow(
                          'AL Stream',
                          _teacherData['career']['alStream'] ??
                              'Not specified'),
                      _buildInfoRow(
                        'Appointment Type',
                        _teacherData['career']['appointmentType'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Education',
                        _teacherData['career']
                                ['highestEducationQualification'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Vocational Training',
                        _teacherData['career']['highestVocationalTraining'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Training Institute',
                        _teacherData['career']['instituteOfTraining'] ??
                            'Not specified',
                      ),
                      if (_teacherData['career']['firstAppointmentDate'] !=
                          null)
                        _buildInfoRow(
                          'First Appointment',
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(
                                _teacherData['career']['firstAppointmentDate']),
                          ),
                        ),
                      _buildInfoRow(
                        'Current Grade',
                        _teacherData['career']['currentServiceGrade'] ??
                            'Not specified',
                      ),
                      if (_teacherData['career']
                              ['currentSchoolAppointmentDate'] !=
                          null)
                        _buildInfoRow(
                          'Current School Since',
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(_teacherData['career']
                                ['currentSchoolAppointmentDate']),
                          ),
                        ),
                      if (_teacherData['career']['retirementDate'] != null)
                        _buildInfoRow(
                          'Retirement Date',
                          DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(
                                _teacherData['career']['retirementDate']),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Family Information Card
                  _buildSectionCard(
                    'Family Information',
                    [
                      _buildInfoRow(
                        'Name of the spouse',
                        _teacherData['family']['kalaathrayaName'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Spouse\'s Mobile',
                        _teacherData['family']['kalaathrayaMobileNumber'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Spouse\'s occupation',
                        _teacherData['family']['kalaathrayaJob'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Spouse\'s Workplace Address',
                        _teacherData['family']['kalaathrayaWorkplaceAddress'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Children Count',
                        _teacherData['family']['childrenCount']?.toString() ??
                            '0',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Subject Information Card
                  _buildSectionCard(
                    'Subject Information',
                    [
                      _buildInfoRow(
                        'Appointed Subject',
                        _teacherData['subject']['appointedSubject'] ??
                            'Not specified',
                      ),
                      _buildInfoRow(
                        'Current Teaching Subjects',
                        (_teacherData['subject']['currentTeachingSubjects']
                                    as List<dynamic>?)
                                ?.join(', ') ??
                            'None',
                      ),
                      _buildInfoRow(
                        'Interested Subjects',
                        (_teacherData['subject']['interestedTeachingSubjects']
                                    as List<dynamic>?)
                                ?.join(', ') ??
                            'None',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children,
      {String? photoUrl}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (photoUrl != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(photoUrl),
                    onBackgroundImageError: (_, __) => const Icon(Icons.person),
                  ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
