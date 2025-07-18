import os
import json
from datetime import datetime
from django.http import JsonResponse, HttpResponse
from django.shortcuts import render

def health_check(request):
    """Enhanced health check endpoint with beautiful HTML page"""
    try:
        is_connected = mongodb_client.is_connected()
        
        # Get detailed environment information
        health_data = {
            'status': 'healthy' if is_connected else 'unhealthy',
            'database': 'connected' if is_connected else 'disconnected',
            'environment': os.getenv('MONGODB_DATABASE', 'mercor_dev'),
            'host': os.getenv('MONGODB_HOST', 'localhost'),
            'port': os.getenv('MONGODB_PORT', '27017'),
            'pr_number': os.getenv('PR_NUMBER', 'unknown'),
            'debug': os.getenv('DEBUG', 'False'),
            'timestamp': datetime.now().isoformat()
        }
        
        # Get additional system information
        additional_info = {
            'django_version': '4.2',  # Update with your Django version
            'python_version': '3.11',  # Update with your Python version
            'container_info': {
                'hostname': os.uname().nodename if hasattr(os, 'uname') else 'unknown',
                'platform': 'AWS ECS Fargate',
                'network_mode': 'bridge'  # Update based on your configuration
            },
            'services': {
                'mongodb': {
                    'status': 'connected' if is_connected else 'disconnected',
                    'host': health_data['host'],
                    'port': health_data['port'],
                    'database': health_data['environment']
                },
                'django': {
                    'status': 'running',
                    'debug_mode': health_data['debug'],
                    'environment': f"PR-{health_data['pr_number']}"
                }
            }
        }
        
        # Try to get MongoDB stats if connected
        mongodb_stats = {}
        if is_connected:
            try:
                db = mongodb_client.get_database()
                mongodb_stats = {
                    'collections': db.list_collection_names(),
                    'server_info': db.client.server_info().get('version', 'unknown'),
                    'database_name': db.name
                }
            except Exception as e:
                mongodb_stats = {'error': str(e)}
        
        # Check if request wants JSON (for programmatic access)
        if request.headers.get('Accept') == 'application/json' or request.GET.get('format') == 'json':
            return JsonResponse({
                **health_data,
                'additional_info': additional_info,
                'mongodb_stats': mongodb_stats
            })
        
        # Render beautiful HTML page
        context = {
            'health_data': health_data,
            'additional_info': additional_info,
            'mongodb_stats': mongodb_stats,
            'is_healthy': is_connected
        }
        
        return render(request, 'health_check.html', context)
        
    except Exception as e:
        error_data = {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }
        
        # Return JSON for API requests, HTML for browser requests
        if request.headers.get('Accept') == 'application/json' or request.GET.get('format') == 'json':
            return JsonResponse(error_data, status=500)
        
        return render(request, 'health_check.html', {
            'health_data': error_data,
            'additional_info': {},
            'mongodb_stats': {},
            'is_healthy': False,
            'error': True
        })