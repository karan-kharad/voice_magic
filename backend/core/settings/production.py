from .base import *

DEBUG = False

# Configurable production security settings
SECURE_SSL_REDIRECT = env.bool('SECURE_SSL_REDIRECT', default=False)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = env.bool('SECURE_SSL_REDIRECT', default=False)
CSRF_COOKIE_SECURE = env.bool('SECURE_SSL_REDIRECT', default=False)
SECURE_HSTS_SECONDS = 31536000 if env.bool('SECURE_SSL_REDIRECT', default=False) else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = env.bool('SECURE_SSL_REDIRECT', default=False)
SECURE_HSTS_PRELOAD = env.bool('SECURE_SSL_REDIRECT', default=False)
SECURE_CONTENT_TYPE_NOSNIFF = True

# CORS configuration
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[])
CSRF_TRUSTED_ORIGINS = env.list('CSRF_TRUSTED_ORIGINS', default=[])
