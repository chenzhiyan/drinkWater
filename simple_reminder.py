#!/usr/bin/env python3
"""
Simple drink reminder script - designed for cron scheduling
No Redis dependency, uses file to track random intervals (45-60 mins)
"""

import sys
import os
import random
import requests
import json
from datetime import datetime, date

# Add project path
sys.path.insert(0, '/root/data/drinkWater')

# Import config
from config import (
    SERVER_CHAN_TOKEN, 
    SERVER_CHAN_TOKEN_2, 
    DRINK_REMINDER_TITLE, 
    DRINK_REMINDER_MESSAGES
)

# Try to import chinese_calendar for workday detection
try:
    from chinese_calendar import is_workday
except ImportError:
    def is_workday(day):
        # Fallback: weekdays only
        return day.weekday() < 5

LOG_FILE = '/root/data/drinkWater/reminder.log'
STATE_FILE = '/root/data/drinkWater/reminder_state.json'

# Random interval range (in seconds)
MIN_INTERVAL = 45 * 60  # 45 minutes
MAX_INTERVAL = 60 * 60  # 60 minutes

def log(message):
    """Write log message"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(log_line + '\n')
    except:
        pass

def load_state():
    """Load state from file"""
    try:
        if os.path.exists(STATE_FILE):
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
    except:
        pass
    return {}

def save_state(state):
    """Save state to file"""
    try:
        with open(STATE_FILE, 'w') as f:
            json.dump(state, f)
    except Exception as e:
        log(f"Warning: Could not save state: {e}")

def send_notification(token, title, message):
    """Send notification via Server酱"""
    url = f"https://sctapi.ftqq.com/{token}.send"
    payload = {'title': title, 'desp': message}
    
    try:
        response = requests.post(url, data=payload, timeout=10)
        result = response.json()
        
        if result.get('code') == 0 or result.get('data'):
            return True, result
        else:
            return False, result
    except Exception as e:
        return False, str(e)

def format_interval(seconds):
    """Format interval seconds to human readable string"""
    mins = seconds // 60
    secs = seconds % 60
    if secs == 0:
        return f"{mins}分钟"
    else:
        return f"{mins}分{secs}秒"

def main():
    current_time = datetime.now()
    current_hour = current_time.hour
    current_timestamp = current_time.timestamp()
    today_str = date.today().isoformat()
    
    log(f"=== Reminder check started ===")
    
    # Check if today is a workday
    today = date.today()
    if not is_workday(today):
        log(f"Skipped - not a workday ({today})")
        return
    
    # Determine current period
    is_morning = 9 <= current_hour < 12
    is_afternoon = 14 <= current_hour < 18
    
    if not (is_morning or is_afternoon):
        log(f"Skipped - outside allowed time periods (hour: {current_hour})")
        return
    
    period = 'morning' if is_morning else 'afternoon'
    state = load_state()
    
    # Check if it's a new day, reset the period if so
    last_date = state.get('last_date', '')
    if last_date != today_str:
        # New day - clear old period states
        state.pop('next_send_morning', None)
        state.pop('next_send_afternoon', None)
        state['last_date'] = today_str
        save_state(state)
        log(f"New day detected, reset timers")
    
    # Get next send time for current period
    state_key = f'next_send_{period}'
    next_send = state.get(state_key, 0)
    
    # Check if it's time to send
    if current_timestamp < next_send:
        remaining = int(next_send - current_timestamp)
        log(f"Skipped - waiting ({format_interval(remaining)} remaining)")
        return
    
    # Send reminder
    log(f"Sending reminder (period: {period})...")
    
    message = random.choice(DRINK_REMINDER_MESSAGES)
    
    # Send to primary account
    success1, result1 = send_notification(SERVER_CHAN_TOKEN, DRINK_REMINDER_TITLE, message)
    log(f"Account 1: {'success' if success1 else 'failed'} - {result1}")
    
    # Send to secondary account if configured
    if SERVER_CHAN_TOKEN_2 and SERVER_CHAN_TOKEN_2.strip():
        success2, result2 = send_notification(SERVER_CHAN_TOKEN_2, DRINK_REMINDER_TITLE, message)
        log(f"Account 2: {'success' if success2 else 'failed'} - {result2}")
    
    # Calculate next random interval (45-60 minutes, precise to second)
    random_interval = random.randint(MIN_INTERVAL, MAX_INTERVAL)
    next_send_time = current_timestamp + random_interval
    
    # Save state
    state[state_key] = next_send_time
    save_state(state)
    
    next_time_str = datetime.fromtimestamp(next_send_time).strftime('%H:%M:%S')
    log(f"Next reminder in {format_interval(random_interval)} (at {next_time_str})")
    log(f"=== Reminder completed ===")

if __name__ == '__main__':
    main()
