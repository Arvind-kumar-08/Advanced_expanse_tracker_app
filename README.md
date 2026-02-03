📊 Advance Expense Tracker App

An advanced expense tracking mobile application built using Flutter and Firebase, designed to help users manage their daily income and expenses efficiently with secure authentication and real-time data synchronization.

🚀 Features

🔐 User Authentication (Login / Register) using Firebase

👤 Secure user-specific data storage in Firestore

💰 Add, update, and delete transactions (Income & Expense)

📅 Filter transactions by date and type

🔄 Real-time transaction updates using Firestore streams

📊 Organized transaction history

📱 Clean and responsive UI

☁️ Cloud-based data sync

🛠️ Tech Stack

Frontend

Flutter

Dart

Provider (State Management)

Backend & Cloud

Firebase Authentication

Cloud Firestore

Tools

Android Studio

Git & GitHub

📂 Project Structure
lib/
 ├── core/
 │   ├── constants/
 │   ├── utils/
 │   └── widgets/
 ├── data/
 │   ├── models/
 │   ├── datasources/
 │   └── repositories/
 ├── state/
 │   └── providers/
 ├── presentation/
 │   └── screens/
 └── main.dart

🔐 Firestore Data Structure
users/{uid}
   └── transactions/{transactionId}

🧪 Validation & Security

Input validation using custom validators

Secure Firestore rules (user can only access their own data)

Authentication required for all read/write operations

▶️ How to Run the Project
1. Clone the repository
git clone https://github.com/your-username/advance_expense_tracker_app.git

2. Install dependencies
flutter pub get

3. Setup Firebase

Create a Firebase project

Enable Authentication (Email/Password)

Create Firestore Database

Add google-services.json to:

android/app/

4. Run the app
flutter run

🔒 Firestore Rules (Recommended)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null 
                          && request.auth.uid == userId;
    }

    match /users/{userId}/transactions/{transactionId} {
      allow read, write: if request.auth != null 
                          && request.auth.uid == userId;
    }
  }
}

📸 Screens (Optional)

You can add screenshots later:

/screenshots/login.png
/screenshots/home.png
/screenshots/add_transaction.png

🎯 Learning Outcomes

Firebase Authentication integration

Firestore CRUD operations

State management using Provider

Clean architecture (data, state, UI layers)

Error handling & validation

Secure cloud-based app development

👨‍💻 Author

Arvind Kumar

GitHub: github.com/Arvind-kumar-08

LinkedIn: linkedin.com/in/arvind-kumar-058899323

📜 License

This project is for educational purposes.
