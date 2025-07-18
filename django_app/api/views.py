import os
import json
from datetime import datetime
from django.http import JsonResponse, HttpResponse
from django.shortcuts import render
from .mongodb import mongodb_client  # Update import path as needed

def health_check(request):
    """Health check endpoint for ALB"""
    try:
        is_connected = mongodb_client.is_connected()
        
        return JsonResponse({
            'status': 'healthy' if is_connected else 'unhealthy',
            'database': 'connected' if is_connected else 'disconnected',
            'environment': os.getenv('MONGODB_DATABASE', 'mercor_dev'),
            'host': os.getenv('MONGODB_HOST', 'localhost'),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({
            'status': 'unhealthy',
            'error': str(e)
        }, status=500)