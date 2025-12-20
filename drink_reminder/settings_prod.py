"""
Production settings for drink_reminder project.

This file contains settings appropriate for production deployment.
"""

from .settings import *
import os

# Override settings for production
DEBUG = False

# Allow all hosts in this example - for production, be specific about allowed hosts
ALLOWED_HOSTS = ['*']  # You should change this to your domain/IP in production

# Use environment variable for SECRET_KEY in production
SECRET_KEY = os.environ.get('SECRET_KEY', SECRET_KEY)

# Database configuration for production (PostgreSQL example)
# Uncomment and configure for production use
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.postgresql',
#         'NAME': os.environ.get('DB_NAME', ''),
#         'USER': os.environ.get('DB_USER', ''),
#         'PASSWORD': os.environ.get('DB_PASSWORD', ''),
#         'HOST': os.environ.get('DB_HOST', ''),
#         'PORT': '5432',
#     }
# }

# Redis configuration for production
REDIS_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL

# Security settings for production
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# Logging for production
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/drink_reminder/drink_reminder.log',
        },
    },
    'loggers': {
        'reminder': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# Static files for production
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'