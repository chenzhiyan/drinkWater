#!/bin/bash

# Drink Water Reminder System - Deployment & Startup Script
# Use this script to deploy and run the drink water reminder system

set -e  # Exit on any error

echo "==========================================="
echo "Drink Water Reminder System Deployment Script"
echo "==========================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "Checking for required tools..."
if ! command_exists python3; then
    echo "❌ Error: python3 is required but not found"
    exit 1
fi

if ! command_exists pip3; then
    echo "❌ Error: pip3 is required but not found"
    exit 1
fi

if ! command_exists git; then
    echo "❌ Error: git is required but not found"
    exit 1
fi

# Check if running in the project directory or need to clone
if [ ! -f "manage.py" ]; then
    echo "ℹ️  Not in project directory, checking if we need to clone..."
    
    # Check if this is the first run (no existing project files)
    if [ ! -f ".git/config" ] || ! grep -q "drinkWater" .git/config 2>/dev/null; then
        echo "ℹ️  Cloning project from GitHub..."
        cd ..
        git clone git@github.com:chenzhiyan/drinkWater.git
        cd drinkWater
    else
        echo "ℹ️  Updating existing repository..."
        git pull origin main
    fi
else
    echo "ℹ️  Already in project directory, updating from repository..."
    git pull origin main
fi

echo "Current directory: $(pwd)"

# Create or activate virtual environment
echo "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
echo "Installing Python dependencies..."
pip install -r requirements.txt

# Run database migrations
echo "Running database migrations..."
python manage.py migrate

# Check if config.py exists and has proper configuration
if [ ! -f "config.py" ]; then
    echo "⚠️  config.py not found. Creating a template..."
    cat > config.py << 'EOF'
# Configuration file for drink reminder app

# Server酱 configuration
SERVER_CHAN_TOKEN = ""  # Fill in your Server酱 SCKEY here
DRINK_REMINDER_TITLE = "喝水提醒"

# List of drink reminder messages - system will randomly select one each time
DRINK_REMINDER_MESSAGES = [
    "记得喝水哦！保持身体水分充足对健康很重要。",
    "水是生命之源，记得及时补充水分！",
    "身体需要水分啦，来杯水吧！",
    "健康生活从喝水开始，记得多喝水哦！",
    "水分不足会影响工作效率，记得及时补水！",
    "喝水有助于保持皮肤水润，记得多喝水！",
    "大脑需要水分保持活力，记得喝水哦！"
]

# Scheduler configuration
REMINDER_INTERVAL_HOURS = 2  # Send reminder every 2 hours
EOF
    echo "📝 Created config.py template. Please update with your Server酱 token!"
    echo "📝 Edit config.py to add your SERVER_CHAN_TOKEN."
fi

# Check if Redis is running
if command_exists redis-cli; then
    if timeout 10 redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis is running"
    else
        echo "⚠️  Redis is not running. You may need to start it:"
        echo "   sudo systemctl start redis"  # For Ubuntu/Debian
        echo "   brew services start redis"   # For macOS with Homebrew
    fi
else
    echo "⚠️  Redis is not installed. Install it with:"
    echo "   Ubuntu/Debian: sudo apt-get install redis-server"
    echo "   macOS: brew install redis"
fi

# Start all services in background
echo "Starting services..."

# Start Django server in background (if not already running)
if ! pgrep -f "manage.py runserver" >/dev/null; then
    echo "🚀 Starting Django server..."
    python manage.py runserver 0.0.0.0:8000 &
    DJANGO_PID=$!
    echo $DJANGO_PID > django.pid
    sleep 3  # Give Django time to start
else
    echo "ℹ️  Django server is already running"
fi

# Start Celery worker in background (if not already running)
if ! pgrep -f "celery.*worker" >/dev/null; then
    echo "🚀 Starting Celery worker..."
    celery -A drink_reminder worker --detach --pidfile=celery_worker.pid --logfile=celery_worker.log
else
    echo "ℹ️  Celery worker is already running"
fi

# Start Celery beat scheduler in background (if not already running)
if ! pgrep -f "celery.*beat" >/dev/null; then
    echo "🚀 Starting Celery beat scheduler..."
    celery -A drink_reminder beat --detach --pidfile=celery_beat.pid --logfile=celery_beat.log
else
    echo "ℹ️  Celery beat scheduler is already running"
fi

echo "==========================================="
echo "Drink Water Reminder System is now running!"
echo "==========================================="
echo 
echo "Services:"
echo "- Django Server: http://your-server-ip:8000"
echo "- Celery Worker: Processing scheduled tasks"
echo "- Celery Beat: Managing task schedule"
echo
echo "Time-based reminders configured:"
echo "- Morning: 9:00 AM - 11:50 AM (random interval 45-60 min)"
echo "- Afternoon: 2:00 PM - 5:30 PM (random interval 45-60 min)"
echo
echo "To check if services are running:"
echo "  - ps aux | grep -E '(manage.py runserver|celery)'"
echo
echo "To stop services:"
echo "  - kill -9 \$(cat django.pid) 2>/dev/null || true"
echo "  - pkill -f 'celery.*worker'"
echo "  - pkill -f 'celery.*beat'"
echo
echo "To restart: Run this script again"