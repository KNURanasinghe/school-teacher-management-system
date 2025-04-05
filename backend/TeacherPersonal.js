// models/TeacherPersonal.js
const mongoose = require('mongoose');

const TeacherPersonalSchema = new mongoose.Schema({
  teacherId: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  nicNo: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  nameWithInitials: {
    type: String,
    required: true,
    trim: true
  },
  gender: {
    type: String,
    required: true,
    enum: ['Male', 'Female', 'Other']
  },
  birthDate: {
    type: Date,
    required: true
  },
  isMarried: {
    type: Boolean,
    default: false
  },
  address: {
    type: String,
    required: true
  },
  mobileNumber: {
    type: String,
    required: true
  },
  whatsappNumber: {
    type: String
  },
  photo: {
    type: String, // Store the URL or path to the photo
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('TeacherPersonal', TeacherPersonalSchema);



