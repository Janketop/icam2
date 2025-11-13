# Архитектура системы ICAM2

## Общая схема

```
┌─────────────────────────────────────────────────────────────────┐
│                        Video Sources                            │
│  RTSP Cameras │ USB Webcams │ Video Files │ HTTP Streams       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Video Capture Layer                          │
│              (OpenCV / GStreamer / FFmpeg)                      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Processing Pipeline                           │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐      │
│  │   YOLO       │  │  ByteTrack   │  │  Face           │      │
│  │   Detector   │─▶│  Tracker     │─▶│  Recognition    │      │
│  │  (YOLOv8)    │  │              │  │  (InsightFace)  │      │
│  └──────────────┘  └──────────────┘  └─────────────────┘      │
│                                              │                   │
│                                              ▼                   │
│                                    ┌─────────────────┐          │
│                                    │  Pose Analyzer  │          │
│                                    │  (MediaPipe)    │          │
│                                    └─────────────────┘          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  Employee        │  │  Attendance      │  │  Analytics   │ │
│  │  Service         │  │  Service         │  │  Service     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  PostgreSQL      │  │  Vector DB       │  │  File        │ │
│  │  (Metadata)      │  │  (Embeddings)    │  │  Storage     │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API Layer (FastAPI)                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  REST Endpoints  │  WebSocket  │  Authentication         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Presentation Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐      │
│  │  Dashboard   │  │  Live Monitor│  │  Reports        │      │
│  │  (Vue.js)    │  │  (WebSocket) │  │  (Charts)       │      │
│  └──────────────┘  └──────────────┘  └─────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

## Поток данных

### 1. Video Processing Flow

```
Video Frame
    │
    ▼
┌───────────────────┐
│ Frame Preprocessing│
│ - Resize           │
│ - Normalize        │
└────────┬──────────┘
         │
         ▼
┌────────────────────┐
│ Person Detection   │
│ (YOLO)             │
│ Output: BBoxes     │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Object Tracking    │
│ (ByteTrack)        │
│ Output: Track IDs  │
└────────┬───────────┘
         │
         ├─────────────────────────┐
         │                         │
         ▼                         ▼
┌────────────────────┐    ┌────────────────────┐
│ Face Recognition   │    │ Pose Analysis      │
│ (InsightFace)      │    │ (MediaPipe)        │
│ Output: Employee   │    │ Output: Activity   │
└────────┬───────────┘    └────────┬───────────┘
         │                         │
         └───────────┬─────────────┘
                     │
                     ▼
            ┌────────────────┐
            │ Update Database│
            │ - Attendance   │
            │ - Activity Log │
            └────────┬───────┘
                     │
                     ▼
            ┌────────────────┐
            │ Broadcast WS   │
            │ (Live Updates) │
            └────────────────┘
```

### 2. Face Recognition Flow

```
Person BBox
    │
    ▼
┌─────────────────┐
│ Extract Face    │
│ Region          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Face Detection  │
│ (RetinaFace)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Face Alignment  │
│ (5 landmarks)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Extract         │
│ Embedding       │
│ (ArcFace)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Search Database │
│ (Cosine Sim)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Match Employee  │
│ (if > threshold)│
└─────────────────┘
```

### 3. Attendance Tracking Flow

```
Employee Detected
    │
    ▼
┌──────────────────────┐
│ Check Existing       │
│ Attendance Record    │
└──────┬───────────────┘
       │
       ├──── No Record ────┐
       │                    │
       │                    ▼
       │            ┌───────────────┐
       │            │ Create Record │
       │            │ - Check In    │
       │            │ - Status      │
       │            └───────┬───────┘
       │                    │
       ▼                    │
┌──────────────────┐        │
│ Update Record    │◄───────┘
│ - Last Seen      │
│ - Duration       │
│ - Activity       │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Check Timeout    │
│ (>5 min absent)  │
└──────┬───────────┘
       │
       ├──── Yes ────┐
       │              │
       │              ▼
       │      ┌───────────────┐
       │      │ Check Out     │
       │      │ - End Time    │
       │      │ - Total Time  │
       │      └───────────────┘
       │
       ▼
