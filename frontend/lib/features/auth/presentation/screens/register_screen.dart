import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran d'inscription de l'application Wallan.
/// Permet à un utilisateur de créer un compte avec un rôle spécifique.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Clé globale pour gérer la validation du formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour récupérer les valeurs saisies par l'utilisateur
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Rôle sélectionné par défaut
  String _selectedRole = 'patient'; // Choix possibles : 'patient', 'proche', 'admin'
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Libération des contrôleurs de texte pour éviter les fuites de mémoire
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône décorative pour l'inscription
                  Icon(
                    Icons.app_registration_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Rejoindre Wallan',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez votre compte pour suivre vos constantes vitales',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 36),

                  // --- Champ Nom Complet ---
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom complet';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Champ Adresse Email ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      if (!value.contains('@')) {
                        return 'Veuillez entrer un email valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Champ Téléphone (Format guinéen de préférence) ---
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      hintText: '+224 ...',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Champ Mot de passe ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit faire au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- Sélecteur de Rôle (SegmentedButton) ---
                  Text(
                    'Vous êtes :',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'patient',
                        label: Text('Patient'),
                        icon: Icon(Icons.sick_outlined),
                      ),
                      ButtonSegment<String>(
                        value: 'proche',
                        label: Text('Proche'),
                        icon: Icon(Icons.family_restroom),
                      ),
                      ButtonSegment<String>(
                        value: 'admin',
                        label: Text('Admin'),
                        icon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                    ],
                    selected: {_selectedRole}, // Rôle actuellement sélectionné
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedRole = newSelection.first; // Met à jour le rôle sélectionné
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- Bouton d'Inscription ---
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Inscription réussie en tant que ${_selectedRole.toUpperCase()} (simulation)'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                        context.go('/'); // Retourne à l'accueil
                      }
                    },
                    child: const Text("S'inscrire"),
                  ),
                  const SizedBox(height: 24),

                  // --- Retour à la Connexion ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous avez déjà un compte ?"),
                      TextButton(
                        onPressed: () => context.pop(), // Rebranche sur l'écran précédent (Login)
                        child: const Text('Connexion'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
