
// models/TeacherCareer.js
const mongoose = require('mongoose');

const TeacherCareerSchema = new mongoose.Schema({
  teacherId: {
    type: String,
    required: true,
    unique: true,
    ref: 'TeacherPersonal'
  },
  alStream: {
    type: String,
    enum: ['Art', 'Commerce', 'Bio-Science', 'Mathematics', 'Technology', 'Other']
  },
  appointmentType: {
    type: String,
    enum: [
      'Degree', 'College Training', 'Untrained', 'Development Officer', 
      'Principle', 'Laboratory Assistant', 'School Clerk', 'Management Assistant', 
      'School Guard', 'Office Assistant', 'Sports Coach'
    ]
  },
  highestEducationQualification: {
    type: String
  },
  highestVocationalTraining: {
    type: String
  },
  instituteOfTraining: {
    type: String
  },
  firstAppointmentDate: {
    type: Date
  },
  currentServiceGrade: {
    type: String,
    enum: [
      'Principle-Grade1', 'Principle-Grade2', 'Principle-Grade3', 
      'SL-Teaching-Service1', 'SL-Teaching-Service2-I', 'SL-Teaching-Service2-II', 
      'SL-Teaching-Service3-II', 'Development Officer', 'School Guard', 
      'Office Assistant', 'Sports Coach', 'Clerk'
    ]
  },
  currentSchoolAppointmentDate: {
    type: Date
  },
  retirementDate: {
    type: Date
  },
  previousSchools: [{
    schoolName: String,
    appointmentDate: Date,
    endDate: Date
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('TeacherCareer', TeacherCareerSchema);