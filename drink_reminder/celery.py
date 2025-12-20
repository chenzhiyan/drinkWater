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
    # Morning period: every 10 minutes from 9:00 to 12:00 (but only send based on 45-60 min intervals)
    'morning-check-900': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='9'),
    },
    'morning-check-1000': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='10'),
    },
    'morning-check-1100': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='11'),
    },
    # Afternoon period: every 10 minutes from 14:00 (2PM) to 17:30 (5:30PM)
    'afternoon-check-1400': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='14'),
    },
    'afternoon-check-1500': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='15'),
    },
    'afternoon-check-1600': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='*/10', hour='16'),
    },
    'afternoon-check-1700': {
        'task': 'reminder.tasks.send_smart_drink_reminder_task',
        'schedule': crontab(minute='0,10,20,30', hour='17'),  # Only first 30 minutes of 5PM
    },
}

app.conf.timezone = 'UTC'