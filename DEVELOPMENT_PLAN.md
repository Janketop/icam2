# План разработки системы видеоаналитики для контроля сотрудников

## Обзор проекта

**Цель**: Создание системы видеонаблюдения с использованием AI для идентификации сотрудников, отслеживания их присутствия и анализа активности в режиме реального времени.

**Платформа**: Ubuntu 22.04 LTS + GPU (NVIDIA CUDA)

**Ключевые возможности**:
- Обнаружение и отслеживание людей в кадре
- Распознавание лиц сотрудников
- Учет времени присутствия/отсутствия
- Анализ активности (работает/не работает)
- Web-панель для управления и аналитики

---

## Этап 1: Подготовка инфраструктуры и окружения

### 1.1 Установка системных зависимостей

**Приоритет**: Критический
**Время**: 2-3 часа

**Задачи**:

1. **Обновление системы**:
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Установка базовых инструментов**:
```bash
sudo apt install -y build-essential cmake git wget curl
sudo apt install -y python3.10 python3.10-dev python3-pip
sudo apt install -y ffmpeg libsm6 libxext6 libxrender-dev
```

3. **Установка NVIDIA CUDA Toolkit**:
```bash
# Проверка версии драйвера
nvidia-smi

# Установка CUDA 12.x
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-3
```

4. **Установка cuDNN**:
```bash
# Скачать с сайта NVIDIA (требуется регистрация)
# https://developer.nvidia.com/cudnn
sudo dpkg -i cudnn-local-repo-ubuntu2204-*.deb
sudo cp /var/cudnn-local-repo-*/cudnn-local-*-keyring.gpg /usr/share/keyrings/
sudo apt update
sudo apt install -y libcudnn8 libcudnn8-dev
```

5. **Проверка установки**:
```bash
nvcc --version
python3 -c "import torch; print(torch.cuda.is_available())"
```

### 1.2 Создание виртуального окружения Python

```bash
cd /home/user/icam2
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
```

### 1.3 Установка Python библиотек

**requirements.txt**:
```txt
# Deep Learning Framework
torch==2.1.0+cu121
torchvision==0.16.0+cu121
torchaudio==2.1.0+cu121

# Computer Vision
opencv-python-headless==4.8.1.78
ultralytics==8.0.220  # YOLOv8
supervision==0.16.0   # ByteTrack

# Face Recognition
insightface==0.7.3
onnxruntime-gpu==1.16.3
deepface==0.0.79

# Pose Estimation
mediapipe==0.10.8

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-multipart==0.0.6
websockets==12.0

# Database
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
asyncpg==0.29.0

# Utilities
pydantic==2.5.0
python-dotenv==1.0.0
pillow==10.1.0
numpy==1.24.3
pandas==2.1.3
scipy==1.11.4

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
```

**Установка**:
```bash
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121
```

---

## Этап 2: Создание структуры проекта

### 2.1 Архитектура проекта

```
icam2/
├── config/                    # Конфигурационные файлы
│   ├── __init__.py
│   ├── settings.py           # Настройки приложения
│   └── database.py           # Настройки БД
├── core/                     # Ядро системы
│   ├── __init__.py
│   ├── detector.py          # Детекция людей (YOLO)
│   ├── tracker.py           # Отслеживание (ByteTrack)
│   ├── face_recognition.py  # Распознавание лиц
│   ├── pose_analyzer.py     # Анализ позы
│   └── video_processor.py   # Обработка видеопотока
├── models/                   # ORM модели
│   ├── __init__.py
│   ├── employee.py          # Модель сотрудника
│   ├── attendance.py        # Модель посещаемости
│   └── activity.py          # Модель активности
├── api/                      # REST API
│   ├── __init__.py
│   ├── main.py              # Главный файл FastAPI
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── employees.py     # Эндпоинты сотрудников
│   │   ├── attendance.py    # Эндпоинты посещаемости
│   │   ├── statistics.py    # Эндпоинты статистики
│   │   └── stream.py        # WebSocket стрим
│   └── dependencies.py      # Зависимости API
├── services/                 # Бизнес-логика
│   ├── __init__.py
│   ├── employee_service.py
│   ├── attendance_service.py
│   └── analytics_service.py
├── schemas/                  # Pydantic схемы
│   ├── __init__.py
│   ├── employee.py
│   ├── attendance.py
│   └── statistics.py
├── database/                 # База данных
│   ├── __init__.py
│   ├── session.py           # Сессии БД
│   └── migrations/          # Alembic миграции
├── utils/                    # Утилиты
│   ├── __init__.py
│   ├── logger.py            # Логирование
│   ├── security.py          # Безопасность
│   └── helpers.py           # Вспомогательные функции
├── web/                      # Frontend
│   ├── static/              # Статические файлы
│   ├── templates/           # HTML шаблоны
│   └── index.html
├── tests/                    # Тесты
│   ├── __init__.py
│   ├── test_detector.py
│   ├── test_tracker.py
│   └── test_face_recognition.py
├── weights/                  # Веса моделей
│   ├── yolov8n.pt
│   ├── yolov8s.pt
│   └── face_models/
├── data/                     # Данные
│   ├── employees/           # Фото сотрудников
│   └── videos/              # Тестовые видео
├── logs/                     # Логи
├── .env                      # Переменные окружения
├── .gitignore
├── requirements.txt
├── README.md
├── DEVELOPMENT_PLAN.md
└── main.py                   # Точка входа
```

