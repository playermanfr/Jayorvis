# Windows Optimizer — Mode d'emploi
**Fichier** : `scripts/windows-optimize.ps1`
**Version** : 4.1 | **Mise a jour** : 06/06/2026

---

## Lancer le script

> Le script propose automatiquement un point de restauration avant chaque modification importante.

**Option 1 — Le plus simple (double-clic)**
1. Copie `Lancer-Optimizer.bat` et `windows-optimize.ps1` dans le meme dossier
2. Double-clic sur `Lancer-Optimizer.bat`
3. Accepte la demande d'administrateur

**Option 2 — PowerShell direct**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "windows-optimize.ps1"
```

---

## Les options du menu

### [1] Profil PERSO — Optimisation max
Pour un PC personnel, performances maximales.

- Plan haute performance, veille et hibernation OFF
- Services desactives : telemetrie, Xbox, cartes, mode demo, indexation, fax, registre distant, tablette, WMP reseau
- Cortana, pubs, historique activite : desactives
- Effets visuels : mode performance (animations, transparence, menus instantanes)
- Demarrage nettoye : OneDrive, Spotify, Discord, Skype, Steam, Epic, Adobe, iTunes, Google Drive, Dropbox
- Registre : priorite foreground max, Nagle OFF, indexation SSD desactivee
- Nettoyage disque complet
- SFC : verification et reparation fichiers systeme

---

### [2] Profil ENTREPRISE — Safe et stable
Pour un PC professionnel, ne touche pas a l'essentiel.

Memes bases que Perso, sauf :
- Plan equilibre (pas haute perf, pour stabilite/batterie)
- Conserves : Windows Search, impression reseau, registre distant, OneDrive, Teams au demarrage
- Effets visuels conserves (look professionnel)
- Retire du demarrage uniquement : Spotify, Skype, Adobe Updater, iTunes, Epic, Steam

---

### [3] Gaming Mode — Activer / [4] Desactiver

**Activer :**
- Plan Ultimate Performance
- Effets visuels OFF
- Services suspendus : SuperFetch, indexation, Windows Update (temp), telemetrie, Sync, tablette
- GPU : Hardware-Accelerated Scheduling (HAGS) active
- Reseau : throttling desactive, priorite GPU/CPU pour les jeux
- Souris : acceleration desactivee (mouvement brut et precis)

**Desactiver :** remet tout comme avant (plan, visuels, services, reseau, souris)

---

### [5] Raccourcis Gaming sur le bureau
Cree 2 fichiers sur le bureau :
- `GameBoost ON.lnk` — active le gaming mode en double-clic
- `GameBoost OFF.lnk` — desactive en double-clic

---

### [6] Nettoyage disque
Vide : TEMP utilisateur, TEMP systeme, Prefetch, cache navigateur,
cache Windows Update, corbeille, cache DNS.

---

### [7] Creer un point de restauration
Cree un point avec un nom personnalise (ou date automatique).
A faire avant toute modification importante.

---

### [8] Restaurer Windows
Liste tous tes points de restauration avec date et nom.
Tu choisis le numero, tu confirmes avec "oui" — le PC redemarrage et revient en arriere.

---

### [9] Supprimer les bloatwares

Fonctionne en 2 etapes :

**Etape 1 — Categories** (affiche combien sont installees sur ton PC)
```
[1] Jeux Xbox et Microsoft     (6/10 installees)
[2] Apps Microsoft inutiles    (12/20 installees)
[3] Constructeurs PC           (0/9  installees)
[4] Apps tierces               (3/7  installees)
[A] Toutes
```

**Etape 2 — Selection fine** app par app (Entree=supprimer / N=garder / Q=stop)

Confirmation "oui" obligatoire avant suppression.
Les apps supprimees ne reviennent pas avec Windows Update.

---

### [10] Supprimer langues inutiles

3 parties :

**Office Click-to-Run** : detecte les langues Office installees, propose de supprimer
les extras via OfficeC2RClient.exe (2-5 min, fenetre en arriere-plan)

**Packs Windows** : liste les packs installes hors langue principale,
suppression via Remove-WindowsCapability

**Claviers** : affiche les claviers configures, tu gardes celui que tu veux,
les autres sont supprimes

---

### [11] Desactiver IA Windows — Slopilot Mode

Desactive completement :
- **Copilot** : bouton barre des taches, app, suggestions recherche
- **Windows Recall** : service AIXService + composant Windows
- **Widgets IA** : flux actualites, app WebExperience
- **Suggestions et pubs** : tips, pubs menu Demarrer, suggestions parametres
- **Paint Cocreator / Photos** : generation IA desactivee
- **Chat/Meet** : icone masquee dans la barre des taches
- **Clipchamp** : supprime completement
- **Composants 24H2+** : Enhanced Phishing Protection desactive

Redemarrage necessaire apres.

---

### [12] Mode Install Propre

#### [A] OOBE Bypass — Pendant l'installation Windows

Genere un dossier `OOBE-Bypass\` sur le bureau avec :

**OOBE-Bypass.bat** — a utiliser pendant l'installation :
1. Pendant l'install Windows, quand l'ecran compte Microsoft apparait
2. Appuie sur `Shift + F10` pour ouvrir une invite de commandes
3. Branche ta cle USB, navigue dessus et lance `OOBE-Bypass.bat`
4. Option 1 : bypass reseau (Windows redemarrage, compte local possible)
5. Option 2 : cree un compte local directement

**autounattend.xml** — methode automatique :
1. Copie ce fichier a la RACINE de ta cle USB d'installation Windows
2. Lance l'installation normalement
3. Windows passe automatiquement tous les ecrans Microsoft
4. Cree le compte "Yoan" en local avec fr-FR
> Modifie le nom dans le XML si besoin avant utilisation !

**LIRE-MOI.txt** — instructions completes pas a pas

#### [B] Post-Install Auto — Apres le premier demarrage

Lance une sequence complete sans intervention :

| Etape | Action | Duree estimee |
|---|---|---|
| 1/6 | Point de restauration automatique | 30 sec |
| 2/6 | Profil PERSO complet | 1-2 min |
| 3/6 | IA Windows desactivee | 30 sec |
| 4/6 | Tous les bloatwares supprimes | 2-3 min |
| 5/6 | Nettoyage disque | 1 min |
| 6/6 | SFC verification fichiers | 2-5 min |
| Fin | Rapport + proposition redemarrage | - |

**Duree totale : 10 a 20 minutes selon le PC**
Ne pas eteindre pendant l'operation.

#### [C] Les deux
Lance A puis B dans la foulee.

---

### [13] DNS Switcher

Change les serveurs DNS sur toutes les interfaces reseau actives.

| Choix | DNS | IPv4 | Usage |
|---|---|---|---|
| 1 | Cloudflare | 1.1.1.1 | Le plus rapide, respect vie privee |
| 2 | AdGuard | 94.140.14.14 | Bloque pubs et trackers |
| 3 | Quad9 | 9.9.9.9 | Securite, bloque domaines malveillants |
| 4 | Google | 8.8.8.8 | Fiable et stable |
| 5 | NextDNS | 45.90.28.0 | Personnalisable via compte nextdns.io |
| 6 | Automatique | DHCP | Remet les DNS par defaut de ta box |

Configure IPv4 et IPv6 automatiquement. Vide le cache DNS apres.

---

### [14] Applications — WinGet

3 modes disponibles :

#### [U] Mettre a jour toutes les apps (silencieux)

Met a jour toutes les applications installees sans rien toucher.

- **Sans exclusions** : lance `winget upgrade --all --silent` — rapide, tout d'un coup
- **Avec exclusions** : met a jour app par app en sautant les exclues, affiche un rapport final

```
  3 mise(s) a jour  |  2 exclue(s)  |  0 echec(s)
