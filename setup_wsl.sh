#!/bin/bash
# ICAM2 Setup Script for WSL2 Ubuntu 22.04
# Автоматическая настройка окружения разработки

set -e  # Остановить при ошибке

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         ICAM2 - Настройка WSL2 окружения                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Проверка что мы в WSL
if ! grep -qi microsoft /proc/version; then
    print_warning "Похоже, это не WSL. Скрипт оптимизирован для WSL2."
    read -p "Продолжить? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Шаг 1/10: Обновление системы..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt update
sudo apt upgrade -y
print_status "Система обновлена"

echo ""
echo "Шаг 2/10: Установка базовых инструментов..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common
print_status "Базовые инструменты установлены"

echo ""
echo "Шаг 3/10: Установка Python 3.10+ и инструментов..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev
print_status "Python $(python3 --version) установлен"

echo ""
echo "Шаг 4/10: Установка PostgreSQL..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt install -y postgresql postgresql-contrib
sudo service postgresql start
print_status "PostgreSQL установлен"

echo ""
echo "Шаг 5/10: Настройка PostgreSQL..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Создание пользователя и базы данных
sudo -u postgres psql -c "CREATE DATABASE icam2;" 2>/dev/null || print_warning "База icam2 уже существует"
sudo -u postgres psql -c "CREATE USER icam2 WITH PASSWORD 'icam2password';" 2>/dev/null || print_warning "Пользователь icam2 уже существует"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE icam2 TO icam2;" 2>/dev/null || true
print_status "PostgreSQL настроен (база: icam2, пользователь: icam2)"

echo ""
echo "Шаг 6/10: Создание виртуального окружения Python..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_status "Виртуальное окружение создано"
else
    print_warning "Виртуальное окружение уже существует"
fi

echo ""
echo "Шаг 7/10: Активация venv и установка базовых пакетов..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
source venv/bin/activate
pip install --upgrade pip setuptools wheel
print_status "pip обновлен"

echo ""
echo "Шаг 8/10: Установка зависимостей проекта..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "requirements.txt" ]; then
    print_warning "requirements.txt еще не создан, установим базовые пакеты..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    pip install \
        ultralytics \
        opencv-python-headless \
        insightface \
        onnxruntime \
        fastapi \
        uvicorn[standard] \
        sqlalchemy \
        alembic \
        psycopg2-binary \
        python-dotenv \
        pydantic \
        pydantic-settings
    print_status "Базовые зависимости установлены (CPU версия PyTorch)"
else
    pip install -r requirements.txt
    print_status "Зависимости из requirements.txt установлены"
fi

echo ""
echo "Шаг 9/10: Создание структуры директорий..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p config core models api services schemas database utils tests weights data logs
mkdir -p data/{employees,videos,test_videos,benchmarks}
mkdir -p logs
mkdir -p weights
touch config/__init__.py
touch core/__init__.py
touch models/__init__.py
touch api/__init__.py
touch services/__init__.py
touch schemas/__init__.py
touch database/__init__.py
touch utils/__init__.py
print_status "Структура директорий создана"

echo ""
echo "Шаг 10/10: Создание .env файла..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_status ".env файл создан из .env.example"
else
    print_warning ".env файл уже существует"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Установка завершена! ✓                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Что установлено:"
echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
echo "  ✓ PostgreSQL $(psql --version | cut -d' ' -f3)"
echo "  ✓ Виртуальное окружение (venv)"
echo "  ✓ PyTorch (CPU версия)"
echo "  ✓ Ultralytics YOLO"
echo "  ✓ InsightFace"
echo "  ✓ FastAPI + Uvicorn"
echo "  ✓ База данных icam2"
echo ""
echo "🚀 Следующие шаги:"
echo ""
echo "  1. Активируйте виртуальное окружение:"
echo "     source venv/bin/activate"
echo ""
echo "  2. Проверьте что PostgreSQL запущен:"
echo "     sudo service postgresql status"
echo "     # Если не запущен: sudo service postgresql start"
echo ""
echo "  3. Отредактируйте .env файл при необходимости:"
echo "     nano .env"
echo ""
echo "  4. (Опционально) Запустите PoC тест:"
echo "     python poc_simple.py"
echo ""
echo "  5. Начните разработку!"
echo "     # См. DEVELOPMENT_PLAN.md"
echo ""
echo "⚠️  ВАЖНО для WSL:"
echo "  • PostgreSQL нужно запускать вручную после каждой перезагрузки:"
echo "    sudo service postgresql start"
echo ""
echo "  • Или добавьте в ~/.bashrc автозапуск:"
echo "    echo 'sudo service postgresql start' >> ~/.bashrc"
echo ""
echo "📚 Документация:"
echo "  • START_HERE.md - с чего начать"
echo "  • DEVELOPMENT_PLAN.md - план разработки"
echo "  • RECOMMENDATIONS.md - рекомендации"
echo ""
echo "Удачи в разработке! 🎉"
