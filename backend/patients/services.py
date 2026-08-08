"""
SERVICES DU MODULE PATIENTS (Semaine 5 - Fatima Abdul Sow)

Ce fichier regroupe la logique métier liée aux recommandations de santé et à l'analyse
des constantes vitales pour chaque patient.
"""

from typing import List, Dict, Any


def generate_patient_recommendations(patient) -> List[Dict[str, Any]]:
    """
    Génère une liste de recommandations hygiéno-diététiques et médicales
    personnalisées pour un patient donné, selon sa condition médicale et ses
    dernières mesures biométriques reçues.
    """
    recommendations = []

    # 1. Recommandations basées sur la condition médicale
    condition = getattr(patient, 'condition', 'rheumatism')
    if condition == 'rheumatism':
        recommendations.append({
            'category': 'condition',
            'severity': 'info',
            'title': 'Gestion du rhumatisme',
            'message': 'Maintenez une activité physique douce et évitez l\'exposition prolongée au froid pour limiter les raideurs articulaires.'
        })
    else:
        recommendations.append({
            'category': 'condition',
            'severity': 'info',
            'title': 'Suivi médical général',
            'message': 'Assurez-vous de respecter les prises médicamenteuses prescrites et de consulter régulièrement votre médecin traitant.'
        })

    # 2. Analyse des dernières mesures biométriques (si disponibles)
    recent_readings = list(patient.biometric_readings.all()[:5])

    if recent_readings:
        latest = recent_readings[0]

        # Analyse du Rythme Cardiaque (Heart Rate)
        if latest.heart_rate > patient.threshold_heart_rate:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'warning',
                'title': 'Rythme cardiaque élevé',
                'message': f"Votre fréquence cardiaque enregistrée ({latest.heart_rate} bpm) dépasse votre seuil personnalisé ({patient.threshold_heart_rate} bpm). Accordez-vous une pause et restez calme."
            })
        elif latest.heart_rate < 50:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'warning',
                'title': 'Rythme cardiaque faible',
                'message': f"Votre fréquence cardiaque enregistrée ({latest.heart_rate} bpm) est particulièrement basse. Prenez contact avec un professionnel si la sensation persiste."
            })
        else:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'success',
                'title': 'Rythme cardiaque stable',
                'message': f"Votre fréquence cardiaque est normale ({latest.heart_rate} bpm)."
            })

        # Analyse de la Température Corporelle
        if latest.temperature > patient.threshold_temperature:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'warning',
                'title': 'Température élevée (Fièvre)',
                'message': f"Votre température ({latest.temperature} °C) dépasse le seuil fixé ({patient.threshold_temperature} °C). Pensez à bien vous hydrater et restez au frais."
            })
        elif latest.temperature < 35.5:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'warning',
                'title': 'Température corporelle basse',
                'message': f"Votre température ({latest.temperature} °C) est inférieure à la normale. Couvrez-vous chaudement."
            })
        else:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'success',
                'title': 'Température corporelle normale',
                'message': f"Température idéale ({latest.temperature} °C)."
            })

        # Analyse du SpO2
        if latest.spo2 < patient.threshold_spo2:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'danger',
                'title': 'Saturation en oxygène faible (SpO2)',
                'message': f"Votre saturation en oxygène ({latest.spo2}%) est en dessous de votre seuil ({patient.threshold_spo2}%). Adoptez une position assise et respirez profondément."
            })
        else:
            recommendations.append({
                'category': 'vital_sign',
                'severity': 'success',
                'title': 'Saturation SpO2 optimale',
                'message': f"Taux d'oxygène dans le sang parfait ({latest.spo2}%)."
            })

    else:
        recommendations.append({
            'category': 'general',
            'severity': 'info',
            'title': 'Synchronisation du bracelet',
            'message': 'Aucune donnée biométrique récente trouvée. Assurez-vous que votre bracelet connecté Wallan est bien appairé et allumé.'
        })

    # 3. Vérification des alertes récentes non résolues
    active_alerts_count = patient.alerts.filter(status='active').count()
    if active_alerts_count > 0:
        recommendations.append({
            'category': 'alert',
            'severity': 'danger',
            'title': 'Alerte active en cours',
            'message': f"Vous avez {active_alerts_count} alerte(s) active(s). Vos proches ou votre médecin référent en ont été informés."
        })

    return recommendations
