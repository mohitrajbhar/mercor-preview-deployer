from django.shortcuts import render
from .models import Person

def list_people(request):
    people = Person.objects.all()
    return render(request, 'people/list.html', {'people': people})