┌──────────────────┐
│ Continue         │
│ Monitoring       │
└──────────────────┘
```

## Модули системы

### Core Modules

#### 1. Detector (core/detector.py)
```python
class PersonDetector:
    """
    Обнаружение людей в кадре с использованием YOLO
    """
    - model: YOLO model
    - device: GPU device
    - confidence_threshold: float
    - iou_threshold: float

    Methods:
    - detect(frame) -> List[Detection]
    - detect_batch(frames) -> List[List[Detection]]
    - preprocess(frame) -> Tensor
    - postprocess(results) -> List[Detection]
```

#### 2. Tracker (core/tracker.py)
```python
class ObjectTracker:
    """
    Отслеживание объектов между кадрами
    """
    - tracker: ByteTrack/BoT-SORT
    - max_lost_frames: int
    - tracks: Dict[int, Track]

    Methods:
    - update(detections, frame) -> List[Track]
    - get_active_tracks() -> List[Track]
    - remove_lost_tracks()
    - reset()
```

#### 3. Face Recognizer (core/face_recognition.py)
```python
class FaceRecognizer:
    """
    Распознавание лиц сотрудников
    """
    - face_detector: RetinaFace/MTCNN
    - face_model: ArcFace/FaceNet
    - embedding_db: Dict[UUID, np.ndarray]
    - threshold: float

    Methods:
    - extract_face(frame, bbox) -> np.ndarray
    - get_embedding(face) -> np.ndarray
    - match_face(embedding) -> Optional[Employee]
    - register_employee(name, images) -> Employee
    - update_database()
```

#### 4. Pose Analyzer (core/pose_analyzer.py)
```python
class PoseAnalyzer:
    """
    Анализ позы и активности
    """
    - pose_model: MediaPipe Pose
    - face_mesh_model: MediaPipe Face Mesh

    Methods:
    - detect_pose(frame, bbox) -> PoseKeypoints
    - analyze_activity(pose, context) -> ActivityType
    - get_head_orientation(pose) -> HeadOrientation
    - is_looking_at_screen(pose) -> bool
```

#### 5. Video Processor (core/video_processor.py)
```python
class VideoProcessor:
    """
    Главный обработчик видеопотока
    """
    - detector: PersonDetector
    - tracker: ObjectTracker
    - face_recognizer: FaceRecognizer
    - pose_analyzer: PoseAnalyzer
    - db_service: AttendanceService

    Methods:
    - process_stream(video_source) -> AsyncGenerator
    - process_frame(frame) -> ProcessedFrame
    - update_attendance(track, employee, activity)
    - broadcast_results(tracks)
```

### Database Models

#### 1. Employee
```sql
CREATE TABLE employees (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    position VARCHAR(255),
    department VARCHAR(255),
    face_embedding BYTEA,
    photo_url VARCHAR(512),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. Attendance Record
```sql
CREATE TABLE attendance_records (
    id UUID PRIMARY KEY,
    employee_id UUID REFERENCES employees(id),
    camera_id VARCHAR(50),
    check_in TIMESTAMP NOT NULL,
    check_out TIMESTAMP,
    total_duration INTEGER,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. Activity Log
```sql
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY,
    employee_id UUID REFERENCES employees(id),
    attendance_id UUID REFERENCES attendance_records(id),
    timestamp TIMESTAMP NOT NULL,
    activity_type VARCHAR(20),
    confidence FLOAT,
    snapshot_url VARCHAR(512),
    created_at TIMESTAMP DEFAULT NOW()
);
```

## API Endpoints

### Employees
- `POST /api/v1/employees` - Create employee
- `GET /api/v1/employees` - List employees
- `GET /api/v1/employees/{id}` - Get employee
- `PUT /api/v1/employees/{id}` - Update employee
- `DELETE /api/v1/employees/{id}` - Delete employee
- `POST /api/v1/employees/{id}/photos` - Upload photos

### Attendance
- `GET /api/v1/attendance/today` - Today's attendance
- `GET /api/v1/attendance/employee/{id}` - Employee history
- `GET /api/v1/attendance/date/{date}` - Attendance by date
- `POST /api/v1/attendance/manual` - Manual check-in/out

### Statistics
- `GET /api/v1/statistics/summary` - Overall statistics
- `GET /api/v1/statistics/employee/{id}` - Employee stats
- `GET /api/v1/statistics/activity` - Activity analysis
- `GET /api/v1/statistics/export` - Export report

### Stream
- `WebSocket /api/v1/stream/live/{camera_id}` - Live video stream
- `GET /api/v1/stream/snapshot/{camera_id}` - Get snapshot

## Конфигурация

### Основные параметры

```yaml
# Application
APP_NAME: "ICAM2 Video Analytics"
DEBUG: true

