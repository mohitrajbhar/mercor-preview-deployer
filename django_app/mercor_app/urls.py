# mercor_app/urls.py
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

def root_redirect(request):
    """Redirect root to health check"""
    return redirect('/health/')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', root_redirect, name='root'),  # Root redirects to health
    path('', include('api.urls')),  # Include API app URLs
]