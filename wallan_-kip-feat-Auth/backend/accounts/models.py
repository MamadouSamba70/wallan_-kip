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

#Table d'identité des utilisateurs
class User(AbstractBaseUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, max_length=254)
    ROLE_CHOICES = [
        ('patient', 'Patient'),
        ('proche', 'Proche'),
        ('admin', 'Administrateur'),
    ]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='patient')
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    
    #Lie UserManager à ce modèle. c'est lui qui sera appelé lors de User.objects.create_user(....)
    objects = UserManager()

    #Indique que le champ 'email' est le champ d'identification unique de l'utilisateur.
    USERNAME_FIELD = 'email'
    #Champ requis lors de la création d'un super utilisateur
    REQUIRED_FIELDS = []

    #Quand tu affiches un User dans le terminal, il affiche l'email
    def __str__(self):
        return self.email
    
    #Fonction qui permet de vérifier si l'utilisateur a une permission
    def has_perm(self, perm, obj=None):
        return self.is_superuser

    #Fonction qui permet de vérifier si l'utilisateur a une permission sur un module
    def has_module_perms(self, app_label):
        return self.is_superuser


        