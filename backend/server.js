// server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const pdf = require('html-pdf');
const ejs = require('ejs');
require('dotenv').config();

// Import models
const TeacherPersonal = require('./TeacherPersonal');
const TeacherCareer = require('./TeacherCareer');
const TeacherFamily = require('./TeacherFamily');
const TeacherSubject = require('./TeacherSubject');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Setup file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ 
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    console.log('File being processed:', file.originalname, 'Mimetype:', file.mimetype);
    
    // Check file extension
    const ext = path.extname(file.originalname).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    
    if (validExtensions.includes(ext) || 
        file.mimetype.startsWith('image/') || 
        file.mimetype === 'application/octet-stream') {
      console.log('File accepted:', file.originalname);
      cb(null, true);
    } else {
      console.log('File rejected. Extension:', ext, 'Mimetype:', file.mimetype);
      if (file.fieldname === 'photo' && !req.body.requirePhoto) {
        console.log('Photo field is optional, continuing without file');
        cb(null, false);
      } else {
        cb(new Error(`Invalid file type. Allowed extensions are: ${validExtensions.join(', ')}`));
      }
    }
  }
});

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb+srv://miyomiapp:Miyomi%402025@cluster0.scy60.mongodb.net/teachers', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.error('MongoDB connection error:', err));

// API Routes

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// Create a new teacher with all details
app.post('/api/teachers', upload.single('photo'), async (req, res) => {
  try {
    const { personal, career, family, subject } = req.body;
    
    // Parse JSON if received as strings
    const personalData = typeof personal === 'string' ? JSON.parse(personal) : personal;
    const careerData = typeof career === 'string' ? JSON.parse(career) : career;
    const familyData = typeof family === 'string' ? JSON.parse(family) : family;
    const subjectData = typeof subject === 'string' ? JSON.parse(subject) : subject;
    
    // Generate a teacher ID (you can customize this logic)
    const teacherId = `TCH${Date.now().toString().slice(-6)}`;
    
    // Create teacher personal info
    const newTeacherPersonal = new TeacherPersonal({
      ...personalData,
      teacherId,
      photo: req.file ? `/uploads/${req.file.filename}` : null
    });
    await newTeacherPersonal.save();
    
    // Create teacher career info
    const newTeacherCareer = new TeacherCareer({
      ...careerData,
      teacherId
    });
    await newTeacherCareer.save();
    
    // Create teacher family info
    const newTeacherFamily = new TeacherFamily({
      ...familyData,
      teacherId
    });
    await newTeacherFamily.save();
    
    // Create teacher subject info
    const newTeacherSubject = new TeacherSubject({
      ...subjectData,
      teacherId
    });
    await newTeacherSubject.save();
    
    res.status(201).json({
      success: true,
      message: 'Teacher created successfully',
      teacherId
    });
  } catch (error) {
    console.error('Error creating teacher:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create teacher',
      error: error.message
    });
  }
});

// Search teachers
app.get('/api/teachers/search', async (req, res) => {
  try {
    const { nicNo, name, appointmentDate } = req.query;
    
    const query = {};
    
    if (nicNo) {
      query.nicNo = { $regex: nicNo, $options: 'i' };
    }
    
    if (name) {
      query.$or = [
        { fullName: { $regex: name, $options: 'i' } },
        { nameWithInitials: { $regex: name, $options: 'i' } }
      ];
    }
    
    // Get teachers matching personal info query
    const teachers = await TeacherPersonal.find(query);
    const teacherIds = teachers.map(t => t.teacherId);
    
    // Filter by appointment date if provided
    let filteredTeacherIds = teacherIds;
    if (appointmentDate) {
      const date = new Date(appointmentDate);
      const careerRecords = await TeacherCareer.find({
        teacherId: { $in: teacherIds },
        $or: [
          { firstAppointmentDate: { $gte: date } },
          { currentSchoolAppointmentDate: { $gte: date } }
        ]
      });
      filteredTeacherIds = careerRecords.map(c => c.teacherId);
    }
    
    // Get full information for filtered teachers
    const filteredTeachers = await TeacherPersonal.find({
      teacherId: { $in: filteredTeacherIds }
    });
    
    res.json({
      success: true,
      count: filteredTeachers.length,
      data: filteredTeachers
    });
  } catch (error) {
    console.error('Error searching teachers:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search teachers',
      error: error.message
    });
  }
});

