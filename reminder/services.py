import requests
import logging
import random
from django.conf import settings
from config import SERVER_CHAN_TOKEN, DRINK_REMINDER_TITLE, DRINK_REMINDER_MESSAGES

logger = logging.getLogger(__name__)

def send_server_chan_notification(title=None, message=None):
    """
    Send notification via ServerChan (serverchan.com)
    
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
    
    # ServerChan API endpoint (using the newer version)
    url = f"https://sctapi.ftqq.com/{SERVER_CHAN_TOKEN}.send"
    
    payload = {
        'title': title,
        'desp': message  # ServerChan uses 'desp' for description/content
    }
    
    try:
        response = requests.post(url, data=payload)
        response.raise_for_status()
        
        result = response.json()
        logger.info(f"ServerChan notification sent: {result}")
        
        # Check if the request was successful
        if result.get('data'):
            return {"success": True, "result": result}
        else:
            logger.error(f"ServerChan notification failed: {result}")
            return {"success": False, "error": result}
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error sending ServerChan notification: {str(e)}")
        return {"success": False, "error": str(e)}
    except ValueError as e:  # Includes JSON decode errors
        logger.error(f"Error parsing ServerChan response: {str(e)}")
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