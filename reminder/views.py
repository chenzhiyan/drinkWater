from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .tasks import send_drink_reminder_task
import json
from config import DRINK_REMINDER_TITLE, DRINK_REMINDER_MESSAGES, REMINDER_INTERVAL_HOURS, SERVER_CHAN_TOKEN

def index(request):
    """Main page showing app info and controls"""
    context = {
        'title': DRINK_REMINDER_TITLE,
        'message': DRINK_REMINDER_MESSAGES[0],  # Show first message as example
        'interval': REMINDER_INTERVAL_HOURS,
        'total_messages': len(DRINK_REMINDER_MESSAGES),
    }
    return render(request, 'reminder/index.html', context)

def send_test_notification(request):
    """Manually trigger a drink reminder for testing"""
    if request.method == 'POST':
        # Send the task asynchronously
        task = send_drink_reminder_task.delay()
        return JsonResponse({
            'status': 'success', 
            'message': 'Test notification sent',
            'task_id': task.id
        })
    else:
        # For GET requests, just show the form
        return render(request, 'reminder/test_notification.html')

def status(request):
    """Show the status of the reminder system"""
    context = {
        'server_chan_configured': bool(SERVER_CHAN_TOKEN.strip()),
    }
    return render(request, 'reminder/status.html', context)