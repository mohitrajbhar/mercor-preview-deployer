import os
from pymongo import MongoClient
from django.conf import settings

class MongoDBClient:
    _instance = None
    _client = None
    _database = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(MongoDBClient, cls).__new__(cls)
        return cls._instance

    def __init__(self):
        if self._client is None:
            self.connect()

    def connect(self):
        """Connect to MongoDB"""
        try:
            mongo_settings = settings.MONGODB_SETTINGS
            self._client = MongoClient(
                host=mongo_settings['host'],
                port=mongo_settings['port'],
                serverSelectionTimeoutMS=5000  # 5 second timeout
            )
            self._database = self._client[mongo_settings['database']]
            # Test connection
            self._client.admin.command('ping')
            print(f"Connected to MongoDB: {mongo_settings['host']}:{mongo_settings['port']}/{mongo_settings['database']}")
        except Exception as e:
            print(f"MongoDB connection failed: {e}")
            self._client = None
            self._database = None

    def get_database(self):
        """Get MongoDB database instance"""
        if self._database is None:
            self.connect()
        return self._database

    def get_collection(self, collection_name):
        """Get MongoDB collection"""
        db = self.get_database()
        if db is not None:
            return db[collection_name]
        return None

    def is_connected(self):
        """Check if MongoDB is connected"""
        try:
            if self._client is not None:
                self._client.admin.command('ping')
                return True
        except:
            pass
        return False

# Singleton instance
mongodb_client = MongoDBClient()
