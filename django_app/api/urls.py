# api/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Health check endpoint
    path('health/', views.health_check, name='health_check'),
    
    # API endpoints
    path('api/users/', views.user_list, name='api_users'),
    path('api/users/<str:user_id>/', views.user_detail, name='user_detail'),
    path('api/products/', views.product_list_api, name='api_products'),
    path('api/test-db/', views.test_db, name='api_test_db'),
    
    # Data initialization
    path('init-data/', views.init_sample_data, name='init_data'),
    
    # Welcome/landing page (optional)
    path('welcome/', views.welcome_view, name='welcome'),
]