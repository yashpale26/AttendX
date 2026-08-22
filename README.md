# AttendX - Student Attendance Management System

## About the Project

AttendX is a Flutter and Firebase based Student Attendance Management System developed as an MSc Artificial Intelligence academic project. The application is designed to digitize the complete attendance process by providing separate Teacher and Student modules.

Teachers can manage student accounts, courses, subjects, course-wise student lists, attendance records, attendance history, and attendance exports. Students can securely log in using their own accounts and view only their own attendance information.

The main goal of AttendX is to provide a simple, organized, secure, and user-friendly attendance management solution that reduces the need for traditional paper-based attendance records.

---

## Project Objectives

- Replace manual attendance registers with a digital attendance system.
- Provide separate authentication and interfaces for Teachers and Students.
- Allow Teachers to manage student accounts directly from the application.
- Allow Teachers to create and manage courses and subjects.
- Allow Teachers to assign students to their respective courses.
- Allow Teachers to record attendance for individual students.
- Store attendance records in Firebase Cloud Firestore.
- Allow Teachers to view course-wise and student-wise attendance.
- Provide attendance history and percentage calculations.
- Provide attendance graphs and useful attendance summaries.
- Allow Teachers to export attendance information.
- Allow Students to view their own attendance records after logging in.
- Maintain a clean and simple user interface.

---

## Technologies Used

### Flutter

Flutter is used to develop the mobile application interface and application functionality.

### Dart

Dart is the primary programming language used for the Flutter application.

### Firebase Authentication

Firebase Authentication is used to create and authenticate Teacher and Student accounts.

### Cloud Firestore

Cloud Firestore is used to store user information, courses, subjects, student enrollment information, and attendance records.

### Android Studio

Android Studio is used as the primary development environment for building and testing the Flutter application.

---

# User Roles

AttendX has two main user roles:

## Teacher

The Teacher module is responsible for managing the academic and attendance-related operations of the application.

Teacher features include:

- Teacher Dashboard
- Manage Students
- Manage Courses & Subjects
- Manage Attendance
- Export Attendance
- Teacher Profile
- Logout

## Student

The Student module is designed for students who want to view their own attendance.

Student features include:

- Student Dashboard
- Attendance Information
- Attendance History
- Subject-wise Attendance
- Student Profile
- Logout

---

# Authentication System

AttendX uses Firebase Authentication for account creation and login.

When a user logs in, the application authenticates the account using Firebase Authentication and checks the user's role information stored in Firestore.

Depending on the role:

- A Teacher is directed to the Teacher Dashboard.
- A Student is directed to the Student Dashboard.

The application therefore maintains separate experiences for Teachers and Students.

---

# Teacher Module

## 1. Teacher Dashboard

The Teacher Dashboard is the main overview screen of the Teacher module.

The dashboard can provide a quick summary of the system, including:

- Teacher email
- Total number of students
- Total courses
- Total subjects
- Attendance overview
- Useful attendance statistics
- Quick access to important features

The dashboard is intended to give the Teacher a quick understanding of the current attendance system without opening every feature individually.

### UI Design

The dashboard follows the AttendX green theme.

The screen can contain:

- Green gradient AppBar
- Welcome section
- Summary cards
- Attendance overview
- Clean light-green background
- Bottom navigation containing Dashboard, Features, and Profile

---

# 2. Manage Students

Manage Students allows Teachers to manage Student accounts from inside the application.

Instead of requiring the Teacher to return to the registration screen or Firebase Console, student accounts can be managed from this feature.

### Main Features

- Display Student accounts
- Scroll through the Student list
- Add Student account
- Refresh Student list
- Delete Student account
- Manage Student Firebase Authentication accounts

### Student List

The list displays only Student-role accounts.

Each item contains:

- Serial number
- Student email

Example:

1. student1@attendx.com
2. student2@attendx.com
3. student3@attendx.com

### Add Student

The Add Student screen contains:

- AppBar with the title "Add Student Users"
- Back button
- Email field
- Password field
- Confirm Password field
- Password visibility controls
- Add Account button

