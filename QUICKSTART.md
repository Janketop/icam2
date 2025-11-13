# Быстрый старт ICAM2

## Требования

✅ Ubuntu 22.04 LTS
✅ NVIDIA GPU (8GB+ VRAM)
✅ CUDA 12.x + cuDNN
✅ Python 3.10+
✅ PostgreSQL 14+

## Установка за 5 минут

### 1. Клонирование и настройка

```bash
# Клонирование репозитория
cd /home/user/icam2

# Создание виртуального окружения
python3 -m venv venv
source venv/bin/activate

# Установка зависимостей
pip install --upgrade pip
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121
```

### 2. Настройка базы данных

```bash
# Установка PostgreSQL
sudo apt install postgresql postgresql-contrib

# Создание БД и пользователя
sudo -u postgres psql
CREATE DATABASE icam2;
CREATE USER icam2 WITH PASSWORD 'icam2password';
GRANT ALL PRIVILEGES ON DATABASE icam2 TO icam2;
\q

# Применение миграций
alembic upgrade head
```

### 3. Конфигурация

```bash
# Создание .env файла
cat > .env << EOF
APP_NAME="ICAM2 Video Analytics"
DEBUG=True
DATABASE_URL=postgresql+asyncpg://icam2:icam2password@localhost/icam2
SECRET_KEY=$(openssl rand -hex 32)
DEVICE=cuda:0
EOF
```

### 4. Запуск

```bash
# Запуск API сервера
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

Откройте браузер: http://localhost:8000/docs

## Основные команды

### Управление зависимостями

```bash
# Установка зависимостей
pip install -r requirements.txt

# Обновление зависимостей
pip list --outdated
pip install --upgrade package_name

# Заморозка зависимостей
pip freeze > requirements.txt
```

### Работа с базой данных

```bash
# Создание новой миграции
alembic revision --autogenerate -m "Description"

# Применение миграций
alembic upgrade head

# Откат миграции
alembic downgrade -1

# Просмотр истории
alembic history

# Сброс БД (ОСТОРОЖНО!)
alembic downgrade base
```

### Запуск приложения

```bash
# Development режим (с автоперезагрузкой)
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000

# Production режим (с несколькими воркерами)
uvicorn api.main:app --workers 4 --host 0.0.0.0 --port 8000

# С использованием Gunicorn
gunicorn api.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Тестирование

```bash
# Запуск всех тестов
pytest

# Запуск с покрытием
pytest --cov=. --cov-report=html

# Запуск конкретного теста
pytest tests/test_detector.py::test_person_detection

# Запуск с логами
pytest -v -s
```

### Docker

```bash
# Сборка образа
docker build -t icam2:latest .

# Запуск контейнера
docker run --gpus all -p 8000:8000 icam2:latest

# Docker Compose
docker-compose up -d
docker-compose logs -f
docker-compose down
```

## Структура проекта (основные файлы)

```
icam2/
├── config/
│   └── settings.py          # Конфигурация
├── core/
│   ├── detector.py          # YOLO детектор
│   ├── tracker.py           # ByteTrack трекер
│   ├── face_recognition.py  # Распознавание лиц
│   └── video_processor.py   # Обработчик видео
├── api/
│   ├── main.py              # FastAPI приложение
│   └── routes/              # API endpoints
├── models/                  # ORM модели
├── services/                # Бизнес-логика
└── main.py                  # Точка входа
```

## API Quick Reference

### Employees

```bash
# Создать сотрудника
curl -X POST http://localhost:8000/api/v1/employees \
  -H "Content-Type: application/json" \
  -d '{"name": "Иван Иванов", "position": "Разработчик"}'

# Получить список
curl http://localhost:8000/api/v1/employees

# Загрузить фото
curl -X POST http://localhost:8000/api/v1/employees/{id}/photos \
  -F "file=@photo.jpg"
```

### Attendance

```bash
# Посещаемость за сегодня
curl http://localhost:8000/api/v1/attendance/today

# История сотрудника
curl http://localhost:8000/api/v1/attendance/employee/{id}

# Посещаемость за дату
curl http://localhost:8000/api/v1/attendance/date/2025-11-13
```

### Statistics

```bash
# Общая статистика
curl http://localhost:8000/api/v1/statistics/summary

# Статистика сотрудника
curl http://localhost:8000/api/v1/statistics/employee/{id}

# Экспорт отчета
curl http://localhost:8000/api/v1/statistics/export?format=csv > report.csv
```

## Конфигурация моделей

### YOLO Models

```python
# Доступные модели (в порядке увеличения точности/размера)
YOLO_MODEL = "yolov8n.pt"  # Nano   - самая быстрая
YOLO_MODEL = "yolov8s.pt"  # Small  - баланс
YOLO_MODEL = "yolov8m.pt"  # Medium
YOLO_MODEL = "yolov8l.pt"  # Large
YOLO_MODEL = "yolov8x.pt"  # XLarge - самая точная
```

