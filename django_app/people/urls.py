from django.urls import path
from .views import list_people

urlpatterns = [
    path('', list_people, name='list_people'),
]
