#!/bin/bash

# Drink Water Reminder System - One-Command Deployment Script for Server酱3
# Use this script to deploy and run the system with Server酱3 support

set -e  # Exit on any error

echo "==========================================="
echo "Drink Water Reminder System - Server酱3 Setup"
echo "==========================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "Checking for required tools..."
for cmd in python3 pip3 git; do
    if ! command_exists $cmd; then
        echo "❌ Error: $cmd is required but not found"
        exit 1
    fi
done

# Clone or update repository
if [ ! -d "drinkWater" ]; then
    echo " cloning project from GitHub..."
    git clone https://github.com/chenzhiyan/drinkWater.git
    cd drinkWater
else
    echo "ℹ️  Updating existing project..."
    cd drinkWater
    git pull origin main
fi

# Create or activate virtual environment
echo "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip and install requirements
pip install --upgrade pip
pip install -r requirements.txt

# Run database migrations
python manage.py migrate

# Update config.py with your token
echo "Updating configuration with Server酱3 support..."
cat > config.py << 'EOF'
# Configuration file for drink reminder app with Server酱3

# Server酱3 configuration
SERVER_CHAN_TOKEN = "sctp14152tndmmd3xysbo35fsgm3myec"  # Your Server酱3 SendKey
DRINK_REMINDER_TITLE = "喝水提醒"

# List of drink reminder messages - system will randomly select one each time
DRINK_REMINDER_MESSAGES = [
    "记得喝水哦！保持身体水分充足对健康很重要。",
    "水是生命之源，记得及时补充水分！",
    "身体需要水分啦，来杯水吧！",
    "健康生活从喝水开始，记得多喝水哦！",
    "水分不足会影响工作效率，记得及时补水！",
    "喝水有助于保持皮肤水润，记得多喝水！",
    "大脑需要水分保持活力，记得喝水哦！",
    "适量饮水有助于维持身体机能，记得喝水！",
    "喝水是保持健康的简单方式，记得多喝水！",
    "身体70%是水，记得及时补充水分！",
    "喝水有助于排毒养颜，记得多喝水哦！",
    "水分充足有助于保持精力充沛，记得喝水！",
    "喝水是维持生命的基本需求，记得及时补充！",
    "身体缺水会影响注意力，记得多喝水！",
    "适量饮水有助于消化，记得保持水分充足！",
    "久坐容易忘记喝水，记得起身喝杯水！",
    "喝水有助于新陈代谢，记得补充水分！",
    "水润身体，健康生活，记得喝水哦！",
    "身体发出缺水信号，赶紧喝杯水吧！",
    "每天八杯水，健康又美丽，记得喝水！"
]

# Scheduler configuration
REMINDER_INTERVAL_HOURS = 2  # Send reminder every 2 hours
EOF

# Update services.py to use Server酱3 API
echo "Updating Server酱 service to use Server酱3 API..."

cat > reminder/services.py << 'EOF'
import requests
import logging
import random
from django.conf import settings
from config import SERVER_CHAN_TOKEN, DRINK_REMINDER_TITLE, DRINK_REMINDER_MESSAGES

logger = logging.getLogger(__name__)

def send_server_chan_notification(title=None, message=None):
    """
    Send notification via ServerChan3 (sc3.ft07.com)
    
    Args:
        title (str): Notification title, defaults to configured title
        message (str): Notification message
    
    Returns:
        dict: Response from ServerChan API
    """
    if not SERVER_CHAN_TOKEN:
        logger.error("ServerChan token is not configured")
        return {"success": False, "error": "ServerChan token not configured"}
    
    # Use default values if not provided
    title = title or DRINK_REMINDER_TITLE
    message = message or random.choice(DRINK_REMINDER_MESSAGES)  # Randomly select a message
    
    # Server酱3 API endpoint
    url = f"https://sc3.ft07.com/send/{SERVER_CHAN_TOKEN}"
    
    payload = {
        'title': title,
        'desp': message  # Server酱 uses 'desp' for description/content
    }
    
    try:
        response = requests.post(url, data=payload)
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"ServerChan3 notification sent: {result}")
        
        # Check if the request was successful
        if ('code' in result and result['code'] == 0) or 'success' in str(result).lower():
            return {"success": True, "result": result}
        else:
            logger.error(f"ServerChan3 notification failed: {result}")
            return {"success": False, "error": result}
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error sending ServerChan3 notification: {str(e)}")
        return {"success": False, "error": str(e)}
    except ValueError as e:  # Includes JSON decode errors
        logger.error(f"Error parsing ServerChan3 response: {str(e)}")
        return {"success": False, "error": str(e)}

def send_drink_reminder():
    """
    Send a drink water reminder using configured settings
    """
    # Randomly select a message from the list
    random_message = random.choice(DRINK_REMINDER_MESSAGES)
    return send_server_chan_notification(
        title=DRINK_REMINDER_TITLE,
        message=random_message
    )
EOF

# Check if Redis is running
REDIS_RUNNING=false
if command_exists redis-cli; then
    if timeout 10 redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis is running"
        REDIS_RUNNING=true
    else
        echo "⚠️  Redis is not running."
    fi
else
    echo "⚠️  Redis is not installed."
fi

if [ "$REDIS_RUNNING" = false ]; then
    echo "Redis is required for this application to work properly."
    echo "Please install and start Redis:"
    echo "  Ubuntu/Debian: sudo apt-get install redis-server && sudo systemctl start redis"
    echo "  CentOS/RHEL: sudo yum install redis && sudo systemctl start redis"
    echo "  macOS: brew install redis && brew services start redis"
    exit 1
fi

# Start all services
echo "Starting services..."

# Start Django server in background
echo "🚀 Starting Django server..."
python manage.py runserver 0.0.0.0:8000 &
sleep 3

# Start Celery worker
echo "🚀 Starting Celery worker..."
celery -A drink_reminder worker --detach --loglevel=info

# Start Celery beat scheduler
echo "🚀 Starting Celery beat scheduler..."
celery -A drink_reminder beat --detach --loglevel=info

echo "==========================================="
echo "System is now running with Server酱3!"
echo "==========================================="
echo
echo "Services:"
echo "- Django Server: http://0.0.0.0:8000"
echo "- Celery Worker: Processing tasks"
echo "- Celery Beat: Managing schedule"
echo
echo "Server酱3 API: https://sc3.ft07.com/send/"
echo
echo "Time-based reminders configured:"
echo "- Morning: 9:00 AM - 11:50 AM (random interval 45-60 min)"
echo "- Afternoon: 2:00 PM - 5:30 PM (random interval 45-60 min)"
echo
echo "🎉 Setup complete! Check your WeChat for incoming water reminders."
echo
echo "To stop services: pkill -f 'manage.py\|celery'"