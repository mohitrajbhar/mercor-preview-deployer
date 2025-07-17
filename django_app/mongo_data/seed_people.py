from pymongo import MongoClient

# Connect to your local Mongo instance
client = MongoClient("mongodb://admin:pass@localhost:27017/")

# Use the correct database and collection
db = client["testdb"]
collection = db["people"]

collection.delete_many({})

# Sample data to insert
people = [
    {"name": "Alice"},
    {"name": "Bob"},
    {"name": "Charlie"},
    {"name": "Dev"},
    {"name": "Mohit"},
]

# Insert the documents
collection.insert_many(people)

print("Data inserted successfully.")