After successful account creation:

- The account is created in Firebase Authentication.
- The input fields are cleared.
- A success message is displayed.
- The account can appear in the Student list after refreshing.

### Refresh

The Refresh button reloads the Student list so newly created Student accounts can be displayed.

A success notification is displayed after a successful refresh.

### Delete

The Delete functionality allows the Teacher to remove a Student account from the application.

The intended functionality is to remove the corresponding Firebase Authentication account as well as its associated application data where applicable.

---

# 3. Manage Courses & Subjects

Manage Courses & Subjects is used by Teachers to organize the academic structure of the attendance system.

Teachers can create courses and associate multiple subjects with each course.

### Main Functions

- Select or create a course
- Add subjects
- Select multiple subjects
- Organize subjects under a course
- Add students according to their course
- Create a course-specific student list
- Reuse the created course and student list later during attendance

### Example

A course such as MSc Artificial Intelligence can contain subjects such as:

- Artificial Intelligence
- Internet of Things
- Machine Learning
- Data Analytics

After selecting the course and subjects, the Teacher can assign the appropriate Students.

This creates a structured list that can later be used while taking attendance.

---

# 4. Manage Attendance

Manage Attendance is one of the main Teacher features.

It is responsible for creating and viewing attendance records.

The feature contains two main areas:

- Create Attendance
- View Attendance

---

## 4.1 Create Attendance

Create Attendance allows the Teacher to record attendance for a particular course and subject.

### Working

The Teacher selects:

1. Course
2. Subject
3. Course student list

The application then displays the Students belonging to the selected course.

The Teacher can mark each Student as:

- Present
- Absent

After completing the attendance process, the Teacher saves the attendance.

The attendance information is stored in Firebase Firestore and associated with the relevant Student, course, subject, lecture, date, time, and Teacher.

### Attendance Information

Attendance records can contain information such as:

- Student email
- Course
- Subject
- Lecture number
- Attendance status
- Date
- Time
- Teacher email

This allows the attendance information to be retrieved later for viewing and reporting.

---

# 4.2 View Attendance

View Attendance allows Teachers to analyze previously recorded attendance.

The feature is organized around course-level and student-level information.

## Course Overview

The Course Overview displays overall attendance information for the selected course.

It can show:

- Course name
- Total lectures conducted
- Overall attendance percentage
- Subject-wise attendance
- Attendance history
- Daily attendance
- Weekly attendance
- Monthly attendance
- Overall attendance
- Attendance graph

The purpose of this screen is to give the Teacher a quick overview of attendance performance for the selected course.

---

## Student List

After selecting a course, the Student List displays the Students enrolled in that course.

Each Student entry can contain:

- Serial number
- Student email
- Overall attendance percentage

Example:

1. student1@attendx.com - 88%
2. student2@attendx.com - 76%
3. student3@attendx.com - 92%

Selecting a Student opens the detailed attendance information for that Student.

---

## Individual Student Attendance

The Individual Student view provides detailed attendance information for the selected Student.

It can contain:

- Student email
- Student name where available
- Course name
- Enrolled subjects
- Subject-wise attendance percentage
- Total lectures
- Present lectures
- Absent lectures
- Overall attendance percentage
- Attendance history
- Attendance graph

The purpose is to allow the Teacher to understand the complete attendance performance of one Student across all subjects in the selected course.

---

# 5. Export Attendance

Export Attendance allows Teachers to generate attendance reports from the application.

The Teacher first selects the required course and then chooses what attendance information should be exported.

### Course Export

The Teacher can export the attendance of the complete selected course.

The exported report can contain:

- Course name
- Teacher name or email
- Student email
- Subject
- Lecture number
- Attendance status
- Date
- Time

The report is designed to keep attendance information detailed and organized so that another person can easily understand the attendance records.

### Individual Student Export

The Teacher can also select an individual Student and export that Student's complete attendance information.

The report can contain:

- Course name
- Teacher name or email
- Student email
- All subjects
- Total lectures
- Present lectures
- Absent lectures
- Attendance percentage
- Date
- Time
- Lecture number

