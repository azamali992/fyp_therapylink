# TherapyLink - AI-Powered Mental Health Companion

<p align="center">
  <img src="assets/therapylink_logo.png" alt="TherapyLink Logo" width="150"/>
</p>

<p align="center">
  <strong>A cross-platform Flutter application that leverages AI to provide accessible mental health support</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.4.4+-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.4.4+-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green" alt="Platform"/>
</p>

---

## Table of Contents

- [About the Project](#about-the-project)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
- [System Design & Diagrams](#system-design--diagrams)
- [Code Snippets](#code-snippets)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Integrations](#api-integrations)
- [User Roles](#user-roles)
- [Contributors](#contributors)

---

## About the Project

**TherapyLink** is a Final Year Project (FYP) that aims to bridge the gap between individuals seeking mental health support and accessible therapeutic resources. The application provides an AI-powered psychologist chatbot, real-time sentiment analysis, mood tracking, stress-relieving activities, and tools for mental health professionals — all within a single, user-friendly mobile and web application.

The system is designed around three core pillars:
1. **AI-Driven Conversational Therapy** — An intelligent chatbot trained on therapeutic techniques to provide empathetic, supportive conversations.
2. **Mood & Sentiment Analytics** — Real-time emotion detection and historical mood tracking to help users understand their emotional patterns.
3. **Holistic Wellness Tools** — Guided meditation, breathing exercises, journaling, artistic expression, and soothing ambient sounds for stress relief.

---

## Key Features

### AI Chatbot (AI Psychologist)
- Conversational AI powered by a custom-trained model hosted on Hugging Face (RAG-based pipeline)
- Real-time sentiment analysis on user messages (via a dedicated Sentiment Analysis API with local fallback)
- Chat history persisted in Cloud Firestore per user
- Introductory dialog explaining the AI psychologist role

### Mood Analysis & Tracking
- Visual mood distribution via pie charts (Happy, Sad, Anxious, Stressed, Calm, Angry)
- Mood trend line charts over configurable time frames (Week, Month, Year)
- Mood data stored per-user in Firestore and displayed on the profile page

### Stress Relief & Wellness Toolkit
- **Relaxation Techniques:**
  - Guided breathing exercises
  - Meditation sessions
  - Visualization exercises
- **Express Yourself:**
  - Journaling with emoji support — create, edit, and review past entries
  - Artistic expression activities
- **Soothing Sounds:**
  - Ambient audio player (rain, ocean breeze, white noise, binaural beats, fireplace, starry sky)
  - Volume control, play/pause/stop functionality
- **Mood Tracker Tab:** Log daily moods with notes right from the stress relief page

### Voice Chat
- Voice-based interaction interface with waveform visualization
- Audio message playback with duration display

### Local Clinics Finder
- Google Maps integration to find nearby mental health clinics
- Google Places API for text-based clinic search with pagination
- Place details (opening hours, phone numbers)
- Favourite clinics saved to Firestore

### Professional Dashboard (Mental Health Professionals)
- Role-based access — separate dashboard for verified mental health professionals
- View aggregated user insights (emotional trends and sentiment analysis with user consent)
- Access professional resources and specialized counseling techniques
- Collaborate with the AI system as a supplementary therapy tool

### Authentication & User Management
- Email/password sign-up and sign-in with Firebase Auth
- Google Sign-In (Android, iOS, and Web)
- Phone authentication (OTP-based)
- Role-based routing: Regular Users → Main App, Professionals → Professional Dashboard
- User profile management (name, age, DOB, gender, phone, country)

### Privacy & Security
- Private account toggle
- Location access control
- Two-factor authentication support
- Data export functionality (JSON export of user data, chat logs, and posts)
- Account deletion scheduling
- Settings synced to both local storage and Firestore

### Settings & Personalization
- Adjustable font size (persisted across sessions via Provider)
- Notification preferences
- Language selection
- Profile editing

### Onboarding
- Animated concentric-transition onboarding screens introducing users to the platform

---

## Screenshots

### Onboarding & Welcome
<p align="center">
  <img src="screenshots/onboarding_screens.jpeg" alt="Onboarding Screens" width="700"/>
</p>
<p align="center"><em>Concentric-transition onboarding introducing users to TherapyLink</em></p>

### Dashboard & Profile
<p align="center">
  <img src="screenshots/dashboard_and_profile.jpeg" alt="Dashboard and Profile" width="700"/>
</p>
<p align="center"><em>Main dashboard with navigation grid and user profile screen</em></p>

### AI Psychologist — Voice & Text Chat
<p align="center">
  <img src="screenshots/ai_voice_and_text_chat.jpeg" alt="AI Voice and Text Chat" width="700"/>
</p>
<p align="center"><em>Interact with the AI therapist via text messages or voice chat</em></p>

### Nearby Clinics — Google Maps Integration
<p align="center">
  <img src="screenshots/maps_nearby_psychologists.jpeg" alt="Maps - Nearby Psychologists" width="700"/>
</p>
<p align="center"><em>Find and book nearby mental health professionals using Google Maps</em></p>

### Professional Dashboard
<p align="center">
  <img src="screenshots/professional_dashboard.jpeg" alt="Professional Dashboard" width="700"/>
</p>
<p align="center"><em>Dashboard for mental health professionals — view user insights and manage bookings</em></p>

### Stress Relief & Psychological Tests
<p align="center">
  <img src="screenshots/stress_relief_and_tests.jpeg" alt="Stress Relief and Tests" width="700"/>
</p>
<p align="center"><em>Stress-relieving activities (meditation, breathing, journaling) and psychological assessments</em></p>

### Admin Panel
<p align="center">
  <img src="screenshots/admin_panel.jpeg" alt="Admin Panel" width="700"/>
</p>
<p align="center"><em>Flutter Web admin panel for managing users, data, and system-wide settings</em></p>

---

## System Design & Diagrams

### Use Case Diagram
<p align="center">
  <img src="screenshots/system_use_case_diagram.jpeg" alt="System Use Case Diagram" width="600"/>
</p>
<p align="center"><em>How users, therapists, and AI interact within the TherapyLink system</em></p>

### Data Flow Diagrams

<table>
  <tr>
    <td align="center"><strong>DFD Level 0</strong></td>
    <td align="center"><strong>DFD Level 1</strong></td>
    <td align="center"><strong>DFD Level 2</strong></td>
  </tr>
  <tr>
    <td><img src="screenshots/dfd_level_0.png" alt="DFD Level 0" width="280"/></td>
    <td><img src="screenshots/dfd_level_1.jpeg" alt="DFD Level 1" width="280"/></td>
    <td><img src="screenshots/dfd_level_2.png" alt="DFD Level 2" width="280"/></td>
  </tr>
</table>

### System Architecture
<p align="center">
  <img src="screenshots/system_architecture.png" alt="System Architecture" width="600"/>
</p>
<p align="center"><em>Overview of system components: UI, AI engine, database, and external services</em></p>

### Class Diagram
<p align="center">
  <img src="screenshots/class_diagram.png" alt="Class Diagram" width="600"/>
</p>
<p align="center"><em>Relationships between users, AI modules, psychological tests, and sentiment analysis</em></p>

### Entity Relationship Diagram (ERD)
<p align="center">
  <img src="screenshots/erd_diagram.png" alt="ERD" width="600"/>
</p>
<p align="center"><em>How TherapyLink stores user data, conversations, mood tracking, and AI recommendations</em></p>

### Sequence Diagrams

| Diagram | Description |
|---|---|
| <img src="screenshots/seq_ai_psychologist.png" width="350"/> | **AI Psychologist Interaction** — User sends a query and receives personalized responses using NLP and sentiment analysis |
| <img src="screenshots/seq_sentiment_mood_tracking.png" width="350"/> | **Sentiment Analysis & Mood Tracking** — Monitoring user emotions and updating mood trends |
| <img src="screenshots/seq_psychological_test.png" width="350"/> | **Psychological Test Execution** — User takes a test, system evaluates it, AI provides support |
| <img src="screenshots/seq_stress_relief.png" width="350"/> | **Stress Relief Techniques** — AI provides techniques based on real-time mood analysis |
| <img src="screenshots/seq_find_nearby_clinics.png" width="350"/> | **Find Nearby Clinics** — User locates clinics for emergency or serious conditions |
| <img src="screenshots/seq_user_authentication.png" width="350"/> | **User Authentication** — Step-by-step login with authentication checks |
| <img src="screenshots/seq_admin_manage_users.png" width="350"/> | **Admin: Manage Users** — Admin manages users from login to activities |
| <img src="screenshots/seq_admin_monitor_performance.png" width="350"/> | **Admin: Monitor System Performance** — Admin monitors system and security issues |
| <img src="screenshots/seq_admin_manage_security.png" width="350"/> | **Admin: Manage Security** — Security policies, encryption, and data integrity |

---

## Code Snippets

Key code snippets from the application:

### RAG Model (AI Chatbot Backend)
<p align="center">
  <img src="screenshots/code_rag_model_1.png" alt="RAG Model Code 1" width="500"/>
  <img src="screenshots/code_rag_model_2.png" alt="RAG Model Code 2" width="500"/>
</p>
<p align="center"><em>Custom RAG (Retrieval-Augmented Generation) model powering the AI psychologist</em></p>

### Sentiment Analysis Model
<p align="center">
  <img src="screenshots/code_sentiment_analysis.jpeg" alt="Sentiment Analysis Code" width="500"/>
</p>
<p align="center"><em>Emotion detection model for real-time sentiment analysis of user messages</em></p>

### Main Menu
<p align="center">
  <img src="screenshots/code_main_menu.png" alt="Main Menu Code" width="500"/>
</p>
<p align="center"><em>Main user interface with navigation buttons for all features</em></p>

### Chat Screen (Homepage)
<p align="center">
  <img src="screenshots/code_homepage_chat.png" alt="Homepage Chat Code" width="500"/>
</p>
<p align="center"><em>Chat screen UI with real-time user sentiment display</em></p>

### Profile Page
<p align="center">
  <img src="screenshots/code_profile_page.jpeg" alt="Profile Page Code" width="500"/>
</p>
<p align="center"><em>Profile page displaying user details — email, current mood, and gender</em></p>

### Voice Chat
<p align="center">
  <img src="screenshots/code_voice_chat.png" alt="Voice Chat Code" width="500"/>
</p>
<p align="center"><em>AI therapist voice chat interface with listening state</em></p>

### Mood Analysis
<p align="center">
  <img src="screenshots/code_mood_analysis.jpeg" alt="Mood Analysis Code" width="500"/>
</p>
<p align="center"><em>Mood analysis page with overall mood distribution and sentiment breakdown</em></p>

### Sign Up & Login
<table>
  <tr>
    <td align="center"><img src="screenshots/code_signup.png" alt="Sign Up Code" width="400"/></td>
    <td align="center"><img src="screenshots/code_login.jpeg" alt="Login Code" width="400"/></td>
  </tr>
  <tr>
    <td align="center"><em>Sign up with personal details</em></td>
    <td align="center"><em>Login with email or professional credentials</em></td>
  </tr>
</table>

### Admin Panel
<p align="center">
  <img src="screenshots/code_admin_panel.jpeg" alt="Admin Panel Code" width="500"/>
</p>
<p align="center"><em>Flutter Web admin panel — user data insights, total users, and mood patterns</em></p>

---

## Architecture

The application follows a clean, layered architecture:

```
┌─────────────────────────────────────────────┐
│                  UI Layer                    │
│         (Views / Widgets / Pages)           │
├─────────────────────────────────────────────┤
│              State Management               │
│          BLoC (Chat) + Provider             │
│          (Font Size / Theme)                │
├─────────────────────────────────────────────┤
│             Repository Layer                │
│      SentimentRepo   │   ChatRepo           │
├─────────────────────────────────────────────┤
│              API / Data Layer               │
│  FirebaseApis  │  Hugging Face  │  Google   │
│  (Firestore)   │  (RAG Model)   │  (Maps)  │
├─────────────────────────────────────────────┤
│               Firebase Backend              │
│  Auth  │  Firestore  │  Cloud Functions     │
└─────────────────────────────────────────────┘
```

- **State Management:** BLoC pattern for chat (message loading, generation), Provider for app-wide settings (font size, theme)
- **Repository Pattern:** `SentimentRepo` for emotion detection (API + local fallback), `ChatRepo` for chat operations
- **Firebase Backend:** Authentication, Firestore for data persistence, Cloud Functions (TypeScript + Python)

---

## Tech Stack

| Category | Technology |
|---|---|
| **Framework** | Flutter (SDK ≥ 3.4.4) |
| **Language** | Dart |
| **State Management** | flutter_bloc, Provider |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions) |
| **AI / NLP** | Hugging Face RAG Pipeline (custom-hosted), Sentiment Analysis API, Google Generative AI (Gemini), Firebase AI |
| **Maps & Location** | Google Maps Flutter, Google Places API, Geolocator |
| **Networking** | Dio, http |
| **Charts** | fl_chart (Pie & Line charts) |
| **Audio** | audioplayers |
| **Authentication** | Firebase Auth, Google Sign-In, Phone OTP |
| **UI Components** | Material Design 3, salomon_bottom_bar, flutter_staggered_grid_view, concentric_transition, emoji_picker_flutter, flutter_svg |
| **Storage** | Cloud Firestore, SharedPreferences |
| **Security** | local_auth (biometric), permission_handler |
| **Video** | youtube_player_flutter, flutter_inappwebview |
| **Platforms** | Android, iOS, Web, Windows, macOS, Linux |

---

## Project Structure

```
lib/
├── main.dart                      # App entry point, Firebase init, auth routing
├── auth.dart                      # AuthService (email, Google, phone sign-in/up)
├── apis.dart                      # FirebaseApis (Firestore CRUD, Hugging Face bot API)
├── firebase_options.dart          # Firebase configuration
├── welcomepage.dart               # Welcome / landing page
│
├── bloc/                          # BLoC state management
│   ├── chat_bloc.dart             # Chat BLoC (load messages, generate responses)
│   ├── chat_event.dart            # Chat events
│   └── chat_state.dart            # Chat states
│
├── models/
│   └── chat_message_model.dart    # Chat message data model
│
├── repos/
│   ├── chat_repo.dart             # Chat repository
│   └── sentiment_repo.dart        # Sentiment analysis (API + local fallback)
│
├── utils/
│   ├── colors.dart                # App color palette
│   ├── constants.dart             # UI constants (padding, font sizes)
│   ├── strings.dart               # App string resources
│   ├── user_role.dart             # UserRole enum (RegularUser, MentalHealthProfessional)
│   └── menu_item_builder.dart     # Reusable menu item widget builder
│
└── Views/
    ├── bottomnav.dart             # Bottom navigation (Chatbot, Home, Profile, Settings)
    ├── mainMenu.dart              # Main menu grid (Voice Chat, Settings, Mood, Stress Relief, Clinics)
    ├── home_page.dart             # AI Chatbot screen with sentiment indicator
    ├── voicechat.dart             # Voice chat interface
    ├── moodanalysis.dart          # Mood analysis charts (pie + trend line)
    ├── stress_relieving.dart      # Stress relief hub (4 tabs)
    ├── profilepage.dart           # User profile with mood levels
    ├── profile_info.dart          # Profile editing form
    ├── settings.dart              # App settings page
    ├── privacy_security_page.dart # Privacy & security controls
    ├── login.dart                 # Login page (email + Google)
    ├── signup.dart                # Sign-up page with profile fields
    ├── phone_auth_screen.dart     # Phone OTP authentication
    ├── onboardingpage.dart        # Concentric onboarding animation
    ├── professional_dashboard.dart# Professional user dashboard
    ├── view_user_insights.dart    # Aggregated user sentiment reports
    ├── custom_app_bar.dart        # Custom app bar widget
    ├── font_size_provider.dart    # Font size ChangeNotifier
    ├── theme_provider.dart        # Theme provider
    │
    ├── relaxtion/                 # Relaxation techniques
    │   ├── breathing_exercise_list_page.dart
    │   ├── breathing_exercise_detail_page.dart
    │   ├── breathing_exercise_model.dart
    │   ├── meditation_list_page.dart
    │   ├── meditation_detail_page.dart
    │   ├── meditation_model.dart
    │   ├── visualization_exercise_list_page.dart
    │   ├── visualization_exercise_detail_page.dart
    │   └── visualization_exercise_model.dart
    │
    ├── express your self/         # Self-expression tools
    │   ├── journal_page.dart
    │   ├── journal_entries_list.dart
    │   ├── artistic_expression_list_page.dart
    │   └── artistic_expression_detail_page.dart
    │
    └── maps/                      # Clinic finder
        ├── google_places_service.dart
        └── map 2.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.4.4
- Dart SDK ≥ 3.4.4
- Firebase project configured (Auth, Firestore, Cloud Functions)
- Google Maps API key (for clinic finder)
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-username>/fyp_therapylink.git
   cd fyp_therapylink
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`
   - Ensure `firebase_options.dart` is configured for your project

4. **Set up API keys:**
   - Configure your Google Maps API key in the Android manifest and iOS plist
   - The Hugging Face RAG endpoint and Sentiment Analysis API are pre-configured in the codebase

5. **Run the app:**
   ```bash
   flutter run
   ```

---

## API Integrations

| API | Purpose | Endpoint |
|---|---|---|
| **Hugging Face RAG** | AI chatbot responses | `https://huggingfacerag.onrender.com/predict` |
| **Sentiment Analysis** | Real-time emotion detection | `https://sentiment-analysis-ubqy.onrender.com/detect_emotion` |
| **Google Maps / Places** | Nearby clinic search, geocoding, place details | Google Maps Platform APIs |
| **Firebase Auth** | User authentication (email, Google, phone) | Firebase SDK |
| **Cloud Firestore** | Data persistence (users, messages, journals, settings) | Firebase SDK |

---

## User Roles

| Role | Access |
|---|---|
| **Regular User** | Full access to chatbot, mood analysis, stress relief tools, journaling, clinic finder, profile, and settings |
| **Mental Health Professional** | Professional dashboard with user insights, professional resources, and system collaboration tools |

Role assignment happens at sign-up and is stored in Firestore. The app routes users to the appropriate interface based on their role.

---

## Contributors

This project was developed as a **Final Year Project (FYP)** at the **University of Management and Technology (UMT), Lahore, Pakistan** — Department of Computer Science, Bachelors of Computer Science, Session Spring 2025.

| Name | Roll Number |
|---|---|
| Muhammad Zeeshan Ali | F2021266423 |
| Azam Ali | F2021266445 |
| Muhammad Ahmad Bhatti | F2021266418 |
| Muhammad Rameez | F2021105064 |

**Project Advisor:** Muhammad Awais Ali

**Project Duration:** November 2024 — July 2025

---

## License

This project is developed for academic purposes as part of a university Final Year Project.

---

<p align="center">
  <em>TherapyLink — Because mental health matters.</em>
</p>