// Get complete teacher details by ID
app.get('/api/teachers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const personalInfo = await TeacherPersonal.findOne({ teacherId: id });
    if (!personalInfo) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found'
      });
    }
    
    const careerInfo = await TeacherCareer.findOne({ teacherId: id });
    const familyInfo = await TeacherFamily.findOne({ teacherId: id });
    const subjectInfo = await TeacherSubject.findOne({ teacherId: id });
    
    res.json({
      success: true,
      data: {
        personal: personalInfo,
        career: careerInfo,
        family: familyInfo,
        subject: subjectInfo
      }
    });
  } catch (error) {
    console.error('Error fetching teacher details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch teacher details',
      error: error.message
    });
  }
});

// Generate and return PDF
app.get('/api/teachers/:id/pdf', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Fetch all teacher data
    const personalInfo = await TeacherPersonal.findOne({ teacherId: id });
    if (!personalInfo) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found'
      });
    }
    
    const careerInfo = await TeacherCareer.findOne({ teacherId: id });
    const familyInfo = await TeacherFamily.findOne({ teacherId: id });
    const subjectInfo = await TeacherSubject.findOne({ teacherId: id });
    
    // Compile the teacher data
    const teacherData = {
      personal: personalInfo,
      career: careerInfo,
      family: familyInfo,
      subject: subjectInfo,
      serverUrl: `${req.protocol}://${req.get('host')}`
    };
    
    // Generate HTML from EJS template
    const ejsTemplate = 'teacher-profile';
    const html = await ejs.renderFile(
      path.join(__dirname, 'views', `${ejsTemplate}.ejs`),
      teacherData
    );
    
    // PDF options
    const options = {
      format: 'A4',
      border: {
        top: '20px',
        right: '20px',
        bottom: '20px',
        left: '20px'
      },
      header: {
        height: '10mm'
      },
      footer: {
        height: '10mm'
      }
    };
    
    // Generate PDF
    pdf.create(html, options).toBuffer((err, buffer) => {
      if (err) {
        console.error('Error generating PDF:', err);
        return res.status(500).json({
          success: false,
          message: 'Failed to generate PDF',
          error: err.message
        });
      }
      
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=teacher-${id}.pdf`);
      res.send(buffer);
    });
  } catch (error) {
    console.error('Error generating PDF:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate PDF',
      error: error.message
    });
  }
});

// Update teacher info
app.put('/api/teachers/:id', upload.single('photo'), async (req, res) => {
  try {
    const { id } = req.params;
    const { personal, career, family, subject } = req.body;
    
    // Parse JSON if received as strings
    const personalData = typeof personal === 'string' ? JSON.parse(personal) : personal;
    const careerData = typeof career === 'string' ? JSON.parse(career) : career;
    const familyData = typeof family === 'string' ? JSON.parse(family) : family;
    const subjectData = typeof subject === 'string' ? JSON.parse(subject) : subject;
    
    // Update photo if provided
    if (req.file) {
      personalData.photo = `/uploads/${req.file.filename}`;
    }
    
    // Update each collection
    await TeacherPersonal.findOneAndUpdate({ teacherId: id }, personalData, { new: true });
    await TeacherCareer.findOneAndUpdate({ teacherId: id }, careerData, { new: true });
    await TeacherFamily.findOneAndUpdate({ teacherId: id }, familyData, { new: true });
    await TeacherSubject.findOneAndUpdate({ teacherId: id }, subjectData, { new: true });
    
    res.json({
      success: true,
      message: 'Teacher information updated successfully'
    });
  } catch (error) {
    console.error('Error updating teacher:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update teacher information',
      error: error.message
    });
  }
});

// Delete teacher
app.delete('/api/teachers/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Delete teacher data from all collections
    await TeacherPersonal.findOneAndDelete({ teacherId: id });
    await TeacherCareer.findOneAndDelete({ teacherId: id });
    await TeacherFamily.findOneAndDelete({ teacherId: id });
    await TeacherSubject.findOneAndDelete({ teacherId: id });
    
    res.json({
      success: true,
      message: 'Teacher deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting teacher:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete teacher',
      error: error.message
    });
  }
});

const PORT = process.env.PORT || 9000;
// Make sure it's binding to all interfaces (0.0.0.0), not just localhost
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));

module.exports = app;