The exported spreadsheet is intended to provide a clean and detailed record that can be stored, shared, or reviewed later.

---

# 6. Teacher Profile

The Teacher Profile is intentionally kept simple.

It contains:

- Teacher account email
- Account information
- Logout button

The Teacher can use the Logout button to securely sign out of Firebase Authentication and return to the Login screen.

---

# Student Module

The Student module is designed so that every Student can access their own attendance information after authentication.

Each Student account has its own Firebase Authentication identity.

Attendance records are stored individually and associated with the relevant Student.

Therefore, when a Student logs in, the application should retrieve attendance records belonging to that Student rather than displaying another Student's attendance.

---

# 1. Student Dashboard

The Student Dashboard provides a quick overview of the Student's attendance.

It can display:

- Student email
- Course name
- Overall attendance percentage
- Total lectures
- Present lectures
- Absent lectures
- Attendance overview
- Attendance graph

The dashboard gives the Student an immediate understanding of their current attendance status.

---

# 2. Student Features

The Student Features section focuses on attendance information.

It can provide:

- Overall attendance
- Subject-wise attendance
- Attendance history
- Daily attendance
- Weekly attendance
- Monthly attendance
- Overall attendance
- Attendance graphs

The Student should only see attendance records associated with their own authenticated account.

---

# 3. Student Profile

The Student Profile is kept simple.

It contains:

- Student email
- Account information
- Logout button

The Student can use the Logout button to sign out of Firebase Authentication.

---

# Firebase Database

AttendX uses Firebase Authentication and Cloud Firestore together.

Firebase Authentication is responsible for account credentials and authentication.

Cloud Firestore stores application-specific information such as:

- User profile information
- User role
- Courses
- Subjects
- Student enrollment
- Attendance records

A user record contains information such as:

- Name
- Email
- Role
- Account creation timestamp

Attendance records contain information such as:

- Student
- Course
- Subject
- Lecture number
- Date
- Time
- Attendance status
- Teacher

---

# Attendance Workflow

The complete attendance workflow works as follows:

1. The Teacher logs into AttendX.
2. The Teacher creates or selects a course.
3. The Teacher adds subjects to the course.
4. The Teacher assigns Students to the course.
5. The Teacher opens Create Attendance.
6. The Teacher selects the course and subject.
7. The application loads the Students belonging to that course.
8. The Teacher marks Students as Present or Absent.
9. The Teacher saves the attendance.
10. The attendance is stored in Firebase Firestore.
11. The Teacher can later view course attendance.
12. The Teacher can view individual Student attendance.
13. The Student logs into their own account.
14. The Student can view only their own attendance records.

---

# User Interface Design

AttendX uses a simple and consistent visual design.

## Teacher Interface

The Teacher module primarily follows a green visual theme.

The UI uses:

- Green gradient AppBars
- Light green backgrounds
- Green feature cards
- White content cards
- Rounded corners
- Simple icons
- Bottom navigation
- Scrollable content where required

## Student Interface

The Student module follows a blue visual theme while maintaining the overall AttendX design language.

The UI uses:

- Blue gradient AppBars
- Light blue backgrounds
- Blue feature cards
- White content cards
- Rounded corners
- Simple icons
- Bottom navigation
- Scrollable content

The intention is to make Teacher and Student modules visually distinguishable while keeping the application consistent.

---

# Project Structure

The project is organized into separate screens and reusable widgets.

The main application files are organized approximately as follows:

- `lib/main.dart` - Application entry point and Firebase initialization.
- `lib/screens/splash_screen.dart` - Splash screen.
- `lib/screens/login_screen.dart` - Login screen.
- `lib/screens/register_screen.dart` - Registration screen.
- `lib/screens/teacher_dashboard.dart` - Teacher dashboard and navigation.
- `lib/screens/student_dashboard.dart` - Student dashboard and navigation.
- `lib/screens/manage_student_screen.dart` - Student management.
- `lib/screens/manage_courses_screen.dart` - Course and subject management.
- `lib/screens/manage_attendance_screen.dart` - Attendance management.
- `lib/screens/export_attendance_screen.dart` - Attendance export.
- `lib/widgets/feature_app_bar.dart` - Reusable feature AppBar.