### 2.2 Создание базовых файлов конфигурации

**config/settings.py**:
```python
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "ICAM2 Video Analytics"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/icam2"

    # YOLO Settings
    YOLO_MODEL: str = "yolov8n.pt"
    YOLO_CONFIDENCE: float = 0.5
    YOLO_IOU_THRESHOLD: float = 0.45

    # Face Recognition
    FACE_DETECTOR: str = "retinaface"  # retinaface, mtcnn, ssd
    FACE_MODEL: str = "ArcFace"
    FACE_SIMILARITY_THRESHOLD: float = 0.6

    # Tracking
    TRACKER_TYPE: str = "bytetrack"  # bytetrack, botsort
    MAX_LOST_FRAMES: int = 30

    # Video Processing
    PROCESS_FPS: int = 5  # Обработка 5 кадров в секунду
    FRAME_SKIP: int = 5   # Пропускать каждые 5 кадров

    # GPU
    DEVICE: str = "cuda:0"
    USE_TENSORRT: bool = False

    # Security
    SECRET_KEY: str = "your-secret-key-here"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    class Config:
        env_file = ".env"

settings = Settings()
```

**.env**:
```env
APP_NAME="ICAM2 Video Analytics"
DEBUG=True
DATABASE_URL=postgresql+asyncpg://icam2:icam2password@localhost/icam2
SECRET_KEY=change-this-to-random-secret-key
DEVICE=cuda:0
```

**.gitignore**:
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/

