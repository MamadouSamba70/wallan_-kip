import uuid #Used to generate a unique identifier for each user
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager #Used to manage user accounts

# Create your models here.

class UserManager(BaseUserManager):
    #Fonction qui permet de créer un utilisateur à chaque inscription
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("L'adresse email est obligatoire")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    #Fonction qui permet de créer un super utilisateur
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('role', 'admin')
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)
