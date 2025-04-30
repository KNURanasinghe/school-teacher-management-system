// lib/screens/add_teacher_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  _AddTeacherScreenState createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Tab controller for the different sections
  late TabController _tabController;

  // Personal Information
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nameWithInitialsController =
      TextEditingController();
  String _selectedGender = 'Male';
  final TextEditingController _birthDateController = TextEditingController();
  bool _isMarried = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  File? _imageFile;

  // Career Information
  String _selectedALStream = 'Art';
  String _selectedAppointmentType = 'Degree';
  final TextEditingController _educationQualificationController =
      TextEditingController();
  final TextEditingController _vocationalTrainingController =
      TextEditingController();
  final TextEditingController _instituteOfTrainingController =
      TextEditingController();
  final TextEditingController _firstAppointmentDateController =
      TextEditingController();
  String _selectedServiceGrade = 'SL-Teaching-Service1';
  final TextEditingController _currentSchoolAppointmentDateController =
      TextEditingController();
  final TextEditingController _retirementDateController =
      TextEditingController();
  final List<Map<String, dynamic>> _previousSchools = [];

  // Family Information
  final TextEditingController _kalaathrayaNameController =
      TextEditingController();
  final TextEditingController _kalaathrayaMobileController =
      TextEditingController();
  final TextEditingController _kalaathrayaJobController =
      TextEditingController();
  final TextEditingController _kalaathrayaWorkplaceController =
      TextEditingController();
  final TextEditingController _childrenCountController =
      TextEditingController();
  final List<Map<String, dynamic>> _children = [];

  // Subject Information
  final TextEditingController _appointedSubjectController =
      TextEditingController();
  final List<String> _currentTeachingSubjects = [];
  final TextEditingController _newCurrentSubjectController =
      TextEditingController();
  final List<String> _interestedTeachingSubjects = [];
  final TextEditingController _newInterestedSubjectController =
      TextEditingController();

  bool _isLoading = false;
  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _childrenCountController.text = '0';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _addPreviousSchool() {
    setState(() {
      _previousSchools
          .add({'schoolName': '', 'appointmentDate': '', 'endDate': ''});
    });
  }

  void _removePreviousSchool(int index) {
    setState(() {
      _previousSchools.removeAt(index);
    });
  }

  void _updatePreviousSchool(int index, String key, String value) {
    setState(() {
      _previousSchools[index][key] = value;
    });
  }

  void _addChild() {
    setState(() {
      _children.add({'name': '', 'age': '', 'education': ''});
    });
    _childrenCountController.text = _children.length.toString();
  }

  void _removeChild(int index) {
    setState(() {
      _children.removeAt(index);
    });
    _childrenCountController.text = _children.length.toString();
  }

  void _updateChild(int index, String key, String value) {
    setState(() {
      _children[index][key] = value;
    });
  }

  void _addCurrentSubject() {
    if (_newCurrentSubjectController.text.isNotEmpty) {
      setState(() {
        _currentTeachingSubjects.add(_newCurrentSubjectController.text);
        _newCurrentSubjectController.clear();
      });
    }
  }

  void _removeCurrentSubject(int index) {
    setState(() {
      _currentTeachingSubjects.removeAt(index);
    });
  }

  void _addInterestedSubject() {
    if (_newInterestedSubjectController.text.isNotEmpty) {
      setState(() {
        _interestedTeachingSubjects.add(_newInterestedSubjectController.text);
        _newInterestedSubjectController.clear();
      });
    }
  }

  void _removeInterestedSubject(int index) {
    setState(() {
      _interestedTeachingSubjects.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _formSubmitted = true;
    });

    try {
      // Create multipart request - update with your actual server address
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://151.106.125.212:9000/api/teachers'), // For Android emulator
        // For iOS simulator, use: Uri.parse('http://localhost:9000/api/teachers')
        // For actual deployment, use your server domain or IP
      );

      // Add photo if selected with proper error handling
      if (_imageFile != null) {
        try {
          final bool fileExists = await File(_imageFile!.path).exists();
          print('Image file exists: $fileExists');

          if (fileExists) {
            final fileSize = await File(_imageFile!.path).length();
            print('Image file size: $fileSize bytes');

            request.files.add(
              await http.MultipartFile.fromPath('photo', _imageFile!.path),
            );
            print('Image successfully added to request');
          } else {
            print(
                'Warning: Image file does not exist at path: ${_imageFile!.path}');
          }
        } catch (e) {
          print('Error handling image file: $e');
        }
      } else {
        print('No image selected by user');
      }

      // Personal information
      final personalData = {
        'nicNo': _nicController.text,
        'fullName': _fullNameController.text,
        'nameWithInitials': _nameWithInitialsController.text,
        'gender': _selectedGender,
        'birthDate': _birthDateController.text,
        'isMarried': _isMarried,
        'address': _addressController.text,
        'mobileNumber': _mobileController.text,
        'whatsappNumber': _whatsappController.text.isNotEmpty
            ? _whatsappController.text
            : null,
      };

      // Career information
      final careerData = {
        'alStream': _selectedALStream,
        'appointmentType': _selectedAppointmentType,
        'highestEducationQualification': _educationQualificationController.text,
        'highestVocationalTraining': _vocationalTrainingController.text,
        'instituteOfTraining': _instituteOfTrainingController.text,
        'firstAppointmentDate': _firstAppointmentDateController.text,
        'currentServiceGrade': _selectedServiceGrade,
        'currentSchoolAppointmentDate':
            _currentSchoolAppointmentDateController.text,
        'retirementDate': _retirementDateController.text.isNotEmpty
            ? _retirementDateController.text
            : null,
        'previousSchools': _previousSchools,
      };

      // Family information
      final familyData = {
        'kalaathrayaName': _kalaathrayaNameController.text,
        'kalaathrayaMobileNumber': _kalaathrayaMobileController.text,
        'kalaathrayaJob': _kalaathrayaJobController.text,
        'kalaathrayaWorkplaceAddress': _kalaathrayaWorkplaceController.text,
        'childrenCount': int.parse(_childrenCountController.text),
        'children': _children,
      };

      // Subject information
      final subjectData = {
        'appointedSubject': _appointedSubjectController.text,
        'currentTeachingSubjects': _currentTeachingSubjects,
        'interestedTeachingSubjects': _interestedTeachingSubjects,
      };

      // Add data to request - encode properly
      request.fields['personal'] = json.encode(personalData);
      request.fields['career'] = json.encode(careerData);
      request.fields['family'] = json.encode(familyData);
      request.fields['subject'] = json.encode(subjectData);

      print('Sending request to: ${request.url}');
      print('Request fields prepared');

      // Send request with improved error handling
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      print('Response status code: ${streamedResponse.statusCode}');
      print('Response headers: ${streamedResponse.headers}');

      final responseData = await streamedResponse.stream.bytesToString();
      print('Response data: $responseData');

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = json.decode(responseData);
      } catch (e) {
        print('Error parsing JSON response: $e');
        jsonResponse = {'message': 'Failed to parse server response'};
      }

      setState(() {
        _isLoading = false;
      });

      if (streamedResponse.statusCode == 201) {
        print('Teacher added successfully!');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Teacher added successfully! ID: ${jsonResponse['teacherId']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to main screen
        Navigator.pop(
            context, true); // Pass true to indicate successful creation
      } else {
        print('Error: ${streamedResponse.statusCode}');

        // Show error message with more details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to add teacher: ${jsonResponse['message'] ?? 'Unknown server error'}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Exception during form submission: $e');

      setState(() {
        _isLoading = false;
      });

      // Show detailed error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Teacher'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Career'),
            Tab(text: 'Family'),
            Tab(text: 'Subject'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Personal Information Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Profile Picture
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _getImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : null,
                                  child: _imageFile == null
                                      ? const Icon(Icons.camera_alt, size: 50)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _getImage,
                                child: const Text('Upload Photo'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // NIC Number
                        TextFormField(
                          controller: _nicController,
                          decoration: const InputDecoration(
                            labelText: 'NIC Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter NIC number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name with Initials
                        TextFormField(
                          controller: _nameWithInitialsController,
                          decoration: const InputDecoration(
                            labelText: 'Name with Initials',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name with initials';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              ['Male', 'Female', 'Other'].map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Birth Date
                        GestureDetector(
                          onTap: () =>
                              _selectDate(context, _birthDateController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _birthDateController,
                              decoration: const InputDecoration(
                                labelText: 'Date of Birth',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select date of birth';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Marital Status
                        CheckboxListTile(
                          title: const Text('Married'),
                          value: _isMarried,
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                _isMarried = value;
                              });
                            }
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mobile Number
                        TextFormField(
                          controller: _mobileController,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // WhatsApp Number
                        TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp Number (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Next Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _tabController.animateTo(1);
                            },
                            child: const Text('Next: Career Information'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Career Information Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Career Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // AL Stream
                        DropdownButtonFormField<String>(
                          value: _selectedALStream,
                          decoration: const InputDecoration(
                            labelText: 'AL Stream',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'Art',
                            'Commerce',
                            'Bio-Science',
                            'Mathematics',
                            'Technology',
                            'Other'
                          ].map((String stream) {
                            return DropdownMenuItem<String>(
                              value: stream,
                              child: Text(stream),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedALStream = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Appointment Type
                        DropdownButtonFormField<String>(
                          value: _selectedAppointmentType,
                          decoration: const InputDecoration(
                            labelText: 'Appointment Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'Degree',
                            'College Training',
                            'Untrained',
                            'Development Officer',
                            'Principle',
                            'Laboratory Assistant',
                            'School Clerk',
                            'Management Assistant',
                            'School Guard',
                            'Office Assistant',
                            'Sports Coach'
                          ].map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedAppointmentType = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Highest Education Qualification
                        TextFormField(
                          controller: _educationQualificationController,
                          decoration: const InputDecoration(
                            labelText: 'Highest Education Qualification',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Highest Vocational Training
                        TextFormField(
                          controller: _vocationalTrainingController,
                          decoration: const InputDecoration(
                            labelText: 'Highest Vocational Training',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Institute of Training
                        TextFormField(
                          controller: _instituteOfTrainingController,
                          decoration: const InputDecoration(
                            labelText: 'Institute of Training',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // First Appointment Date
                        GestureDetector(
                          onTap: () => _selectDate(
                              context, _firstAppointmentDateController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _firstAppointmentDateController,
                              decoration: const InputDecoration(
                                labelText: 'First Appointment Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select first appointment date';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Current Service Grade
                        DropdownButtonFormField<String>(
                          value: _selectedServiceGrade,
                          decoration: const InputDecoration(
                            labelText: 'Current Service Grade',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'Principle-Grade1',
                            'Principle-Grade2',
                            'Principle-Grade3',
                            'SL-Teaching-Service1',
                            'SL-Teaching-Service2-I',
                            'SL-Teaching-Service2-II',
                            'SL-Teaching-Service3-II',
                            'Development Officer',
                            'School Guard',
                            'Office Assistant',
                            'Sports Coach',
                            'Clerk'
                          ].map((String grade) {
                            return DropdownMenuItem<String>(
                              value: grade,
                              child: Text(grade),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedServiceGrade = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Current School Appointment Date
                        GestureDetector(
                          onTap: () => _selectDate(
                              context, _currentSchoolAppointmentDateController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller:
                                  _currentSchoolAppointmentDateController,
                              decoration: const InputDecoration(
                                labelText: 'Current School Appointment Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select current school appointment date';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Retirement Date
                        GestureDetector(
                          onTap: () =>
                              _selectDate(context, _retirementDateController),
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _retirementDateController,
                              decoration: const InputDecoration(
                                labelText: 'Retirement Date (Optional)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Previous Schools
                        const Text(
                          'Previous Schools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // List of Previous Schools
                        ..._previousSchools.asMap().entries.map((entry) {
                          final index = entry.key;
                          final school = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('School ${index + 1}'),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _removePreviousSchool(index),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: school['schoolName'],
                                    decoration: const InputDecoration(
                                      labelText: 'School Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _updatePreviousSchool(
                                        index, 'schoolName', value),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1940),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        _updatePreviousSchool(
                                          index,
                                          'appointmentDate',
                                          DateFormat('yyyy-MM-dd')
                                              .format(picked),
                                        );
                                        setState(() {});
                                      }
                                    },
                                    //TODO
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: TextEditingController(
                                            text: school['appointmentDate']),
                                        decoration: const InputDecoration(
                                          labelText: 'Appointment Date',
                                          border: OutlineInputBorder(),
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(1940),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        _updatePreviousSchool(
                                          index,
                                          'endDate',
                                          DateFormat('yyyy-MM-dd')
                                              .format(picked),
                                        );
                                        setState(() {});
                                      }
                                    },
                                    child: AbsorbPointer(
                                      child: TextFormField(
                                        controller: TextEditingController(
                                            text: school['endDate']),
                                        decoration: const InputDecoration(
                                          labelText: 'End Date',
                                          border: OutlineInputBorder(),
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Add School Button
                        ElevatedButton.icon(
                          onPressed: _addPreviousSchool,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Previous School'),
                        ),
                        const SizedBox(height: 24),

                        // Navigation Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(0);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Previous'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(2);
                              },
                              child: const Text('Next: Family Information'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Family Information Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kaalaathraya Name
                        TextFormField(
                          controller: _kalaathrayaNameController,
                          decoration: const InputDecoration(
                            labelText: 'Name of the spouse',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kaalaathraya Mobile
                        TextFormField(
                          controller: _kalaathrayaMobileController,
                          decoration: const InputDecoration(
                            labelText: 'Spouse\'s Mobile Number',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Kaalaathraya Job
                        TextFormField(
                          controller: _kalaathrayaJobController,
                          decoration: const InputDecoration(
                            labelText: 'Spouse\'s occupation',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kaalaathraya Workplace
                        TextFormField(
                          controller: _kalaathrayaWorkplaceController,
                          decoration: const InputDecoration(
                            labelText: 'Spouse\'s Workplace Address',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Children Count
                        TextFormField(
                          controller: _childrenCountController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Children',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          readOnly: true,
                        ),
                        const SizedBox(height: 24),

                        // Children List
                        const Text(
                          'Children Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // List of Children
                        ..._children.asMap().entries.map((entry) {
                          final index = entry.key;
                          final child = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Child ${index + 1}'),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeChild(index),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: child['name'],
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        _updateChild(index, 'name', value),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: child['age'],
                                    decoration: const InputDecoration(
                                      labelText: 'Age',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) =>
                                        _updateChild(index, 'age', value),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: child['education'],
                                    decoration: const InputDecoration(
                                      labelText: 'Education',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        _updateChild(index, 'education', value),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Add Child Button
                        ElevatedButton.icon(
                          onPressed: _addChild,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Child'),
                        ),
                        const SizedBox(height: 24),

                        // Navigation Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(1);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Previous'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(3);
                              },
                              child: const Text('Next: Subject Information'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Subject Information Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subject Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Appointed Subject
                        TextFormField(
                          controller: _appointedSubjectController,
                          decoration: const InputDecoration(
                            labelText: 'Appointed Subject',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter appointed subject';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Current Teaching Subjects
                        const Text(
                          'Current Teaching Subjects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Current Teaching Subjects List
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentTeachingSubjects
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final subject = entry.value;
                            return Chip(
                              label: Text(subject),
                              deleteIcon: const Icon(Icons.clear, size: 18),
                              onDeleted: () => _removeCurrentSubject(index),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Add Current Teaching Subject
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newCurrentSubjectController,
                                decoration: const InputDecoration(
                                  labelText: 'Add Current Teaching Subject',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _addCurrentSubject,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Interested Teaching Subjects
                        const Text(
                          'Interested Teaching Subjects',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Interested Teaching Subjects List
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interestedTeachingSubjects
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final subject = entry.value;
                            return Chip(
                              label: Text(subject),
                              deleteIcon: const Icon(Icons.clear, size: 18),
                              onDeleted: () => _removeInterestedSubject(index),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Add Interested Teaching Subject
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newInterestedSubjectController,
                                decoration: const InputDecoration(
                                  labelText: 'Add Interested Teaching Subject',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _addInterestedSubject,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Navigation and Submit Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _tabController.animateTo(2);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Previous'),
                            ),
                            ElevatedButton.icon(
                              // onPressed: _formSubmitted ? null : _submitForm,
                              onPressed: _submitForm,
                              icon: const Icon(Icons.save),
                              label: const Text('Submit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Custom Form Field Widget
class CustomFormField extends StatelessWidget {
  final String initialValue;
  final Function(String) onChanged;
  final String label;
  final bool required;

  const CustomFormField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            }
          : null,
      onChanged: onChanged,
    );
  }
}
