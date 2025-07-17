from django.contrib import admin
from django.urls import path
from people.views import list_people

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', list_people, name='home'),  # This maps `/` to your view
]