```

#### [E] Gerer les exclusions

Certaines apps tu ne veux pas les mettre a jour automatiquement
(ex: tu veux garder une vieille version de quelque chose).

```
  Apps exclues des mises a jour :
    [1] Spotify.Spotify
    [2] Discord

  [A]  Ajouter une exclusion
  [S]  Supprimer une exclusion
  [V]  Voir les apps avec updates dispo
```

- **[A]** : tape le nom ou l'ID WinGet (ex: `Spotify` ou `Spotify.Spotify`, les deux marchent)
- **[V]** : affiche la liste des apps qui ont une update disponible — pratique pour savoir exactement quoi exclure
- Les exclusions sont **sauvegardees** dans `winget-exclusions.txt` a cote du script
- Elles persistent entre les sessions, meme apres redemarrage

#### [I] Installer de nouvelles applications

Installe des apps en batch via WinGet.

**6 categories disponibles :**
- Navigateurs (Chrome, Firefox, Brave, Edge)
- Utilitaires (7-Zip, Notepad++, VLC, PowerToys, Everything, WinSCP, PuTTY)
- Developpement (VSCode, Git, Python, Node.js, Docker, Windows Terminal)
- Communication (Discord, Slack, Teams, Zoom)
- Multimedia (GIMP, Spotify, HandBrake, OBS, Greenshot)
- Securite (Bitwarden, ProtonVPN, Malwarebytes, Wireshark)

Tu choisis les categories, puis tu valides app par app.
Si une app est deja installee, elle est ignoree automatiquement.

> WinGet est inclus avec Windows 11. Sur Windows 10 : installe "App Installer" depuis le Microsoft Store.

---

### [17] Profil SECURITE — Windows Hardening

Inspire des benchmarks **CIS / ANSSI / STIG Microsoft**. Trois niveaux progressifs.

---

#### Quand utiliser chaque niveau ?

| Niveau | Pour qui | Quand |
|---|---|---|
| **[1] Standard** | Tout le monde | Toujours, sur chaque machine. SMBv1, WDigest et LLMNR sont des failles actives. Zero impact sur l'usage quotidien. |
| **[2] Renforce** | PC perso serieux, teletravail, donnees sensibles | Quand tu veux vraiment controler ce qui se passe. LSA + logs = si quelqu'un essaie quelque chose, c'est trace. |
| **[3] Paranoid** | Dev/secu, pas de jeux en ligne, tu sais ce que tu fais | Quand tu traites des donnees critiques. Le firewall outbound block = tu decides ce qui parle sur le reseau. |
| **[4] Scan reseau** | N'importe quand | Voir qui parle a qui en live, ports en ecoute, blocs firewall recents. |

---

#### [1] STANDARD — Zero risque, corrections critiques

| Ce qui est bloque | Pourquoi ca compte |
|---|---|
| SMBv1 off | Faille WannaCry / NotPetya — encore presente sur beaucoup de Windows |
| LLMNR off | 30 secondes avec Responder sur le meme reseau = credential vole |
| NetBIOS over TCP/IP off | Meme vecteur de poisoning reseau local |
| WDigest off | Sans ca, ton mot de passe est **en clair en RAM** — Mimikatz le lit en 1 commande |
| UAC niveau max | Elevation explicite sur bureau securise, pas de bypass silencieux |
| Autorun off | Toute cle USB branchee = execution potentielle bloquee |
| Defender durci | Protection reseau + PUA + cloud HIGH + tamper protection |
| WPAD off | Web Proxy Auto-Discovery — vecteur MITM classique |
| Firewall ON tous profils | Domain, Public, Private |
| Logs evenements elargis | Security 128 MB, System 64 MB |

#### [2] RENFORCE — Fort mais utilisable

- **LSA Protection (RunAsPPL)** — meme admin ne peut pas injecter dans lsass.exe
- **PowerShell logging** — tout ce qui se tape en PS est logge dans `C:\PSLogs`
- **Audit policy** — connexions, creations de processus, modifications compte, privileges
- **Firewall log 32 MB** — tout ce qui est DROP est trace dans un fichier
- **RDP off** — surface d'attaque reseau fermee
- **WinRM off** — remote management desactive
- **SMB signing requis** — plus d'attaques relay/MITM SMB
- **Partages admin caches off** — C$, ADMIN$, IPC$ inaccessibles
- **SEHOP** — protection contre corruption de pile d'exception
- **Print Spooler off** — si aucune imprimante detectee (PrintNightmare)

> Redemarrage requis pour que LSA Protection soit actif.

#### [3] PARANOID — Mode forteresse

- **Firewall outbound BLOCK** + whitelist stricte :

| Port | Protocole | Autorise |
|---|---|---|
| 53 | UDP + TCP | DNS |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 853 | TCP | DNS over HTTPS |
| 67 | UDP | DHCP |
| 123 | UDP | NTP (horloge) |
| ICMP | — | Ping |

- **PowerShell v2 supprime** — plus de downgrade pour bypasser le logging
- **WSH off** — les `.vbs`, `.js`, `.wsf` ne s'executent plus
- **DNS over HTTPS** — meme ton FAI ne voit plus tes requetes DNS (Cloudflare chiffre)
- **Controlled Folder Access** — ransomware ne peut plus toucher Documents/Bureau/Images
- **Credential Guard** — credentials dans une VM hardware isolee (si Hyper-V dispo)
- **LSASS dump interdit** — impossible de dumper les credentials en memoire

> Si le reseau ne fonctionne plus apres Paranoid : **[5] Reset Firewall** dans le sous-menu.

> Pour autoriser une app specifique : Panneau de config > Pare-feu Windows > Autoriser une app.

#### [4] Scan reseau

Affiche en temps reel :
- Connexions TCP etablies avec le nom du processus
- Ports en ecoute (les jaunes = inhabituels)
- 15 derniers blocs firewall (si logging Renforce active)
- Interfaces reseau actives avec IP et DNS configures

#### [5] Reset Firewall

Annule uniquement le **outbound block** du mode Paranoid.
Remet le firewall en Allow par defaut et supprime les regles `SECU-*`.
Les autres configurations (WSH, PSv2, DoH) restent actives.

---

### [18] Raccourci BYoan — Recreer les icones

Regenere les icones et repin le raccourci BYoan sur la barre des taches.
Utile si tu as change de PC ou de chemin pour le script.

---

### [16] Full Auto — Tout en 1 clic

Lance la **sequence complete sans aucune interaction** et genere un **rapport de performance sur le bureau**.

**Sequence (8 etapes) :**
1. Point de restauration automatique
2. Profil PERSO complet
3. IA Windows desactivee (Copilot, Recall, Widgets, Suggestions)
4. Tous les bloatwares supprimes
5. Nettoyage disque
6. DNS → Cloudflare (1.1.1.1)
7. Windows Update → Securite uniquement
8. Apps WinGet mises a jour (respecte le fichier d'exclusions si present)

**Rapport genere sur le bureau :** `WinOptimizer-Rapport-AAAA-MM-JJ_HH-mm.txt`

Contenu du rapport :
- Espace libere en MB/Go (mesure avant/apres)
- Services actifs avant → apres (combien desactives)
- Nombre de bloatwares supprimes
- Nombre de packages AppX avant → apres
- Apps mises a jour
- Duree totale d'execution
- Liste des erreurs non bloquantes

> Meme resultat que la sequence etape par etape, entierement automatise.
> Duree : 15 a 30 minutes. Ne pas eteindre pendant l'operation.

---

### [15] Windows Update — Gestion

| Option | Ce que ca fait |
|---|---|
| Securite uniquement | Feature updates bloques 1 an, patches securite avec 4 jours de delai |
| Desactiver tout | Arrete completement Windows Update (deconseille long terme) |
| Par defaut | Remet le comportement Windows normal |
| Verifier maintenant | Ouvre Windows Update pour lancer une verif immediate |

> Le mode "Securite uniquement" est inspire de WinUtil (Chris Titus Tech).
> Il evite les grosses mises a jour Windows qui cassent parfois des choses,
> tout en gardant les patches de securite importants.

---

## Icones BYoan

Au **premier lancement**, le script propose de creer un raccourci sur la barre des taches.
Les icones sont generees par le script lui-meme (System.Drawing natif Windows, aucun fichier externe).

| Icone | Fichier | Design |
|---|---|---|
| **BYoan** | `scripts\icons\BYoan.ico` | Fond noir, "B" cyan + "Y" vert matrix, grille circuit, coins L-shape |
| **Gaming** | `scripts\icons\BYoanGaming.ico` | Fond violet, eclair jaune-orange avec glow |

Les icones sont aussi appliquees sur les raccourcis **GameBoost ON/OFF** du bureau.
Option **[18]** pour recreer les icones et le raccourci si besoin.

---

## Notes importantes

- Toujours lancer en Admin (le .bat le fait automatiquement)
- Redemarrer apres un profil Perso, Entreprise, ou Secu Renforce
- Le Gaming Mode ne necessite pas de redemarrage
- Rien n'est irreversible — utilise [8] pour revenir en arriere
- Le script ne supprime rien d'irreversible sans confirmation "oui"
- Mode Paranoid : si reseau coupe, lance [17] > [5] Reset Firewall