# Models
YOLO_MODEL: "yolov8n.pt"  # yolov8n/s/m/l/x
FACE_DETECTOR: "retinaface"  # retinaface/mtcnn/ssd
FACE_MODEL: "ArcFace"  # ArcFace/FaceNet/VGG-Face

# Thresholds
YOLO_CONFIDENCE: 0.5
FACE_SIMILARITY_THRESHOLD: 0.6
MAX_LOST_FRAMES: 30

# Performance
PROCESS_FPS: 5
FRAME_SKIP: 5
BATCH_SIZE: 4

# GPU
DEVICE: "cuda:0"
USE_TENSORRT: false
FP16_MODE: false
```

## Производительность

### Целевые показатели

| Метрика | Значение |
|---------|----------|
| Latency (детекция) | < 50ms |
| Latency (распознавание) | < 100ms |
| Throughput | 10+ FPS |
| GPU Memory | < 6GB |
| CPU Usage | < 50% |

### Оптимизации

1. **Model Optimization**:
   - TensorRT engine
   - ONNX export
   - Quantization (FP16)
   - Pruning

2. **Batch Processing**:
   - Batch inference
   - Parallel streams
   - Frame buffering

3. **Caching**:
   - Embedding cache
   - Model cache
   - Result cache

## Безопасность

### Меры защиты

1. **Data Encryption**:
   - HTTPS/TLS
   - Database encryption
   - File encryption

2. **Authentication**:
   - JWT tokens
   - OAuth2
   - Role-based access

3. **Privacy**:
   - GDPR compliance
   - Data anonymization
   - Consent management
   - Right to deletion

4. **Audit**:
   - Access logs
   - Change tracking
   - Event logging

## Масштабирование

### Горизонтальное масштабирование

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ Worker 1 │    │ Worker 2 │    │ Worker N │
│ (GPU 1)  │    │ (GPU 2)  │    │ (GPU N)  │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────────────┴───────────────┘
                     │
                     ▼
            ┌────────────────┐
            │ Message Queue  │
            │ (RabbitMQ/Kafka)│
            └────────┬───────┘
                     │
                     ▼
            ┌────────────────┐
            │ Central DB     │
            │ (PostgreSQL)   │
            └────────────────┘
```

### Вертикальное масштабирование

- Multi-GPU inference
- Larger batch sizes
- Higher resolution models
- More parallel streams

## Мониторинг

### Метрики

1. **System Metrics**:
   - GPU utilization
   - Memory usage
   - CPU usage
   - Network I/O

2. **Application Metrics**:
   - Detection accuracy
   - Recognition accuracy
   - Processing latency
   - Throughput

3. **Business Metrics**:
   - Active employees
   - Average presence time
   - Activity distribution
   - Attendance rate

### Инструменты

- Prometheus (metrics)
- Grafana (visualization)
- ELK Stack (logs)
- Sentry (error tracking)

## Развертывание

### Production Environment

```yaml
# docker-compose.prod.yml
services:
  postgres:
    image: postgres:14

  redis:
    image: redis:7

  api:
    image: icam2:latest
    deploy:
      replicas: 2

  worker:
    image: icam2:latest
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1

  nginx:
    image: nginx:latest
```

### CI/CD Pipeline

```
Code Push → Tests → Build → Deploy
    │         │       │        │
    │         │       │        ▼
    │         │       │   ┌──────────┐
    │         │       │   │ Staging  │
    │         │       │   └────┬─────┘
    │         │       │        │
    │         │       │        ▼
    │         │       │   ┌──────────┐
    │         │       └──▶│Production│
    │         │           └──────────┘
    │         │
    │         ▼
    │    Unit Tests
    │    Integration Tests
    │    E2E Tests
    │
    ▼
GitHub Actions / GitLab CI
```
