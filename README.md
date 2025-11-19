# MumuGym - iOS Fitness App

A comprehensive iOS fitness app built with SwiftUI and Core Data that helps users track their workouts, manage exercise templates, monitor progress, and achieve their fitness goals.

## Features

### 🔐 Authentication System
- **User Registration**: Complete signup with personal details (name, age, gender, email preferences)
- **Secure Login**: Password-protected user sessions with persistent login
- **Form Validation**: Real-time validation for all input fields
- **Password Security**: Encrypted password storage using SHA256

### 🏠 Home Dashboard
- **Personal Profile**: Welcome screen with user information
- **Weight Tracking**: Set and monitor current weight and target weight goals
- **Progress Visualization**: Visual progress indicators for weight goals
- **Quick Stats**: Weekly workout summaries (workouts completed, duration, estimated calories)
- **Quick Actions**: Fast navigation to key features (start workout, create template, log records)

### 📝 Workout Templates
- **Pre-built Templates**: Ready-to-use workouts (Push Day, Pull Day, Leg Day)
- **Custom Templates**: Create personalized workout routines
- **Exercise Library**: 20+ predefined exercises with instructions
- **Template Management**: View, edit, and delete custom templates
- **Exercise Configuration**: Set sets, reps, weight, and rest times for each exercise

### 🎯 Live Workout Sessions
- **Real-time Tracking**: Step-by-step workout guidance
- **Set Management**: Track weight and reps for each set with completion markers
- **Rest Timer**: Automatic rest period countdown with pause/resume functionality
- **Progress Navigation**: Move between exercises with previous/next controls
- **Workout Analytics**: Track total duration and exercise completion

### 📊 Workout History
- **Complete History**: View all past workouts with detailed statistics
- **Workout Details**: See exercises performed, sets completed, and duration
- **Date Organization**: Workouts grouped by date (Today, Yesterday, specific dates)
- **Performance Metrics**: Track total exercises, sets, and workout duration

### 🏆 Personal Records
- **PR Tracking**: Log and monitor personal bests for each exercise
- **1RM Calculator**: Automatic one-rep max estimation using Epley formula
- **Progress History**: View improvement over time for each exercise
- **Strength Analytics**: Calculate training percentages (75%, 85%, 95% of 1RM)
- **Record Management**: Add, view, and delete personal records

## Technical Architecture

### Core Data Models
- **User**: Store user profile and authentication data
- **Exercise**: Exercise library with names, types, and instructions
- **WorkoutTemplate**: Reusable workout configurations
- **Workout**: Individual workout sessions with completion tracking
- **PersonalRecord**: Best performances for each exercise
- **Sets and Relationships**: Complete relational structure for workout data

### SwiftUI Components
- **Modular Design**: Reusable components and view modifiers
- **Responsive UI**: Optimized for all iPhone screen sizes
- **Animations**: Smooth transitions and loading states
- **Accessibility**: VoiceOver support and accessibility identifiers

### Key Features
- **Offline First**: Full functionality without internet connection
- **Data Persistence**: Core Data for reliable local storage
- **Security**: Password hashing and secure data handling
- **Performance**: Optimized queries and efficient memory usage
- **User Experience**: Haptic feedback and intuitive navigation

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later

### Installation
1. **Clone or download the project**
2. **Open the project in Xcode**:
   ```
   open MumuGym.xcodeproj
   ```
3. **Build and run the project**:
   - Select your target device or simulator
   - Press ⌘R or click the "Run" button

### Project Structure
```
MumuGym/
├── Core/
│   ├── PersistenceController.swift       # Core Data stack
│   ├── AuthenticationManager.swift      # User authentication
│   └── ExerciseData.swift               # Predefined exercises
├── Models/
│   └── WorkoutSession.swift             # Live workout models
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   └── RegistrationView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Templates/
│   │   ├── TemplatesView.swift
│   │   ├── CreateTemplateView.swift
│   │   └── TemplateDetailView.swift
│   ├── LiveWorkout/
│   │   └── LiveWorkoutView.swift
│   ├── History/
│   │   └── HistoryView.swift
│   ├── PersonalRecords/
│   │   └── PersonalRecordsView.swift
│   ├── MainTabView.swift
│   └── SplashView.swift
├── Extensions/
│   ├── Color+Theme.swift
│   └── ViewModifiers.swift
├── Utils/
│   └── HapticManager.swift
├── MumuGym.xcdatamodeld/              # Core Data model
└── Assets.xcassets/                    # App icons and images
```

## Getting Started

### First Time Setup
1. **Launch the app** - You'll see the splash screen followed by the login screen
2. **Create an account** - Tap "Sign Up" and fill in your details
3. **Set your weight goals** - Use the home screen to set current and target weight
4. **Explore templates** - Check out the pre-built workout templates
5. **Start your first workout** - Choose a template or create a custom routine

### Using the App
1. **Home Screen**: Overview of your progress and quick actions
2. **Templates**: Browse, create, and manage workout routines
3. **Workout**: Start live workout sessions with guided tracking
4. **History**: Review past workouts and track your consistency
5. **Records**: Log personal bests and monitor strength progress

## Development Notes

### Key Design Decisions
- **Core Data**: Chosen for robust offline data persistence
- **SwiftUI**: Modern declarative UI framework for iOS
- **MVVM Pattern**: Clean separation of concerns
- **Modular Architecture**: Reusable components and easy maintenance

### Performance Optimizations
- **Lazy Loading**: Efficient list rendering for large datasets
- **Fetch Request Optimization**: Minimal Core Data queries
- **Memory Management**: Proper object lifecycle handling
- **Background Processing**: Non-blocking UI operations

### Security Considerations
- **Password Hashing**: SHA256 encryption for user passwords
- **Data Validation**: Input sanitization and validation
- **Local Storage**: Secure Core Data implementation
- **Privacy**: No external data transmission

## Future Enhancements

### Potential Features
- **Cloud Sync**: iCloud integration for cross-device synchronization
- **Social Features**: Share workouts and compete with friends
- **Advanced Analytics**: Detailed progress charts and insights
- **Apple Health Integration**: Sync with HealthKit for comprehensive tracking
- **Workout Plans**: Multi-week training programs
- **Exercise Videos**: Built-in exercise demonstrations
- **Nutrition Tracking**: Meal logging and macro tracking
- **Export Features**: PDF reports and data export options

### Technical Improvements
- **Widget Support**: iOS home screen widgets for quick stats
- **Watch App**: Apple Watch companion for workout tracking
- **Siri Integration**: Voice commands for workout logging
- **Background Processing**: Automatic workout detection
- **Machine Learning**: Personalized workout recommendations

## Support

For questions, bug reports, or feature requests, please create an issue in the project repository.

## License

This project is created for educational and personal use. Feel free to modify and expand upon it for your own projects.

---

**MumuGym** - Your journey to fitness starts here! 🏋️‍♀️💪