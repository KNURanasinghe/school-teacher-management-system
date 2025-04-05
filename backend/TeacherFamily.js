
// models/TeacherFamily.js
const mongoose = require('mongoose');

const TeacherFamilySchema = new mongoose.Schema({
  teacherId: {
    type: String,
    required: true,
    unique: true,
    ref: 'TeacherPersonal'
  },
  kalaathrayaName: {
    type: String
  },
  kalaathrayaMobileNumber: {
    type: String
  },
  kalaathrayaJob: {
    type: String
  },
  kalaathrayaWorkplaceAddress: {
    type: String
  },
  childrenCount: {
    type: Number,
    default: 0
  },
  children: [{
    name: String,
    age: Number,
    education: String
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

module.exports = mongoose.model('TeacherFamily', TeacherFamilySchema);