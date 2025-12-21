#!/usr/bin/env python3
"""
Test script to verify Server酱 notification works in current environment
"""

import os
import sys
import django

# Add the project directory to Python path
sys.path.append('/root/data/drinkWater')

# Set the Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'drink_reminder.settings')

# Setup Django
django.setup()

from reminder.services import send_drink_reminder
from reminder.tasks import send_smart_drink_reminder_task
import datetime

if __name__ == "__main__":
    print("Testing Server酱 notification directly...")
    result = send_drink_reminder()
    print(f"Result: {result}")

    if result['success']:
        print("✅ Direct notification sent successfully! Check your WeChat for the message.")
    else:
        print(f"❌ Failed to send notification: {result['error']}")

    print("\nTesting smart reminder task...")
    print(f"Current time: {datetime.datetime.now()}")

    smart_result = send_smart_drink_reminder_task()
    print(f"Smart task result: {smart_result}")

    if smart_result.get('status') == 'success':
        print("✅ Smart reminder sent successfully!")
    elif smart_result.get('status') == 'check_passed':
        print("ℹ️  Smart reminder checked time window but didn't send (waiting for random interval).")
    elif smart_result.get('status') == 'skipped':
        print("ℹ️  Smart reminder skipped (outside allowed time period).")
    else:
        print(f"❌ Smart reminder failed: {smart_result.get('error')}")