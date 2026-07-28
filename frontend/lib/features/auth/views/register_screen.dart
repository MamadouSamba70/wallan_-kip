import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// RegisterScreen — Vue (V) dans la structure MVVM.
/// Écran d'inscription complet avec validation, gestion du chargement et navigation.
/// Design responsive compatible mobile et tablette.
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Clé de formulaire pour la validation globale ───────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Contrôleurs des champs de saisie ──────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── FocusNodes pour la navigation au clavier ──────────────────────────────
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // ── État local de l'écran ─────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'patient'; // Rôle sélectionné par défaut

  // ── Erreurs de validation retournées par le backend Django ─────────────────
  // Quand Django retourne { "email": ["Ce champ est déjà utilisé."] },
  // on stocke ces erreurs ici et on les affiche directement sous le bon champ.
  final Map<String, String> _fieldErrors = {};

  // ── Animation d'entrée ────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Animation fade + slide vers le haut à l'ouverture de l'écran
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    // Libération de toutes les ressources pour éviter les fuites mémoire
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Action d'inscription ───────────────────────────────────────────────────
  /// Déclenche la validation puis appelle le ViewModel pour s'inscrire.
  /// Gère les erreurs locales (validation Flutter) ET les erreurs backend (Django).
  Future<void> _onRegisterPressed() async {
    // 1. Efface les erreurs backend précédentes avant une nouvelle tentative
    setState(() => _fieldErrors.clear());

    // 2. Ferme le clavier
    FocusScope.of(context).unfocus();

    // 3. Validation locale des champs (règles côté Flutter)
    if (!_formKey.currentState!.validate()) return;

    // 4. Appel au ViewModel → AuthRepository → API Django
    final viewModel = ref.read(authViewModelProvider.notifier);
    final success = await viewModel.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      // ✅ Inscription réussie → SnackBar succès + redirection vers Login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Compte créé ! Connectez-vous maintenant.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/login');
    } else {
      // ❌ Échec → analyse le type d'erreur
      final errorMessage = ref.read(authViewModelProvider).errorMessage ?? '';

      // Tente d'injecter les erreurs champ par champ depuis le message backend.
      // Exemple de message parsé : "Email: Ce champ est déjà utilisé."
      final injected = _tryInjectFieldError(errorMessage);

      if (injected) {
        // Les erreurs sont affichées directement sous les champs → re-valider
        _formKey.currentState?.validate();
      } else if (errorMessage.isNotEmpty) {
        // Erreur globale (ex: serveur down, timeout) → SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  /// Tente d'injecter une erreur backend dans le champ concerné.
  /// Retourne true si l'erreur a été injectée dans un champ spécifique.
  bool _tryInjectFieldError(String message) {
    // Mapping entre les préfixes d'erreur et les clés de champs
    final fieldMap = {
      'Email': 'email',
      'Téléphone': 'phone',
      'Mot de passe': 'password',
      'Nom': 'name',
      'Rôle': 'role',
    };

    for (final entry in fieldMap.entries) {
      if (message.startsWith('${entry.key}:')) {
        setState(() {
          _fieldErrors[entry.value] = message.replaceFirst('${entry.key}: ', '');
        });
        return true;
      }
    }
    return false;
  }

  // ── Validateurs des champs ─────────────────────────────────────────────────
  // Chaque validateur vérifie d'abord les règles locales, puis les erreurs
  // backend injectées via _fieldErrors (erreurs de validation Django).

  String? _validateName(String? value) {
    if (_fieldErrors.containsKey('name')) return _fieldErrors['name'];
    if (value == null || value.trim().isEmpty) {
      return 'Le nom complet est obligatoire';
    }
    if (value.trim().length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }
    if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(value.trim())) {
      return 'Le nom ne doit contenir que des lettres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    // Affiche l'erreur backend en priorité (ex: "Email déjà utilisé")
    if (_fieldErrors.containsKey('email')) return _fieldErrors['email'];
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse email est obligatoire';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (_fieldErrors.containsKey('phone')) return _fieldErrors['phone'];
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire';
    }
    // Accepte les formats : +224XXXXXXXXX, 6XXXXXXXX, 2246XXXXXXXX, etc.
    final phoneRegex = RegExp(r'^[\+]?[\d\s\-\(\)]{8,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Entrez un numéro valide (ex: +224 620 00 00 01)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (_fieldErrors.containsKey('password')) return _fieldErrors['password'];
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Ajoutez au moins une lettre majuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Ajoutez au moins un chiffre';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  // ── Interface utilisateur ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    // Responsive : adapte la largeur selon la taille de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final contentWidth = isTablet ? 560.0 : double.infinity;
    final horizontalPadding = isTablet ? 0.0 : 24.0;

    return Scaffold(
      body: Container(
        // ── Fond dégradé ───────────────────────────────────────────────────
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgLight,
              Color(0xFFDCEEFB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── En-tête ──────────────────────────────────────
                          _buildHeader(theme),
                          const SizedBox(height: 24),

                          // ── Carte du formulaire ───────────────────────────
                          _buildFormCard(theme, isLoading),
                          const SizedBox(height: 20),

                          // ── Lien vers Login ───────────────────────────────
                          _buildLoginLink(theme, isLoading),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget: En-tête de l'écran ─────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Bouton retour manuel (AppBar retiré pour design custom)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppTheme.primaryBlue,
              tooltip: 'Retour à la connexion',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Logo
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Créer un compte',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryBlue,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Rejoignez la plateforme Wallan',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ── Widget: Carte principale du formulaire ─────────────────────────────────
  Widget _buildFormCard(ThemeData theme, bool isLoading) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Nom complet ──────────────────────────────────────────────
            _buildSectionLabel('Informations personnelles'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              // Efface l'erreur backend dès que l'utilisateur retape
              onChanged: (_) => setState(() => _fieldErrors.remove('name')),
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                hintText: 'Mamadou Diallo',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            // ── 2. Adresse Email ────────────────────────────────────────────
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              // Efface l'erreur backend "email déjà utilisé" dès que l'utilisateur retape
              onChanged: (_) => setState(() => _fieldErrors.remove('email')),
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Adresse Email *',
                hintText: 'exemple@wallan.gn',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),

            // ── 3. Téléphone ────────────────────────────────────────────────
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              onChanged: (_) => setState(() => _fieldErrors.remove('phone')),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                hintText: '+224 620 00 00 01',
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: 'Format : +224 6XX XX XX XX',
              ),
              validator: _validatePhone,
            ),
            const SizedBox(height: 24),

            // ── 4. Sécurité (Mot de passe) ──────────────────────────────────
            _buildSectionLabel('Sécurité'),
            const SizedBox(height: 12),

            // Indicateur de règles du mot de passe
            _PasswordRulesHint(passwordController: _passwordController),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              onChanged: (_) => setState(() {}), // Rafraîchit les indicateurs
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              decoration: InputDecoration(
                labelText: 'Mot de passe *',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),

            // ── 5. Confirmation du mot de passe ─────────────────────────────
            TextFormField(
              controller: _confirmPasswordController,
              focusNode: _confirmFocus,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              onFieldSubmitted: (_) => _onRegisterPressed(),
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe *',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 24),

            // ── 6. Sélection du rôle ────────────────────────────────────────
            _buildSectionLabel('Vous êtes :'),
            const SizedBox(height: 12),
            _RoleSelector(
              selectedRole: _selectedRole,
              isDisabled: isLoading,
              onChanged: (role) => setState(() => _selectedRole = role),
            ),
            const SizedBox(height: 28),

            // ── 7. Bouton d'inscription ─────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: isLoading ? 0 : 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Créer mon compte",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget: Label de section ───────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.primaryBlue,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── Widget: Lien vers la page de connexion ─────────────────────────────────
  Widget _buildLoginLink(ThemeData theme, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous avez déjà un compte ?',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
          child: const Text(
            'Se connecter',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Widget affichant les indicateurs de validation du mot de passe en temps réel.
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordRulesHint extends StatelessWidget {
  final TextEditingController passwordController;

  const _PasswordRulesHint({required this.passwordController});

  @override
  Widget build(BuildContext context) {
    final password = passwordController.text;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Règles du mot de passe :',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          _PasswordRule(
            label: 'Au moins 8 caractères',
            isValid: password.length >= 8,
          ),
          _PasswordRule(
            label: 'Une lettre majuscule',
            isValid: RegExp(r'[A-Z]').hasMatch(password),
          ),
          _PasswordRule(
            label: 'Un chiffre',
            isValid: RegExp(r'[0-9]').hasMatch(password),
          ),
        ],
      ),
    );
  }
}

/// Une seule règle de mot de passe avec indicateur visuel (✓ ou ✗).
class _PasswordRule extends StatelessWidget {
  final String label;
  final bool isValid;

  const _PasswordRule({required this.label, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isValid ? AppTheme.successGreen : Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppTheme.successGreen : Colors.black45,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Widget de sélection du rôle avec des cartes visuelles (Patient, Proche, Admin).
// ─────────────────────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final bool isDisabled;
  final void Function(String) onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.isDisabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      _RoleOption(
        value: 'patient',
        label: 'Patient',
        description: 'Suivi de mes constantes vitales',
        icon: Icons.monitor_heart_outlined,
        color: AppTheme.primaryBlue,
      ),
      _RoleOption(
        value: 'relative',
        label: 'Proche',
        description: 'Surveillance d\'un proche',
        icon: Icons.family_restroom_rounded,
        color: Colors.indigo,
      ),
      _RoleOption(
        value: 'admin',
        label: 'Admin',
        description: 'Gestion de la plateforme',
        icon: Icons.admin_panel_settings_outlined,
        color: Colors.blueGrey.shade700,
      ),
    ];

    return Column(
      children: roles.map((role) {
        final isSelected = selectedRole == role.value;
        return GestureDetector(
          onTap: isDisabled ? null : () => onChanged(role.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? role.color.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? role.color : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? role.color.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    role.icon,
                    size: 20,
                    color: isSelected ? role.color : Colors.grey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected ? role.color : Colors.black87,
                        ),
                      ),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? role.color.withValues(alpha: 0.8)
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: role.color, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Modèle de données pour une option de rôle.
class _RoleOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}
