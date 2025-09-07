# Data Structure Test

## Expected Firestore Paths

After the fix, your data should now be saved to these organized paths:

### Weight Data
```
/users/{userID}/health_data/weight/data/{uuid}
```

### Blood Sugar Data
```
/users/{userID}/health_data/blood_sugar/data/{uuid}
```

### Heart Rate Data
```
/users/{userID}/health_data/heart_rate/data/{uuid}
```

### Blood Pressure Sessions
```
/users/{userID}/health_data/bp_session/data/{uuid}
```

### Fitness Sessions
```
/users/{userID}/health_data/fitness_session/data/{uuid}
```

## What Was Fixed

1. **BPDataManager.syncHealthMetricsToFirebase()**: Now maps each metric type to the correct HealthDataType
2. **BPDataManager.syncToFirebase()**: Updated to use correct data types for health metrics
3. **BPDataManager.loadFromFirebase()**: Updated to handle the new data type structure

## Data Type Mapping

| MetricType | HealthDataType | Firestore Path |
|------------|----------------|----------------|
| .weight | .weight | `/weight/data/` |
| .bloodSugar | .bloodSugar | `/blood_sugar/data/` |
| .heartRate | .heartRate | `/heart_rate/data/` |
| .bloodPressure | .bloodPressureSession | `/bp_session/data/` |

## Test It

Try adding a weight measurement now - it should save to:
`/users/{userID}/health_data/weight/data/{uuid}`

Instead of the old path:
`/users/{userID}/health_data/health_metric/data/{uuid}`
