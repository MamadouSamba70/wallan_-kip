import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran de connexion de l'application Wallan.
/// Permet à l'utilisateur de saisir ses identifiants et valide le formulaire en local.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Clé globale pour gérer la validation du formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour récupérer les textes saisis
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Gère l'affichage/masquage du mot de passe
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Libération des ressources des contrôleurs pour éviter les fuites de mémoire
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey, // Associe la clé globale au formulaire
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône d'authentification décorative
                  Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Content de vous revoir',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entrez vos identifiants pour vous connecter à votre bracelet Wallan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 36),

                  // --- Champ Adresse Email ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse Email',
                      hintText: 'exemple@wallan.gn',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    // Validations locales du format d'email
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

                  // --- Champ Mot de passe ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Masque les caractères si true
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      // Bouton à l'extrémité droite pour révéler/masquer le mot de passe
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
                    // Validation du mot de passe
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
                  const SizedBox(height: 12),

                  // --- Bouton "Mot de passe oublié ?" (Simulation) ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonctionnalité de récupération simulée'),
                          ),
                        );
                      },
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Bouton de Connexion ---
                  ElevatedButton(
                    onPressed: () {
                      // Déclenche les fonctions `validator` de chaque champ du formulaire
                      if (_formKey.currentState!.validate()) {
                        // Affiche un message de succès simulé
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connexion réussie (simulation)'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                        // Redirige vers la page d'accueil principale
                        context.go('/');
                      }
                    },
                    child: const Text('Se connecter'),
                  ),
                  const SizedBox(height: 24),

                  // --- Lien d'inscription si pas encore de compte ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Vous n'avez pas de compte ?"),
                      TextButton(
                        onPressed: () => context.push('/register'), // Navigue vers Register
                        child: const Text("S'inscrire"),
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
