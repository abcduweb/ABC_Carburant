import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À Propos'),
        backgroundColor: AppColors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo/Titre
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.local_gas_station,
                    size: 64,
                    color: AppColors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ABC Carburant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Clause de non-responsabilite : application independante,
            // sans lien avec un service public. Doit rester visible sans
            // action de l'utilisateur (exigence Google Play).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8A33D)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF8A5A00)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ABC Carburant est une application indépendante, éditée '
                      'par ABCduWeb. Elle n\'est ni un service officiel ni un '
                      'site du gouvernement : elle affiche des données '
                      'publiques mises à disposition par l\'État.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF5C3D00)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Présentation
            const Text(
              'À Propos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ABC Carburant est une application mobile qui vous permet de comparer les prix des carburants en France en temps réel. '
              'Trouvez les stations les moins chères autour de vous grâce à la géolocalisation GPS et filtrez par type de carburant.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 32),

            // Fonctionnalités
            const Text(
              'Fonctionnalités',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('📍 Géolocalisation GPS', 'Trouve les stations proches de vous'),
            _buildFeatureItem('💰 Prix en temps réel', 'Données publiques actualisées en continu'),
            _buildFeatureItem('🔍 Recherche', 'Cherchez par code postal ou commune'),
            _buildFeatureItem('📊 Filtres', 'Filtrez par type de carburant'),
            _buildFeatureItem('📈 Tri', 'Triez par distance ou prix'),

            const SizedBox(height: 32),

            // Données
            const Text(
              'Source des Données',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏛️ Data.economie.gouv.fr',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Données publiques ouvertes du Ministère de l\'Économie. '
                    'ABC Carburant s\'y connecte pour afficher les prix, sans '
                    'lien officiel avec cette administration.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl('https://data.economie.gouv.fr'),
                    child: const Text(
                      'https://data.economie.gouv.fr',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔌 Open Data Réseaux Énergies (ODRÉ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Localisation des bornes de recharge électrique '
                    '(fichier national IRVE), sans lien officiel avec cet '
                    'organisme. Les Superchargers Tesla affichés dans '
                    'l\'application proviennent de ce même fichier, filtré '
                    'par opérateur — sans lien avec Tesla, Inc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl(
                        'https://odre.opendatasoft.com/explore/dataset/bornes-irve/'),
                    child: const Text(
                      'odre.opendatasoft.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.charcoalLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧭 OpenStreetMap',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fond de carte, recherche d\'adresses et calcul '
                    'd\'itinéraires : données communautaires OpenStreetMap.',
                    style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl('https://www.openstreetmap.org/copyright'),
                    child: const Text(
                      'openstreetmap.org/copyright',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Crédits - ABCDUWEB
            const Text(
              'Développement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/abcduweb.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ABCduWeb',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Agence Web - Beauvallon, Drôme',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ABCduWeb est une agence web spécialisée dans la création de sites WordPress, le SEO/SEA et les solutions custom.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl('https://www.abcduweb.fr'),
                    child: const Text(
                      'www.abcduweb.fr',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.green,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Code source — l'interet du lien n'est pas technique : il
            // rend verifiable la promesse "aucun traceur, aucune
            // publicite" affichee sur la fiche Play Store.
            const Text(
              'Code source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 18, color: AppColors.greenDark),
                      const SizedBox(width: 8),
                      const Text(
                        'Transparence',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.greenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ABC Carburant ne collecte aucune donnée personnelle, '
                    'n\'intègre aucun traceur et n\'affiche aucune '
                    'publicité. Le code source est consultable pour que '
                    'chacun puisse le vérifier par lui-même.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openUrl(
                        'https://github.com/abcduweb/ABC_Carburant'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.code, size: 14, color: AppColors.greenDark),
                        SizedBox(width: 6),
                        Text(
                          'github.com/abcduweb/ABC_Carburant',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greenDark,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Code publié à des fins de vérification. '
                    'Tous droits réservés : toute réutilisation, '
                    'compilation ou redistribution requiert '
                    'l\'autorisation écrite d\'ABCduWeb.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.charcoalLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Technos
            const Text(
              'Technologies Utilisées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTechChip('Flutter'),
                _buildTechChip('Dart'),
                _buildTechChip('Provider'),
                _buildTechChip('OpenStreetMap'),
              ],
            ),

            const SizedBox(height: 32),

            // Liens
            const Text(
              'Ressources',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkItem('Site ABCduWeb', 'https://www.abcduweb.fr'),
            _buildLinkItem('Données data.economie.gouv.fr', 'https://data.economie.gouv.fr'),
            _buildLinkItem('Code source (GitHub)',
                'https://github.com/abcduweb/ABC_Carburant'),
            _buildLinkItem('Flutter Documentation', 'https://flutter.dev'),

            const SizedBox(height: 32),

            // Copyright
            Center(
              child: Column(
                children: [
                  const Text(
                    '© 2026 ABCduWeb',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tous droits réservés',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Ouverture d'une URL dans le navigateur externe
  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // lien invalide ou aucun navigateur disponible
    }
  }

  Widget _buildLinkItem(String title, String url) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title)),
            const Icon(Icons.arrow_outward, size: 16, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}
