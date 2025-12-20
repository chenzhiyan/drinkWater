#!/bin/bash

# Drink Water Reminder System - Startup Script
# Use this script to start the system after initial deployment

echo "==========================================="
echo "Drink Water Reminder System Startup Script"
echo "==========================================="

# Function to check if program is running
is_running() {
    local process_name="$1"
    if pgrep -f "$process_name" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "⚠️  Virtual environment not found. Please run deploy_and_run.sh first."
    exit 1
fi

# Check configuration
if [ ! -f "config.py" ] || [ -z "$(grep 'sctp14152tndmmd3xysbo35fsgm3myec' config.py)" ]; then
    echo "⚠️  Configuration file not found or not properly set up."
    echo "📝 Please check config.py and ensure SERVER_CHAN_TOKEN is configured."
    exit 1
fi

# Start services if not running
echo "Checking and starting services..."

# Start Django server if not running
if ! is_running "manage.py runserver"; then
    echo "🚀 Starting Django server..."
    python manage.py runserver 0.0.0.0:8000 &
    sleep 3
else
    echo "✅ Django server is already running"
fi

# Start Celery worker if not running
if ! is_running "celery.*worker"; then
    echo "🚀 Starting Celery worker..."
    celery -A drink_reminder worker --detach --pidfile=celery_worker.pid --logfile=celery_worker.log
else
    echo "✅ Celery worker is already running"
fi

# Start Celery beat if not running
if ! is_running "celery.*beat"; then
    echo "🚀 Starting Celery beat scheduler..."
    celery -A drink_reminder beat --detach --pidfile=celery_beat.pid --logfile=celery_beat.log
else
    echo "✅ Celery beat scheduler is already running"
fi

echo "==========================================="
echo "System is now running!"
echo "==========================================="
echo
echo "Services:"
echo "- Django Server: http://0.0.0.0:8000"
echo "- Celery Worker: Processing tasks"
echo "- Celery Beat: Managing schedule"
echo
echo "Check your WeChat for incoming water reminders!"