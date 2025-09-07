# Organized Health Data Structure

## Overview
All user health data is now organized under a single `health_data` collection in Firestore, with separate subcollections for each data type. This provides a clean, organized structure that's easy to navigate and query.

## Firestore Structure

```
users/
  {userID}/
    health_data/
      weight/
        data/
          {uuid}/
            - type: "weight"
            - value: 150.5
            - unit: "lbs"
            - timestamp: 2024-01-15T10:30:00Z
            - createdAt: 2024-01-15T10:30:00Z
            - updatedAt: 2024-01-15T10:30:00Z
      
      blood_sugar/
        data/
          {uuid}/
            - type: "blood_sugar"
            - value: 100.0
            - unit: "mg/dL"
            - timestamp: 2024-01-15T10:30:00Z
            - createdAt: 2024-01-15T10:30:00Z
            - updatedAt: 2024-01-15T10:30:00Z
      
      heart_rate/
        data/
          {uuid}/
            - type: "heart_rate"
            - value: 72.0
            - unit: "bpm"
            - timestamp: 2024-01-15T10:30:00Z
            - createdAt: 2024-01-15T10:30:00Z
            - updatedAt: 2024-01-15T10:30:00Z
      
      bp_session/
        data/
          {uuid}/
            - dataType: "bp_session"
            - {BPSession object data}
            - timestamp: 2024-01-15T10:30:00Z
            - createdAt: 2024-01-15T10:30:00Z
            - updatedAt: 2024-01-15T10:30:00Z
      
      fitness_session/
        data/
          {uuid}/
            - dataType: "fitness_session"
            - {FitnessSession object data}
            - timestamp: 2024-01-15T10:30:00Z
            - createdAt: 2024-01-15T10:30:00Z
            - updatedAt: 2024-01-15T10:30:00Z
```

## Data Types

### HealthDataType Enum
- `health_metric`: Individual health measurements (weight, blood pressure, blood sugar, heart rate)
- `bp_session`: Blood pressure reading sessions
- `fitness_session`: Fitness workout sessions
- `weight`: Weight measurements (legacy support)
- `blood_sugar`: Blood sugar measurements (legacy support)
- `heart_rate`: Heart rate measurements (legacy support)

### UnifiedHealthData Model
The `UnifiedHealthData` struct contains:
- `id`: UUID identifier
- `dataType`: Type of health data
- `timestamp`: When the data was recorded
- Optional fields based on data type:
  - `metricType`, `value`, `unit`: For health metrics
  - `bpSession`: For blood pressure sessions
  - `fitnessSession`: For fitness sessions

## Benefits

1. **Organized Storage**: Each data type has its own folder for easy navigation
2. **Clean Structure**: Weight data goes in `/weight/`, BP data in `/bp_session/`, etc.
3. **Easy Querying**: Can query specific data types or all data
4. **Consistent Structure**: Same base structure for all data types
5. **Scalable**: Easy to add new data types with their own folders
6. **Backward Compatible**: Legacy methods still work
7. **Better Performance**: Queries are faster when targeting specific data types

## Usage Examples

### Save Health Data
```swift
// Save a weight measurement
let weightData = UnifiedHealthData(
    id: UUID(),
    dataType: .healthMetric,
    metricType: .weight,
    value: 150.5,
    unit: "lbs",
    timestamp: Date()
)
firestoreService.saveHealthData([weightData])

// Save a blood pressure session
let bpData = UnifiedHealthData(
    id: session.id,
    dataType: .bloodPressureSession,
    bpSession: session,
    timestamp: session.startTime
)
firestoreService.saveHealthData([bpData])
```

### Load Health Data
```swift
// Load all health data
firestoreService.loadHealthData { result in
    // Handle all health data
}

// Load only blood pressure sessions
firestoreService.loadHealthData(dataType: .bloodPressureSession) { result in
    // Handle BP sessions only
}
```

## Migration

The existing methods (`saveHealthMetrics`, `saveBPSessions`, `saveFitnessSessions`) now use the unified structure internally, so no changes are needed in your existing code.
