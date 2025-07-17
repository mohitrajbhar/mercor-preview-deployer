from django.db import models

class Person(models.Model):
    name = models.CharField(max_length=100)

    class Meta:
        db_table = "people" 

    def __str__(self):
        return self.name
