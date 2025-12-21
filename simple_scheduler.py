#!/usr/bin/env python3
"""
Simple scheduler script to send drink reminders at random intervals
"""

import os
import sys
import django
import time
import datetime
import random

# Add the project directory to Python path
sys.path.append('/root/data/drinkWater')

# Set the Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'drink_reminder.settings')

# Setup Django
django.setup()

from reminder.tasks import send_smart_drink_reminder_task

def main():
    print("Starting simple drink reminder scheduler...")
    print(f"Current time: {datetime.datetime.now()}")
    print("This script will send reminders every 3-5 minutes during 14:00-14:30")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            current_time = datetime.datetime.now()
            
            # Check if we're in the test period (14:00-14:30)
            if current_time.hour == 14 and current_time.minute <= 30:
                print(f"\n[{current_time}] Triggering smart reminder...")
                result = send_smart_drink_reminder_task()
                print(f"Result: {result}")
                
                # Calculate random interval between 3-5 minutes
                interval = random.randint(3*60, 5*60)  # 3-5 minutes in seconds
                print(f"Next reminder in {interval//60} minutes and {interval%60} seconds...")

                # Wait for the random interval
                time.sleep(interval)
            else:
                print(f"\n[{current_time}] Outside test period (14:00-14:30)")
                break  # Exit if we're outside the test period
            
    except KeyboardInterrupt:
        print("\nScheduler stopped by user.")

if __name__ == "__main__":
    main()