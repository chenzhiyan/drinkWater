import os
from celery import Celery
from django.conf import settings
import random

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'drink_reminder.settings')

app = Celery('drink_reminder')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django apps.
app.autodiscover_tasks()

# Configure periodic tasks (Celery Beat)
from celery.schedules import crontab

# Production: Check every 10 minutes during allowed periods
# The task will decide whether to send based on random 45-60 min intervals
app.conf.beat_schedule = {
    # Morning period: 9:00 - 11:50, check every 10 minutes
    'morning-check-9-11': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='9-11'),
    },
    # Afternoon period: 14:00 - 17:30, check every 10 minutes
    'afternoon-check-14-17': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='14-17'),
    },
}

app.conf.timezone = 'Asia/Shanghai'