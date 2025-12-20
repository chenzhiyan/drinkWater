#!/bin/bash

# Drink Water Reminder System - SSH Server Deployment Script
# This script will deploy and run the drink water reminder system on your SSH server

set -e  # Exit on any error

echo "==============================================="
echo "Drink Water Reminder System - SSH Server Setup"
echo "==============================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
echo "🔍 Checking for required tools..."
required_tools=("python3" "pip3" "git")
for tool in "${required_tools[@]}"; do
    if ! command_exists "$tool"; then
        echo "❌ Error: $tool is required but not found"
        echo "💡 Install it with:"
        echo "   Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip git"
        echo "   CentOS/RHEL: sudo yum install python3 python3-pip git"
        echo "   macOS: brew install python3 git"
        exit 1
    fi
done

echo "✅ All required tools found"

# Clone the repository if not already in it
if [ ! -f "manage.py" ]; then
    echo "📥 Cloning project from GitHub..."
    if [ -d "drinkWater" ]; then
        echo "⚠️  Removing existing drinkWater directory..."
        rm -rf drinkWater
    fi
    git clone https://github.com/chenzhiyan/drinkWater.git
    cd drinkWater
else
    echo "🔄 Updating existing project..."
    git pull origin main
fi

# Setup Python virtual environment
echo "🐍 Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip and install requirements
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Run database migrations
echo "🔧 Running database migrations..."
python manage.py migrate

# Check for Redis
echo ".Redis status check..."
if command_exists redis-cli; then
    if timeout 10 redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis is running"
        REDIS_STATUS="running"
    else
        echo "⚠️  Redis is not running"
        REDIS_STATUS="stopped"
    fi
else
    echo "❌ Redis is not installed"
    REDIS_STATUS="missing"
fi

# Configure Server酱 settings 
echo "⚙️  Configuring system..."
cat > config.py << 'EOF'
# Configuration file for drink reminder app

# Server酱/Server酱3 configuration
SERVER_CHAN_TOKEN = "sctp14152tndmmd3xysbo35fsgm3myec"  # Your Server酱 SCKEY or Server酱3 SendKey
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

# Update services.py to handle both Server酱 and Server酱3
echo "🔄 Updating notification service to handle Server酱/Server酱3..."

cat > reminder/services.py << 'EOF'
import requests
import logging
import random
from django.conf import settings
from config import SERVER_CHAN_TOKEN, DRINK_REMINDER_TITLE, DRINK_REMINDER_MESSAGES

logger = logging.getLogger(__name__)

def send_server_chan_notification(title=None, message=None):
    """
    Send notification via Server酱 or Server酱3
    
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
    
    # Prepare payload
    payload = {
        'title': title,
        'desp': message  # Server酱 uses 'desp' for description/content
    }
    
    # Try Server酱3 API first
    server3_url = f"https://sc3.ft07.com/send/{SERVER_CHAN_TOKEN}"
    
    try:
        response = requests.post(server3_url, data=payload)
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"Server酱3 notification sent: {result}")
        
        # Check if the request was successful
        if ('code' in result and result['code'] == 0) or 'success' in str(result).lower():
            return {"success": True, "result": result}
        else:
            logger.error(f"Server酱3 notification failed: {result}")
    except requests.exceptions.RequestException as e:
        logger.warning(f"Server酱3 API failed: {str(e)}, trying original Server酱...")
    except ValueError as e:  # JSON decode error
        logger.warning(f"Server酱3 response decode failed: {str(e)}, trying original Server酱...")
    
    # Fallback to original Server酱 API
    original_url = f"https://sctapi.ftqq.com/{SERVER_CHAN_TOKEN}.send"
    
    try:
        response = requests.post(original_url, data=payload)
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"Original Server酱 notification sent: {result}")
        
        if result.get('data'):
            return {"success": True, "result": result}
        else:
            logger.error(f"Original Server酱 notification failed: {result}")
            return {"success": False, "error": result}
    except Exception as e:
        logger.error(f"Both Server酱 APIs failed: {str(e)}")
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

# Check and handle Redis requirement
if [ "$REDIS_STATUS" = "missing" ] || [ "$REDIS_STATUS" = "stopped" ]; then
    echo
    echo "⚠️  IMPORTANT: Redis is required for this application to work properly."
    echo
    echo "Please install and start Redis:"
    echo "  Ubuntu/Debian: sudo apt install redis-server && sudo systemctl start redis && sudo systemctl enable redis"
    echo "  CentOS/RHEL: sudo yum install redis && sudo systemctl start redis && sudo systemctl enable redis"
    echo "  macOS: brew install redis && brew services start redis"
    echo
    if [ "$REDIS_STATUS" = "missing" ]; then
        echo "❌ Cannot continue without Redis. Please install Redis and run this script again."
        exit 1
    else
        echo "⚠️  Redis is installed but not running. Please start Redis service and run this script again."
        exit 1
    fi
fi

# Start all services
echo "🚀 Starting Drink Water Reminder System..."

# Start Django server in background
echo "  Starting Django server..."
if ! pgrep -f "manage.py runserver" >/dev/null; then
    python manage.py runserver 0.0.0.0:8000 &
    sleep 3
    echo $! > django.pid
    echo "  ✅ Django server started on port 8000"
else
    echo "  ℹ️  Django server is already running"
fi

# Start Celery worker
echo "  Starting Celery worker..."
if ! pgrep -f "celery.*worker" >/dev/null; then
    celery -A drink_reminder worker --detach --loglevel=info
    echo "  ✅ Celery worker started"
else
    echo "  ℹ️  Celery worker is already running"
fi

# Start Celery beat scheduler
echo "  Starting Celery beat scheduler..."
if ! pgrep -f "celery.*beat" >/dev/null; then
    celery -A drink_reminder beat --detach --loglevel=info
    echo "  ✅ Celery beat scheduler started"
else
    echo "  ℹ️  Celery beat scheduler is already running"
fi

echo
echo "==============================================="
echo "🎉 SUCCESS: Drink Water Reminder System is now running!"
echo "==============================================="
echo
echo "📊 Services Status:"
echo "   - Django Server: Running on port 8000"
echo "   - Celery Worker: Processing scheduled tasks"
echo "   - Celery Beat: Managing task schedule"
echo "   - Redis: $REDIS_STATUS"
echo
echo "⏰ Schedule Configuration:"
echo "   - Morning: 9:00 AM - 11:50 AM (random interval 45-60 min)"
echo "   - Afternoon: 2:00 PM - 5:30 PM (random interval 45-60 min)"
echo
echo "💬 Notification Service:"
echo "   - Server酱/Server酱3: Configured and ready"
echo "   - Messages: 20 random messages available"
echo
echo "🌐 Access the web interface at: http://$(curl -s ifconfig.me):8000"
echo
echo "🔧 Management Commands:"
echo "   - Stop all services: pkill -f 'manage.py\|celery' && rm -f *.pid"
echo "   - Restart: Run this script again"
echo "   - Check status: ps aux | grep -E 'manage.py|celery'"
echo
echo "🎁 You should receive a test notification shortly. Check your WeChat!"
echo "==============================================="