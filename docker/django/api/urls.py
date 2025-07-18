from django.urls import path
from . import views

urlpatterns = [
    # HTML Views
    path('', views.welcome_view, name='welcome'),
    path('products/', views.product_catalog_view, name='product_catalog'),
    path('init-data/', views.init_sample_data, name='init_sample_data'),
    
    # API Endpoints
    path('health/', views.health_check, name='health_check'),
    path('api/products/', views.product_list_api, name='product_list_api'),
    path('api/products/category/<str:category>/', views.product_by_category_api, name='product_by_category_api'),
    path('api/users/', views.user_list, name='user_list'),
    path('api/users/<str:user_id>/', views.user_detail, name='user_detail'),
    path('api/test-db/', views.test_db, name='test_db'),
]
