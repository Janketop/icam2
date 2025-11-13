# Настройка WSL2 для работы с ICAM2

## 🎯 Быстрый старт (5 минут)

### 1. Установка WSL2 + Ubuntu 22.04

**В PowerShell (от администратора):**
```powershell
# Установить WSL2 с Ubuntu 22.04
wsl --install -d Ubuntu-22.04

# Проверить установку
wsl --list --verbose
# Должно показать: Ubuntu-22.04, VERSION 2
```

### 2. Первый запуск

```bash
# Запустить Ubuntu (из меню Пуск или PowerShell)
wsl -d Ubuntu-22.04

# При первом запуске создайте пользователя
# Введите username и password (они останутся в WSL)
```

### 3. Клонирование проекта

```bash
# В WSL терминале
cd ~
git clone https://github.com/Janketop/icam2.git
cd icam2
git checkout claude/plan-development-011CV5oW2sDU4P6DvFanacb7
```

### 4. Автоматическая установка

```bash
# Сделать скрипт исполняемым
chmod +x setup_wsl.sh

# Запустить установку (займет 5-10 минут)
./setup_wsl.sh
```

**Скрипт установит:**
- ✅ Python 3.10+
- ✅ PostgreSQL
- ✅ Виртуальное окружение Python
- ✅ PyTorch (CPU версия)
- ✅ Ultralytics YOLO
- ✅ InsightFace
- ✅ FastAPI
- ✅ Все зависимости
- ✅ Структуру проекта

---

## 💻 VS Code + WSL (Рекомендуемый способ)

### Установка VS Code

1. **Скачайте VS Code для Windows:**
   https://code.visualstudio.com/

2. **Установите расширение WSL:**
   - Откройте VS Code
   - Extensions (Ctrl+Shift+X)
   - Найдите "WSL" (от Microsoft)
   - Нажмите Install

### Подключение к WSL

**Способ 1: Из WSL терминала**
```bash
# В Ubuntu WSL
cd ~/icam2
code .
```

**Способ 2: Из VS Code**
- Нажмите `F1`
- Выберите "WSL: Connect to WSL"
- Откройте папку `/home/your_user/icam2`

**Теперь VS Code работает ВНУТРИ WSL** - все команды выполняются в Linux!

### Полезные расширения для VS Code

После подключения к WSL, установите:
- Python (Microsoft)
- Pylance (Microsoft)
- Black Formatter
- GitLens
- REST Client (для тестирования API)

---

## 🚀 Работа с проектом

### Активация окружения

```bash
# Каждый раз при открытии нового терминала
cd ~/icam2
source venv/bin/activate

# Проверка
python --version  # Должно быть 3.10+
which python      # Должно показать путь к venv
```

### Запуск PostgreSQL

```bash
# PostgreSQL в WSL нужно запускать вручную
sudo service postgresql start

# Проверка статуса
sudo service postgresql status

# Остановка (если нужно)
sudo service postgresql stop
```

**Автозапуск PostgreSQL:**
```bash
# Добавить в ~/.bashrc
echo 'sudo service postgresql start 2>/dev/null' >> ~/.bashrc
```

### Проверка установки

```bash
# Активировать venv
source venv/bin/activate

# Проверить Python
python --version

# Проверить пакеты
pip list | grep -E "(torch|ultralytics|fastapi|insightface)"

# Проверить PostgreSQL
psql -U icam2 -d icam2 -c "SELECT version();"
# Пароль: icam2password
```

---

## 🎮 Как работать с проектом и общаться со мной

### Я буду помогать вам через команды

**Примеры того, что я могу делать:**

1. **Создавать файлы:**
   ```
   "Создай файл config/settings.py с базовой конфигурацией"
   ```

2. **Редактировать код:**
   ```
   "Добавь функцию detect() в core/detector.py"
   ```

3. **Запускать команды:**
   ```
   "Установи зависимости через pip"
   "Запусти тесты"
   "Проверь статус PostgreSQL"
   ```

4. **Объяснять и помогать:**
   ```
   "Объясни как работает ByteTrack"
   "Покажи пример использования YOLO"
   ```

### Типичный workflow

