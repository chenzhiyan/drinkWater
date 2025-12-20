#!/bin/bash

# Drink Water Reminder System - Stop Script
# Use this script to stop all running services

echo "==========================================="
echo "Drink Water Reminder System Stop Script"
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

# Stop Django server
if is_running "manage.py runserver"; then
    echo "⏹️  Stopping Django server..."
    pkill -f "manage.py runserver"
    if [ -f "django.pid" ]; then
        rm django.pid
    fi
    echo "✅ Django server stopped"
else
    echo "ℹ️  Django server is not running"
fi

# Stop Celery worker
if is_running "celery.*worker"; then
    echo "⏹️  Stopping Celery worker..."
    pkill -f "celery.*worker"
    if [ -f "celery_worker.pid" ]; then
        rm celery_worker.pid
    fi
    echo "✅ Celery worker stopped"
else
    echo "ℹ️  Celery worker is not running"
fi

# Stop Celery beat
if is_running "celery.*beat"; then
    echo "⏹️  Stopping Celery beat scheduler..."
    pkill -f "celery.*beat"
    if [ -f "celery_beat.pid" ]; then
        rm celery_beat.pid
    fi
    echo "✅ Celery beat scheduler stopped"
else
    echo "ℹ️  Celery beat scheduler is not running"
fi

echo "==========================================="
echo "All services have been stopped!"
echo "==========================================="