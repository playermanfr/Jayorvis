# CHANGELOG — windows-optimizer

## v4.1 — 06/06/2026
- Icones generees par le script (System.Drawing natif, aucune dependance externe)
  - BYoan.ico : fond sombre, "B" cyan + "Y" vert matrix, grille circuit, coins L-shape
  - BYoanGaming.ico : fond violet, eclair jaune-orange avec glow
  - Stockees dans scripts\icons\ a cote du .ps1
- Raccourci BYoan sur la barre des taches (cree au premier lancement, option O/N)
  - Detection premier lancement via HKCU\SOFTWARE\WinOptimizer\TaskbarShortcut
  - Raccourci bureau BYoan.lnk + barre des taches (Quick Launch pinned)
  - Refresh shell via SHChangeNotify sans tuer explorer
- [5] renomme : Raccourcis BYoan + Gaming (bureau + taskbar)
  - Genere les icones si absentes, applique BYoanGaming.ico sur GameBoost ON/OFF
- [18] Recreer raccourci BYoan (si besoin)

## v4.0 — 06/06/2026
- Ajout [17] PROFIL SECURITE — Windows Hardening (inspire CIS / ANSSI / STIG)
  - [1] STANDARD : SMBv1, LLMNR, NetBIOS, WDigest, UAC max, Defender+, WPAD, Autorun
  - [2] RENFORCE : LSA Protection, PowerShell logging, audit policy, firewall log,
                   RDP off, WinRM off, SMB signing, partages admin off, SEHOP, RPC
  - [3] PARANOID : Firewall outbound block + whitelist, PSv2 off, WSH off,
                   DNS over HTTPS, Controlled Folder Access, Credential Guard, LSASS dump off
  - [4] SCAN RESEAU : connexions TCP live, ports en ecoute, blocs firewall recents
  - [5] RESET FIREWALL : annuler le block outbound Paranoid
- Audit policy avec GUIDs locale-independants (fonctionne en FR, EN, etc.)

## v3.2 — 06/06/2026
- Rapport Full Auto converti en HTML (de .txt a .html)
- Score synthetique 0-100% calcule sur 4 criteres (disque, services, bloatwares, winget)
- Commentaire automatique selon le score (Optimal / Tres bon / Bon / Partiel)
- 4 cartes chiffres cles en haut : MB liberes, services, bloatwares, AppX
- Barre de progression coloree (vert/bleu/orange/rouge selon score)
- Detail des actions avec badges par categorie
- Rapport s'ouvre automatiquement dans le navigateur apres Full Auto

## v3.1 — 06/06/2026
- Delivery Optimization (DODownloadMode=3) : Internet + reseau local active par defaut
  - Applique dans Profil PERSO (Set-Registry)
  - Applique dans Windows Update Manager option [1] Securite
  - Applique dans Full Auto etape 7

## v3.0 — 06/06/2026
- Ajout [16] FULL AUTO : sequence complete sans interaction (restore+perso+IA+bloat+nettoyage+DNS+WU+winget)
- Rapport de performance genere sur le bureau apres Full Auto (espace libere, services, bloatwares, duree)
- Mesures avant/apres : disque C:, nb services actifs, nb packages AppX
- Rapport compatible avec ou sans exclusions WinGet

## v2.9 — 05/06/2026
- [14] WinGet : ajout mode [E] gestion des exclusions de mise a jour (fichier winget-exclusions.txt persistant)
- [14] Update : si exclusions presentes, update app par app en skippant les exclusions — sinon upgrade --all direct
- [14] Mode [V] dans exclusions : affiche les apps avec updates dispo pour choisir quoi exclure

## v2.8 — 05/06/2026
- [14] WinGet : ajout mode [U] mise a jour silencieuse de toutes les apps installees (winget upgrade --all --silent)

## v2.7 — 05/06/2026
- Ajout [13] DNS Switcher : Cloudflare / AdGuard / Quad9 / Google / NextDNS / DHCP auto — IPv4+IPv6, toutes interfaces actives
- Ajout [14] WinGet Batch Install : 6 categories, 30+ apps, selection fine, code retour "deja installe" gere
- Ajout [15] Windows Update Manager : mode securite (feature updates +365j, patches +4j) / desactivation / defaut / verifier maintenant
- Inspire de WinUtil / Chris Titus Tech

## v2.6 — 05/06/2026
- Ajout option [12] : Mode Install Propre
  - [A] OOBE Bypass : genere OOBE-Bypass.bat + autounattend.xml + LIRE-MOI.txt sur le bureau
  - [B] Post-install auto : sequence complete sans menu (restore point + perso + IA off + bloatwares + nettoyage + SFC + rapport + redemarrage)
  - [C] Les deux

## v2.5 — 05/06/2026
- Ajout option [11] : desactivation IA Windows (Copilot, Recall, Widgets, Suggestions, Clipchamp)
- Inspire de FlyOOBE / builtbybel (Slopilot)
- 8 sections : Copilot / Recall + service AIX / Widgets AppX / Pubs IA / Paint Cocreator / Chat barre taches / Clipchamp / Composants 24H2

## v2.4 — 05/06/2026
- Ajout option [10] : suppression langues inutiles (Office C2R + Windows Capabilities + claviers)
- Script entierement re-encode en ASCII pur (suppression emojis et caracteres speciaux)
- Correction erreurs d'encodage UTF-8 sur Windows

## v2.3 — 04/06/2026
- Ajout option [8] : restaurer Windows depuis un point existant (liste numerotee + confirmation)
- Ajout option [7] : creer un point de restauration manuellement avec nom custom

## v2.2 — 04/06/2026
- Point de restauration propose automatiquement au demarrage
- Propose aussi avant les profils Perso et Entreprise
- Option [P] pour ne plus redemander pendant la session

## v2.1 — 03/06/2026
- Ajout option [9] : suppression bloatwares en 2 etapes (categorie puis fine)
- 4 categories : Jeux Xbox, Apps Microsoft, Constructeurs PC, Apps tierces
- Confirmation "oui" obligatoire avant suppression
- Suppression AppxPackage + AppxProvisionedPackage (pas de retour au prochain update)

## v2.0 — 03/06/2026
- Refonte complete avec menu console numerote
- Profil PERSO : optimisation max (services, visuels, demarrage, registre, SFC)
- Profil ENTREPRISE : optimisation safe (conserve Search, Print, RemoteRegistry, OneDrive, Teams)
- Gaming Mode ON/OFF : toggle instantane
- Creation raccourcis bureau GameBoost ON/OFF (.lnk + .bat)
- Nettoyage disque : TEMP, Prefetch, cache, corbeille, DNS
- Lanceur Lancer-Optimizer.bat pour contourner la restriction de signature

## v1.0 — 03/06/2026
- Script initial sans menu, execution lineaire
