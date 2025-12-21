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

# For true random interval scheduling, we'll run a task every 10 minutes during allowed periods
# and have the task decide whether to send a notification based on random intervals
app.conf.beat_schedule = {
    # Test period: every 5 minutes from 12:00 to 13:00 (but only send based on 5-10 min intervals)
    'lunch-check-1200': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/5', hour='12'),
    },
}

app.conf.timezone = 'Asia/Shanghai'