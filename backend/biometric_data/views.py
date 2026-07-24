from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .serializers import BiometricSyncSerializer

class BiometricSyncView(APIView):
    # Seuls les utilisateurs authentifiés via JWT peuvent envoyer des données biométriques
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # On s'attend à recevoir une liste (un tableau JSON) de mesures
        data = request.data
        if not isinstance(data, list):
            return Response(
                {"error": "Le format attendu est une liste (un tableau JSON) de mesures biométriques."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # On passe `many=True` car on valide et enregistre plusieurs mesures d'un coup
        serializer = BiometricSyncSerializer(data=data, many=True)
        if serializer.is_valid():
            # On sauvegarde le lot en lui injectant dynamiquement l'utilisateur connecté (le patient)
            serializer.save(patient=request.user)
            return Response(
                {"message": f"{len(serializer.validated_data)} mesures synchronisées avec succès."},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