# Models and weights
weights/*.pt
weights/*.onnx
weights/*.engine
!weights/.gitkeep

# Data
data/employees/*/
data/videos/*.mp4
logs/*.log

# Database
*.db
*.sqlite

# IDE
.vscode/
.idea/
*.swp
*.swo

# Environment
.env
.env.local

# Testing
.pytest_cache/
.coverage
htmlcov/
```

---

## Этап 3: Разработка модуля детекции объектов (YOLO)

### 3.1 Детектор людей

**core/detector.py**:

**Основные функции**:
- Загрузка модели YOLOv8/v9
- Обнаружение людей в кадре
- Фильтрация по классу "person"
- Возврат bounding boxes

**Технические детали**:
- Использование Ultralytics YOLO
- Поддержка GPU ускорения
- Настраиваемые пороги confidence и IoU
- Batch processing для нескольких кадров

**Ключевые методы**:
```python
class PersonDetector:
    def __init__(self, model_path, device, confidence_threshold)
    def detect(self, frame) -> List[Detection]
    def detect_batch(self, frames) -> List[List[Detection]]
```

### 3.2 Оптимизация детекции

**Методы оптимизации**:
1. Использование более легких моделей (yolov8n, yolov8s)
2. Снижение разрешения входного изображения
3. Batch inference для нескольких камер
4. TensorRT оптимизация (опционально)

---

## Этап 4: Реализация системы отслеживания

### 4.1 Трекер объектов

**core/tracker.py**:

**Основные функции**:
- Присвоение уникальных ID объектам
- Отслеживание движения между кадрами
- Обработка потери/возвращения объектов
- Re-identification на основе appearance features

**Выбор алгоритма**:
- **ByteTrack** - для высокой скорости (real-time)
- **BoT-SORT** - для высокой точности (сложные сцены)

**Ключевые методы**:
```python
class ObjectTracker:
    def __init__(self, tracker_type, max_lost_frames)
    def update(self, detections, frame) -> List[Track]
    def get_active_tracks() -> List[Track]
    def reset()
```

### 4.2 Управление треками

**Логика работы**:
1. Получение новых детекций
2. Предсказание позиции существующих треков
3. Ассоциация детекций с треками (Hungarian algorithm)
4. Обновление состояния треков
5. Удаление потерянных треков

---

## Этап 5: Разработка модуля распознавания лиц

### 5.1 Детекция и выравнивание лиц

**core/face_recognition.py**:

**Компоненты**:

1. **Face Detector**:
   - RetinaFace (высокая точность)
   - MTCNN (баланс скорость/точность)
   - SSD (высокая скорость)

2. **Face Alignment**:
   - Определение ключевых точек (landmarks)
   - Выравнивание по глазам
   - Нормализация размера

3. **Embedding Extractor**:
   - ArcFace (InsightFace)
   - FaceNet
   - VGG-Face

**Ключевые методы**:
```python
class FaceRecognizer:
    def __init__(self, detector_backend, model_name)
    def extract_face(self, frame, bbox) -> np.ndarray
    def get_embedding(self, face) -> np.ndarray
    def match_face(self, embedding, threshold) -> Optional[Employee]
    def register_employee(self, name, images) -> Employee
```

### 5.2 База данных эмбеддингов

**Хранение**:
- PostgreSQL для метаданных
- NumPy arrays для векторов (или специализированные векторные БД: Milvus, Faiss)

**Поиск**:
- Косинусное сходство
- Euclidean distance
- Пороговая фильтрация

**Оптимизация**:
- Индексация векторов (FAISS)
- Кэширование результатов
- Batch verification

---

## Этап 6: Создание системы базы данных

### 6.1 Модели данных

**models/employee.py**:
```python
class Employee(Base):
    id: UUID (Primary Key)
    name: str
    position: str
    department: str
    face_embedding: bytes  # NumPy array сериализованный
    photo_url: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
```

**models/attendance.py**:
```python
class AttendanceRecord(Base):
    id: UUID (Primary Key)
    employee_id: UUID (Foreign Key)
    camera_id: str
    check_in: datetime
    check_out: Optional[datetime]
    total_duration: Optional[int]  # секунды
    status: Enum (present, absent, on_break)
```

**models/activity.py**:
```python
class ActivityLog(Base):
    id: UUID (Primary Key)
    employee_id: UUID (Foreign Key)
    attendance_id: UUID (Foreign Key)
    timestamp: datetime
    activity_type: Enum (working, idle, away)
    confidence: float
    snapshot_url: Optional[str]
```

### 6.2 Миграции базы данных

**Использование Alembic**:
```bash
# Инициализация
alembic init database/migrations

# Создание миграции
alembic revision --autogenerate -m "Initial schema"

# Применение миграций
alembic upgrade head
```

### 6.3 CRUD операции

**services/employee_service.py**:
- create_employee()
- get_employee()
- update_employee()
- delete_employee()
- search_employees()

**services/attendance_service.py**:
- start_attendance()
- end_attendance()
- get_daily_attendance()
- get_employee_history()

---

## Этап 7: Реализация анализа позы и активности

### 7.1 Определение позы

**core/pose_analyzer.py**:

**Функциональность**:
- Извлечение ключевых точек тела (MediaPipe Pose)
- Определение позы (сидит, стоит, наклонен)
- Анализ направления взгляда
- Классификация активности

**Правила классификации**:
```python
# Пример логики
if person_in_workspace and head_oriented_to_screen:
    activity = "working"
elif person_in_workspace and head_not_oriented:
    activity = "idle"
else:
    activity = "away"
```

**Ключевые методы**:
```python
class PoseAnalyzer:
    def __init__(self)
    def detect_pose(self, frame, bbox) -> PoseKeypoints
    def analyze_activity(self, pose, context) -> ActivityType
    def get_head_orientation(self, pose) -> HeadOrientation
```

### 7.2 Интеграция с MediaPipe

**Преимущества MediaPipe**:
- Высокая скорость на CPU/GPU
- Легковесность
- Кроссплатформенность
- Готовые решения

**Компоненты**:
- MediaPipe Pose - скелет тела
- MediaPipe Face Mesh - направление взгляда
- MediaPipe Hands - жесты рук (опционально)

---

## Этап 8: Разработка основного обработчика видеопотока

### 8.1 Видеопроцессор

**core/video_processor.py**:

**Архитектура**:
```python
class VideoProcessor:
    def __init__(self, config):
        self.detector = PersonDetector(...)
        self.tracker = ObjectTracker(...)
        self.face_recognizer = FaceRecognizer(...)
        self.pose_analyzer = PoseAnalyzer(...)
        self.db_service = AttendanceService(...)

    async def process_stream(self, video_source):
        """
        Главный цикл обработки видео
        """
        while True:
            frame = await self.get_frame(video_source)

            # 1. Детекция людей
            detections = self.detector.detect(frame)

            # 2. Отслеживание
            tracks = self.tracker.update(detections, frame)

            # 3. Обработка каждого трека
            for track in tracks:
                # Распознавание лица
                if track.frames_since_recognition > 30:
                    face = self.face_recognizer.extract_face(frame, track.bbox)
                    employee = self.face_recognizer.match_face(face)
                    track.employee_id = employee.id if employee else None

                # Анализ активности
                pose = self.pose_analyzer.detect_pose(frame, track.bbox)
                activity = self.pose_analyzer.analyze_activity(pose)

                # Обновление БД
                await self.update_attendance(track, employee, activity)

            # 4. Отправка результатов по WebSocket
            await self.broadcast_results(tracks)
```

### 8.2 Управление видеопотоками

**Поддержка источников**:
- RTSP камеры
- USB веб-камеры
- Файлы видео
- HTTP стримы

**Декодирование**:
- OpenCV VideoCapture
- GStreamer pipeline
- FFmpeg

**Многопоточность**:
- Отдельный поток для захвата кадров
- Очередь кадров (asyncio.Queue)
- Пул воркеров для обработки

---

## Этап 9: Создание REST API (FastAPI)

### 9.1 Основное API приложение

**api/main.py**:

**Структура**:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import employees, attendance, statistics, stream

app = FastAPI(
    title="ICAM2 Video Analytics API",
    version="1.0.0",
    description="API для системы видеоаналитики"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Роуты
app.include_router(employees.router, prefix="/api/v1/employees", tags=["Employees"])
app.include_router(attendance.router, prefix="/api/v1/attendance", tags=["Attendance"])
app.include_router(statistics.router, prefix="/api/v1/statistics", tags=["Statistics"])
app.include_router(stream.router, prefix="/api/v1/stream", tags=["Stream"])
```

### 9.2 Эндпоинты

**Employees API** (api/routes/employees.py):
- `POST /api/v1/employees` - Регистрация нового сотрудника
- `GET /api/v1/employees` - Список сотрудников
- `GET /api/v1/employees/{id}` - Информация о сотруднике
- `PUT /api/v1/employees/{id}` - Обновление данных
- `DELETE /api/v1/employees/{id}` - Удаление сотрудника
- `POST /api/v1/employees/{id}/photos` - Добавление фото

**Attendance API** (api/routes/attendance.py):
- `GET /api/v1/attendance/today` - Присутствие на сегодня
- `GET /api/v1/attendance/employee/{id}` - История сотрудника
- `GET /api/v1/attendance/date/{date}` - Присутствие за дату
- `POST /api/v1/attendance/manual` - Ручная отметка

**Statistics API** (api/routes/statistics.py):
- `GET /api/v1/statistics/summary` - Общая статистика
- `GET /api/v1/statistics/employee/{id}` - Статистика сотрудника
- `GET /api/v1/statistics/activity` - Анализ активности
- `GET /api/v1/statistics/export` - Экспорт отчета

**Stream API** (api/routes/stream.py):
- `WebSocket /api/v1/stream/live/{camera_id}` - Live видео
- `GET /api/v1/stream/snapshot/{camera_id}` - Снимок

### 9.3 Аутентификация и авторизация

**JWT токены**:
```python
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    # Проверка токена
    # Возврат пользователя
```

**Роли**:
- Admin - полный доступ
- Manager - просмотр и отчеты
- Viewer - только просмотр

---

## Этап 10: Разработка веб-интерфейса

### 10.1 Технологический стек

**Frontend**:
- HTML5/CSS3/JavaScript
- Vue.js 3 или React (опционально)
- Bootstrap 5 или Tailwind CSS
- Chart.js для графиков
- WebSocket для real-time обновлений

### 10.2 Страницы интерфейса

**1. Dashboard (Главная)**:
- Текущее количество присутствующих
- Список активных сотрудников
- Графики активности за день
- Уведомления

**2. Employees (Сотрудники)**:
- Таблица всех сотрудников
- Добавление нового сотрудника
- Редактирование/удаление
- Загрузка фото для распознавания

**3. Attendance (Посещаемость)**:
- Календарь посещаемости
- Фильтры по дате, сотруднику
- Экспорт в Excel/PDF

**4. Live Monitor (Мониторинг)**:
- Просмотр live камер
- Наложение bounding boxes
- Информация о распознанных сотрудниках

**5. Statistics (Статистика)**:
- Графики присутствия
- Топ самых активных/неактивных
- Средние показатели
- Сравнение периодов

**6. Settings (Настройки)**:
- Управление камерами
- Настройка порогов распознавания
- Конфигурация уведомлений
- Управление пользователями API

### 10.3 Базовый HTML

**web/index.html**:
```html
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ICAM2 - Система видеоаналитики</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="/static/css/style.css" rel="stylesheet">
</head>
<body>
    <div id="app">
        <!-- Navigation -->
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
            <div class="container-fluid">
                <a class="navbar-brand" href="#">ICAM2</a>
                <!-- Nav items -->
            </div>
        </nav>

        <!-- Main Content -->
        <div class="container-fluid mt-4">
            <div id="content">
                <!-- Dynamic content -->
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.0.0/dist/chart.umd.js"></script>
    <script src="/static/js/app.js"></script>
</body>
</html>
```

---

## Этап 11: Интеграция и тестирование

### 11.1 Unit тесты

**tests/test_detector.py**:
```python
import pytest
from core.detector import PersonDetector

def test_detector_initialization():
    detector = PersonDetector("yolov8n.pt", "cuda:0", 0.5)
    assert detector is not None

def test_person_detection():
    detector = PersonDetector("yolov8n.pt", "cuda:0", 0.5)
    frame = load_test_image()
    detections = detector.detect(frame)
    assert len(detections) > 0
```

### 11.2 Integration тесты

**tests/test_integration.py**:
```python
async def test_full_pipeline():
    # Тест полного пайплайна: видео -> детекция -> трекинг -> распознавание
    processor = VideoProcessor(config)
    video_path = "data/videos/test.mp4"
    results = await processor.process_stream(video_path)
    assert results is not None
```

### 11.3 Нагрузочное тестирование

**Сценарии**:
- Обработка 1/4/8 камер одновременно
- Производительность при разном разрешении
- Потребление памяти GPU
- Задержка распознавания

**Инструменты**:
- pytest-benchmark
- locust для API
- nvidia-smi для мониторинга GPU

---

## Этап 12: Оптимизация производительности

### 12.1 GPU ускорение

**TensorRT оптимизация**:
```python
# Конвертация YOLO в TensorRT
from ultralytics import YOLO

model = YOLO("yolov8n.pt")
model.export(format="engine", device=0)  # TensorRT engine
```

**Batch inference**:
```python
# Обработка нескольких кадров за раз
frames_batch = [frame1, frame2, frame3, frame4]
results_batch = model(frames_batch)
```

### 12.2 Оптимизация памяти

**Методы**:
- Mixed precision (FP16 вместо FP32)
- Gradient checkpointing
- Очистка кэша GPU
- Ограничение размера очередей

### 12.3 Профилирование

**Инструменты**:
```python
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()
# Код для профилирования
profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumtime').print_stats(20)
```

**NVIDIA Nsight**:
```bash
nsys profile --trace=cuda,nvtx python main.py
```

---

## Этап 13: Документация и развертывание

### 13.1 Документация API

**Автоматическая генерация** (FastAPI):
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

**Дополнительная документация**:
- API Reference (Markdown)
- Примеры использования
- Коды ошибок

### 13.2 Инструкции по установке

**README.md**:
```markdown
# ICAM2 - Система видеоаналитики

## Требования
- Ubuntu 22.04 LTS
- NVIDIA GPU (8GB+ VRAM)
- CUDA 12.x
- Python 3.10+
- PostgreSQL 14+

## Установка
1. Клонировать репозиторий
2. Установить зависимости
3. Настроить базу данных
4. Скачать модели
5. Запустить приложение

## Использование
...
```

### 13.3 Docker контейнеризация

**Dockerfile**:
```dockerfile
FROM nvidia/cuda:12.3.0-cudnn9-runtime-ubuntu22.04

WORKDIR /app

# Install Python
RUN apt-get update && apt-get install -y python3.10 python3-pip

# Copy requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . .

# Run
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: icam2
      POSTGRES_USER: icam2
      POSTGRES_PASSWORD: icam2password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgresql+asyncpg://icam2:icam2password@postgres/icam2
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  postgres_data:
```

### 13.4 Скрипты запуска

**scripts/start.sh**:
```bash
#!/bin/bash

# Activate virtual environment
source venv/bin/activate

# Run database migrations
alembic upgrade head

# Start API server
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## Временные оценки

| Этап | Задачи | Время |
|------|--------|-------|
| 1 | Подготовка окружения | 3-4 часа |
| 2 | Структура проекта | 2-3 часа |
| 3 | Детекция (YOLO) | 1 день |
| 4 | Трекинг | 1 день |
| 5 | Распознавание лиц | 2 дня |
| 6 | База данных | 1 день |
| 7 | Анализ позы | 1-2 дня |
| 8 | Видеопроцессор | 2 дня |
| 9 | REST API | 2 дня |
| 10 | Web интерфейс | 3 дня |
| 11 | Тестирование | 2 дня |
| 12 | Оптимизация | 2 дня |
| 13 | Документация | 1 день |

**Итого**: ~20-25 рабочих дней (4-5 недель)

---

## Приоритизация

### Критические компоненты (MVP):
1. Детекция людей (YOLO)
2. Отслеживание (ByteTrack)
3. Распознавание лиц (InsightFace)
4. База данных (PostgreSQL)
5. REST API (базовые эндпоинты)
6. Простой веб-интерфейс

### Дополнительные функции:
1. Анализ позы и активности
2. Продвинутая аналитика
3. Уведомления
4. Экспорт отчетов
5. Мобильное приложение

---

## Риски и митигация

### Технические риски:

1. **Низкая производительность GPU**
   - Митигация: Использовать TensorRT, уменьшить разрешение, оптимизировать batch size

2. **Плохое качество распознавания**
   - Митигация: Собрать больше фото, использовать аугментацию, настроить пороги

3. **Потеря треков при перекрытиях**
   - Митигация: Использовать BoT-SORT, добавить re-identification

4. **Проблемы с освещением**
   - Митигация: Предобработка изображений, использование IR камер

### Юридические риски:

1. **GDPR / Защита персональных данных**
   - Митигация: Шифрование, контроль доступа, согласие сотрудников, право на удаление

2. **Биометрические данные**
   - Митигация: Хранить только embeddings, не raw изображения

---

## Следующие шаги

После согласования плана:

1. ✅ Подготовка окружения и установка зависимостей
2. ✅ Создание базовой структуры проекта
3. ✅ Разработка core модулей (detector, tracker, face_recognition)
4. ✅ Интеграция с базой данных
5. ✅ Создание API
6. ✅ Разработка интерфейса
7. ✅ Тестирование и оптимизация

---

## Контакты и поддержка

Для вопросов по реализации обращайтесь к документации или создавайте issues в репозитории.
