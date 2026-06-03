from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import datetime

doc = Document()

for section in doc.sections:
    section.top_margin    = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin   = Cm(3.0)
    section.right_margin  = Cm(3.0)

BLUE  = RGBColor(0x1E, 0x3A, 0x5F)
GRAY  = RGBColor(0x44, 0x44, 0x44)
ORANGE = RGBColor(0xF5, 0x9E, 0x0B)

# ── Entête ────────────────────────────────────────────────────────────────────
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run('COMPLEXE SCOLAIRE LE SAGE')
r.bold = True; r.font.size = Pt(11); r.font.color.rgb = ORANGE

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run('The Wise School International — Kinshasa, RDC')
r.font.size = Pt(9); r.font.color.rgb = GRAY

doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run('SCHOOLSAFE v3.0')
r.bold = True; r.font.size = Pt(20); r.font.color.rgb = BLUE

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run('Liste des services offerts par l\'application')
r.font.size = Pt(12); r.font.color.rgb = GRAY; r.italic = True

doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run(datetime.date.today().strftime('%d %B %Y'))
r.font.size = Pt(9); r.font.color.rgb = GRAY; r.italic = True

doc.add_page_break()

# ── Helper ─────────────────────────────────────────────────────────────────────
def section_title(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after  = Pt(4)
    r = p.add_run(text.upper())
    r.bold = True; r.font.size = Pt(11); r.font.color.rgb = BLUE

def service(doc, numero, titre, description):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after  = Pt(3)
    p.paragraph_format.left_indent  = Cm(0.5)
    r1 = p.add_run(f'{numero}.  {titre}')
    r1.bold = True; r1.font.size = Pt(10.5); r1.font.color.rgb = GRAY
    r2 = p.add_run(f'\n        {description}')
    r2.font.size = Pt(9.5); r2.font.color.rgb = RGBColor(0x66,0x66,0x66); r2.italic = True

# ══════════════════════════════════════════════════════════════════════════════
n = 1

section_title(doc, '🎓  Gestion des élèves')
service(doc, n, 'Enregistrement des élèves', 'Créer, modifier et archiver le dossier complet de chaque élève'); n+=1
service(doc, n, 'Production de cartes scolaires QR', 'Générer la carte d\'identité scolaire avec photo, nom, classe et QR code unique'); n+=1
service(doc, n, 'Export des cartes en lot', 'Télécharger toutes les cartes scolaires en une seule fois pour impression'); n+=1
service(doc, n, 'Suivi du dossier médical', 'Enregistrer les allergies, médicaments et visites à l\'infirmerie pour chaque élève'); n+=1
service(doc, n, 'Gestion de la conduite', 'Attribuer une note de comportement et documenter les sanctions disciplinaires'); n+=1

section_title(doc, '🏫  Gestion scolaire')
service(doc, n, 'Gestion des classes', 'Créer et organiser les classes avec leurs enseignants titulaires'); n+=1
service(doc, n, 'Gestion des matières', 'Définir les matières enseignées dans chaque classe'); n+=1
service(doc, n, 'Emploi du temps', 'Créer et afficher le planning hebdomadaire de chaque classe'); n+=1
service(doc, n, 'Calendrier scolaire', 'Publier les événements, examens, fêtes et journées spéciales de l\'école'); n+=1
service(doc, n, 'Activités parascolaires', 'Gérer les clubs et activités extra-scolaires avec inscription des élèves'); n+=1

section_title(doc, '📋  Présences & Absences')
service(doc, n, 'Suivi des présences journalières', 'Enregistrer et consulter les présences de chaque élève (présent, retard, absent, excusé, malade)'); n+=1
service(doc, n, 'Justification des absences', 'Les parents soumettent une justification, la direction approuve ou rejette'); n+=1
service(doc, n, 'Déclaration d\'absence enseignant', 'Un professeur déclare son propre congé avec notification automatique à la direction'); n+=1

section_title(doc, '🔒  Sécurité & Portail d\'accès')
service(doc, n, 'Contrôle d\'entrée par QR code', 'Scanner la carte de l\'élève à l\'entrée de l\'école avec enregistrement automatique de l\'heure'); n+=1
service(doc, n, 'Contrôle de sortie', 'Vérifier l\'identité de la personne venant récupérer l\'élève à la sortie'); n+=1
service(doc, n, 'Personnes autorisées à la sortie', 'Enregistrer les personnes autorisées à récupérer chaque élève (avec photo)'); n+=1
service(doc, n, 'Journal des entrées et sorties', 'Historique complet et horodaté de tous les passages au portail'); n+=1
service(doc, n, 'Alertes de sécurité', 'Notification automatique en cas de QR inconnu ou de personne non autorisée'); n+=1
service(doc, n, 'Mode LOCKDOWN', 'Verrouillage d\'urgence de toutes les sorties avec notification immédiate aux parents'); n+=1
service(doc, n, 'Blocage automatique des impayés', 'Refus d\'entrée configurable pour les élèves dont les frais scolaires sont en retard'); n+=1

section_title(doc, '📚  Pédagogie')
service(doc, n, 'Saisie et consultation des notes', 'Les enseignants entrent les notes par matière et trimestre ; parents et direction les consultent'); n+=1
service(doc, n, 'Calcul automatique des moyennes', 'Calcul instantané des moyennes par matière, trimestre et moyenne générale'); n+=1
service(doc, n, 'Palmarès et classement', 'Affichage du top 10 des élèves par moyenne à l\'échelle de l\'école et par classe'); n+=1
service(doc, n, 'Cours de rattrapage', 'Signalement, validation et planification des séances de remédiation pour les élèves en difficulté'); n+=1
service(doc, n, 'Devoirs et travaux à domicile', 'Publication des devoirs par les enseignants, consultation par les parents'); n+=1
service(doc, n, 'Cahier de texte numérique', 'Les enseignants consignent le contenu de chaque cours, validé par la direction pédagogique'); n+=1
service(doc, n, 'Examens TENAFEP (CM2)', 'Suivi des dossiers des élèves de 5ème année pour l\'examen national'); n+=1

section_title(doc, '💰  Finances')
service(doc, n, 'Suivi des paiements de scolarité', 'Enregistrer et consulter les paiements des frais scolaires par élève et par trimestre'); n+=1
service(doc, n, 'Calcul du solde restant', 'Afficher automatiquement le montant encore dû par chaque famille'); n+=1
service(doc, n, 'Enregistrement des dépenses', 'Consigner les dépenses de l\'école avec catégorie et montant'); n+=1
service(doc, n, 'Rapport journalier de caisse', 'Résumé quotidien des recettes et dépenses'); n+=1
service(doc, n, 'Configuration des frais scolaires', 'Définir les montants de scolarité pour chaque trimestre'); n+=1

section_title(doc, '🍽️  Cantine')
service(doc, n, 'Gestion des abonnements cantine', 'Suivre les élèves inscrits au service de restauration et leurs frais'); n+=1
service(doc, n, 'Menus journaliers', 'Publier le menu du jour consultable par les parents'); n+=1
service(doc, n, 'Présences à la cantine', 'Enregistrer la participation quotidienne des élèves au repas'); n+=1

section_title(doc, '📢  Communication')
service(doc, n, 'Messagerie interne', 'Échanges directs entre enseignants, parents et direction'); n+=1
service(doc, n, 'Notifications en temps réel', 'Alertes automatiques pour absences, paiements, devoirs, convocations'); n+=1
service(doc, n, 'Annonces générales', 'Diffusion d\'un message à l\'ensemble des parents de l\'école en un clic'); n+=1
service(doc, n, 'Convocations parents', 'Planifier et suivre les réunions avec les parents (avec gestion de présence)'); n+=1

section_title(doc, '👥  Ressources humaines')
service(doc, n, 'Gestion des comptes utilisateurs', 'Créer et gérer les accès pour enseignants, parents, gardiens et directeurs'); n+=1
service(doc, n, 'Salaires et avances', 'Enregistrer les salaires mensuels et les avances des enseignants'); n+=1
service(doc, n, 'Primes et bonus', 'Attribuer et consulter les primes d\'incentive pour le personnel'); n+=1
service(doc, n, 'Évaluation des enseignants', 'Conduire et archiver les évaluations annuelles de performance'); n+=1
service(doc, n, 'Rapport SECOPE / MEPSP', 'Générer le rapport de conformité pour le Ministère de l\'EPST'); n+=1

section_title(doc, '🗂️  Administration & Données')
service(doc, n, 'Journal d\'audit', 'Traçabilité complète de toutes les actions effectuées dans le système'); n+=1
service(doc, n, 'Approbations & workflow', 'File de validation unifiée pour absences, matières, messages, rattrapages'); n+=1
service(doc, n, 'Export de données', 'Télécharger les données (élèves, notes, paiements, présences) en CSV ou PDF'); n+=1
service(doc, n, 'Archivage de fin d\'année', 'Générer un PDF complet de l\'année scolaire et nettoyer la base pour la rentrée'); n+=1
service(doc, n, 'Importation en masse', 'Importer des listes d\'élèves ou d\'utilisateurs depuis un fichier tableur'); n+=1
service(doc, n, 'Paramétrage de l\'école', 'Configurer le nom, le logo, les horaires et les options de l\'établissement'); n+=1

section_title(doc, '📱  Technologie')
service(doc, n, 'Application installable (PWA)', 'Installer SchoolSafe sur téléphone ou tablette comme une application native'); n+=1
service(doc, n, 'Mode hors-ligne', 'Utilisation complète sans connexion internet grâce au stockage local sécurisé'); n+=1
service(doc, n, 'Synchronisation automatique', 'Les données locales sont envoyées au serveur dès le retour en ligne'); n+=1
service(doc, n, 'Interface bilingue (FR / EN)', 'Application disponible en français et en anglais selon la préférence'); n+=1
service(doc, n, 'Sécurité des données', 'Données chiffrées (AES-256-GCM), accès protégés, mots de passe sécurisés'); n+=1

# ── Pied de page ──────────────────────────────────────────────────────────────
doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run(f'SchoolSafe v3.0  ·  {n-1} services  ·  {datetime.date.today().strftime("%Y")}')
r.font.size = Pt(8.5); r.font.color.rgb = RGBColor(0xAA,0xAA,0xAA); r.italic = True

path = '/home/user/zalavrai/SchoolSafe_Services.docx'
doc.save(path)
print(f'OK — {n-1} services — {path}')
