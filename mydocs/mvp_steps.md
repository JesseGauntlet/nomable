# MVP Implementation Steps: Flutter Frontend & Python Backend

This guide walks you through creating a basic TikTok-like app MVP with a **Flutter** frontend and a **Python** backend. It assumes you have some familiarity with basic development and command-line tools. If you are entirely new to either Flutter or Python, consider reviewing the official documentation first.

---

## 1. Prerequisites

1. **Flutter SDK**  
   - [Installation Guide](https://docs.flutter.dev/get-started/install)
   - Confirm Flutter is installed:
     ```bash
     flutter doctor
     ```
   - Install Android Studio or Xcode if you plan to run on Android/iOS simulators.

2. **Python 3.8+**  
   - Verify your Python installation:
     ```bash
     python --version
     ```
   - Recommend using a virtual environment (e.g., `venv`, `conda`) for dependency management.

3. **Firebase CLI & Google Cloud**  
   - Install the Firebase CLI if you plan to deploy or host services through Firebase:
     ```bash
     npm install -g firebase-tools
     ```
   - You may also want a Google Cloud account if you'll be integrating more advanced services (Cloud Functions, Firestore, etc.).

4. **Code Editor / IDE**  
   - Visual Studio Code, Android Studio, PyCharm, or IntelliJ can all work.  
   - Make sure you have the Flutter and Python plugins/extensions installed where possible.

5. **Git & Version Control**  
   - Initialize a Git repo for your project.

---

## 2. Project Structure Overview

We'll keep things simple by creating two main folders: 
my_tiktok_mvp/
├─ flutter_app/ (Flutter frontend)
└─ python_backend/ (Python backend)

Each sub-project will be handled separately. We'll link them together via API calls.

---

## 3. Set Up the Flutter Frontend

### 3.1 Create a New Flutter Project

1. Navigate to your preferred directory in a terminal, then run:
   ```bash
   flutter create flutter_app
   ```
2. Open `flutter_app` in your preferred IDE or code editor.

### 3.2 Main Dependencies & Folder Structure

1. By default, Flutter creates:
   ```
   flutter_app/
     ├─ android/
     ├─ ios/
     ├─ lib/
     └─ test/
   ```
2. We'll focus on the `lib/` folder for our Dart code. Inside `lib/`, you may create folders like `services/`, `models/`, `screens/` for better organization.

3. In your `pubspec.yaml`, you could add dependencies:
   ```yaml
   dependencies:
     http: ^0.13.5
     firebase_core: ^2.0.0
     firebase_auth: ^4.0.0
     cloud_firestore: ^3.4.0
     # other dependencies for video recording or UI libraries
   ```
   - `http` allows you to make HTTP requests to your Python backend.
   - Additional packages (e.g., `camera`, `video_player`) can be added later.

### 3.3 Building Pages & Basic UI Flows

1. Open `lib/main.dart` and ensure the basic `MaterialApp` is set up:
   ```dart
   import 'package:flutter/material.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(const MyApp());
   }

   class MyApp extends StatelessWidget {
     const MyApp({Key? key}) : super(key: key);

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'TikTok MVP',
         home: Scaffold(
           appBar: AppBar(
             title: const Text('MVP Demo'),
           ),
           body: const Center(
             child: Text('Hello TikTok MVP'),
           ),
         ),
       );
     }
   }
   ```
2. Create a simple page for uploading videos, a feed, and user profile. Keep everything minimal—hardcode a few items (e.g., sample video URLs) to test the UI.

3. (Optional) If you want to record videos, look into plugins like [`camera`](https://pub.dev/packages/camera) or [`image_picker`](https://pub.dev/packages/image_picker).

### 3.4 Making API Calls to Your Backend

1. In `lib/services/`, create a file called `api_service.dart`.  
2. Use the `http` package to make basic requests to your Python backend—e.g., for uploading a video or fetching a feed:
   ```dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;

   class ApiService {
     static const String _baseUrl = 'http://127.0.0.1:8000'; // or your server address

     static Future<List<dynamic>> getFeed() async {
       final response = await http.get(Uri.parse('$_baseUrl/feed'));
       if (response.statusCode == 200) {
         return jsonDecode(response.body);
       } else {
         throw Exception('Failed to load feed');
       }
     }

     // Add more methods (e.g., uploadVideo, login, etc.)
   }
   ```
3. Integrate these methods in your UI (e.g., in a feed screen) to verify data flow.

### 3.5 Firebase Initialization (New)
1. Initialize Firebase in your Flutter project. For example, in `main.dart`:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(const MyApp());
   }
   ```
2. Configure your app in the Firebase console to enable services like Authentication or Firestore.

---

## 4. Set Up the Python Backend

### 4.1 Create a New Python Project

1. Inside your `my_tiktok_mvp` folder, create a `python_backend` folder:
   ```
   my_tiktok_mvp/
     ├─ flutter_app/
     └─ python_backend/
   ```
2. Navigate to `python_backend` and create/activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Mac/Linux
   # or venv\Scripts\activate (Windows)
   ```
3. Install FastAPI, Uvicorn, and any other dependencies:
   ```bash
   pip install fastapi uvicorn python-multipart
   ```
   - `fastapi` helps in quickly setting up a RESTful API.  
   - `python-multipart` is needed for file uploads.

### 4.2 Basic File Structure

```
python_backend/
  ├─ venv/
  ├─ main.py
  └─ requirements.txt
```

Update `requirements.txt` by adding:
```
fastapi
uvicorn
python-multipart
```

### 4.3 minimal FastAPI App (main.py)

```python
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse

app = FastAPI()

# In-memory data stores for quick testing (no real DB yet)
fake_feed = [
    {"video_url": "https://example.com/v/video1.mp4", "likes": 10},
    {"video_url": "https://example.com/v/video2.mp4", "likes": 20},
]

@app.get("/feed")
def get_feed():
    """
    Return a list of videos (URLs, like counts, etc.).
    In a real app, you'd query a database.
    """
    return fake_feed

@app.post("/upload")
async def upload_video(file: UploadFile = File(...)):
    """
    Handle file uploads. Save the file to storage (local or cloud),
    then return a status.
    """
    # Example: save file locally (not recommended for production)
    with open(f"./uploaded_videos/{file.filename}", "wb") as buffer:
        buffer.write(await file.read())
    return JSONResponse({"detail": "Video uploaded successfully"})
```

4. **Run the server**:
   ```bash
   uvicorn main:app --reload --port 8000
   ```
   - By default, your API is at `http://127.0.0.1:8000`.

### 4.4 Testing API Endpoints

- **Feed**: In your browser or using a tool like [Postman](https://www.postman.com/), make a GET request to `http://127.0.0.1:8000/feed`. You should see the `fake_feed` data.  
- **Upload**: Make a POST request with a file to `http://127.0.0.1:8000/upload`. Confirm the file is saved in `./uploaded_videos/`.

### 4.4 Firebase / Google Cloud Integration (Optional)
If you choose to store some data (e.g., user credentials, analytics) in Firebase from the Python side, you might:
1. Use the Firebase Admin SDK for Python:
   ```bash
   pip install firebase-admin
   ```
2. Initialize the admin app in your `main.py` (or similar):
   ```python
   import firebase_admin
   from firebase_admin import credentials, firestore

   cred = credentials.Certificate("path_to_service_account.json")
   firebase_admin.initialize_app(cred)
   db = firestore.client()
   ```
3. Store video metadata, user preferences, or friend relationships in Firestore.  
   *Alternatively*, keep using your local or any other DB for the FastAPI portion and let the Flutter app communicate with Firebase directly for authentication.

---

## 5. Connecting Flutter to Python

1. In your Flutter app, change the base URL in `api_service.dart` to point to your local server if you're using an emulator:
   ```dart
   static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator
   ```
   - If you're running on a physical device, ensure your app can reach your development machine (e.g., use the machine's LAN IP).

2. Fetch the feed data in your feed screen:
   ```dart
   Future<void> loadFeed() async {
     try {
       final data = await ApiService.getFeed();
       setState(() {
         feedData = data;
       });
     } catch (e) {
       print('Error fetching feed: $e');
     }
   }
   ```
3. Create a simple UI to display these videos (you can start by just showing text or placeholders).

4. For uploading:
   - Integrate a file picker or camera plugin.
   - Send the file to the Python backend endpoint:
     ```dart
     Future<void> uploadVideo(File videoFile) async {
       var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
       request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
       var response = await request.send();
       if (response.statusCode == 200) {
         // handle success
       } else {
         // handle error
       }
     }
     ```

---

## 6. Enhancing the MVP

1. **Firebase Authentication**  
   - Move user sign-up/sign-in flows to Firebase.  
   - The Python backend can verify Firebase tokens if needed via the Firebase Admin SDK.

2. **New Social Features (from @PRD.md)**  
   - **Food Posting** and pictures/videos appear on user profiles. In the MVP, you can store these in Firebase Storage or on your Python server.  
   - **Friends List** can be maintained in Firestore (or the Python backend).  
   - Basic UI elements (friend profiles, add friend button) should match the user stories in the PRD.

3. **Daily Cravings & Analytics**  
   - Use Firestore or your own database to track daily cravings.  
   - You can expand to show personal analytics in real time.

4. **Further Cloud Integrations**  
   - Host your Python backend on Google Cloud Run or a similar service for scalability.  
   - Serve static assets (video or images) via Firebase Hosting or Cloud Storage.

---

## 7. Summary
Your updated MVP now taps into Firebase's Authentication, Firestore, and optional Hosting/Storage, aligning with the **@PRD.md** requirements. Key additional steps:
- Initialize Firebase in Flutter for user auth and data.  
- Optionally integrate Firebase Admin in Python.  
- Expand social features (photo/video posts, friend lists) per the updated PRD.  
- Gradually replace local in-memory or local-file storage with cloud-based solutions for scaling.

This foundation should be enough for a junior engineer to explore the necessary steps, build core functionality, and incrementally add features that transform it into a more robust, TikTok-like application.