import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANT LOGO WALLAN
//
// Représente l'identité visuelle officielle de l'application Wallan :
// Cœur médical + boucle de bracelet connecté + ondes radio cyan + typographie.
// ─────────────────────────────────────────────────────────────────────────────

/// Widget Logo officiel Wallan réutilisable dans l'application.
class WallanLogo extends StatelessWidget {
  /// Taille (hauteur) du logo.
  final double size;

  /// Si true, affiche le badge blanc circulaire autour du logo (ex: SplashScreen / Login).
  final bool showBadge;

  /// Si true, affiche uniquement le symbole/icône sans le texte "WALLAN".
  final bool iconOnly;

  const WallanLogo({
    super.key,
    this.size = 100,
    this.showBadge = true,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Image.asset(
      'assets/images/wallan_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback vectoriel en cas de problème de chargement d'image
        return _VectorWallanLogo(size: size, iconOnly: iconOnly);
      },
    );

    if (showBadge) {
      return Container(
        padding: EdgeInsets.all(size * 0.15),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003087).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
  }
}

/// Fallback visuel vectoriel du logo officiel Wallan
class _VectorWallanLogo extends StatelessWidget {
  final double size;
  final bool iconOnly;

  const _VectorWallanLogo({required this.size, required this.iconOnly});

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF0B2545);
    const cyanBlue = Color(0xFF00A8E8);

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône Cœur + Bracelet + Signal
          SizedBox(
            width: size * 0.6,
            height: size * 0.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: size * 0.45,
                  color: navyBlue,
                ),
                Positioned(
                  right: 0,
                  top: 2,
                  child: Icon(
                    Icons.sensors_rounded,
                    size: size * 0.25,
                    color: cyanBlue,
                  ),
                ),
              ],
            ),
          ),
          if (!iconOnly) ...[
            SizedBox(width: size * 0.1),
            Text(
              'WALLAN',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w900,
                color: navyBlue,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
