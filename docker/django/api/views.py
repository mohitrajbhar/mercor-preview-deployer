import json
import os
from django.http import JsonResponse, HttpResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from datetime import datetime
from bson import ObjectId
from .mongodb import mongodb_client

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

def welcome_view(request):
    """Welcome page with navigation"""
    try:
        if not mongodb_client.is_connected():
            return render(request, 'error.html', {
                'error': 'Database connection failed',
                'details': 'MongoDB is not accessible'
            })
            
        products_collection = mongodb_client.get_collection('products')
        users_collection = mongodb_client.get_collection('users')
        
        products_count = products_collection.count_documents({}) if products_collection else 0
        users_count = users_collection.count_documents({}) if users_collection else 0
        
        context = {
            'pr_number': os.getenv('PR_NUMBER', 'unknown'),
            'mongodb_host': os.getenv('MONGODB_HOST', 'localhost'),
            'products_count': products_count,
            'users_count': users_count,
            'endpoints': [
                {'name': 'Product Catalog', 'url': '/products/', 'description': 'View all products'},
                {'name': 'API - Products', 'url': '/api/products/', 'description': 'Products JSON API'},
                {'name': 'API - Users', 'url': '/api/users/', 'description': 'Users JSON API'},
                {'name': 'Health Check', 'url': '/health/', 'description': 'System health status'},
                {'name': 'Admin Panel', 'url': '/admin/', 'description': 'Django admin interface'},
            ]
        }
        
        return render(request, 'welcome.html', context)
        
    except Exception as e:
        return render(request, 'error.html', {
            'error': 'Application error',
            'details': str(e)
        })

def product_catalog_view(request):
    """Display products in a nice HTML page"""
    try:
        products_collection = mongodb_client.get_collection('products')
        if not products_collection:
            return render(request, 'error.html', {
                'error': 'Database connection failed',
                'details': 'Cannot connect to MongoDB'
            })
            
        products = list(products_collection.find())
        
        # Convert ObjectId to string for template rendering
        for product in products:
            product['_id'] = str(product['_id'])
            if 'created_at' in product and hasattr(product['created_at'], 'isoformat'):
                product['created_at'] = product['created_at'].isoformat()
            
        context = {
            'products': products,
            'pr_number': os.getenv('PR_NUMBER', 'unknown'),
            'total_products': len(products)
        }
        
        return render(request, 'products.html', context)
        
    except Exception as e:
        return render(request, 'error.html', {
            'error': 'Failed to fetch products',
            'details': str(e)
        })

def init_sample_data(request):
    """Initialize sample data in MongoDB"""
    try:
        products_collection = mongodb_client.get_collection('products')
        users_collection = mongodb_client.get_collection('users')
        
        if not products_collection or not users_collection:
            return JsonResponse({
                'status': 'error',
                'message': 'Database connection failed'
            }, status=500)
        
        # Check if data already exists
        if products_collection.count_documents({}) > 0:
            return JsonResponse({
                'status': 'info',
                'message': 'Sample data already exists',
                'products_count': products_collection.count_documents({}),
                'users_count': users_collection.count_documents({})
            })
        
        # Sample products data
        sample_products = [
            {
                'name': 'Laptop Pro 15"',
                'description': 'High-performance laptop with 16GB RAM and 512GB SSD',
                'price': 1299.99,
                'category': 'Electronics',
                'in_stock': True,
                'stock_quantity': 25,
                'created_at': datetime.now(),
                'tags': ['laptop', 'computer', 'portable']
            },
            {
                'name': 'Wireless Headphones',
                'description': 'Premium noise-cancelling wireless headphones',
                'price': 199.99,
                'category': 'Audio',
                'in_stock': True,
                'stock_quantity': 50,
                'created_at': datetime.now(),
                'tags': ['headphones', 'wireless', 'audio']
            },
            {
                'name': 'Smart Watch Series 8',
                'description': 'Advanced fitness tracking and health monitoring',
                'price': 399.99,
                'category': 'Wearables',
                'in_stock': True,
                'stock_quantity': 30,
                'created_at': datetime.now(),
                'tags': ['smartwatch', 'fitness', 'health']
            },
            {
                'name': 'Coffee Maker Deluxe',
                'description': 'Programmable coffee maker with built-in grinder',
                'price': 149.99,
                'category': 'Kitchen',
                'in_stock': True,
                'stock_quantity': 15,
                'created_at': datetime.now(),
                'tags': ['coffee', 'kitchen', 'appliance']
            },
            {
                'name': 'Gaming Mouse RGB',
                'description': 'High-precision gaming mouse with customizable RGB lighting',
                'price': 79.99,
                'category': 'Gaming',
                'in_stock': False,
                'stock_quantity': 0,
                'created_at': datetime.now(),
                'tags': ['gaming', 'mouse', 'rgb']
            },
            {
                'name': 'Bluetooth Speaker',
                'description': 'Portable waterproof speaker with 12-hour battery',
                'price': 89.99,
                'category': 'Audio',
                'in_stock': True,
                'stock_quantity': 40,
                'created_at': datetime.now(),
                'tags': ['speaker', 'bluetooth', 'portable']
            }
        ]
        
        # Sample users data
        sample_users = [
            {
                'name': 'Alice Johnson',
                'email': 'alice@example.com',
                'role': 'customer',
                'created_at': datetime.now(),
                'preferences': ['Electronics', 'Gaming']
            },
            {
                'name': 'Bob Smith',
                'email': 'bob@example.com',
                'role': 'customer',
                'created_at': datetime.now(),
                'preferences': ['Kitchen', 'Audio']
            },
            {
                'name': 'Carol Wilson',
                'email': 'carol@example.com',
                'role': 'admin',
                'created_at': datetime.now(),
                'preferences': ['Wearables', 'Electronics']
            }
        ]
        
        # Insert data
        products_result = products_collection.insert_many(sample_products)
        users_result = users_collection.insert_many(sample_users)
        
        return JsonResponse({
            'status': 'success',
            'message': 'Sample data initialized successfully',
            'products_inserted': len(products_result.inserted_ids),
            'users_inserted': len(users_result.inserted_ids),
            'view_products': '/products/',
            'api_products': '/api/products/'
        })
        
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)

