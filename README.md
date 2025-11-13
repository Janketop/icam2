# ICAM2 - Система видеоаналитики для контроля сотрудников

[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org/)
[![CUDA](https://img.shields.io/badge/CUDA-12.x-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-teal.svg)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎯 О проекте

ICAM2 - это современная система видеоаналитики на базе AI для автоматического контроля присутствия и активности сотрудников на рабочем месте. Система использует передовые технологии компьютерного зрения и глубокого обучения для обнаружения, отслеживания и идентификации людей в режиме реального времени.

## ✨ Основные возможности

- 🎥 **Обнаружение и отслеживание** - детекция людей с использованием YOLOv8/v9 и отслеживание с ByteTrack/BoT-SORT
- 👤 **Распознавание лиц** - идентификация сотрудников с высокой точностью (InsightFace, ArcFace)
- ⏱️ **Учет времени** - автоматическая фиксация времени прихода/ухода и присутствия
- 📊 **Анализ активности** - определение активности сотрудников (работает/не работает/отсутствует)
- 🖥️ **Web-интерфейс** - удобная панель управления с live мониторингом и аналитикой
- 🚀 **GPU ускорение** - оптимизированная обработка видео на NVIDIA GPU
- 📈 **Отчеты и статистика** - детальная аналитика и экспорт данных

## 🏗️ Архитектура

```
Video Input → Detection (YOLO) → Tracking (ByteTrack) → Face Recognition (InsightFace)
                                                              ↓
                                                    Activity Analysis (MediaPipe)
                                                              ↓
                                                        Database (PostgreSQL)
                                                              ↓
                                                        REST API (FastAPI)
                                                              ↓
                                                        Web Interface
```

## 🛠️ Технологический стек

### Backend
- **Python 3.10+** - основной язык программирования
- **PyTorch** - фреймворк для deep learning
- **Ultralytics YOLOv8** - детекция объектов
- **InsightFace** - распознавание лиц
- **MediaPipe** - анализ позы
- **FastAPI** - REST API
- **PostgreSQL** - база данных
- **SQLAlchemy** - ORM

### Computer Vision
- **YOLOv8/v9** - обнаружение людей
- **ByteTrack/BoT-SORT** - multi-object tracking
- **ArcFace** - face recognition
- **RetinaFace/MTCNN** - face detection
- **MediaPipe Pose** - pose estimation

### Frontend
- **HTML/CSS/JavaScript**
- **Bootstrap 5** - UI framework
- **Chart.js** - графики и визуализация
- **WebSocket** - real-time updates

## 📋 Требования

### Аппаратные требования
- **GPU**: NVIDIA GPU с 8GB+ VRAM (рекомендуется RTX 3060 или выше)
- **CPU**: 8+ cores
- **RAM**: 16GB+
- **Storage**: 100GB+ SSD

### Программные требования
- **OS**: Ubuntu 22.04 LTS
- **CUDA**: 12.x
- **cuDNN**: 8.x
- **Python**: 3.10+
- **PostgreSQL**: 14+

## 🚀 Быстрый старт

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-repo/icam2.git
cd icam2
```

### 2. Установка зависимостей

```bash
# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка Python пакетов
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121
```

### 3. Настройка базы данных

```bash
# Создание БД PostgreSQL
sudo -u postgres psql
CREATE DATABASE icam2;
CREATE USER icam2 WITH PASSWORD 'icam2password';
GRANT ALL PRIVILEGES ON DATABASE icam2 TO icam2;
\q

# Применение миграций
alembic upgrade head
```

### 4. Конфигурация

```bash
# Создание .env файла
cp .env.example .env
# Отредактируйте .env и укажите свои параметры
```

### 5. Запуск

```bash
# Запуск API сервера
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

Откройте браузер: http://localhost:8000

Документация API: http://localhost:8000/docs

## 📚 Документация

- 📖 [**План разработки**](DEVELOPMENT_PLAN.md) - детальный план реализации проекта
- 🏛️ [**Архитектура**](ARCHITECTURE.md) - описание архитектуры системы
- ⚡ [**Быстрый старт**](QUICKSTART.md) - шпаргалка по основным командам
- 📊 [**Приоритеты задач**](TASK_PRIORITIES.md) - приоритизация разработки

## 🎯 Статус разработки

### Текущая версия: 0.1.0 (Planning Phase)

#### ✅ Готово
- [x] Планирование архитектуры
- [x] Выбор технологий
- [x] Подготовка документации

#### 🚧 В разработке
- [ ] Настройка окружения
- [ ] Базовая структура проекта
- [ ] Core модули (detector, tracker, face recognition)

#### 📅 Запланировано
- [ ] REST API
- [ ] Web интерфейс
- [ ] Тестирование
- [ ] Оптимизация

## 🎨 Пример использования

### Регистрация сотрудника через API

```python
import requests

# Создание сотрудника
response = requests.post(
    "http://localhost:8000/api/v1/employees",
    json={
        "name": "Иван Иванов",
        "position": "Разработчик",
        "department": "IT"
    }
)
employee = response.json()

# Загрузка фотографий
for photo_path in ["photo1.jpg", "photo2.jpg", "photo3.jpg"]:
    with open(photo_path, "rb") as f:
        files = {"file": f}
        requests.post(
            f"http://localhost:8000/api/v1/employees/{employee['id']}/photos",
            files=files
        )
```

### Получение статистики

```python
# Посещаемость за сегодня
response = requests.get("http://localhost:8000/api/v1/attendance/today")
attendance = response.json()

print(f"Присутствует: {attendance['present_count']}")
print(f"Отсутствует: {attendance['absent_count']}")

# Статистика сотрудника
response = requests.get(f"http://localhost:8000/api/v1/statistics/employee/{employee_id}")
stats = response.json()

print(f"Среднее время присутствия: {stats['avg_presence_time']} часов")
print(f"Посещаемость: {stats['attendance_rate']}%")
```

## 🔧 Конфигурация

Основные параметры настраиваются через `.env` файл:

```env
# Application
APP_NAME="ICAM2 Video Analytics"
DEBUG=True

# Database
DATABASE_URL=postgresql+asyncpg://icam2:icam2password@localhost/icam2

# Models
YOLO_MODEL=yolov8n.pt
FACE_DETECTOR=retinaface
FACE_MODEL=ArcFace

# Thresholds
YOLO_CONFIDENCE=0.5
FACE_SIMILARITY_THRESHOLD=0.6

# Performance
PROCESS_FPS=5
BATCH_SIZE=4
DEVICE=cuda:0
```

## 📊 Производительность

### Целевые показатели

| Метрика | Значение |
|---------|----------|
| Latency (детекция) | < 50ms |
| Latency (распознавание) | < 100ms |
| Throughput | 10+ FPS |
| GPU Memory | < 6GB |
| Accuracy (face recognition) | > 95% |

### Реальные результаты (будут добавлены после тестирования)

## 🧪 Тестирование

```bash
# Запуск всех тестов
pytest

# С покрытием кода
pytest --cov=. --cov-report=html

# Конкретный модуль
pytest tests/test_detector.py
```

## 📈 Roadmap

### Phase 1: MVP (4 недели)
- ✅ Планирование и архитектура
- 🚧 Core функциональность (detection, tracking, recognition)
- 📅 Базовый API
- 📅 Простой web интерфейс

### Phase 2: Enhancement (2 недели)
- 📅 Анализ активности и позы
- 📅 Расширенная аналитика
- 📅 Оптимизация производительности

### Phase 3: Production Ready (2 недели)
- 📅 Полное тестирование
- 📅 Документация
- 📅 Docker/Kubernetes deployment
- 📅 Monitoring и logging

## 🔒 Безопасность и конфиденциальность

⚠️ **Важно**: Система обрабатывает биометрические данные. Необходимо:

- ✅ Получить письменное согласие сотрудников
- ✅ Соблюдать требования GDPR / ФЗ-152
- ✅ Обеспечить безопасное хранение данных
- ✅ Предоставить возможность удаления данных
- ✅ Ограничить доступ к системе
- ✅ Шифровать данные при передаче и хранении

## 🤝 Contribution

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Лицензия

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Авторы

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

## 🙏 Благодарности

- [Ultralytics](https://github.com/ultralytics/ultralytics) - YOLOv8
- [InsightFace](https://github.com/deepinsight/insightface) - Face Recognition
- [MediaPipe](https://github.com/google/mediapipe) - Pose Estimation
- [FastAPI](https://fastapi.tiangolo.com/) - Web Framework

## 📧 Контакты

- Email: support@example.com
- Website: https://example.com
- Issues: https://github.com/your-repo/icam2/issues

## ⚖️ Disclaimer

Эта система предназначена только для законного использования с согласия всех участников. Разработчики не несут ответственности за неправомерное использование программного обеспечения.

---

**Сделано с ❤️ для улучшения workplace management**
