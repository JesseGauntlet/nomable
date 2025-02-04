# MVP Build Checklist

## 1. Prerequisites
- [x] **Install & Configure Flutter SDK**  
  - Follow the [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)  
  - Run `flutter doctor` to confirm installation  
  - Install Android Studio/Xcode for simulators  
- [x] **Install Python 3.8+**  
  - Verify by running `python --version`  
  - Consider using `venv` or `conda` for dependency management  
- [x] **Set Up Firebase CLI & Google Cloud**  
  - `npm install -g firebase-tools`  
  - (Optional) Create an account on Google Cloud if using advanced features  
- [x] **Set Up Your Code Editor or IDE**  
  - VS Code, Android Studio, PyCharm, or IntelliJ  
  - Ensure Flutter/Python plugins are installed  
- [x] **Initialize Git & Version Control**  
  - `git init` in your project folder

---

## 2. Project Structure
- [ ] **Create Two Folders**  
  - `/flutter_app`  
  - `/python_backend`  
- [ ] **Link With API Calls** between Flutter (frontend) and Python (backend)

---

## 3. Flutter Frontend
1. **Create Flutter Project**  
   - [ ] Run `flutter create flutter_app`
   - [ ] Open it in your IDE
2. **Add Dependencies**  
   - [ ] In `pubspec.yaml`, add:
     ```yaml
     http: ^0.13.5
     firebase_core: ^2.0.0
     firebase_auth: ^4.0.0
     cloud_firestore: ^3.4.0
     ```
3. **Set Up Basic UI**  
   - [ ] Configure `MaterialApp` in `main.dart`  
   - [ ] Confirm “Hello TikTok MVP” or a similar placeholder is displayed  
4. **Initialize Firebase**  
   - [ ] Call `await Firebase.initializeApp()` in `main.dart`  
   - [ ] Configure your app in Firebase console (Enable Auth, Firestore, etc.)
5. **Create Pages**  
   - [ ] Simple feed screen (show test videos or placeholders)  
   - [ ] Simple upload screen (to pick or record video)  
   - [ ] Optional user profile screen
6. **API Service**  
   - [ ] Create `api_service.dart` in `lib/services/`  
   - [ ] Implement GET feed request  
   - [ ] Implement POST upload route
7. **Implement Basic UI Wiring**  
   - [ ] In feed screen, call `ApiService.getFeed()` to load mock data  

---

## 4. Python Backend
1. **Create Python Project**  
   - [ ] `mkdir python_backend` → `cd python_backend`  
   - [ ] Create and activate a virtual environment  
   - [ ] `pip install fastapi uvicorn python-multipart`
2. **Set Up `requirements.txt`**  
   - [ ] List `fastapi`, `uvicorn`, `python-multipart`
3. **Implement Minimal FastAPI App**  
   - [ ] `main.py` with sample `fake_feed` data  
   - [ ] `@app.get("/feed")` returns feed array  
   - [ ] `@app.post("/upload")` handles file uploads
4. **Test the API**  
   - [ ] Run `uvicorn main:app --reload --port 8000`  
   - [ ] Verify basic endpoints in browser/Postman
5. **(Optional) Firebase Admin**  
   - [ ] `pip install firebase-admin`  
   - [ ] Initialize credentials in `main.py` if you want to read/write Firestore or validate tokens

---

## 5. Connecting Flutter & Python
- [ ] Update `_baseUrl` in `api_service.dart` to match your server’s IP or `10.0.2.2` for the Android emulator  
- [ ] Fetch feed data on the Flutter side (e.g., feed screen)  
- [ ] Test uploading a file from Flutter to FastAPI

---

## 6. Enhancing the MVP
1. **Firebase Authentication**  
   - [ ] Move sign-up/sign-in flows to Firebase  
   - [ ] (Optional) Verify Firebase tokens in your Python backend using the Admin SDK
2. **Social Features**  
   - [ ] Implement “Food Posting” flows: capturing photos/videos, storing them in Firebase Storage (or local)  
   - [ ] Implement a “Friends List” in Firestore (or Python DB)  
   - [ ] Add basic UI components for friend profiles and friend invitations
3. **Daily Cravings & Analytics**  
   - [ ] Track daily cravings & store them in Firestore or your own DB  
   - [ ] Show any relevant charts/visuals in the Flutter app
4. **Further Cloud/Deployment**  
   - [ ] Deploy Python backend on Google Cloud Run (or Heroku, AWS, etc.)  
   - [ ] Use Firebase Hosting or Cloud Storage for serving static video/image files
5. **Iterate & Scale**  
   - [ ] Implement more robust analytics (user sign-ups, video uploads, feed views)  
   - [ ] Expand from local storage to advanced solutions (e.g., streaming data, advanced ML)

---

## 7. Completion Criteria
- [ ] You can upload videos or images from the Flutter app to the Python server (or Firebase Storage)  
- [ ] A basic feed shows existing videos, either from mock data or real uploads  
- [ ] Users can log in via Firebase Auth and see personalized info (if implemented)  
- [ ] A minimal friend list and user profiles exist (if implemented)  
- [ ] The entire pipeline (Flutter → Python → optional Firebase) is functional for the MVP