### Face Recognition Models

```python
# Детекторы лиц
FACE_DETECTOR = "retinaface"  # Лучшая точность
FACE_DETECTOR = "mtcnn"       # Баланс
FACE_DETECTOR = "ssd"         # Скорость
FACE_DETECTOR = "opencv"      # Самая быстрая

# Модели распознавания
FACE_MODEL = "ArcFace"     # Рекомендуется
FACE_MODEL = "FaceNet"
FACE_MODEL = "VGG-Face"
FACE_MODEL = "OpenFace"
```

## Настройка производительности

### GPU Memory

```python
# Для GPU с 4GB VRAM
YOLO_MODEL = "yolov8n.pt"
BATCH_SIZE = 1
PROCESS_FPS = 3

# Для GPU с 8GB VRAM
YOLO_MODEL = "yolov8s.pt"
BATCH_SIZE = 4
PROCESS_FPS = 5

# Для GPU с 16GB+ VRAM
YOLO_MODEL = "yolov8m.pt"
BATCH_SIZE = 8
PROCESS_FPS = 10
```

### TensorRT Optimization

```python
# Экспорт модели в TensorRT
from ultralytics import YOLO

model = YOLO("yolov8n.pt")
model.export(format="engine", device=0)  # Создаст yolov8n.engine

# Использование TensorRT модели
model = YOLO("yolov8n.engine")
results = model(frame)
```

## Troubleshooting

### Проблема: CUDA out of memory

```python
# Решение 1: Уменьшить batch size
BATCH_SIZE = 1

# Решение 2: Уменьшить разрешение
FRAME_WIDTH = 640
FRAME_HEIGHT = 480

# Решение 3: Использовать меньшую модель
YOLO_MODEL = "yolov8n.pt"

# Решение 4: Очистка кэша GPU
import torch
torch.cuda.empty_cache()
```

### Проблема: Низкая точность распознавания

```python
# Решение 1: Собрать больше фото (5-10 на человека)
# Решение 2: Снизить порог сходства
FACE_SIMILARITY_THRESHOLD = 0.5  # Было 0.6

# Решение 3: Использовать более точный детектор
FACE_DETECTOR = "retinaface"  # Вместо "opencv"

# Решение 4: Улучшить освещение/качество камеры
```

### Проблема: Потеря треков

```python
# Решение 1: Увеличить max_lost_frames
MAX_LOST_FRAMES = 50  # Было 30

# Решение 2: Использовать BoT-SORT вместо ByteTrack
TRACKER_TYPE = "botsort"

# Решение 3: Снизить PROCESS_FPS для более частого обновления
PROCESS_FPS = 10  # Было 5
```

## Мониторинг GPU

```bash
# Мониторинг в реальном времени
watch -n 1 nvidia-smi

# Детальная информация
nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv

# Логирование в файл
nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv --loop=1 > gpu_log.csv
```

## Логи

```bash
# Просмотр логов приложения
tail -f logs/app.log

# Фильтрация по уровню
grep ERROR logs/app.log

# Логи за сегодня
grep $(date +%Y-%m-%d) logs/app.log
```

## Backup

```bash
# Backup базы данных
pg_dump -U icam2 icam2 > backup_$(date +%Y%m%d).sql

# Восстановление
psql -U icam2 icam2 < backup_20251113.sql

# Backup файлов сотрудников
tar -czf employees_backup_$(date +%Y%m%d).tar.gz data/employees/

# Восстановление
tar -xzf employees_backup_20251113.tar.gz
```

## Production Checklist

- [ ] Обновить SECRET_KEY в .env
- [ ] Установить DEBUG=False
- [ ] Настроить HTTPS (SSL сертификаты)
- [ ] Настроить firewall (ufw)
- [ ] Включить автозапуск (systemd)
- [ ] Настроить backup базы данных
- [ ] Настроить мониторинг (Prometheus/Grafana)
- [ ] Настроить логирование (ELK Stack)
- [ ] Проверить GDPR compliance
- [ ] Получить согласие сотрудников
- [ ] Настроить rate limiting
- [ ] Настроить CORS правильно
- [ ] Добавить healthcheck endpoints
- [ ] Протестировать на нагрузку

## Полезные ссылки

- **Документация API**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Ultralytics YOLO**: https://docs.ultralytics.com/
- **InsightFace**: https://github.com/deepinsight/insightface
- **FastAPI**: https://fastapi.tiangolo.com/
- **PostgreSQL**: https://www.postgresql.org/docs/

## Поддержка

Для вопросов и багов:
- GitHub Issues: https://github.com/your-repo/icam2/issues
- Email: support@example.com

## Лицензия

[Укажите лицензию проекта]

---

**Важно**: Убедитесь, что вы соблюдаете законодательство о защите персональных данных (GDPR, ФЗ-152) при использовании системы видеонаблюдения.
