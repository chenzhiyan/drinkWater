from celery import shared_task
from reminder.services import send_drink_reminder
import logging
import random
from datetime import datetime
import time
import redis

logger = logging.getLogger(__name__)

@shared_task
def send_drink_reminder_task():
    """
    Celery task to send drink reminder notification
    """
    try:
        result = send_drink_reminder()
        if result['success']:
            logger.info("Drink reminder sent successfully")
            return {"status": "success", "message": "Drink reminder sent successfully"}
        else:
            logger.error(f"Failed to send drink reminder: {result['error']}")
            return {"status": "failed", "error": result['error']}
    except Exception as e:
        logger.error(f"Exception occurred while sending drink reminder: {str(e)}")
        return {"status": "error", "error": str(e)}

@shared_task
def send_smart_drink_reminder_task():
    """
    Smart drink reminder task that sends reminders based on time periods with random intervals
    TESTING MODE: Random interval 1-3 mins (until 15:30)
    Morning period: 9:00 - 11:50
    Afternoon period: 14:00 - 17:30
    TODO: Revert to 45-60 mins after testing
    """
    try:
        # Connect to Redis to store timing information
        redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
        
        current_time = datetime.now()
        current_hour = current_time.hour
        current_minute = current_time.minute
        current_timestamp = time.time()

        # Check if current time is in the allowed periods
        is_morning_period = (9 <= current_hour < 12)  # 9:00-11:59
        is_afternoon_period = (14 <= current_hour < 18)  # 14:00-17:59

        should_send = False
        period_name = None

        if is_morning_period:
            period_name = 'morning'
            # Get last morning notification time from Redis
            last_notification_str = redis_client.get('drink_reminder:last_morning_notification')
            last_notification = float(last_notification_str) if last_notification_str else 0

            # Random interval between 45-60 minutes (in seconds)
            random_interval = random.randint(45*60, 60*60)

            if current_timestamp - last_notification >= random_interval:
                should_send = True
                # Update the last notification time in Redis
                redis_client.set('drink_reminder:last_morning_notification', str(current_timestamp))
        
        elif is_afternoon_period:
            period_name = 'afternoon'
            # Get last afternoon notification time from Redis
            last_notification_str = redis_client.get('drink_reminder:last_afternoon_notification')
            last_notification = float(last_notification_str) if last_notification_str else 0

            # Random interval between 45-60 minutes (in seconds)
            random_interval = random.randint(45*60, 60*60)

            if current_timestamp - last_notification >= random_interval:
                should_send = True
                # Update the last notification time in Redis
                redis_client.set('drink_reminder:last_afternoon_notification', str(current_timestamp))
        
        if should_send:
            result = send_drink_reminder()
            if result['success']:
                logger.info(f"Smart drink reminder sent successfully at {current_hour}:{current_minute:02d} ({period_name} period)")
                return {"status": "success", "message": f"Smart drink reminder sent at {current_hour}:{current_minute:02d} ({period_name} period)"}
            else:
                logger.error(f"Failed to send smart drink reminder: {result['error']}")
                return {"status": "failed", "error": result['error']}
        else:
            # Check if we should send just based on time window but not enough time passed
            if is_morning_period or is_afternoon_period:
                logger.info(f"Smart drink reminder check - within {period_name} window but not enough time passed since last reminder")
                return {"status": "check_passed", "message": f"Within {period_name} window, waiting for random interval"}
            else:
                logger.info(f"Smart drink reminder skipped - outside allowed time periods (current time: {current_hour}:{current_minute:02d})")
                return {"status": "skipped", "message": f"Outside allowed time periods (current time: {current_hour}:{current_minute:02d})"}
            
    except redis.ConnectionError:
        logger.error("Could not connect to Redis, falling back to simple reminder")
        # Fallback to sending the reminder if Redis is not available
        try:
            result = send_drink_reminder()
            if result['success']:
                logger.info("Simple fallback reminder sent successfully")
                return {"status": "success", "message": "Simple fallback reminder sent"}
            else:
                logger.error(f"Failed to send fallback reminder: {result['error']}")
                return {"status": "failed", "error": result['error']}
        except Exception as e:
            logger.error(f"Exception occurred while sending fallback reminder: {str(e)}")
            return {"status": "error", "error": str(e)}
    except Exception as e:
        logger.error(f"Exception occurred while sending smart drink reminder: {str(e)}")
        return {"status": "error", "error": str(e)}