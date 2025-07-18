from django.urls import path
from . import views

urlpatterns = [
    # API Endpoints
    path('health/', views.health_check, name='health_check'),
]
