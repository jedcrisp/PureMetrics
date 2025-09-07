# Organized Health Data Structure

## Visual Representation

```
📁 users/
  └── 📁 {userID}/
      └── 📁 health_data/
          ├── 📁 weight/
          │   └── 📁 data/
          │       ├── 📄 {uuid1} → {weight: 150.5, unit: "lbs", timestamp: ...}
          │       ├── 📄 {uuid2} → {weight: 151.2, unit: "lbs", timestamp: ...}
          │       └── 📄 {uuid3} → {weight: 149.8, unit: "lbs", timestamp: ...}
          │
          ├── 📁 blood_sugar/
          │   └── 📁 data/
          │       ├── 📄 {uuid1} → {value: 100, unit: "mg/dL", timestamp: ...}
          │       └── 📄 {uuid2} → {value: 95, unit: "mg/dL", timestamp: ...}
          │
          ├── 📁 heart_rate/
          │   └── 📁 data/
          │       ├── 📄 {uuid1} → {value: 72, unit: "bpm", timestamp: ...}
          │       └── 📄 {uuid2} → {value: 68, unit: "bpm", timestamp: ...}
          │
          ├── 📁 bp_session/
          │   └── 📁 data/
          │       ├── 📄 {uuid1} → {BPSession object with readings}
          │       └── 📄 {uuid2} → {BPSession object with readings}
          │
          └── 📁 fitness_session/
              └── 📁 data/
                  ├── 📄 {uuid1} → {FitnessSession object with exercises}
                  └── 📄 {uuid2} → {FitnessSession object with exercises}
```

## Key Improvements

### ✅ **Before (Mixed Structure)**
```
users/{userID}/health_data/
├── health_metric_{uuid} (weight)
├── health_metric_{uuid} (blood sugar)
├── bp_session_{uuid}
└── fitness_session_{uuid}
```

### ✅ **After (Organized by Type)**
```
users/{userID}/health_data/
├── weight/data/{uuid}
├── blood_sugar/data/{uuid}
├── heart_rate/data/{uuid}
├── bp_session/data/{uuid}
└── fitness_session/data/{uuid}
```

## Benefits

1. **🎯 Clean Organization**: Each data type has its own dedicated folder
2. **🔍 Easy Navigation**: Find weight data in `/weight/`, BP data in `/bp_session/`
3. **⚡ Better Performance**: Queries are faster when targeting specific data types
4. **📈 Scalable**: Easy to add new data types (e.g., `/sleep/`, `/mood/`)
5. **🔄 Backward Compatible**: Existing code continues to work
6. **📊 Better Analytics**: Easier to analyze trends for specific metrics

## Data Type Mapping

| Health Data | Folder Path | Collection |
|-------------|-------------|------------|
| Weight | `/weight/data/` | Individual weight measurements |
| Blood Sugar | `/blood_sugar/data/` | Blood glucose readings |
| Heart Rate | `/heart_rate/data/` | Heart rate measurements |
| Blood Pressure | `/bp_session/data/` | BP reading sessions |
| Fitness | `/fitness_session/data/` | Workout sessions |

## Usage

The FirestoreService automatically organizes data into the appropriate folders based on the data type, making it much cleaner and easier to manage your health data!