Additional screens and widgets can be added as the project continues to grow.

---

# Firebase Configuration

To run AttendX, Firebase must be configured for the project.

The Firebase project should have:

- Firebase Authentication enabled
- Cloud Firestore enabled
- Flutter/Firebase configuration files added to the application
- Appropriate Firestore security rules

The Firebase configuration should not be publicly exposed in inappropriate places, and sensitive credentials or private server-side configuration should not be committed to GitHub.

---

# Installation

## 1. Clone the Repository

Clone the AttendX repository from GitHub.

```bash
git clone https://github.com/YOUR_USERNAME/AttendX.git
```

Replace `YOUR_USERNAME` with the GitHub username containing the repository.

## 2. Open the Project

Open the cloned project in Android Studio.

## 3. Install Flutter Dependencies

Run:

```bash
flutter pub get
```

## 4. Configure Firebase

Connect the Flutter project with your Firebase project and add the required Firebase configuration files.

## 5. Run the Application

Use:

```bash
flutter run
```

The application can then be tested on a connected Android device or emulator.

---

# Testing

The main Teacher workflow can be tested using the following sequence:

1. Register or create a Teacher account.
2. Log in as Teacher.
3. Open Manage Students.
4. Add Student accounts.
5. Verify Student accounts.
6. Create a Course.
7. Add Subjects.
8. Assign Students.
9. Create Attendance.
10. Mark attendance.
11. Save attendance.
12. Open View Attendance.
13. Check Course Overview.
14. Check Student List.
15. Open an individual Student.
16. Verify attendance calculations.
17. Test attendance export.
18. Logout.

The Student workflow can be tested by:

1. Create a Student account.
2. Log in using the Student account.
3. Open the Student Dashboard.
4. Verify that the Student sees their own attendance.
5. Check subject-wise attendance.
6. Check attendance history.
7. Check attendance graphs.
8. Logout.

---

# Security Considerations

AttendX uses Firebase Authentication to authenticate users.

The application also uses role information to separate Teacher and Student functionality.

Important security considerations include:

- Authentication should be handled through Firebase Authentication.
- Firestore security rules should restrict unauthorized access.
- Students should only be allowed to read their own attendance.
- Teachers should only receive the permissions required for their management functions.
- Firebase configuration and sensitive credentials should not be exposed publicly.
- Server-side administrative operations should not be performed using client-side secret credentials.

---

# Future Enhancements

Potential future improvements include:

- Push notifications
- Low-attendance alerts
- PDF attendance reports
- Advanced attendance analytics
- Semester management
- Multiple Teacher support
- Dedicated Admin module
- QR-code based attendance
- AI-assisted attendance analytics
- Face recognition based attendance
- Automated attendance notifications
- Cloud-based report management

These features can be added in future versions depending on project requirements.

---

# Academic Project

AttendX is developed as an MSc Artificial Intelligence academic project.

The project demonstrates practical implementation of:

- Mobile application development
- Flutter and Dart programming
- Firebase Authentication
- Cloud database management
- Role-based application design
- CRUD operations
- Attendance data management
- Data visualization
- Report generation
- User interface design

---

# Conclusion

AttendX provides a complete digital approach to student attendance management. The system separates Teacher and Student functionality, allowing Teachers to manage students, courses, subjects, attendance, and reports while allowing Students to securely access their own attendance information.

By combining Flutter with Firebase Authentication and Cloud Firestore, AttendX provides a practical foundation for a scalable attendance management application.

---

# Developer

**AttendX**

MSc Artificial Intelligence Academic Project

Developed using Flutter, Dart, Firebase Authentication, Cloud Firestore, and Android Studio.

---

# License

This project was developed as an academic project. If you intend to reuse, modify, or distribute the project, please check the repository owner's licensing terms.
