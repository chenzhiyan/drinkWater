#!/bin/bash

# Startup script for drink reminder system
# This script starts both Django server and Celery workers

echo "Starting Drink Reminder System..."

# Start Django server in background
echo "Starting Django server..."
python manage.py runserver 0.0.0.0:8000 &

# Give Django a moment to start
sleep 3

# Start Celery worker in background
echo "Starting Celery worker..."
celery -A drink_reminder worker -l info &

# Start Celery beat (scheduler) in background
echo "Starting Celery beat scheduler..."
celery -A drink_reminder beat -l info &

echo "All services started successfully!"
echo "Django server: http://localhost:8000"
echo "Press Ctrl+C to stop all services."

# Wait for all background processes
wait