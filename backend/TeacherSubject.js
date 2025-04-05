// models/TeacherSubject.js
const mongoose = require('mongoose');

const TeacherSubjectSchema = new mongoose.Schema({
  teacherId: {
    type: String,
    required: true,
    unique: true,
    ref: 'TeacherPersonal'
  },
  appointedSubject: {
    type: String
  },
  currentTeachingSubjects: [{
    type: String
  }],
  interestedTeachingSubjects: [{
    type: String
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

module.exports = mongoose.model('TeacherSubject', TeacherSubjectSchema);