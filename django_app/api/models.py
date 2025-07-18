from django.db import models

class SystemLog(models.Model):
    """Simple Django model for system logging (uses SQLite)"""
    timestamp = models.DateTimeField(auto_now_add=True)
    level = models.CharField(max_length=20, default='INFO')
    message = models.TextField()
    pr_number = models.CharField(max_length=50, blank=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.timestamp} - {self.level}: {self.message[:50]}"