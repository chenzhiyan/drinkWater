#!/usr/bin/env python3
"""
Continuous test script to manually trigger notifications every few minutes
"""

import os
import sys
import django
import time
import datetime

# Add the project directory to Python path
sys.path.append('/root/data/drinkWater')

# Set the Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'drink_reminder.settings')

# Setup Django
django.setup()

from reminder.tasks import send_smart_drink_reminder_task

def main():
    print("Starting continuous test of drink reminder system...")
    print(f"Current time: {datetime.datetime.now()}")
    print("This script will trigger a notification every 5 minutes during 12:00-13:00")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            current_time = datetime.datetime.now()
            
            # Check if we're in the test period (12:00-13:00)
            if current_time.hour == 12:
                print(f"\n[{current_time}] Testing smart reminder...")
                result = send_smart_drink_reminder_task()
                print(f"Result: {result}")
            else:
                print(f"\n[{current_time}] Outside test period (12:00-13:00)")
                break  # Exit if we're outside the test period
            
            # Wait 5 minutes before next check
            print("Waiting 5 minutes before next check...")
            time.sleep(300)  # 300 seconds = 5 minutes
            
    except KeyboardInterrupt:
        print("\nTest stopped by user.")

if __name__ == "__main__":
    main()