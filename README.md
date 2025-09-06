# PureBP - Blood Pressure Tracker

A professional iOS app for tracking blood pressure readings with comprehensive analysis and trends.

## Features

### 📊 **Session Management**
- Manual entry of systolic, diastolic, and heart rate values
- Up to 5 readings per session with automatic averaging
- Start/stop session control
- Manual date/time entry for historical readings

### 📈 **Trends Analysis**
- Interactive charts showing blood pressure trends over time
- Combined systolic/diastolic graph for easy comparison
- Individual metric analysis (systolic, diastolic, heart rate)
- Multiple time ranges (week, month, 3 months, year)

### 📅 **Daily View**
- Day-by-day session review
- Expandable session details
- Individual reading breakdown
- BP category indicators (Normal, Elevated, Stage 1, Stage 2, Crisis)

### 👤 **Profile & Statistics**
- User profile management
- Overall statistics and averages
- Recent activity tracking
- Session count and reading totals

## Technical Details

- **Platform:** iOS 17.0+
- **Framework:** SwiftUI
- **Architecture:** MVVM pattern
- **Data Persistence:** UserDefaults
- **Charts:** SwiftUI Charts framework

## App Structure

```
PureBP/
├── PureBPApp.swift          # Main app entry point
├── ContentView.swift        # Tab view container
├── SessionView.swift        # Main entry and session management
├── DailyReadingsView.swift  # Daily readings with session details
├── TrendsView.swift         # Interactive charts and trends
├── ProfileView.swift        # User profile and statistics
├── BloodPressureReading.swift # Data model for individual readings
├── BPSession.swift         # Data model for reading sessions
└── BPDataManager.swift     # Data management and persistence
```

## Key Features

### 🎯 **Professional UI**
- Medical-grade design with proper color coding
- Large, accessible input fields
- Clean visual hierarchy
- Professional card-based layout

### 📊 **Comprehensive Analytics**
- Real-time session averaging
- Historical trend analysis
- Statistical summaries
- Visual health indicators

### 🔒 **Data Management**
- Local data storage
- Session-based organization
- Manual timestamp entry
- Data export capabilities

## Getting Started

1. Open `PureBP.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+

## License

This project is available for personal and educational use.