@csrf_exempt
@require_http_methods(["GET"])
def product_list_api(request):
    """API endpoint to get all products"""
    try:
        products_collection = mongodb_client.get_collection('products')
        if not products_collection:
            return JsonResponse({
                'status': 'error',
                'error': 'Database connection failed'
            }, status=500)
            
        products = list(products_collection.find())
        
        # Convert ObjectId and datetime to string
        for product in products:
            product['_id'] = str(product['_id'])
            if 'created_at' in product and hasattr(product['created_at'], 'isoformat'):
                product['created_at'] = product['created_at'].isoformat()
        
        return JsonResponse({
            'status': 'success',
            'products': products,
            'count': len(products)
        })
        
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)

@csrf_exempt
@require_http_methods(["GET"])
def product_by_category_api(request, category):
    """API endpoint to get products by category"""
    try:
        products_collection = mongodb_client.get_collection('products')
        if not products_collection:
            return JsonResponse({
                'status': 'error',
                'error': 'Database connection failed'
            }, status=500)
            
        products = list(products_collection.find({'category': category}))
        
        # Convert ObjectId and datetime to string
        for product in products:
            product['_id'] = str(product['_id'])
            if 'created_at' in product and hasattr(product['created_at'], 'isoformat'):
                product['created_at'] = product['created_at'].isoformat()
        
        return JsonResponse({
            'status': 'success',
            'category': category,
            'products': products,
            'count': len(products)
        })
        
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)

def test_db(request):
    """Test database connection and operations"""
    try:
        test_collection = mongodb_client.get_collection('test_collection')
        if not test_collection:
            return JsonResponse({
                'status': 'error',
                'error': 'Database connection failed'
            }, status=500)
        
        # Insert a test document
        test_doc = {
            'message': 'Hello from PR environment!',
            'timestamp': datetime.now(),
            'pr_number': os.getenv('PR_NUMBER', 'unknown')
        }
        result = test_collection.insert_one(test_doc)
        
        # Retrieve the document
        retrieved = test_collection.find_one({'_id': result.inserted_id})
        retrieved['_id'] = str(retrieved['_id'])
        if 'timestamp' in retrieved and hasattr(retrieved['timestamp'], 'isoformat'):
            retrieved['timestamp'] = retrieved['timestamp'].isoformat()
        
        return JsonResponse({
            'status': 'success',
            'operation': 'insert_and_retrieve',
            'document': retrieved
        })
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)

@csrf_exempt
@require_http_methods(["GET", "POST"])
def user_list(request):
    """List all users or create a new user"""
    try:
        users_collection = mongodb_client.get_collection('users')
        if not users_collection:
            return JsonResponse({
                'status': 'error',
                'error': 'Database connection failed'
            }, status=500)
    
        if request.method == 'GET':
            users = list(users_collection.find())
            for user in users:
                user['_id'] = str(user['_id'])
                if 'created_at' in user and hasattr(user['created_at'], 'isoformat'):
                    user['created_at'] = user['created_at'].isoformat()
            
            return JsonResponse({
                'status': 'success',
                'users': users,
                'count': len(users)
            })
        
        elif request.method == 'POST':
            data = json.loads(request.body)
            data['created_at'] = datetime.now()
            result = users_collection.insert_one(data)
            
            return JsonResponse({
                'status': 'success',
                'user_id': str(result.inserted_id),
                'message': 'User created successfully'
            }, status=201)
            
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)

@csrf_exempt
@require_http_methods(["GET", "PUT", "DELETE"])
def user_detail(request, user_id):
    """Get, update, or delete a specific user"""
    try:
        users_collection = mongodb_client.get_collection('users')
        if not users_collection:
            return JsonResponse({
                'status': 'error',
                'error': 'Database connection failed'
            }, status=500)
    
        if request.method == 'GET':
            user = users_collection.find_one({'_id': ObjectId(user_id)})
            if user:
                user['_id'] = str(user['_id'])
                if 'created_at' in user and hasattr(user['created_at'], 'isoformat'):
                    user['created_at'] = user['created_at'].isoformat()
                return JsonResponse({
                    'status': 'success',
                    'user': user
                })
            else:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                }, status=404)
        
        elif request.method == 'PUT':
            data = json.loads(request.body)
            data['updated_at'] = datetime.now()
            result = users_collection.update_one(
                {'_id': ObjectId(user_id)},
                {'$set': data}
            )
            
            if result.matched_count:
                return JsonResponse({
                    'status': 'success',
                    'message': 'User updated successfully'
                })
            else:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                }, status=404)
        
        elif request.method == 'DELETE':
            result = users_collection.delete_one({'_id': ObjectId(user_id)})
            
            if result.deleted_count:
                return JsonResponse({
                    'status': 'success',
                    'message': 'User deleted successfully'
                })
            else:
                return JsonResponse({
                    'status': 'error',
                    'message': 'User not found'
                }, status=404)
                
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'error': str(e)
        }, status=500)