```bash
# 1. Открываете VS Code подключенный к WSL
# (файлы из WSL будут видны в VS Code)

# 2. Говорите мне что нужно сделать, например:
# "Создай модуль детекции людей с YOLO"

# 3. Я создам файл core/detector.py с кодом

# 4. Вы можете:
#    - Посмотреть файл в VS Code
#    - Попросить меня изменить что-то
#    - Запустить код через меня: "Запусти detector.py"

# 5. Я буду отслеживать прогресс через todo-list
```

### Где хранятся файлы

```bash
# WSL файлы доступны из Windows по пути:
\\wsl$\Ubuntu-22.04\home\your_user\icam2\

# Или в проводнике Windows:
# Левая панель → Linux → Ubuntu-22.04 → home → your_user → icam2
```

---

## 🐛 Troubleshooting

### PostgreSQL не запускается

```bash
# Проверить логи
sudo tail -f /var/log/postgresql/postgresql-*.log

# Переустановить
sudo apt remove --purge postgresql postgresql-contrib
sudo apt install postgresql postgresql-contrib
sudo service postgresql start
```

### Виртуальное окружение не активируется

```bash
# Пересоздать venv
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
```

### WSL медленно работает

```bash
# Убедитесь что файлы в Linux файловой системе, а не в /mnt/c/
pwd
# Должно быть: /home/your_user/icam2
# НЕ ДОЛЖНО быть: /mnt/c/Users/...

# Если файлы в /mnt/c/, переместите:
mv /mnt/c/Users/YourName/icam2 ~/
cd ~/icam2
```

### "command not found" после установки

```bash
# Обновить PATH
source ~/.bashrc

# Или перезапустить WSL
exit
# Потом: wsl -d Ubuntu-22.04
```

---

## 📝 Ежедневный workflow

### Начало работы

```bash
# 1. Запустить Ubuntu WSL
wsl -d Ubuntu-22.04

# 2. Перейти в проект
cd ~/icam2

# 3. Активировать venv
source venv/bin/activate

# 4. Запустить PostgreSQL
sudo service postgresql start

# 5. Открыть VS Code
code .
```

### Во время работы

```bash
# Работайте в VS Code (редактируйте файлы)
# Общайтесь со мной (я буду создавать/редактировать код)
# Запускайте команды через встроенный терминал VS Code
```

### Конец работы

```bash
# Коммит изменений (я могу это сделать)
git add .
git commit -m "Ваше сообщение"
git push

# Деактивировать venv (опционально)
deactivate

# Выйти из WSL
exit
```

---

## 🎯 Преимущества WSL для этого проекта

✅ **Полноценный Linux** - все команды работают как в настоящем Ubuntu
✅ **Быстрый доступ** - файлы доступны и из Windows и из Linux
✅ **VS Code интеграция** - редактор Windows работает с Linux кодом
✅ **PostgreSQL** - работает нативно
✅ **Python пакеты** - устанавливаются без проблем
✅ **Я могу помогать** - все мои команды работают в WSL

---

## 🚀 Готовы начать?

После запуска `./setup_wsl.sh`:

1. **Проверьте установку:**
   ```bash
   source venv/bin/activate
   python poc_simple.py
   ```

2. **Начните разработку:**
   ```
   Скажите мне: "Давай начнем разработку"
   Я буду следовать DEVELOPMENT_PLAN.md
   ```

3. **Следите за прогрессом:**
   ```
   Я буду использовать todo-list
   Вы всегда можете спросить: "Что уже сделано?"
   ```

---

## 💬 Примеры команд для меня

```
"Создай базовую структуру проекта"
"Напиши модуль детекции с YOLO"
"Запусти тесты"
"Покажи что уже готово"
"Исправь ошибку в файле X"
"Объясни как работает этот код"
"Запусти API сервер"
"Создай миграцию базы данных"
```

Я буду:
- ✅ Создавать и редактировать файлы
- ✅ Запускать команды в WSL
- ✅ Следить за todo-list
- ✅ Коммитить изменения
- ✅ Объяснять код
- ✅ Помогать с ошибками

**Готовы? Скажите что делать дальше!** 🚀
