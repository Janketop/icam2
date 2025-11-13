#!/bin/bash
# Продолжение установки ICAM2 после создания requirements.txt

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      ICAM2 - Продолжение установки (Шаги 8-10)           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Шаг 8: Установка зависимостей
echo "Шаг 8/10: Установка зависимостей проекта..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "requirements.txt" ]; then
    source venv/bin/activate
    echo "Это займет 5-10 минут, подождите..."
    echo "Установка PyTorch с GPU (CUDA 12.1) поддержкой..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    echo "Установка остальных зависимостей..."
    pip install opencv-python-headless==4.9.0.80 ultralytics supervision insightface \
        onnxruntime-gpu fastapi uvicorn[standard] python-multipart websockets aiofiles \
        sqlalchemy alembic psycopg2-binary asyncpg pydantic pydantic-settings python-dotenv \
        pillow numpy scipy python-jose[cryptography] passlib[bcrypt] python-dateutil pytz \
        pydantic-core pytest pytest-asyncio pytest-cov httpx
    print_status "Зависимости установлены (GPU версия)"
else
    print_warning "requirements.txt не найден!"
    exit 1
fi

echo ""
echo "Шаг 9/10: Создание структуры директорий..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p config core models api services schemas database utils tests weights data logs
mkdir -p api/routes
mkdir -p data/{employees,videos,test_videos,benchmarks}
mkdir -p database/migrations
mkdir -p web/{static,templates}
mkdir -p web/static/{css,js,images}

# Создание __init__.py файлов
touch config/__init__.py
touch core/__init__.py
touch models/__init__.py
touch api/__init__.py
touch api/routes/__init__.py
touch services/__init__.py
touch schemas/__init__.py
touch database/__init__.py
touch utils/__init__.py
touch tests/__init__.py

# Создание .gitkeep для пустых директорий
touch weights/.gitkeep
touch logs/.gitkeep
touch data/employees/.gitkeep
touch data/videos/.gitkeep

print_status "Структура директорий создана"

echo ""
echo "Шаг 10/10: Создание .env файла..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_status ".env файл создан из .env.example"
    else
        print_warning ".env.example не найден, создаем базовый .env"
        cat > .env << 'EOF'
APP_NAME="ICAM2 Video Analytics"
DEBUG=True
DATABASE_URL=postgresql+asyncpg://icam2:icam2password@localhost/icam2
SECRET_KEY=change-this-secret-key
DEVICE=cpu
YOLO_MODEL=yolov8n.pt
FACE_DETECTOR=retinaface
PROCESS_FPS=3
EOF
        print_status "Базовый .env файл создан"
    fi
else
    print_warning ".env файл уже существует"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Установка полностью завершена! ✓             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Установленные компоненты:"
echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
echo "  ✓ PyTorch (CPU версия)"
echo "  ✓ Ultralytics YOLO"
echo "  ✓ InsightFace"
echo "  ✓ FastAPI"
echo "  ✓ PostgreSQL (база icam2)"
echo "  ✓ Структура проекта"
echo ""
echo "🎯 Проверьте установку:"
echo "  source venv/bin/activate"
echo "  python -c 'import torch; import ultralytics; print(\"OK\")"'"
echo ""
echo "📁 Структура проекта:"
tree -L 2 -I 'venv|__pycache__|*.pyc' . 2>/dev/null || ls -la

echo ""
echo "🚀 Следующие шаги:"
echo ""
echo "  1. Активируйте виртуальное окружение:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Проверьте PostgreSQL:"
echo "     sudo service postgresql status"
echo "     # Если не запущен: sudo service postgresql start"
echo ""
echo "  3. (Опционально) Запустите PoC тест:"
echo "     python poc_simple.py"
echo ""
echo "  4. Скажите мне: 'Начинаем разработку!'"
echo ""
