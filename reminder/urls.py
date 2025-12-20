from django.urls import path
from . import views

app_name = 'reminder'
urlpatterns = [
    path('', views.index, name='index'),
    path('send-test/', views.send_test_notification, name='send_test_notification'),
    path('status/', views.status, name='status'),
]