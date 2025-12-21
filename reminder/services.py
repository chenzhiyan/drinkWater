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
    
    # Try different Server酱3 API endpoints
    # Common formats: https://sctp-xyz.send.ft07.com/send or https://sc3.ft07.com/send/{key}
    # Based on the user's URL format: https://sc3.ft07.com/sendkey
    # Correct format is likely: https://sc3.ft07.com/send/{key}
    
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
        # Check if it's 405 error which might mean we need to use a different format
        if "405" in str(e):
            logger.warning("Received 405 error, trying alternative Server酱3 API format...")
            # Try the original Server酱 format in case Server酱3 is compatible
            url = f"https://sctapi.ftqq.com/{SERVER_CHAN_TOKEN}.send"
            
            try:
                response = requests.post(url, data=payload)
                response.raise_for_status()
                
                result = response.json()
                logger.info(f"Original Server酱 API notification sent: {result}")
                
                if result.get('data'):
                    return {"success": True, "result": result}
                else:
                    logger.error(f"Original Server酱 API notification failed: {result}")
                    return {"success": False, "error": result}
            except Exception as e2:
                logger.error(f"Both Server酱3 and original Server酱 APIs failed: {str(e2)}")
                return {"success": False, "error": f"Main API: {str(e)}, Fallback API: {str(e2)}"}
        else:
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