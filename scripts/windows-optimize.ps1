#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Script d'optimisation Windows - Menu interactif
.DESCRIPTION
    3 profils : Perso (opti a fond) | Entreprise (safe) | Gaming Mode (toggle + raccourcis)
    Compatible Windows 10/11. Lancer en tant qu'Administrateur.
#>

$ErrorActionPreference = "SilentlyContinue"
$HOST.UI.RawUI.WindowTitle = "Windows Optimizer - by Jarvis"
$SCRIPT_VERSION = "4.1"

# Bureau de l'utilisateur reel (robuste meme en session admin elevee)
$realUser    = (Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue).UserName -replace '.*\\',''
if (-not $realUser) { $realUser = $env:USERNAME }
$userDesktop = "C:\Users\$realUser\Desktop"

# ==================================================================
#  HELPERS
# ==================================================================

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host "  |       WINDOWS OPTIMIZER  v$SCRIPT_VERSION                    |" -ForegroundColor Cyan
    Write-Host "  |       $(Get-Date -f 'dd/MM/yyyy HH:mm')                            |" -ForegroundColor DarkCyan
    Write-Host "  |       OS : $((Get-WmiObject Win32_OperatingSystem).Caption.PadRight(38).Substring(0,38))|" -ForegroundColor DarkCyan
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Title($t) {
    Write-Host ""
    Write-Host "  >> $t" -ForegroundColor Yellow
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
}

function Write-OK($t)   { Write-Host "    [OK] $t" -ForegroundColor Green }
function Write-INFO($t) { Write-Host "    [i]  $t" -ForegroundColor Cyan }
function Write-SKIP($t) { Write-Host "    [-]  $t" -ForegroundColor DarkGray }
function Write-WARN($t) { Write-Host "    [!]  $t" -ForegroundColor Yellow }

function Pause-Return {
    Write-Host ""
    Write-Host "  Appuie sur une touche pour revenir au menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ==================================================================
#  MENU PRINCIPAL
# ==================================================================

function Show-MainMenu {
    Write-Banner
    Write-Host "  +---------------------------------------------------+" -ForegroundColor White
    Write-Host "  |  Choisis un profil ou une action                  |" -ForegroundColor White
    Write-Host "  +---------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  [1]  PERSO      - Optimisation max               |" -ForegroundColor Green
    Write-Host "  |  [2]  ENTREPRISE - Safe et stable                 |" -ForegroundColor Cyan
    Write-Host "  |  [3]  GAMING     - Activer                        |" -ForegroundColor Magenta
    Write-Host "  |  [4]  GAMING     - Desactiver                     |" -ForegroundColor DarkMagenta
    Write-Host "  |  [5]  Raccourcis BYoan + Gaming (bureau + taskbar)|" -ForegroundColor White
    Write-Host "  |  [6]  Nettoyage disque uniquement                 |" -ForegroundColor DarkYellow
    Write-Host "  |  [9]  Supprimer les bloatwares                    |" -ForegroundColor DarkRed
    Write-Host "  |  [10] Supprimer langues inutiles (Office + Win)   |" -ForegroundColor DarkCyan
    Write-Host "  |  [11] Desactiver IA Windows (Copilot/Recall/...)  |" -ForegroundColor DarkRed
    Write-Host "  |  [12] MODE INSTALL PROPRE (OOBE + post-install)   |" -ForegroundColor Yellow
    Write-Host "  |  [13] Changer de DNS (Cloudflare/AdGuard/...)     |" -ForegroundColor Cyan
    Write-Host "  |  [14] Installer mes applications (WinGet)         |" -ForegroundColor Green
    Write-Host "  |  [15] Windows Update - Gerer les mises a jour     |" -ForegroundColor DarkYellow
    Write-Host "  +---------------------------------------------------+" -ForegroundColor White
    Write-Host "  |  [16] FULL AUTO - Tout optimiser en 1 clic        |" -ForegroundColor Green
    Write-Host "  |  [17] SECU - Windows Hardening (3 niveaux)        |" -ForegroundColor Red
    Write-Host "  |  [18] Raccourci BYoan (recrer icones + taskbar)   |" -ForegroundColor DarkCyan
    Write-Host "  |  [19] Diagnostic systeme (crashes/RAM/CPU/disque) |" -ForegroundColor DarkYellow
    Write-Host "  +---------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  [7]  Creer un point de restauration              |" -ForegroundColor DarkCyan
    Write-Host "  |  [8]  Restaurer Windows (points existants)        |" -ForegroundColor Red
    Write-Host "  |  [0]  Quitter                                     |" -ForegroundColor DarkGray
    Write-Host "  +---------------------------------------------------+" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  Ton choix"
    return $choice
}

# ==================================================================
#  MODULE : ALIMENTATION
# ==================================================================

function Set-PowerPlan($mode) {
    switch ($mode) {
        "performance" {
            powercfg -setactive SCHEME_MIN
            powercfg -change standby-timeout-ac 0
            powercfg -change hibernate-timeout-ac 0
            powercfg /hibernate off
            Write-OK "Plan haute performance active, veille/hibernation OFF"
        }
        "gaming" {
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
            powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if ($LASTEXITCODE -ne 0) { powercfg -setactive SCHEME_MIN }
            powercfg -change standby-timeout-ac 0
            powercfg /hibernate off
            Write-OK "Plan Ultimate Performance active"
        }
        "balanced" {
            powercfg -setactive SCHEME_BALANCED
            powercfg -change standby-timeout-ac 15
            Write-OK "Plan equilibre restaure"
        }
    }
}

# ==================================================================
#  MODULE : SERVICES
# ==================================================================

function Set-Services($profile) {
    $common = @(
        @{ Name="DiagTrack";        Desc="Telemetrie Microsoft" },
        @{ Name="dmwappushservice"; Desc="Push WAP" },
        @{ Name="MapsBroker";       Desc="Cartes hors-ligne" },
        @{ Name="XblAuthManager";   Desc="Xbox Auth" },
        @{ Name="XblGameSave";      Desc="Xbox Game Save" },
        @{ Name="XboxNetApiSvc";    Desc="Xbox Network" },
        @{ Name="XboxGipSvc";       Desc="Xbox Accessory" },
        @{ Name="RetailDemo";       Desc="Mode demo magasin" }
    )
    $persoOnly = @(
        @{ Name="WSearch";            Desc="Indexation (Windows Search)" },
        @{ Name="Fax";                Desc="Fax" },
        @{ Name="PrintNotify";        Desc="Notifications imprimante" },
        @{ Name="RemoteRegistry";     Desc="Registre distant" },
        @{ Name="TabletInputService"; Desc="Saisie tablette" },
        @{ Name="WMPNetworkSvc";      Desc="Partage reseau WMP" }
    )
    $toDisable = if ($profile -eq "perso") { $common + $persoOnly } else { $common }
    foreach ($svc in $toDisable) {
        $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($s) {
            Stop-Service -Name $svc.Name -Force
            Set-Service  -Name $svc.Name -StartupType Disabled
            Write-OK "Desactive : $($svc.Desc)"
        } else {
            Write-SKIP "Absent : $($svc.Desc)"
        }
    }
    if ($profile -eq "entreprise") {
        Write-INFO "Conserves : Windows Search, Impression, RemoteRegistry, OneDrive, Teams"
    }
}

# ==================================================================
#  MODULE : TELEMETRIE / VIE PRIVEE
# ==================================================================

function Set-Privacy {
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"        /v AllowTelemetry        /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search"        /v AllowCortana          /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled               /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"                /v EnableActivityFeed    /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"                /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System"                /v UploadUserActivities  /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Telemetrie, Cortana, pubs et historique desactives"
}

# ==================================================================
#  MODULE : VISUELS
# ==================================================================

function Set-Visuals($mode) {
    if ($mode -eq "performance") {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting    /t REG_DWORD /d 2   /f | Out-Null
        reg add "HKCU\Control Panel\Desktop\WindowMetrics"                               /v MinAnimate         /t REG_SZ    /d 0   /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"     /v EnableTransparency /t REG_DWORD /d 0   /f | Out-Null
        reg add "HKCU\Control Panel\Desktop"                                             /v MenuShowDelay      /t REG_SZ    /d 0   /f | Out-Null
        Write-OK "Effets visuels -> performance max, animations OFF"
    } else {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting    /t REG_DWORD /d 1   /f | Out-Null
        reg add "HKCU\Control Panel\Desktop\WindowMetrics"                               /v MinAnimate         /t REG_SZ    /d 1   /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"     /v EnableTransparency /t REG_DWORD /d 1   /f | Out-Null
        reg add "HKCU\Control Panel\Desktop"                                             /v MenuShowDelay      /t REG_SZ    /d 400 /f | Out-Null
        Write-OK "Effets visuels restaures"
    }
}

# ==================================================================
#  MODULE : DEMARRAGE
# ==================================================================

function Set-Startup($profile) {
    $appsPerso      = @("OneDrive","Spotify","Discord","Skype","Steam","EpicGamesLauncher",
                        "AdobeUpdater","iTunesHelper","GoogleDriveFS","Dropbox")
    $appsEntreprise = @("Spotify","Skype","AdobeUpdater","iTunesHelper","EpicGamesLauncher","Steam")
    $apps = if ($profile -eq "perso") { $appsPerso } else { $appsEntreprise }
    foreach ($app in $apps) {
        foreach ($path in @("HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                             "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
            if (Get-ItemProperty -Path $path -Name $app -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $path -Name $app -Force
                Write-OK "Retire du demarrage : $app"
            }
        }
    }
    if ($profile -eq "entreprise") {
        Write-INFO "Conserves au demarrage : OneDrive, Teams"
    }
}

# ==================================================================
#  MODULE : REGISTRE SYSTEME
# ==================================================================

function Set-Registry {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl"            /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null
    Write-OK "Priorite foreground maximisee"
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"          /v TCPNoDelay              /t REG_DWORD /d 1  /f | Out-Null
    Write-OK "Latence reseau reduite (Nagle OFF)"
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoResolveSearch         /t REG_DWORD /d 1  /f | Out-Null
    Write-OK "Recherche lecteurs reseau au demarrage desactivee"
    # Delivery Optimization : telecharger depuis Internet + reseau local (mode 3)
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"    /v DODownloadMode          /t REG_DWORD /d 3  /f | Out-Null
    Write-OK "Delivery Optimization -> Internet + reseau local (mode 3)"
    $drive = Get-WmiObject Win32_DiskDrive | Where-Object { $_.Model -match "SSD|NVMe|M.2" }
    if ($drive) {
        $vol = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter='$env:SystemDrive'"
        if ($vol) { $vol.IndexingEnabled = $false; $vol.Put() | Out-Null }
        Write-OK "Indexation SSD/NVMe desactivee"
    } else {
        Write-SKIP "HDD detecte - indexation conservee"
    }
}

# ==================================================================
#  MODULE : NETTOYAGE DISQUE
# ==================================================================

function Invoke-DiskClean {
    Write-Title "Nettoyage disque"
    $folders = @(
        "$env:TEMP",
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:SystemRoot\SoftwareDistribution\Download"
    )
    $total = 0
    foreach ($p in $folders) {
        if (Test-Path $p) {
            $size = (Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
            $total += $size
            Write-OK "Nettoye : $p"
        }
    }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-OK "Corbeille videe"
    ipconfig /flushdns | Out-Null
    Write-OK "Cache DNS vide"
    $mb = [math]::Round($total / 1MB, 1)
    Write-INFO "Espace libere estime : $mb MB"
}

# ==================================================================
#  PROFIL 1 : PERSO
# ==================================================================

function Invoke-ProfilePerso {
    Write-Banner
    Write-Host "  PROFIL PERSO - Optimisation maximale" -ForegroundColor Green
    Write-Host ""

    # -- Mesures AVANT ----------------------------------------------
    $startTime   = Get-Date
    $diskBefore  = (Get-PSDrive -Name C -ErrorAction SilentlyContinue).Free
    $svcBefore   = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
    $appxBefore  = (Get-AppxPackage -ErrorAction SilentlyContinue).Count

    Write-Title "Alimentation"
    Set-PowerPlan "performance"
    Write-Title "Services inutiles"
    Set-Services "perso"
    Write-Title "Telemetrie"
    Set-Privacy
    Write-Title "Effets visuels"
    Set-Visuals "performance"
    Write-Title "Applications au demarrage"
    Set-Startup "perso"
    Write-Title "Registre"
    Set-Registry
    Invoke-DiskClean
    Write-Title "SFC - Verification fichiers systeme"
    Write-INFO "Scan SFC en cours (2-5 min)..."
    $sfc = Start-Process sfc.exe -ArgumentList "/scannow" -NoNewWindow -PassThru -Wait
    $sfcOK = ($sfc.ExitCode -eq 0)
    if ($sfcOK) { Write-OK "Aucun fichier corrompu" }
    else { Write-WARN "Fichiers repares - voir C:\Windows\Logs\CBS\CBS.log" }

    # -- Mesures APRES ----------------------------------------------
    $diskAfter   = (Get-PSDrive -Name C -ErrorAction SilentlyContinue).Free
    $svcAfter    = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
    $appxAfter   = (Get-AppxPackage -ErrorAction SilentlyContinue).Count
    $duration    = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    $diskFreedMB = [math]::Max(0, [math]::Round(($diskAfter - $diskBefore) / 1MB, 0))
    $svcDisabled = [math]::Max(0, $svcBefore - $svcAfter)
    $appxRemoved = [math]::Max(0, $appxBefore - $appxAfter)
    $diskFreeGB  = [math]::Round($diskAfter / 1GB, 1)

    # -- Rapport HTML -----------------------------------------------
    $reportDate  = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $reportPath  = "$userDesktop\BYoan-Perso-$reportDate.html"
    $dateDisplay = Get-Date -Format "dd/MM/yyyy HH:mm"
    $osCaption   = (Get-WmiObject Win32_OperatingSystem).Caption
    $hostname    = $env:COMPUTERNAME

    $sfcLabel = if ($sfcOK) { "OK - Aucun fichier corrompu" } else { "Fichiers repares (voir CBS.log)" }
    $sfcColor = if ($sfcOK) { "#10b981" } else { "#f59e0b" }

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BYoan - Rapport Perso $dateDisplay</title>
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  body{background:#0a0a0f;color:#e2e8f0;font-family:'Segoe UI',system-ui,sans-serif;min-height:100vh;padding:2rem}
  .container{max-width:860px;margin:0 auto}
  .header{text-align:center;margin-bottom:2.5rem;padding:2rem;background:linear-gradient(135deg,#0f172a,#1e293b);border-radius:16px;border:1px solid #1e3a5f}
  .header h1{font-size:2rem;font-weight:700;background:linear-gradient(90deg,#06b6d4,#10b981);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
  .header .meta{margin-top:.75rem;color:#64748b;font-size:.9rem}
  .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:1.25rem;margin-bottom:2rem}
  .card{background:#111827;border-radius:12px;padding:1.5rem;text-align:center;border:1px solid #1f2937}
  .card .value{font-size:2.2rem;font-weight:700;margin:.25rem 0}
  .card .label{font-size:.8rem;color:#64748b;text-transform:uppercase;letter-spacing:.05em}
  .card .unit{font-size:1rem;font-weight:400}
  .section{background:#111827;border-radius:12px;padding:1.5rem;margin-bottom:1.25rem;border:1px solid #1f2937}
  .section h3{font-size:1rem;font-weight:600;color:#94a3b8;text-transform:uppercase;letter-spacing:.08em;margin-bottom:1rem}
  .item{display:flex;justify-content:space-between;align-items:center;padding:.5rem 0;border-bottom:1px solid #1f2937}
  .item:last-child{border-bottom:none}
  .item .name{color:#cbd5e1}
  .badge{padding:.25rem .75rem;border-radius:99px;font-size:.8rem;font-weight:600}
  .ok{background:#052e16;color:#10b981}
  .warn{background:#451a03;color:#f59e0b}
  .footer{text-align:center;margin-top:2rem;color:#374151;font-size:.8rem}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>BYoan - Rapport Profil PERSO</h1>
    <div class="meta">$hostname &nbsp;|&nbsp; $osCaption &nbsp;|&nbsp; $dateDisplay</div>
  </div>

  <div class="cards">
    <div class="card">
      <div class="label">Espace libere</div>
      <div class="value" style="color:#10b981">$diskFreedMB<span class="unit"> MB</span></div>
      <div class="label">Libre total : $diskFreeGB GB</div>
    </div>
    <div class="card">
      <div class="label">Services arretes</div>
      <div class="value" style="color:#06b6d4">$svcDisabled</div>
      <div class="label">Avant : $svcBefore | Apres : $svcAfter</div>
    </div>
    <div class="card">
      <div class="label">AppX retires</div>
      <div class="value" style="color:#818cf8">$appxRemoved</div>
      <div class="label">Avant : $appxBefore | Apres : $appxAfter</div>
    </div>
    <div class="card">
      <div class="label">Duree</div>
      <div class="value" style="color:#f59e0b">$duration<span class="unit"> min</span></div>
      <div class="label">Redemarrage recommande</div>
    </div>
  </div>

  <div class="section">
    <h3>Actions effectuees</h3>
    <div class="item"><span class="name">Plan alimentation</span><span class="badge ok">Haute performance</span></div>
    <div class="item"><span class="name">Services Windows</span><span class="badge ok">$svcDisabled desactives</span></div>
    <div class="item"><span class="name">Telemetrie et vie privee</span><span class="badge ok">Bloquee</span></div>
    <div class="item"><span class="name">Effets visuels</span><span class="badge ok">Performance max</span></div>
    <div class="item"><span class="name">Demarrage auto</span><span class="badge ok">Nettoye</span></div>
    <div class="item"><span class="name">Registre (Nagle/foreground/SSD)</span><span class="badge ok">Optimise</span></div>
    <div class="item"><span class="name">Nettoyage disque (TEMP/cache/DNS)</span><span class="badge ok">$diskFreedMB MB liberes</span></div>
    <div class="item"><span class="name">SFC - Fichiers systeme</span><span class="badge" style="background:#0c1a2e;color:$sfcColor">$sfcLabel</span></div>
  </div>

  <div class="footer">
    Genere par BYoan v$SCRIPT_VERSION &nbsp;|&nbsp; windows-optimize.ps1
  </div>
</div>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host ""
    Write-Host "  Profil PERSO applique avec succes !" -ForegroundColor Green
    Write-INFO "Rapport genere : $reportPath"
    Write-WARN "Un redemarrage est recommande."
    try { Start-Process $reportPath } catch {}
    Pause-Return
}

# ==================================================================
#  PROFIL 2 : ENTREPRISE
# ==================================================================

function Invoke-ProfileEntreprise {
    Write-Banner
    Write-Host "  PROFIL ENTREPRISE - Optimisation safe" -ForegroundColor Cyan
    Write-Host ""

    # -- Choix plan alimentation ------------------------------------
    Write-Host "  Plan d'alimentation :" -ForegroundColor White
    Write-Host "  [1] Equilibre      (recommande laptop - economie batterie)" -ForegroundColor Cyan
    Write-Host "  [2] Haute perf     (secteur uniquement - perfs max)" -ForegroundColor Green
    Write-Host ""
    $powerChoice = Read-Host "  Ton choix (Entree = Equilibre)"
    Write-Title "Alimentation"
    if ($powerChoice -eq "2") {
        Set-PowerPlan "performance"
    } else {
        Set-PowerPlan "balanced"
    }
    Write-Title "Services"
    Write-INFO "Conserves : Windows Search, Impression, RemoteRegistry, OneDrive, Teams"
    Set-Services "entreprise"
    Write-Title "Telemetrie"
    Set-Privacy
    Write-Title "Applications au demarrage"
    Set-Startup "entreprise"
    Write-Title "Registre"
    Set-Registry
    Invoke-DiskClean
    Write-Host ""
    Write-Host "  Profil ENTREPRISE applique !" -ForegroundColor Cyan
    Write-WARN "Un redemarrage est recommande."
    Pause-Return
}

# ==================================================================
#  GAMING MODE - ON
# ==================================================================

function Invoke-GamingOn {
    Write-Banner
    Write-Host "  GAMING MODE - ACTIVATION" -ForegroundColor Magenta
    Write-Host ""
    Write-Title "Alimentation"
    Set-PowerPlan "gaming"
    Write-Title "Effets visuels"
    Set-Visuals "performance"
    Write-Title "Services suspendus"
    $gamingPause = @(
        @{ Name="SysMain";            Desc="SuperFetch" },
        @{ Name="WSearch";            Desc="Indexation" },
        @{ Name="wuauserv";           Desc="Windows Update (temp)" },
        @{ Name="DiagTrack";          Desc="Telemetrie" },
        @{ Name="OneSyncSvc";         Desc="Sync Microsoft" },
        @{ Name="TabletInputService"; Desc="Saisie tablette" }
    )
    foreach ($svc in $gamingPause) {
        $s = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($s -and $s.Status -eq "Running") {
            Stop-Service -Name $svc.Name -Force
            Write-OK "Suspendu : $($svc.Desc)"
        }
    }
    Write-Title "GPU - Mode performance"
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f | Out-Null
    Write-OK "Hardware-Accelerated GPU Scheduling active"
    Write-Title "Reseau gaming"
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"              /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority"         /t REG_DWORD /d 8          /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority               /t REG_DWORD /d 6          /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category"  /t REG_SZ    /d High        /f | Out-Null
    Write-OK "Priorite GPU et reseau gaming activees"
    Write-Title "Souris - Acceleration desactivee"
    reg add "HKCU\Control Panel\Mouse" /v MouseSpeed      /t REG_SZ /d 0  /f | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0  /f | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0  /f | Out-Null
    Write-OK "Acceleration souris desactivee"
    reg add "HKCU\SOFTWARE\WinOptimizer" /v GamingMode /t REG_DWORD /d 1 /f | Out-Null
    Write-Host ""
    Write-Host "  GAMING MODE ON - Bonne partie !" -ForegroundColor Magenta
    Pause-Return
}

# ==================================================================
#  GAMING MODE - OFF
# ==================================================================

function Invoke-GamingOff {
    Write-Banner
    Write-Host "  GAMING MODE - DESACTIVATION" -ForegroundColor DarkMagenta
    Write-Host ""
    Write-Title "Alimentation"
    Set-PowerPlan "balanced"
    Write-Title "Effets visuels"
    Set-Visuals "normal"
    Write-Title "Services - Restauration"
    $toRestore = @("SysMain","WSearch","wuauserv","OneSyncSvc")
    foreach ($svc in $toRestore) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Set-Service   -Name $svc -StartupType Automatic
            Start-Service -Name $svc -ErrorAction SilentlyContinue
            Write-OK "Restaure : $svc"
        }
    }
    Write-Title "Reseau - Restauration"
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f | Out-Null
    Write-OK "Throttling reseau restaure"
    Write-Title "Souris - Acceleration restauree"
    reg add "HKCU\Control Panel\Mouse" /v MouseSpeed      /t REG_SZ /d 1  /f | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 6  /f | Out-Null
    reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 10 /f | Out-Null
    Write-OK "Acceleration souris restauree"
    reg add "HKCU\SOFTWARE\WinOptimizer" /v GamingMode /t REG_DWORD /d 0 /f | Out-Null
    Write-Host ""
    Write-Host "  Gaming Mode desactive - Systeme restaure." -ForegroundColor DarkMagenta
    Pause-Return
}

# ==================================================================
#  RACCOURCIS GAMING SUR LE BUREAU
# ==================================================================

function Create-GamingShortcuts {
    Write-Banner
    Write-Host "  Raccourcis BYoan + Gaming sur le bureau" -ForegroundColor Cyan
    Write-Host ""
    $scriptPath     = $PSCommandPath
    $desktop        = $userDesktop
    $gamingIconPath = "$PSScriptRoot\icons\BYoanGaming.ico"
    $mainIconPath   = "$PSScriptRoot\icons\BYoan.ico"

    # Generer les icones si absentes
    if (-not (Test-Path $gamingIconPath)) {
        $iconDir = "$PSScriptRoot\icons"
        New-Item -ItemType Directory -Path $iconDir -Force -ErrorAction SilentlyContinue | Out-Null
        try { New-IconBYoan $mainIconPath; New-IconGaming $gamingIconPath; Write-OK "Icones generees" }
        catch { $gamingIconPath = "shell32.dll,43" }
    }

    $iconOn  = if (Test-Path $gamingIconPath) { "$gamingIconPath,0" } else { "shell32.dll,43" }
    $iconOff = if (Test-Path $gamingIconPath) { "$gamingIconPath,0" } else { "shell32.dll,238" }

    $batOn  = "@echo off`r`nPowerShell -ExecutionPolicy Bypass -Command `"Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \`"$scriptPath\`" -GamingOn' -Verb RunAs`""
    $batOff = "@echo off`r`nPowerShell -ExecutionPolicy Bypass -Command `"Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \`"$scriptPath\`" -GamingOff' -Verb RunAs`""
    $batOnPath  = "$desktop\GameBoost-ON.bat"
    $batOffPath = "$desktop\GameBoost-OFF.bat"
    Set-Content -Path $batOnPath  -Value $batOn  -Encoding ASCII
    Set-Content -Path $batOffPath -Value $batOff -Encoding ASCII
    $wsh    = New-Object -ComObject WScript.Shell
    $lnkOn  = $wsh.CreateShortcut("$desktop\GameBoost ON.lnk")
    $lnkOn.TargetPath   = "cmd.exe"
    $lnkOn.Arguments    = "/c `"$batOnPath`""
    $lnkOn.IconLocation = $iconOn
    $lnkOn.Description  = "Activer Gaming Mode"
    $lnkOn.Save()
    $lnkOff = $wsh.CreateShortcut("$desktop\GameBoost OFF.lnk")
    $lnkOff.TargetPath   = "cmd.exe"
    $lnkOff.Arguments    = "/c `"$batOffPath`""
    $lnkOff.IconLocation = $iconOff
    $lnkOff.Description  = "Desactiver Gaming Mode"
    $lnkOff.Save()
    Write-OK "Raccourci cree : GameBoost ON.lnk"
    Write-OK "Raccourci cree : GameBoost OFF.lnk"
    Write-INFO "Double-clic sur le bureau pour basculer le Gaming Mode !"
    Pause-Return
}

# ==================================================================
#  BLOATWARES
# ==================================================================

function Invoke-RemoveBloatware {
    $catalogue = @{
        "1-Jeux Xbox et Microsoft" = @(
            @{ Name="Microsoft.XboxApp";                      Label="Xbox (app principale)" },
            @{ Name="Microsoft.XboxGameOverlay";              Label="Xbox Game Overlay" },
            @{ Name="Microsoft.XboxGamingOverlay";            Label="Xbox Gaming Overlay" },
            @{ Name="Microsoft.XboxIdentityProvider";         Label="Xbox Identity Provider" },
            @{ Name="Microsoft.GamingApp";                    Label="Xbox Gaming (W11)" },
            @{ Name="king.com.CandyCrushSaga";                Label="Candy Crush Saga" },
            @{ Name="king.com.CandyCrushFriends";             Label="Candy Crush Friends" },
            @{ Name="king.com.BubbleWitch3Saga";              Label="Bubble Witch 3" },
            @{ Name="Microsoft.MicrosoftSolitaireCollection"; Label="Solitaire Collection" },
            @{ Name="Disney.37853D22215E2";                   Label="Disney+" }
        )
        "2-Apps Microsoft inutiles" = @(
            @{ Name="Microsoft.3DBuilder";               Label="3D Builder" },
            @{ Name="Microsoft.Microsoft3DViewer";       Label="3D Viewer" },
            @{ Name="Microsoft.BingNews";                Label="Actualites Bing" },
            @{ Name="Microsoft.BingWeather";             Label="Meteo Bing" },
            @{ Name="Microsoft.BingFinance";             Label="Finances Bing" },
            @{ Name="Microsoft.MixedReality.Portal";     Label="Mixed Reality" },
            @{ Name="Microsoft.People";                  Label="Contacts" },
            @{ Name="Microsoft.Getstarted";              Label="Mise en route" },
            @{ Name="Microsoft.WindowsFeedbackHub";      Label="Hub de commentaires" },
            @{ Name="Microsoft.WindowsMaps";             Label="Cartes Windows" },
            @{ Name="Microsoft.ZuneMusic";               Label="Groove Musique" },
            @{ Name="Microsoft.ZuneVideo";               Label="Films et TV" },
            @{ Name="Microsoft.SkypeApp";                Label="Skype" },
            @{ Name="Microsoft.Wallet";                  Label="Microsoft Pay" },
            @{ Name="Microsoft.Print3D";                 Label="Impression 3D" },
            @{ Name="Microsoft.MicrosoftOfficeHub";      Label="Office Hub" },
            @{ Name="Microsoft.Todos";                   Label="Microsoft To Do" },
            @{ Name="Microsoft.Whiteboard";              Label="Tableau blanc" },
            @{ Name="MicrosoftTeams";                    Label="Teams (perso)" },
            @{ Name="Microsoft.549981C3F5F10";           Label="Cortana (app)" }
        )
        "3-Constructeurs PC (Dell HP Lenovo)" = @(
            @{ Name="DellInc.DellSupportAssistforPCs";   Label="Dell SupportAssist" },
            @{ Name="DellInc.DellCommandUpdate";         Label="Dell Command Update" },
            @{ Name="DellInc.DellDigitalDelivery";       Label="Dell Digital Delivery" },
            @{ Name="HPInc.MyHP";                        Label="HP My HP" },
            @{ Name="AD2F1837.HPSupportAssistant";       Label="HP Support Assistant" },
            @{ Name="E046963F.LenovoCompanion";          Label="Lenovo Companion" },
            @{ Name="LenovoInc.LenovoVantage";           Label="Lenovo Vantage" },
            @{ Name="AcerInc.AcerCare";                  Label="Acer Care Center" },
            @{ Name="ASUSTeKCo.MyASUS";                  Label="MyASUS" }
        )
        "4-Apps tierces preinstallees" = @(
            @{ Name="SpotifyAB.SpotifyMusic";            Label="Spotify" },
            @{ Name="9E2F88E3.Twitter";                  Label="Twitter / X" },
            @{ Name="Facebook.Facebook";                 Label="Facebook" },
            @{ Name="TikTok.TikTok";                     Label="TikTok" },
            @{ Name="Amazon.com.Amazon";                 Label="Amazon" },
            @{ Name="Netflix.Netflix";                   Label="Netflix" },
            @{ Name="WinZipComputing.WinZipUniversal";   Label="WinZip" }
        )
    }

    Write-Banner
    Write-Host "  SUPPRESSION DES BLOATWARES" -ForegroundColor DarkRed
    Write-Host "  ETAPE 1 / 2 - Selection par categorie" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Quelles categories veux-tu traiter ?" -ForegroundColor White
    Write-Host "  (tu pourras affiner app par app ensuite)" -ForegroundColor DarkGray
    Write-Host ""

    $categories = $catalogue.Keys | Sort-Object
    $catIndex   = @{}
    $i = 1
    foreach ($cat in $categories) {
        $installed = ($catalogue[$cat] | Where-Object {
            Get-AppxPackage -Name $_.Name -ErrorAction SilentlyContinue
        }).Count
        $total = $catalogue[$cat].Count
        $color = if ($installed -gt 0) { "White" } else { "DarkGray" }
        Write-Host "  [$i] $($cat.Substring(2))  ($installed/$total installees)" -ForegroundColor $color
        $catIndex[$i] = $cat
        $i++
    }
    Write-Host "  [A] Toutes les categories" -ForegroundColor DarkYellow
    Write-Host "  [0] Annuler" -ForegroundColor DarkGray
    Write-Host ""
    $catChoix = Read-Host "  Categories (ex: 1 2 ou A)"
    if ($catChoix -eq "0" -or $catChoix -eq "") { return }

    $selectedCats = @()
    if ($catChoix.ToUpper() -eq "A") {
        $selectedCats = $categories
    } else {
        foreach ($num in ($catChoix -split " ")) {
            $n = $num -as [int]
            if ($n -and $catIndex.ContainsKey($n)) { $selectedCats += $catIndex[$n] }
        }
    }
    if ($selectedCats.Count -eq 0) { Write-WARN "Aucune categorie selectionnee."; Pause-Return; return }

    Write-Host ""
    Write-Host "  ETAPE 2 / 2 - Selection fine" -ForegroundColor Yellow
    Write-Host "  [Entree] = supprimer   [N] = garder   [Q] = stop" -ForegroundColor DarkGray
    Write-Host ""

    $toRemove = @()
    $stop     = $false
    foreach ($cat in $selectedCats) {
        if ($stop) { break }
        Write-Host "  >> $($cat.Substring(2))" -ForegroundColor DarkRed
        Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
        foreach ($app in $catalogue[$cat]) {
            if ($stop) { break }
            $pkg = Get-AppxPackage -Name $app.Name -ErrorAction SilentlyContinue
            if (-not $pkg) { Write-SKIP "Non installee : $($app.Label)"; continue }
            Write-Host ""
            Write-Host "  -> $($app.Label) (installee)" -ForegroundColor White
            $rep = Read-Host "     Supprimer ? (Entree=oui / N=garder / Q=stop)"
            if ($rep.ToUpper() -eq "Q")     { $stop = $true }
            elseif ($rep.ToUpper() -ne "N") { $toRemove += $app }
        }
        Write-Host ""
    }

    if ($toRemove.Count -eq 0) { Write-INFO "Rien a supprimer."; Pause-Return; return }

    Write-Host "  Recap - $($toRemove.Count) app(s) a supprimer :" -ForegroundColor Yellow
    $toRemove | ForEach-Object { Write-Host "    * $($_.Label)" -ForegroundColor White }
    Write-Host ""
    $confirm = Read-Host "  Confirmer la suppression ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    Write-Host ""
    Write-Title "Suppression en cours..."
    $ok = 0; $fail = 0
    foreach ($app in $toRemove) {
        try {
            Get-AppxPackage -Name $app.Name | Remove-AppxPackage -ErrorAction Stop
            Get-AppxProvisionedPackage -Online |
                Where-Object DisplayName -like $app.Name |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            Write-OK "Supprime : $($app.Label)"
            $ok++
        } catch {
            Write-WARN "Echec : $($app.Label)"
            $fail++
        }
    }
    Write-Host ""
    Write-Host "  $ok supprimee(s)  |  $fail echec(s)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
    Write-INFO "Les apps supprimees ne reviendront pas avec Windows Update."
    Pause-Return
}

# ==================================================================
#  LANGUES INUTILES (Office + Windows + Claviers)
# ==================================================================

function Invoke-RemoveLanguages {
    Write-Banner
    Write-Host "  SUPPRESSION DES LANGUES INUTILES" -ForegroundColor Cyan
    Write-Host "  Couvre : Office (Click-to-Run) + Windows + Claviers" -ForegroundColor DarkGray
    Write-Host ""

    $userLang = (Get-Culture).Name
    Write-INFO "Langue principale detectee : $userLang"
    $override = Read-Host "  C'est correct ? (Entree=oui / tape une autre ex: fr-FR)"
    if ($override -ne "") { $userLang = $override }
    Write-OK "Langue conservee : $userLang"
    Write-Host ""

    # -- Office C2R --
    Write-Title "Office Click-to-Run"
    $c2rPath   = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
    $c2rConfig = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
    if (-not (Test-Path $c2rPath) -or -not $c2rConfig) {
        Write-SKIP "Office Click-to-Run non detecte - section ignoree."
    } else {
        $rawLangs    = if ($c2rConfig.LanguageIds) { $c2rConfig.LanguageIds } else { $c2rConfig.ClientCulture }
        $officeLangs = @()
        if ($rawLangs) { $officeLangs = $rawLangs -split "[ ,;]" | Where-Object { $_ -ne "" } | Sort-Object -Unique }
        if ($officeLangs.Count -le 1) {
            Write-INFO "Une seule langue Office - rien a faire."
        } else {
            Write-INFO "Langues Office installees :"
            $officeLangs | ForEach-Object { Write-Host "    * $_" -ForegroundColor White }
            Write-Host ""
            $toRemoveOffice = $officeLangs | Where-Object { $_ -ne $userLang -and $_ -notmatch "^en-" }
            $enLangs        = $officeLangs | Where-Object { $_ -match "^en-" -and $_ -ne $userLang }
            if ($enLangs) {
                $keepEn = Read-Host "  Garder l'anglais Office ($($enLangs -join ', ')) ? (O/N)"
                if ($keepEn.ToUpper() -eq "N") { $toRemoveOffice = $toRemoveOffice + $enLangs }
            }
            if ($toRemoveOffice.Count -eq 0) {
                Write-INFO "Aucune langue Office a supprimer."
            } else {
                Write-Host "  Langues a supprimer :" -ForegroundColor Yellow
                $toRemoveOffice | ForEach-Object { Write-Host "    * $_" -ForegroundColor DarkRed }
                $confirm = Read-Host "  Confirmer ? (oui/non)"
                if ($confirm.ToLower() -eq "oui") {
                    $xmlPath    = "$env:TEMP\OfficeRemoveLangs.xml"
                    $xmlContent = "<Configuration>`n  <Remove>`n    <Product ID=`"LanguagePack`">`n"
                    foreach ($lang in $toRemoveOffice) { $xmlContent += "      <Language ID=`"$lang`"/>`n" }
                    $xmlContent += "    </Product>`n  </Remove>`n</Configuration>"
                    Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8
                    Write-INFO "Lancement Office C2R - peut prendre 2-5 min..."
                    $proc = Start-Process -FilePath $c2rPath -ArgumentList "/configure `"$xmlPath`"" -PassThru -Wait
                    if ($proc.ExitCode -eq 0) { Write-OK "Langues Office supprimees." }
                    else { Write-WARN "Code retour $($proc.ExitCode) - verifie dans Office > Options > Langue" }
                    Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
                } else { Write-INFO "Annule." }
            }
        }
    }

    # -- Windows Capabilities --
    Write-Title "Packs de langue Windows"
    $winLangs = Get-WindowsCapability -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "Language.Basic*" -and $_.State -eq "Installed" }
    if (-not $winLangs) {
        Write-SKIP "Aucun pack supplementaire detecte."
    } else {
        $extraWin = $winLangs | Where-Object {
            $lang = ($_.Name -split "~~~")[1] -split "~" | Select-Object -First 1
            $lang -ne $userLang
        }
        if ($extraWin.Count -eq 0) {
            Write-INFO "Aucune langue Windows en trop."
        } else {
            $toRemoveWin = @()
            foreach ($cap in $extraWin) {
                $lang = ($cap.Name -split "~~~")[1] -split "~" | Select-Object -First 1
                Write-Host "  * $lang" -ForegroundColor White
                $rep = Read-Host "    Supprimer ? (Entree=oui / N=garder)"
                if ($rep.ToUpper() -ne "N") { $toRemoveWin += $cap }
            }
            if ($toRemoveWin.Count -gt 0) {
                $confirm = Read-Host "  Confirmer suppression $($toRemoveWin.Count) pack(s) ? (oui/non)"
                if ($confirm.ToLower() -eq "oui") {
                    foreach ($cap in $toRemoveWin) {
                        $lang = ($cap.Name -split "~~~")[1] -split "~" | Select-Object -First 1
                        try { Remove-WindowsCapability -Online -Name $cap.Name -ErrorAction Stop | Out-Null; Write-OK "Supprime : $lang" }
                        catch { Write-WARN "Echec : $lang" }
                    }
                } else { Write-INFO "Annule." }
            }
        }
    }

    # -- Claviers --
    Write-Title "Claviers configures"
    $layouts = Get-WinUserLanguageList
    if ($layouts.Count -le 1) {
        Write-INFO "Un seul clavier - rien a faire."
    } else {
        $i = 1; $idxMap = @{}
        foreach ($l in $layouts) {
            Write-Host "  [$i] $($l.LanguageTag) - $($l.LocalizedName)" -ForegroundColor White
            $idxMap[$i] = $l
            $i++
        }
        Write-Host ""
        $keep    = Read-Host "  Numero du clavier a GARDER (les autres supprimes)"
        $keepIdx = $keep -as [int]
        if ($keepIdx -and $idxMap.ContainsKey($keepIdx)) {
            Set-WinUserLanguageList -LanguageList $idxMap[$keepIdx] -Force
            Write-OK "Clavier conserve : $($idxMap[$keepIdx].LocalizedName)"
        } else { Write-WARN "Choix invalide - claviers non modifies." }
    }

    Write-Host ""
    Write-Host "  Nettoyage des langues termine !" -ForegroundColor Cyan
    Write-WARN "Un redemarrage peut etre necessaire pour finaliser les suppressions Office."
    Pause-Return
}

# ==================================================================
#  DESACTIVER IA WINDOWS (Copilot, Recall, Widgets, Ads IA)
# ==================================================================

function Invoke-DisableWindowsAI {
    Write-Banner
    Write-Host "  DESACTIVER L'IA WINDOWS - Slopilot Mode" -ForegroundColor DarkRed
    Write-Host "  Inspire de FlyOOBE / builtbybel" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Ce que ce module desactive :" -ForegroundColor White
    Write-Host "    * Copilot (bouton barre des taches + app)" -ForegroundColor Gray
    Write-Host "    * Windows Recall (enregistrement d'ecran IA)" -ForegroundColor Gray
    Write-Host "    * Widgets IA (flux d'actualites IA)" -ForegroundColor Gray
    Write-Host "    * Suggestions IA dans la recherche" -ForegroundColor Gray
    Write-Host "    * Paint Cocreator / Photos generatif" -ForegroundColor Gray
    Write-Host "    * Publicites et tips personnalises" -ForegroundColor Gray
    Write-Host "    * Chat/Meet dans la barre des taches" -ForegroundColor Gray
    Write-Host ""

    $confirm = Read-Host "  Desactiver tout ca ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    Write-Host ""

    # ------------------------------------------------------------------
    # 1. COPILOT
    # ------------------------------------------------------------------
    Write-Title "Copilot"

    # Desactiver Copilot via policy
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
    # Masquer le bouton Copilot dans la barre des taches
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f | Out-Null
    # Desactiver Copilot dans Windows Search
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled     /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent        /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "Copilot desactive"

    # ------------------------------------------------------------------
    # 2. WINDOWS RECALL
    # ------------------------------------------------------------------
    Write-Title "Windows Recall (enregistrement d'ecran IA)"

    # Desactiver Recall
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"    /v DisableAIDataAnalysis     /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"    /v DisableAIDataAnalysis     /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"   /v DisablePrivacyExperience  /t REG_DWORD /d 1 /f | Out-Null

    # Desactiver le service Recall si present
    $recallSvc = Get-Service -Name "AIXService" -ErrorAction SilentlyContinue
    if ($recallSvc) {
        Stop-Service "AIXService" -Force
        Set-Service  "AIXService" -StartupType Disabled
        Write-OK "Service Recall (AIXService) desactive"
    }

    # Supprimer Recall via DISM si disponible
    $recallFeature = Get-WindowsCapability -Online -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -like "*Recall*" -and $_.State -eq "Installed" }
    if ($recallFeature) {
        Remove-WindowsCapability -Online -Name $recallFeature.Name -ErrorAction SilentlyContinue | Out-Null
        Write-OK "Composant Recall supprime du systeme"
    } else {
        Write-OK "Recall desactive (non installe ou deja absent)"
    }

    # ------------------------------------------------------------------
    # 3. WIDGETS IA
    # ------------------------------------------------------------------
    Write-Title "Widgets IA (flux d'actualites)"

    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh"                                           /v AllowNewsAndInterests  /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"               /v TaskbarDa              /t REG_DWORD /d 0 /f | Out-Null
    # Supprimer Widgets AppX si present
    Get-AppxPackage -Name "MicrosoftWindows.Client.WebExperience" -ErrorAction SilentlyContinue |
        Remove-AppxPackage -ErrorAction SilentlyContinue
    Write-OK "Widgets IA desactives et bouton masque"

    # ------------------------------------------------------------------
    # 4. SUGGESTIONS & PUBS IA
    # ------------------------------------------------------------------
    Write-Title "Suggestions et publicites IA"

    # Tips et suggestions Windows
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled               /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled     /t REG_DWORD /d 0 /f | Out-Null
    # Suggestions dans les parametres
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"  /v ScoobeSystemSettingEnabled       /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Suggestions et pubs IA desactivees"

    # ------------------------------------------------------------------
    # 5. PAINT COCREATOR / GENERATIF
    # ------------------------------------------------------------------
    Write-Title "Apps IA generatives (Paint Cocreator, Photos)"

    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt     /t REG_DWORD /d 0 /f | Out-Null
    # Desactiver la generation IA dans Paint
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx"                    /v DisableStoreOriginatedApps /t REG_DWORD /d 0 /f | Out-Null
    # Desactiver Generative Erase dans Photos
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PhotoViewerAI"     /v DisableGenerativeErase     /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "Fonctions generatives desactivees"

    # ------------------------------------------------------------------
    # 6. CHAT / MEET BARRE DES TACHES
    # ------------------------------------------------------------------
    Write-Title "Chat et Meet dans la barre des taches"

    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Icone Chat/Meet masquee"

    # ------------------------------------------------------------------
    # 7. DESACTIVER CLIPCHAMP (editeur video IA)
    # ------------------------------------------------------------------
    Write-Title "Clipchamp (editeur video IA Microsoft)"

    Get-AppxPackage -Name "Clipchamp.Clipchamp" -ErrorAction SilentlyContinue |
        Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like "Clipchamp*" |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    Write-OK "Clipchamp supprime"

    # ------------------------------------------------------------------
    # 8. DESACTIVER AI COMPONENTS (Windows 11 24H2+)
    # ------------------------------------------------------------------
    Write-Title "Composants IA Windows 11 24H2+"

    # Smart App Control
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v VerifiedAndReputablePolicyState /t REG_DWORD /d 0 /f | Out-Null
    # Desactiver Enhanced Phishing Protection (envoie les frappes clavier a MS)
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components" /v ServiceEnabled /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Composants IA systeme desactives"

    Write-Host ""
    Write-Host "  IA Windows desactivee - Slopilot mode ON !" -ForegroundColor DarkRed
    Write-WARN "Redemarrage necessaire pour appliquer tous les changements."
    Pause-Return
}

# ==================================================================
#  POINT DE RESTAURATION - Propose au demarrage
# ==================================================================

function Invoke-RestorePoint {
    Write-Banner
    Write-Host "  SAUVEGARDE - Point de restauration Windows" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Avant toute modification, il est conseille de creer" -ForegroundColor White
    Write-Host "  un point de restauration. Si quelque chose ne te plait" -ForegroundColor White
    Write-Host "  pas apres, Windows revient exactement comme avant." -ForegroundColor White
    Write-Host ""
    Write-Host "  [O]  Oui - Creer un point de restauration" -ForegroundColor Green
    Write-Host "  [N]  Non - Continuer sans sauvegarde"      -ForegroundColor DarkYellow
    Write-Host "  [P]  Passer - Ne plus demander cette session" -ForegroundColor DarkGray
    Write-Host ""
    $rep = Read-Host "  Ton choix (O/N/P)"
    switch ($rep.ToUpper()) {
        "O" {
            Write-INFO "Creation du point de restauration..."
            try {
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
                $date = Get-Date -Format "dd/MM/yyyy HH:mm"
                Checkpoint-Computer -Description "Avant Windows Optimizer - $date" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                Write-OK "Point cree : Avant Windows Optimizer - $date"
                Start-Sleep 2
                return $true
            } catch {
                Write-WARN "Impossible de creer le point automatiquement."
                Write-WARN "Fais-le manuellement : Demarrer > point de restauration > Creer"
                $manual = Read-Host "  Continuer quand meme ? (O/N)"
                return ($manual.ToUpper() -eq "O")
            }
        }
        "N" { Write-WARN "Pas de sauvegarde."; Start-Sleep 1; return $true }
        "P" { return "skip" }
        default { return $true }
    }
}

# ==================================================================
#  CREER UN POINT MANUELLEMENT
# ==================================================================

function Invoke-CreateRestorePoint {
    Write-Banner
    Write-Host "  Creer un point de restauration" -ForegroundColor Cyan
    Write-Host ""
    $label = Read-Host "  Nom du point (Entree = date auto)"
    if (-not $label) { $label = "Manuel - $(Get-Date -Format 'dd/MM/yyyy HH:mm')" }
    Write-INFO "Creation en cours..."
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $label -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-OK "Point cree : $label"
    } catch {
        Write-WARN "Echec. Essaie manuellement : Demarrer > point de restauration > Creer"
    }
    Pause-Return
}

# ==================================================================
#  RESTAURER WINDOWS
# ==================================================================

function Invoke-RestoreWindows {
    Write-Banner
    Write-Host "  RESTAURATION WINDOWS" -ForegroundColor Red
    Write-Host ""
    $points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    if (-not $points) {
        Write-WARN "Aucun point de restauration trouve."
        Write-INFO "Cree-en un via [7] du menu."
        Pause-Return
        return
    }
    Write-INFO "Points disponibles :"
    Write-Host ""
    $i = 1; $list = @()
    foreach ($p in ($points | Sort-Object CreationTime -Descending)) {
        $date = ([Management.ManagementDateTimeConverter]::ToDateTime($p.CreationTime)).ToString("dd/MM/yyyy HH:mm")
        Write-Host "  [$i] $date - $($p.Description)" -ForegroundColor White
        $list += $p
        $i++
    }
    Write-Host ""
    Write-Host "  [0] Annuler" -ForegroundColor DarkGray
    Write-Host ""
    $choix = Read-Host "  Choisir le point a restaurer"
    if ($choix -eq "0" -or $choix -eq "") { return }
    $idx = [int]$choix - 1
    if ($idx -lt 0 -or $idx -ge $list.Count) { Write-WARN "Choix invalide."; Pause-Return; return }
    $selected = $list[$idx]
    $dateAff  = ([Management.ManagementDateTimeConverter]::ToDateTime($selected.CreationTime)).ToString("dd/MM/yyyy HH:mm")
    Write-Host ""
    Write-Host "  Tu vas restaurer Windows a :" -ForegroundColor Yellow
    Write-Host "  $dateAff - $($selected.Description)" -ForegroundColor White
    Write-Host "  Le PC va redemarrer automatiquement." -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "  Confirmer ? (oui/non)"
    if ($confirm.ToLower() -eq "oui") {
        Write-INFO "Lancement de la restauration..."
        Start-Sleep 2
        Restore-Computer -RestorePoint $selected.SequenceNumber -Confirm:$false
    } else {
        Write-OK "Restauration annulee."
        Pause-Return
    }
}

# ==================================================================
#  MODE INSTALL PROPRE
# ==================================================================

function Invoke-CleanInstall {
    Write-Banner
    Write-Host "  MODE INSTALL PROPRE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Ce mode fait deux choses :" -ForegroundColor White
    Write-Host ""
    Write-Host "  [A] OOBE - Generer les outils pour bypasser" -ForegroundColor Cyan
    Write-Host "      le compte Microsoft pendant l'installation" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [B] POST-INSTALL - Tout configurer automatiquement" -ForegroundColor Green
    Write-Host "      en une seule passe (profil Perso + IA off +" -ForegroundColor DarkGray
    Write-Host "      bloatwares + langues) sans passer par le menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [C] Les deux" -ForegroundColor Yellow
    Write-Host "  [0] Retour" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Ton choix"

    switch ($choice.ToUpper()) {
        "A" { Invoke-OOBETools }
        "B" { Invoke-PostInstallAuto }
        "C" { Invoke-OOBETools; Invoke-PostInstallAuto }
        "0" { return }
        default { Write-WARN "Choix invalide." }
    }
}

# ------------------------------------------------------------------
#  PARTIE A : OOBE BYPASS TOOLS
# ------------------------------------------------------------------

function Invoke-OOBETools {
    Write-Banner
    Write-Host "  OOBE BYPASS - Outils pour installation propre" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Deux methodes pour eviter le compte Microsoft :" -ForegroundColor White
    Write-Host ""
    Write-Host "  Methode 1 - Commande rapide (pendant l'install)" -ForegroundColor Yellow
    Write-Host "  Methode 2 - Fichier autounattend.xml (cle USB)" -ForegroundColor Yellow
    Write-Host ""

    $desktop = $userDesktop
    $oobePath = "$desktop\OOBE-Bypass"
    New-Item -ItemType Directory -Path $oobePath -Force | Out-Null

    # -- Methode 1 : Script bypass rapide --------------------------
    $bypassScript = @"
@echo off
:: ================================================================
:: OOBE BYPASS - Compte local sans Microsoft
:: Usage : pendant l'installation Windows, Shift+F10 pour ouvrir
::         CMD, puis lancer ce fichier depuis une cle USB
:: ================================================================

echo.
echo  [1] Bypass reseau (force compte local) - RECOMMANDE
echo  [2] Creer compte local directement
echo  [3] Quitter
echo.
set /p choix= Ton choix :

if "%choix%"=="1" goto bypass
if "%choix%"=="2" goto local
goto end

:bypass
echo.
echo  Bypass du reseau en cours...
echo  Windows va redemarrer, tu pourras creer un compte local.
echo.
oobe\BypassNRO
goto end

:local
echo.
set /p username= Nom du compte local a creer :
net user "%username%" /add
net localgroup administrators "%username%" /add
echo.
echo  [OK] Compte local cree : %username%
echo  Tu peux maintenant fermer cette fenetre et continuer l'installation.
echo.
pause

:end
"@
    Set-Content -Path "$oobePath\OOBE-Bypass.bat" -Value $bypassScript -Encoding ASCII
    Write-OK "Methode 1 creee : OOBE-Bypass.bat"

    # -- Methode 2 : autounattend.xml ------------------------------
    $unattendXml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <!-- ============================================================
       autounattend.xml - Installation Windows sans compte Microsoft
       Placer ce fichier a la RACINE de la cle USB d'installation
       ============================================================ -->

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">

      <OOBE>
        <!-- Passer les ecrans inutiles -->
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>false</HideLocalAccountScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
        <!-- Desactiver la telemetrie pendant l'install -->
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>

      <!-- Compte local - MODIFIE ces valeurs avant utilisation -->
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password>
              <Value></Value>
              <PlainText>true</PlainText>
            </Password>
            <DisplayName>Yoan</DisplayName>
            <Group>Administrators</Group>
            <Name>Yoan</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>

      <!-- Region et langue -->
      <UILanguage>fr-FR</UILanguage>
      <SystemLocale>fr-FR</SystemLocale>
      <UserLocale>fr-FR</UserLocale>
      <TimeZone>Romance Standard Time</TimeZone>

    </component>
  </settings>

  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">
      <!-- Desactiver telemetrie des le depart -->
      <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
    </component>

    <!-- Desactiver la collecte de donnees -->
    <component name="Microsoft-Windows-SQMAPI"
               processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35"
               language="neutral"
               versionScope="nonSxS">
      <CEIPEnabled>0</CEIPEnabled>
    </component>
  </settings>

</unattend>
"@
    Set-Content -Path "$oobePath\autounattend.xml" -Value $unattendXml -Encoding UTF8
    Write-OK "Methode 2 creee : autounattend.xml"

    # -- README ----------------------------------------------------
    $readme = @"
OOBE BYPASS - Mode d'emploi
===========================

METHODE 1 - OOBE-Bypass.bat (la plus simple)
----------------------------------------------
1. Copie OOBE-Bypass.bat sur une cle USB
2. Lance l'installation Windows normalement
3. Quand l'ecran "Connexion" Microsoft apparait :
   - Appuie sur Shift + F10 pour ouvrir CMD
   - Tape : E:\OOBE-Bypass.bat  (remplace E: par ta cle USB)
4. Choisis option 1 (bypass reseau) -> Windows redemarrage
5. Tu pourras creer un compte local

METHODE 2 - autounattend.xml (la plus automatique)
---------------------------------------------------
1. Copie autounattend.xml a la RACINE de la cle USB d'installation
2. Lance l'installation normalement
3. Windows passera automatiquement les ecrans Microsoft
   et creera le compte "Yoan" en local
IMPORTANT : modifie le nom dans le XML avant utilisation !

APRES L'INSTALLATION
--------------------
Lance windows-optimize.ps1 et choisis [12] > [B] Post-install
pour tout configurer automatiquement.
"@
    Set-Content -Path "$oobePath\LIRE-MOI.txt" -Value $readme -Encoding UTF8
    Write-OK "Guide creee : LIRE-MOI.txt"

    Write-Host ""
    Write-Host "  Dossier cree sur le bureau : OOBE-Bypass\" -ForegroundColor Yellow
    Write-Host "  Contenu :" -ForegroundColor White
    Write-Host "    * OOBE-Bypass.bat    <- lancer pendant l'install (Shift+F10)" -ForegroundColor Gray
    Write-Host "    * autounattend.xml   <- a mettre a la racine de la cle USB" -ForegroundColor Gray
    Write-Host "    * LIRE-MOI.txt       <- instructions completes" -ForegroundColor Gray
    Write-Host ""
    Write-WARN "Pense a modifier le nom du compte dans autounattend.xml avant utilisation !"
    Pause-Return
}

# ------------------------------------------------------------------
#  PARTIE B : POST-INSTALL AUTOMATIQUE
# ------------------------------------------------------------------

function Invoke-PostInstallAuto {
    Write-Banner
    Write-Host "  POST-INSTALL AUTO - Configuration complete" -ForegroundColor Green
    Write-Host "  Tout va se lancer automatiquement dans l'ordre." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Sequence :" -ForegroundColor White
    Write-Host "    1. Point de restauration de securite" -ForegroundColor Gray
    Write-Host "    2. Profil PERSO complet (services, visuels, registre)" -ForegroundColor Gray
    Write-Host "    3. Desactivation IA Windows (Copilot, Recall, Widgets)" -ForegroundColor Gray
    Write-Host "    4. Suppression bloatwares (tout, sans confirmation)" -ForegroundColor Gray
    Write-Host "    5. Nettoyage disque" -ForegroundColor Gray
    Write-Host "    6. SFC - verification fichiers systeme" -ForegroundColor Gray
    Write-Host ""
    Write-WARN "Cette sequence prend 10 a 20 minutes selon le PC."
    Write-WARN "Ne pas eteindre le PC pendant l'operation."
    Write-Host ""
    $confirm = Read-Host "  Lancer la configuration complete ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    $startTime = Get-Date
    $errors    = @()

    # -- 1. Point de restauration -----------------------------------
    Write-Title "1/6 - Point de restauration"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        $date = Get-Date -Format "dd/MM/yyyy HH:mm"
        Checkpoint-Computer -Description "Avant Post-Install Auto - $date" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-OK "Point de restauration cree"
    } catch { Write-WARN "Point de restauration echoue - on continue quand meme" }

    # -- 2. Profil Perso --------------------------------------------
    Write-Title "2/6 - Profil PERSO"
    try {
        Set-PowerPlan "performance"
        Set-Services  "perso"
        Set-Privacy
        Set-Visuals   "performance"
        Set-Startup   "perso"
        Set-Registry
        Write-OK "Profil PERSO applique"
    } catch { $errors += "Profil PERSO : $_" }

    # -- 3. IA Windows ----------------------------------------------
    Write-Title "3/6 - Desactivation IA Windows"
    try {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"           /v TurnOffWindowsCopilot     /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v ShowCopilotButton         /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"                /v DisableAIDataAnalysis     /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v TaskbarDa                 /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
        Get-AppxPackage -Name "MicrosoftWindows.Client.WebExperience" | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage -Name "Clipchamp.Clipchamp"                   | Remove-AppxPackage -ErrorAction SilentlyContinue
        $svc = Get-Service -Name "AIXService" -ErrorAction SilentlyContinue
        if ($svc) { Stop-Service "AIXService" -Force; Set-Service "AIXService" -StartupType Disabled }
        Write-OK "IA Windows desactivee"
    } catch { $errors += "IA Windows : $_" }

    # -- 4. Bloatwares (silencieux) ---------------------------------
    Write-Title "4/6 - Suppression bloatwares"
    $allBloatware = @(
        "Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider","Microsoft.GamingApp",
        "king.com.CandyCrushSaga","king.com.CandyCrushFriends","king.com.BubbleWitch3Saga",
        "Microsoft.MicrosoftSolitaireCollection","Disney.37853D22215E2",
        "Microsoft.3DBuilder","Microsoft.Microsoft3DViewer",
        "Microsoft.BingNews","Microsoft.BingWeather","Microsoft.BingFinance",
        "Microsoft.MixedReality.Portal","Microsoft.People","Microsoft.Getstarted",
        "Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.SkypeApp",
        "Microsoft.Wallet","Microsoft.Print3D","Microsoft.MicrosoftOfficeHub",
        "Microsoft.Todos","Microsoft.Whiteboard","MicrosoftTeams",
        "Microsoft.549981C3F5F10","SpotifyAB.SpotifyMusic","9E2F88E3.Twitter",
        "Facebook.Facebook","TikTok.TikTok","WinZipComputing.WinZipUniversal",
        "DellInc.DellSupportAssistforPCs","DellInc.DellCommandUpdate",
        "HPInc.MyHP","AD2F1837.HPSupportAssistant",
        "LenovoInc.LenovoVantage","E046963F.LenovoCompanion",
        "AcerInc.AcerCare","ASUSTeKCo.MyASUS"
    )
    $removed = 0
    foreach ($name in $allBloatware) {
        $pkg = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue
        if ($pkg) {
            $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $name |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            $removed++
        }
    }
    Write-OK "$removed bloatware(s) supprimes"

    # -- 5. Nettoyage disque ----------------------------------------
    Write-Title "5/6 - Nettoyage disque"
    Invoke-DiskClean

    # -- 6. SFC -----------------------------------------------------
    Write-Title "6/6 - Verification fichiers systeme (SFC)"
    Write-INFO "Scan en cours - 2 a 5 minutes..."
    $sfc = Start-Process sfc.exe -ArgumentList "/scannow" -NoNewWindow -PassThru -Wait
    if ($sfc.ExitCode -eq 0) { Write-OK "Aucun fichier corrompu" }
    else { Write-WARN "SFC a repare des fichiers - voir C:\Windows\Logs\CBS\CBS.log" }

    # -- Rapport final ----------------------------------------------
    $duration = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Green
    Write-Host "  |   POST-INSTALL TERMINE en $duration min               |" -ForegroundColor Green
    Write-Host "  +==================================================+" -ForegroundColor Green
    Write-Host ""
    if ($errors.Count -eq 0) {
        Write-OK "Aucune erreur - tout s'est passe parfaitement !"
    } else {
        Write-WARN "$($errors.Count) erreur(s) non bloquante(s) :"
        $errors | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkYellow }
    }
    Write-Host ""
    Write-WARN "REDEMARRAGE OBLIGATOIRE pour finaliser toutes les modifications."
    Write-Host ""
    $restart = Read-Host "  Redemarrer maintenant ? (oui/non)"
    if ($restart.ToLower() -eq "oui") { Restart-Computer -Force }
    else { Pause-Return }
}

# ==================================================================
#  DNS SWITCHER
# ==================================================================

function Invoke-DNSSwitcher {
    Write-Banner
    Write-Host "  DNS SWITCHER" -ForegroundColor Cyan
    Write-Host "  Inspire de WinUtil / Chris Titus Tech" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Un bon DNS = navigation plus rapide + moins de tracking" -ForegroundColor White
    Write-Host ""
    Write-Host "  +-------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  [1]  Cloudflare     1.1.1.1  (le + rapide)  |" -ForegroundColor White
    Write-Host "  |  [2]  AdGuard        94.140.14.14 (bloque pubs) |" -ForegroundColor White
    Write-Host "  |  [3]  Quad9          9.9.9.9  (securite)     |" -ForegroundColor White
    Write-Host "  |  [4]  Google         8.8.8.8  (fiable)       |" -ForegroundColor White
    Write-Host "  |  [5]  NextDNS        45.90.28.0 (personnalisable) |" -ForegroundColor White
    Write-Host "  |  [6]  DNS Automatique (DHCP - par defaut)    |" -ForegroundColor DarkGray
    Write-Host "  |  [0]  Annuler                                |" -ForegroundColor DarkGray
    Write-Host "  +-------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""

    $dns = @{
        "1" = @{ Name="Cloudflare";  IPv4Pri="1.1.1.1";      IPv4Sec="1.0.0.1";       IPv6Pri="2606:4700:4700::1111"; IPv6Sec="2606:4700:4700::1001" }
        "2" = @{ Name="AdGuard";     IPv4Pri="94.140.14.14";  IPv4Sec="94.140.15.15";  IPv6Pri="2a10:50c0::ad1:ff";    IPv6Sec="2a10:50c0::ad2:ff" }
        "3" = @{ Name="Quad9";       IPv4Pri="9.9.9.9";       IPv4Sec="149.112.112.112"; IPv6Pri="2620:fe::fe";         IPv6Sec="2620:fe::9" }
        "4" = @{ Name="Google";      IPv4Pri="8.8.8.8";       IPv4Sec="8.8.4.4";       IPv6Pri="2001:4860:4860::8888"; IPv6Sec="2001:4860:4860::8844" }
        "5" = @{ Name="NextDNS";     IPv4Pri="45.90.28.0";    IPv4Sec="45.90.30.0";    IPv6Pri="2a07:a8c0::";          IPv6Sec="2a07:a8c1::" }
    }

    $choice = Read-Host "  Ton choix"
    if ($choice -eq "0") { return }

    # Reinitialiser en automatique (DHCP)
    if ($choice -eq "6") {
        Write-INFO "Retour au DNS automatique (DHCP)..."
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ResetServerAddresses
            Write-OK "DNS auto sur : $($a.Name)"
        }
        ipconfig /flushdns | Out-Null
        Write-OK "DNS remis en automatique + cache vide"
        Pause-Return
        return
    }

    if (-not $dns.ContainsKey($choice)) { Write-WARN "Choix invalide."; Pause-Return; return }

    $selected = $dns[$choice]
    Write-Host ""
    Write-INFO "Application de $($selected.Name) sur toutes les interfaces actives..."

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if ($adapters.Count -eq 0) { Write-WARN "Aucune interface reseau active trouvee."; Pause-Return; return }

    foreach ($adapter in $adapters) {
        try {
            # IPv4
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex `
                -ServerAddresses @($selected.IPv4Pri, $selected.IPv4Sec) -ErrorAction Stop
            # IPv6
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex `
                -ServerAddresses @($selected.IPv6Pri, $selected.IPv6Sec) -ErrorAction SilentlyContinue
            Write-OK "$($adapter.Name) -> $($selected.IPv4Pri) / $($selected.IPv4Sec)"
        } catch {
            Write-WARN "Echec sur $($adapter.Name) : $_"
        }
    }

    # Vider le cache DNS
    ipconfig /flushdns | Out-Null
    Write-OK "Cache DNS vide"
    Write-Host ""
    Write-Host "  DNS $($selected.Name) applique !" -ForegroundColor Cyan
    Write-INFO "Test : ouvre un navigateur et verifie que ca marche."
    Pause-Return
}

# ==================================================================
#  WINGET BATCH INSTALL
# ==================================================================

function Invoke-AppInstaller {
    Write-Banner
    Write-Host "  APPLICATIONS - WinGet" -ForegroundColor Green
    Write-Host "  Inspire de WinUtil / Chris Titus Tech" -ForegroundColor DarkGray
    Write-Host ""

    # Verifier que WinGet est disponible
    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wg) {
        Write-WARN "WinGet non trouve sur ce PC."
        Write-INFO "Il est inclus avec Windows 11 et Windows 10 recent."
        Write-INFO "Sinon installe-le depuis le Microsoft Store : App Installer"
        Pause-Return
        return
    }
    Write-OK "WinGet detecte : $((winget --version))"
    Write-Host ""
    Write-Host "  [U]  Mettre a jour toutes les apps (silencieux)" -ForegroundColor Yellow
    Write-Host "  [I]  Installer de nouvelles applications" -ForegroundColor Green
    Write-Host "  [E]  Gerer les exclusions de mise a jour" -ForegroundColor DarkYellow
    Write-Host "  [0]  Annuler" -ForegroundColor DarkGray
    Write-Host ""
    $mode = Read-Host "  Ton choix"

    if ($mode -eq "0" -or $mode -eq "") { return }

    # Fichier d'exclusions - stocke dans le meme dossier que le script
    $excludeFile = "$PSScriptRoot\winget-exclusions.txt"

    # Charger les exclusions existantes
    $exclusions = @()
    if (Test-Path $excludeFile) {
        $exclusions = Get-Content $excludeFile | Where-Object { $_ -ne "" }
    }

    # -- MODE EXCLUSIONS --------------------------------------------
    if ($mode.ToUpper() -eq "E") {
        Write-Host ""
        Write-Title "Gestion des exclusions WinGet"

        do {
            Write-Host ""
            if ($exclusions.Count -eq 0) {
                Write-INFO "Aucune exclusion configuree."
            } else {
                Write-Host "  Apps exclues des mises a jour :" -ForegroundColor Yellow
                $i = 1
                foreach ($ex in $exclusions) {
                    Write-Host "    [$i] $ex" -ForegroundColor White
                    $i++
                }
            }
            Write-Host ""
            Write-Host "  [A]  Ajouter une exclusion" -ForegroundColor Green
            Write-Host "  [S]  Supprimer une exclusion" -ForegroundColor DarkRed
            Write-Host "  [V]  Voir les apps avec updates dispo (pour choisir)" -ForegroundColor Cyan
            Write-Host "  [0]  Retour" -ForegroundColor DarkGray
            Write-Host ""
            $exChoice = Read-Host "  Ton choix"

            switch ($exChoice.ToUpper()) {
                "A" {
                    Write-INFO "Tape le nom ou l'ID WinGet de l'app a exclure"
                    Write-INFO "(ex: Spotify.Spotify  ou  spotify  ou  Spotify)"
                    $newEx = Read-Host "  App a exclure"
                    if ($newEx -ne "") {
                        $exclusions += $newEx
                        $exclusions | Set-Content $excludeFile -Encoding UTF8
                        Write-OK "Exclusion ajoutee : $newEx"
                    }
                }
                "S" {
                    if ($exclusions.Count -eq 0) { Write-INFO "Aucune exclusion a supprimer."; break }
                    $numDel = Read-Host "  Numero a supprimer"
                    $idx = ($numDel -as [int]) - 1
                    if ($idx -ge 0 -and $idx -lt $exclusions.Count) {
                        $removed = $exclusions[$idx]
                        $exclusions = $exclusions | Where-Object { $_ -ne $removed }
                        $exclusions | Set-Content $excludeFile -Encoding UTF8
                        Write-OK "Exclusion supprimee : $removed"
                    } else { Write-WARN "Numero invalide." }
                }
                "V" {
                    Write-INFO "Apps avec mises a jour disponibles :"
                    Write-Host ""
                    winget upgrade --include-unknown 2>&1 | Select-Object -Skip 1 |
                        Where-Object { $_ -match "\S" -and $_ -notmatch "^-" } |
                        ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
                    Write-Host ""
                    Read-Host "  Appuie sur Entree pour continuer"
                }
            }
        } while ($exChoice -ne "0")

        Pause-Return
        return
    }

    # -- MODE UPDATE ------------------------------------------------
    if ($mode.ToUpper() -eq "U") {
        Write-Host ""
        Write-Title "Mise a jour silencieuse"

        if ($exclusions.Count -gt 0) {
            Write-INFO "Exclusions actives ($($exclusions.Count)) : $($exclusions -join ', ')"
        }
        Write-INFO "Recherche des mises a jour disponibles..."
        Write-Host ""

        # Construire la commande avec exclusions
        if ($exclusions.Count -gt 0) {
            # WinGet ne supporte pas --exclude nativement
            # On recupere la liste et on exclut manuellement
            $upgradeList = winget upgrade --include-unknown 2>&1

            # Extraire les IDs des apps a mettre a jour
            $toUpdate = $upgradeList |
                Where-Object { $_ -match "^\S" -and $_ -notmatch "^Nom|^-|^Les|^$|winget" } |
                ForEach-Object {
                    # Extraire l'ID (3eme colonne environ)
                    $cols = $_ -split "\s{2,}"
                    if ($cols.Count -ge 3) { $cols[2].Trim() }
                } | Where-Object { $_ -ne "" }

            if ($toUpdate.Count -eq 0) {
                Write-OK "Toutes les applications sont deja a jour !"
                Pause-Return
                return
            }

            # Filtrer les exclusions
            $filtered = $toUpdate | Where-Object {
                $appId = $_
                $excluded = $false
                foreach ($ex in $exclusions) {
                    if ($appId -like "*$ex*") { $excluded = $true; break }
                }
                -not $excluded
            }

            $skipped = $toUpdate.Count - $filtered.Count
            if ($skipped -gt 0) { Write-INFO "$skipped app(s) ignoree(s) (exclusions)" }

            if ($filtered.Count -eq 0) {
                Write-OK "Aucune mise a jour apres exclusions."
                Pause-Return
                return
            }

            Write-INFO "$($filtered.Count) app(s) a mettre a jour..."
            Write-Host ""
            $ok = 0; $fail = 0
            foreach ($appId in $filtered) {
                Write-INFO "Mise a jour : $appId"
                winget upgrade --id $appId --silent --accept-package-agreements --accept-source-agreements | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-OK "OK : $appId"; $ok++ }
                else { Write-WARN "Echec : $appId"; $fail++ }
            }
            Write-Host ""
            Write-Host "  $ok mise(s) a jour  |  $skipped exclue(s)  |  $fail echec(s)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })

        } else {
            # Pas d'exclusions : mise a jour globale directe
            Write-INFO "Mise a jour de toutes les apps en cours..."
            Write-Host ""
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-OK "Mise a jour terminee !"
        }

        Write-INFO "Les apps qui ont echoue peuvent necessiter une mise a jour manuelle."
        Pause-Return
        return
    }

    # -- MODE INSTALL -----------------------------------------------
    # Catalogue d'apps par categorie
    $apps = @{
        "1-Navigateurs" = @(
            @{ Id="Google.Chrome";        Label="Google Chrome" },
            @{ Id="Mozilla.Firefox";      Label="Mozilla Firefox" },
            @{ Id="Brave.Brave";          Label="Brave Browser" },
            @{ Id="Microsoft.Edge";       Label="Microsoft Edge" }
        )
        "2-Utilitaires essentiels" = @(
            @{ Id="7zip.7zip";            Label="7-Zip" },
            @{ Id="Notepad++.Notepad++";  Label="Notepad++" },
            @{ Id="VideoLAN.VLC";         Label="VLC Media Player" },
            @{ Id="Microsoft.PowerToys";  Label="PowerToys" },
            @{ Id="voidtools.Everything"; Label="Everything (recherche fichiers)" },
            @{ Id="WinSCP.WinSCP";        Label="WinSCP (FTP/SFTP)" },
            @{ Id="PuTTY.PuTTY";          Label="PuTTY (SSH)" }
        )
        "3-Developpement" = @(
            @{ Id="Microsoft.VisualStudioCode"; Label="Visual Studio Code" },
            @{ Id="Git.Git";                   Label="Git" },
            @{ Id="Python.Python.3.12";        Label="Python 3.12" },
            @{ Id="OpenJS.NodeJS";             Label="Node.js" },
            @{ Id="Docker.DockerDesktop";      Label="Docker Desktop" },
            @{ Id="Microsoft.WindowsTerminal"; Label="Windows Terminal" }
        )
        "4-Communication" = @(
            @{ Id="Discord.Discord";         Label="Discord" },
            @{ Id="SlackTechnologies.Slack"; Label="Slack" },
            @{ Id="Microsoft.Teams";         Label="Microsoft Teams" },
            @{ Id="Zoom.Zoom";               Label="Zoom" }
        )
        "5-Multimedia et photo" = @(
            @{ Id="GIMP.GIMP";               Label="GIMP" },
            @{ Id="Spotify.Spotify";         Label="Spotify" },
            @{ Id="HandBrake.HandBrake";     Label="HandBrake (video)" },
            @{ Id="OBSProject.OBSStudio";    Label="OBS Studio" },
            @{ Id="Greenshot.Greenshot";     Label="Greenshot (capture ecran)" }
        )
        "6-Securite et reseau" = @(
            @{ Id="Bitwarden.Bitwarden";        Label="Bitwarden (mots de passe)" },
            @{ Id="ProtonVPN.ProtonVPN";         Label="ProtonVPN" },
            @{ Id="Malwarebytes.Malwarebytes";   Label="Malwarebytes" },
            @{ Id="WiresharkFoundation.Wireshark"; Label="Wireshark" }
        )
    }

    # Selection categories
    Write-Host "  ETAPE 1 - Quelles categories installer ?" -ForegroundColor Yellow
    Write-Host ""
    $categories = $apps.Keys | Sort-Object
    $catIndex   = @{}
    $i = 1
    foreach ($cat in $categories) {
        Write-Host "  [$i] $($cat.Substring(2))" -ForegroundColor White
        $catIndex[$i] = $cat
        $i++
    }
    Write-Host "  [A] Toutes" -ForegroundColor DarkYellow
    Write-Host "  [0] Annuler" -ForegroundColor DarkGray
    Write-Host ""
    $catChoix = Read-Host "  Categories (ex: 1 2 ou A)"
    if ($catChoix -eq "0" -or $catChoix -eq "") { return }

    $selectedCats = @()
    if ($catChoix.ToUpper() -eq "A") {
        $selectedCats = $categories
    } else {
        foreach ($num in ($catChoix -split " ")) {
            $n = $num -as [int]
            if ($n -and $catIndex.ContainsKey($n)) { $selectedCats += $catIndex[$n] }
        }
    }
    if ($selectedCats.Count -eq 0) { Write-WARN "Aucune categorie selectionnee."; Pause-Return; return }

    # Selection fine
    Write-Host ""
    Write-Host "  ETAPE 2 - Selection fine" -ForegroundColor Yellow
    Write-Host "  [Entree] = installer   [N] = passer   [Q] = stop" -ForegroundColor DarkGray
    Write-Host ""

    $toInstall = @()
    $stop      = $false
    foreach ($cat in $selectedCats) {
        if ($stop) { break }
        Write-Host "  >> $($cat.Substring(2))" -ForegroundColor Green
        Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
        foreach ($app in $apps[$cat]) {
            if ($stop) { break }
            Write-Host "  -> $($app.Label)" -ForegroundColor White
            $rep = Read-Host "     Installer ? (Entree=oui / N=passer / Q=stop)"
            if ($rep.ToUpper() -eq "Q")     { $stop = $true }
            elseif ($rep.ToUpper() -ne "N") { $toInstall += $app }
        }
        Write-Host ""
    }

    if ($toInstall.Count -eq 0) { Write-INFO "Rien a installer."; Pause-Return; return }

    # Recap
    Write-Host "  Recap - $($toInstall.Count) app(s) a installer :" -ForegroundColor Yellow
    $toInstall | ForEach-Object { Write-Host "    * $($_.Label)" -ForegroundColor White }
    Write-Host ""
    $confirm = Read-Host "  Confirmer l'installation ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    # Installation
    Write-Host ""
    Write-Title "Installation en cours..."
    $ok = 0; $fail = 0; $skip = 0

    foreach ($app in $toInstall) {
        Write-Host ""
        Write-INFO "Installation : $($app.Label)..."
        $result = winget install --id $app.Id --silent --accept-package-agreements --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Installe : $($app.Label)"
            $ok++
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-SKIP "Deja installe : $($app.Label)"
            $skip++
        } else {
            Write-WARN "Echec : $($app.Label) (code $LASTEXITCODE)"
            $fail++
        }
    }

    Write-Host ""
    Write-Host "  $ok installee(s)  |  $skip deja presente(s)  |  $fail echec(s)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
    Pause-Return
}

# ==================================================================
#  WINDOWS UPDATE - GESTION
# ==================================================================

function Invoke-WindowsUpdateManager {
    Write-Banner
    Write-Host "  WINDOWS UPDATE - Gestion des mises a jour" -ForegroundColor DarkYellow
    Write-Host "  Inspire de WinUtil / Chris Titus Tech" -ForegroundColor DarkGray
    Write-Host ""

    # Afficher le mode actuel
    $currentDefer = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue).DeferFeatureUpdatesPeriodInDays
    $currentMode  = if ($currentDefer -ge 365) { "Securite uniquement (365j)" }
                    elseif ($currentDefer -gt 0) { "Differe ($currentDefer jours)" }
                    else { "Par defaut (toutes les mises a jour)" }
    Write-INFO "Mode actuel : $currentMode"
    Write-Host ""
    Write-Host "  +-----------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  [1]  SECURITE uniquement (recommande)        |" -ForegroundColor Green
    Write-Host "  |       Feature updates bloques 1 an            |" -ForegroundColor DarkGray
    Write-Host "  |       Securite patchs : delai 4 jours         |" -ForegroundColor DarkGray
    Write-Host "  |                                               |" -ForegroundColor DarkGray
    Write-Host "  |  [2]  DESACTIVER toutes les mises a jour      |" -ForegroundColor DarkRed
    Write-Host "  |       (deconseille sauf cas specifique)       |" -ForegroundColor DarkGray
    Write-Host "  |                                               |" -ForegroundColor DarkGray
    Write-Host "  |  [3]  TOUT activer (comportement Windows)     |" -ForegroundColor Cyan
    Write-Host "  |       Remet les parametres par defaut         |" -ForegroundColor DarkGray
    Write-Host "  |                                               |" -ForegroundColor DarkGray
    Write-Host "  |  [4]  Verifier les mises a jour maintenant    |" -ForegroundColor White
    Write-Host "  |  [5]  Ouvrir Windows Update                   |" -ForegroundColor White
    Write-Host "  |  [0]  Annuler                                 |" -ForegroundColor DarkGray
    Write-Host "  +-----------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Ton choix"

    switch ($choice) {
        "1" {
            Write-INFO "Mode Securite uniquement..."
            # Bloquer les feature updates 365 jours
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdates         /t REG_DWORD /d 1   /f | Out-Null
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdatesPeriodInDays /t REG_DWORD /d 365 /f | Out-Null
            # Securite : delai 4 jours (evite les bad patches du Patch Tuesday)
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdates         /t REG_DWORD /d 1   /f | Out-Null
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdatesPeriodInDays /t REG_DWORD /d 4 /f | Out-Null
            # Garder le service Windows Update actif
            Set-Service -Name wuauserv -StartupType Automatic
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            # Delivery Optimization : Internet + reseau local (mode 3)
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 3 /f | Out-Null
            Write-OK "Feature updates bloques 365 jours"
            Write-OK "Patches securite avec delai de 4 jours"
            Write-OK "Delivery Optimization -> Internet + reseau local"
            Write-INFO "Tu recevras les mises a jour de securite, pas les grosses versions Windows"
        }
        "2" {
            Write-WARN "Desactivation complete de Windows Update..."
            reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f | Out-Null
            Stop-Service  -Name wuauserv -Force
            Set-Service   -Name wuauserv -StartupType Disabled
            Write-OK "Windows Update desactive"
            Write-WARN "Pense a le reactiver regulierement pour les patches securite !"
        }
        "3" {
            Write-INFO "Retour aux parametres par defaut..."
            $keys = @("DeferFeatureUpdates","DeferFeatureUpdatesPeriodInDays",
                      "DeferQualityUpdates","DeferQualityUpdatesPeriodInDays")
            foreach ($k in $keys) {
                reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v $k /f 2>$null | Out-Null
            }
            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f 2>$null | Out-Null
            Set-Service  -Name wuauserv -StartupType Automatic
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Write-OK "Windows Update remis en mode par defaut"
        }
        "4" {
            Write-INFO "Lancement de la verification des mises a jour..."
            Start-Process "ms-settings:windowsupdate-action"
            Write-OK "Ouvert dans les Parametres Windows"
        }
        "5" {
            Start-Process "ms-settings:windowsupdate"
            Write-OK "Windows Update ouvert"
        }
        "0" { return }
        default { Write-WARN "Choix invalide." }
    }

    Pause-Return
}

# ==================================================================
#  FULL AUTO - Tout optimiser en 1 clic + rapport de perf
# ==================================================================

function Invoke-FullAuto {
    Write-Banner
    Write-Host "  FULL AUTO - Optimisation complete en 1 clic" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Sequence complete sans intervention :" -ForegroundColor White
    Write-Host "    1/8  Point de restauration de securite" -ForegroundColor Gray
    Write-Host "    2/8  Profil PERSO complet" -ForegroundColor Gray
    Write-Host "    3/8  IA Windows desactivee (Copilot, Recall, Widgets)" -ForegroundColor Gray
    Write-Host "    4/8  Tous les bloatwares supprimes" -ForegroundColor Gray
    Write-Host "    5/8  Nettoyage disque" -ForegroundColor Gray
    Write-Host "    6/8  DNS -> Cloudflare (1.1.1.1)" -ForegroundColor Gray
    Write-Host "    7/8  Windows Update -> Securite uniquement" -ForegroundColor Gray
    Write-Host "    8/8  Apps mises a jour (WinGet)" -ForegroundColor Gray
    Write-Host "    ---  Rapport genere sur le bureau" -ForegroundColor DarkGray
    Write-Host ""
    Write-WARN "Duree estimee : 15 a 30 minutes. Ne pas eteindre le PC."
    Write-Host ""
    $confirm = Read-Host "  Lancer Full Auto ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    $startTime = Get-Date
    $errors    = @()

    # -- Mesures AVANT ----------------------------------------------
    Write-Title "Capture de l'etat initial"
    $diskBefore     = (Get-PSDrive -Name C -ErrorAction SilentlyContinue).Free
    $svcBefore      = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
    $appxBefore     = (Get-AppxPackage -ErrorAction SilentlyContinue).Count
    $ramTotal       = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
    Write-OK "Etat initial capture (disque, services, packages)"

    # -- 1/8 Point de restauration ----------------------------------
    Write-Title "1/8 - Point de restauration"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        $rpDate = Get-Date -Format "dd/MM/yyyy HH:mm"
        Checkpoint-Computer -Description "Avant Full Auto - $rpDate" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-OK "Point de restauration cree"
    } catch { Write-WARN "Echec restore point - on continue quand meme"; $errors += "RestorePoint: $_" }

    # -- 2/8 Profil PERSO -------------------------------------------
    Write-Title "2/8 - Profil PERSO"
    try {
        Set-PowerPlan "performance"
        Set-Services  "perso"
        Set-Privacy
        Set-Visuals   "performance"
        Set-Startup   "perso"
        Set-Registry
        Write-OK "Profil PERSO applique"
    } catch { $errors += "Profil PERSO: $_"; Write-WARN "Erreur profil PERSO" }

    # -- 3/8 IA Windows ---------------------------------------------
    Write-Title "3/8 - IA Windows OFF"
    try {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"           /v TurnOffWindowsCopilot              /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"           /v TurnOffWindowsCopilot              /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v ShowCopilotButton                  /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"             /v BingSearchEnabled                  /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"                /v DisableAIDataAnalysis              /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"                /v DisableAIDataAnalysis              /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh"                              /v AllowNewsAndInterests               /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v TaskbarDa                          /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"  /v TaskbarMn                          /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"  /v ScoobeSystemSettingEnabled      /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PhotoViewerAI"      /v DisableGenerativeErase             /t REG_DWORD /d 1 /f | Out-Null
        Get-AppxPackage -Name "MicrosoftWindows.Client.WebExperience" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage -Name "Clipchamp.Clipchamp" -ErrorAction SilentlyContinue  | Remove-AppxPackage -ErrorAction SilentlyContinue
        $aiSvc = Get-Service -Name "AIXService" -ErrorAction SilentlyContinue
        if ($aiSvc) { Stop-Service "AIXService" -Force; Set-Service "AIXService" -StartupType Disabled }
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components"    /v ServiceEnabled                     /t REG_DWORD /d 0 /f | Out-Null
        Write-OK "IA Windows desactivee"
    } catch { $errors += "IA Windows: $_"; Write-WARN "Erreur IA Windows" }

    # -- 4/8 Bloatwares ---------------------------------------------
    Write-Title "4/8 - Suppression bloatwares"
    $allBloatware = @(
        "Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider","Microsoft.GamingApp",
        "king.com.CandyCrushSaga","king.com.CandyCrushFriends","king.com.BubbleWitch3Saga",
        "Microsoft.MicrosoftSolitaireCollection","Disney.37853D22215E2",
        "Microsoft.3DBuilder","Microsoft.Microsoft3DViewer",
        "Microsoft.BingNews","Microsoft.BingWeather","Microsoft.BingFinance",
        "Microsoft.MixedReality.Portal","Microsoft.People","Microsoft.Getstarted",
        "Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.SkypeApp",
        "Microsoft.Wallet","Microsoft.Print3D","Microsoft.MicrosoftOfficeHub",
        "Microsoft.Todos","Microsoft.Whiteboard","MicrosoftTeams",
        "Microsoft.549981C3F5F10","SpotifyAB.SpotifyMusic","9E2F88E3.Twitter",
        "Facebook.Facebook","TikTok.TikTok","WinZipComputing.WinZipUniversal",
        "DellInc.DellSupportAssistforPCs","DellInc.DellCommandUpdate",
        "HPInc.MyHP","AD2F1837.HPSupportAssistant",
        "LenovoInc.LenovoVantage","E046963F.LenovoCompanion",
        "AcerInc.AcerCare","ASUSTeKCo.MyASUS"
    )
    $bloatRemoved = 0
    foreach ($name in $allBloatware) {
        $pkg = Get-AppxPackage -Name $name -ErrorAction SilentlyContinue
        if ($pkg) {
            $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $name |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            $bloatRemoved++
        }
    }
    Write-OK "$bloatRemoved bloatware(s) supprimes"

    # -- 5/8 Nettoyage disque ---------------------------------------
    Write-Title "5/8 - Nettoyage disque"
    Invoke-DiskClean

    # -- 6/8 DNS Cloudflare -----------------------------------------
    Write-Title "6/8 - DNS Cloudflare"
    try {
        $activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $activeAdapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex `
                -ServerAddresses @("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex `
                -ServerAddresses @("2606:4700:4700::1111","2606:4700:4700::1001") -ErrorAction SilentlyContinue
        }
        ipconfig /flushdns | Out-Null
        Write-OK "DNS Cloudflare applique sur $($activeAdapters.Count) interface(s) + cache vide"
    } catch { $errors += "DNS: $_"; Write-WARN "Erreur DNS" }

    # -- 7/8 Windows Update securite -------------------------------
    Write-Title "7/8 - Windows Update -> Securite uniquement"
    try {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdates               /t REG_DWORD /d 1   /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferFeatureUpdatesPeriodInDays   /t REG_DWORD /d 365 /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdates               /t REG_DWORD /d 1   /f | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DeferQualityUpdatesPeriodInDays   /t REG_DWORD /d 4   /f | Out-Null
        Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        # Delivery Optimization : Internet + reseau local (mode 3)
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 3 /f | Out-Null
        Write-OK "Feature updates bloques 365j | Patches securite delai 4j"
        Write-OK "Delivery Optimization -> Internet + reseau local"
    } catch { $errors += "WindowsUpdate: $_"; Write-WARN "Erreur Windows Update" }

    # -- 8/8 WinGet update ------------------------------------------
    Write-Title "8/8 - Apps WinGet"
    $appsUpdated   = 0
    $appsUpdatedAll = $false
    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if ($wg) {
        $excludeFile = "$PSScriptRoot\winget-exclusions.txt"
        $exclusions  = @()
        if (Test-Path $excludeFile) {
            $exclusions = Get-Content $excludeFile | Where-Object { $_ -ne "" }
        }
        if ($exclusions.Count -gt 0) {
            Write-INFO "Exclusions actives ($($exclusions.Count)) - update selectif..."
            $upgradeList = winget upgrade --include-unknown 2>&1
            $toUpdate = $upgradeList |
                Where-Object { $_ -match "^\S" -and $_ -notmatch "^Nom|^-|^Les|^$|winget" } |
                ForEach-Object {
                    $cols = $_ -split "\s{2,}"
                    if ($cols.Count -ge 3) { $cols[2].Trim() }
                } | Where-Object { $_ -ne "" }
            $filtered = $toUpdate | Where-Object {
                $appId   = $_
                $excl    = $false
                foreach ($ex in $exclusions) { if ($appId -like "*$ex*") { $excl = $true; break } }
                -not $excl
            }
            foreach ($appId in $filtered) {
                winget upgrade --id $appId --silent --accept-package-agreements --accept-source-agreements | Out-Null
                if ($LASTEXITCODE -eq 0) { $appsUpdated++ }
            }
            Write-OK "$appsUpdated app(s) mise(s) a jour ($($toUpdate.Count - $filtered.Count) exclue(s))"
        } else {
            Write-INFO "Mise a jour globale (winget upgrade --all)..."
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements | Out-Null
            $appsUpdatedAll = $true
            Write-OK "Toutes les apps mises a jour"
        }
    } else {
        Write-SKIP "WinGet non disponible sur ce PC"
    }

    # -- Mesures APRES ----------------------------------------------
    $diskAfter  = (Get-PSDrive -Name C -ErrorAction SilentlyContinue).Free
    $svcAfter   = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
    $appxAfter  = (Get-AppxPackage -ErrorAction SilentlyContinue).Count

    $diskFreedBytes = $diskAfter - $diskBefore
    $diskFreedMB    = [math]::Round($diskFreedBytes / 1MB, 0)
    $diskFreedGB    = [math]::Round($diskFreedBytes / 1GB, 2)
    $svcDisabled    = [math]::Max(0, $svcBefore - $svcAfter)
    $appxSuppressed = [math]::Max(0, $appxBefore - $appxAfter)
    $duration       = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

    # -- Score synthetique ------------------------------------------
    $scorePoints = 0
    if     ($diskFreedMB -gt 1000) { $scorePoints += 3 }
    elseif ($diskFreedMB -gt 500)  { $scorePoints += 2 }
    elseif ($diskFreedMB -gt 100)  { $scorePoints += 1 }
    if     ($svcDisabled -gt 10)   { $scorePoints += 3 }
    elseif ($svcDisabled -gt 5)    { $scorePoints += 2 }
    elseif ($svcDisabled -gt 0)    { $scorePoints += 1 }
    if     ($bloatRemoved -gt 10)  { $scorePoints += 3 }
    elseif ($bloatRemoved -gt 5)   { $scorePoints += 2 }
    elseif ($bloatRemoved -gt 0)   { $scorePoints += 1 }
    if ($appsUpdated -gt 0 -or $appsUpdatedAll) { $scorePoints += 1 }
    $scorePct   = [math]::Round($scorePoints / 10 * 100)
    $scoreColor = if ($scorePct -ge 90) { "#00e87a" } elseif ($scorePct -ge 70) { "#44aaff" } elseif ($scorePct -ge 50) { "#ffaa00" } else { "#ff6644" }
    $scoreLabel = if ($scorePct -ge 90) { "OPTIMAL" } elseif ($scorePct -ge 70) { "TRES BON" } elseif ($scorePct -ge 50) { "BON" } else { "PARTIEL" }
    $comment    = if ($scorePct -ge 90) {
        "Resultat exceptionnel. Ton PC tourne desormais au maximum de ses capacites. Services alleges, bloatwares elimines, vie privee protegee et DNS optimise. Pense a redemarrer pour finaliser."
    } elseif ($scorePct -ge 70) {
        "Tres bonne optimisation. Le PC tourne significativement mieux qu'avant. Si le score bloatwares est faible, c'est probablement que Windows etait deja propre - c'est une bonne nouvelle."
    } elseif ($scorePct -ge 50) {
        "Bonne optimisation de base. L'essentiel est en place : DNS, Windows Update et vie privee. Le PC etait peut-etre deja partiellement configure avant ce passage."
    } else {
        "Optimisation partielle. Soit le PC etait deja bien prepare, soit certaines etapes ont rencontre des obstacles. Verifie les erreurs ci-dessous et relance si necessaire."
    }

    # -- Donnees systeme --------------------------------------------
    Write-Title "Generation du rapport HTML"
    $osInfo      = Get-WmiObject Win32_OperatingSystem
    $cpuInfo     = (Get-WmiObject Win32_Processor | Select-Object -First 1).Name
    $ramGB       = [math]::Round($ramTotal / 1GB, 1)
    $diskTotalGB = [math]::Round(($diskAfter + (Get-PSDrive -Name C -ErrorAction SilentlyContinue).Used) / 1GB, 0)
    $diskUsedGB  = [math]::Round($diskTotalGB - ($diskAfter / 1GB), 1)
    $dateRapport = Get-Date -Format "dd/MM/yyyy a HH:mm"
    $appsLine    = if ($appsUpdatedAll) { "Toutes (winget --all)" } elseif ($appsUpdated -gt 0) { "$appsUpdated app(s)" } else { "0 - deja a jour" }

    # Bloc erreurs HTML
    $errHtml = ""
    if ($errors.Count -gt 0) {
        $errHtml = "<div class='section'><div class='sec-title'>Erreurs non bloquantes</div>"
        foreach ($e in $errors) { $errHtml += "<div class='err-item'><span style='flex-shrink:0'>!</span><span>$e</span></div>" }
        $errHtml += "</div>"
    }

    $reportHtml = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>WinOptimizer - Rapport $dateRapport</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0c0c14;color:#c8c8d8;font-family:'Segoe UI',system-ui,sans-serif;padding:32px;max-width:900px;margin:0 auto}
.header{text-align:center;padding:32px 0 24px;border-bottom:1px solid #1a1a2a;margin-bottom:28px}
.header h1{font-size:12px;color:#333;letter-spacing:5px;text-transform:uppercase}
.header .date{color:#333;font-size:12px;margin-top:10px}
.hero{display:flex;align-items:center;justify-content:center;gap:52px;padding:32px;background:#10101c;border-radius:14px;margin-bottom:24px;border:1px solid #1a1a2a}
.score-wrap{text-align:center;flex-shrink:0}
.score-num{font-size:80px;font-weight:800;line-height:1;color:$scoreColor;letter-spacing:-3px}
.score-sym{font-size:28px;color:$scoreColor;opacity:.5;font-weight:300}
.score-tag{font-size:10px;letter-spacing:5px;color:$scoreColor;margin-top:8px;opacity:.85}
.hero-right{max-width:300px}
.bar-bg{background:#1a1a2a;border-radius:99px;height:6px;overflow:hidden;margin-bottom:16px}
.bar-fill{height:6px;border-radius:99px;background:$scoreColor;width:$($scorePct)%;transition:width .4s}
.hero-comment{font-size:13px;color:#666;line-height:1.7}
.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:24px}
.card{background:#10101c;border:1px solid #1a1a2a;border-radius:10px;padding:18px 12px;text-align:center}
.card-val{font-size:34px;font-weight:700;color:#44aaff;line-height:1}
.card-unit{font-size:10px;color:#44aaff;opacity:.5;margin-top:3px}
.card-lbl{font-size:9px;color:#333;margin-top:10px;text-transform:uppercase;letter-spacing:2px}
.restart-note{background:#111108;border:1px solid #2a2a10;border-radius:8px;padding:12px 18px;text-align:center;color:#666633;font-size:12px;margin-bottom:24px}
.section{margin-bottom:22px}
.sec-title{font-size:9px;letter-spacing:4px;text-transform:uppercase;color:#2a2a3a;margin-bottom:8px;padding-bottom:7px;border-bottom:1px solid #141424}
.sys-grid{display:grid;grid-template-columns:1fr 1fr;gap:5px}
.sys-row{display:flex;justify-content:space-between;padding:8px 12px;background:#10101c;border-radius:5px}
.sk{color:#333;font-size:12px}.sv{color:#888;font-size:12px;font-weight:500}
.checks{display:flex;flex-direction:column;gap:4px}
.chk{display:flex;align-items:center;gap:12px;padding:8px 12px;background:#10101c;border-radius:5px}
.ico{font-size:11px;color:#00e87a;flex-shrink:0;width:14px;text-align:center;font-weight:700}
.chk-txt{font-size:12px;color:#777;flex:1}
.badge{font-size:10px;color:#44aaff;background:#0d1c2a;padding:2px 7px;border-radius:4px;white-space:nowrap}
.err-item{display:flex;gap:10px;padding:8px 12px;background:#120606;border-left:2px solid #ff3333;border-radius:5px;margin-bottom:4px;font-size:12px;color:#cc5555}
.footer{text-align:center;padding:20px 0 0;color:#1a1a2a;font-size:11px;border-top:1px solid #141424;margin-top:28px}
</style>
</head>
<body>

<div class="header">
  <h1>Windows Optimizer &nbsp;v3.1&nbsp; - Rapport d optimisation</h1>
  <div class="date">$dateRapport &nbsp;|&nbsp; Duree : $duration min &nbsp;|&nbsp; $($osInfo.Caption)</div>
</div>

<div class="hero">
  <div class="score-wrap">
    <div class="score-num">$scorePct<span class="score-sym">%</span></div>
    <div class="score-tag">$scoreLabel</div>
  </div>
  <div class="hero-right">
    <div class="bar-bg"><div class="bar-fill"></div></div>
    <div class="hero-comment">$comment</div>
  </div>
</div>

<div class="cards">
  <div class="card">
    <div class="card-val">+$diskFreedMB</div>
    <div class="card-unit">MB liberes</div>
    <div class="card-lbl">Espace disque</div>
  </div>
  <div class="card">
    <div class="card-val">$svcDisabled</div>
    <div class="card-unit">services en moins</div>
    <div class="card-lbl">Allegement RAM</div>
  </div>
  <div class="card">
    <div class="card-val">$bloatRemoved</div>
    <div class="card-unit">apps supprimees</div>
    <div class="card-lbl">Bloatwares</div>
  </div>
  <div class="card">
    <div class="card-val">$appxSuppressed</div>
    <div class="card-unit">packages enleves</div>
    <div class="card-lbl">AppX total</div>
  </div>
</div>

<div class="restart-note">Redemarrage recommande pour finaliser toutes les modifications</div>

<div class="section">
  <div class="sec-title">Systeme</div>
  <div class="sys-grid">
    <div class="sys-row"><span class="sk">OS</span><span class="sv">$($osInfo.Caption)</span></div>
    <div class="sys-row"><span class="sk">CPU</span><span class="sv">$cpuInfo</span></div>
    <div class="sys-row"><span class="sk">RAM</span><span class="sv">$ramGB Go</span></div>
    <div class="sys-row"><span class="sk">Disque C:</span><span class="sv">$diskUsedGB / $diskTotalGB Go</span></div>
  </div>
</div>

<div class="section">
  <div class="sec-title">Actions effectuees</div>
  <div class="checks">
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Point de restauration cree avant toute modification</span><span class="badge">securite</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Profil PERSO - plan perf, services, visuels, registre, demarrage</span><span class="badge">perf max</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">IA Windows desactivee - Copilot, Recall, Widgets, Suggestions, Clipchamp</span><span class="badge">vie privee</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Bloatwares supprimes (AppX + provisioned)</span><span class="badge">$bloatRemoved apps</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Nettoyage disque - TEMP, Prefetch, cache, corbeille, DNS</span><span class="badge">+$diskFreedMB MB</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">DNS - Cloudflare 1.1.1.1 / 1.0.0.1 sur toutes les interfaces (IPv4 + IPv6)</span><span class="badge">reseau</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Windows Update - Securite only, feature +365j, patches +4j, DO mode 3</span><span class="badge">stabilite</span></div>
    <div class="chk"><span class="ico">+</span><span class="chk-txt">Apps mises a jour via WinGet</span><span class="badge">$appsLine</span></div>
  </div>
</div>

$errHtml

<div class="footer">WinOptimizer v3.1 &nbsp;|&nbsp; $dateRapport</div>

</body>
</html>
"@

    $desktop    = $userDesktop
    $reportName = "WinOptimizer-Rapport-$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    $reportPath = "$desktop\$reportName"
    Set-Content -Path $reportPath -Value $reportHtml -Encoding UTF8
    Start-Process $reportPath
    Write-OK "Rapport HTML genere et ouvert : $reportName"

    # -- Resume console ---------------------------------------------
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Green
    Write-Host "  |   FULL AUTO TERMINE - $duration min                     |" -ForegroundColor Green
    Write-Host "  +==================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Host "  GAINS REELS :" -ForegroundColor Yellow
    Write-Host "    Espace libere     : +$diskFreedMB MB ($diskFreedGB Go)" -ForegroundColor White
    Write-Host "    Services actifs   : $svcBefore -> $svcAfter  ($svcDisabled desactives)" -ForegroundColor White
    Write-Host "    Bloatwares        : $bloatRemoved supprimes" -ForegroundColor White
    Write-Host "    Packages AppX     : $appxBefore -> $appxAfter  ($appxSuppressed enleves)" -ForegroundColor White
    Write-Host "    Apps mises a jour : $appsLine" -ForegroundColor White
    Write-Host ""
    Write-Host "  Rapport HTML ouvert dans le navigateur : $reportName" -ForegroundColor Cyan
    Write-Host ""
    if ($errors.Count -gt 0) {
        Write-WARN "$($errors.Count) erreur(s) non bloquante(s) - voir rapport"
    } else {
        Write-OK "Aucune erreur - optimisation parfaite !"
    }
    Write-Host ""
    Write-WARN "REDEMARRAGE RECOMMANDE pour finaliser."
    Write-Host ""
    $restart = Read-Host "  Redemarrer maintenant ? (oui/non)"
    if ($restart.ToLower() -eq "oui") { Restart-Computer -Force }
    else { Pause-Return }
}

# ==================================================================
#  ICONES ET RACCOURCI BARRE DES TACHES - BYoan
# ==================================================================

function Save-BitmapAsIco($bmp, $path) {
    # Ecrit un fichier .ico a partir d'un bitmap (format PNG-in-ICO, W7+)
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngData = $ms.ToArray()
    $ms.Dispose()

    $fs     = New-Object System.IO.FileStream($path, [System.IO.FileMode]::Create)
    $writer = New-Object System.IO.BinaryWriter($fs)
    # ICO header (6 bytes)
    $writer.Write([System.UInt16]0)                          # reserved
    $writer.Write([System.UInt16]1)                          # type = icon
    $writer.Write([System.UInt16]1)                          # count = 1
    # ICONDIRENTRY (16 bytes)
    $writer.Write([System.Byte]$bmp.Width)
    $writer.Write([System.Byte]$bmp.Height)
    $writer.Write([System.Byte]0)                            # colorCount
    $writer.Write([System.Byte]0)                            # reserved
    $writer.Write([System.UInt16]1)                          # planes
    $writer.Write([System.UInt16]32)                         # bitCount
    $writer.Write([System.UInt32]$pngData.Length)            # size
    $writer.Write([System.UInt32]22)                         # offset (6+16)
    $writer.Write($pngData)
    $writer.Dispose()
    $fs.Dispose()
}

function New-IconBYoan($path) {
    # Icone BYoan v2 : "BY" cote a cote centre, B cyan / Y vert, scan line, coins L epais
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $S   = 32
    $bmp = New-Object System.Drawing.Bitmap($S, $S)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    # Fond bleu-noir degrade (simule avec deux rects)
    $g.Clear([System.Drawing.Color]::FromArgb(5, 10, 25))
    $fade = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(10, 0, 0, 0))
    for ($i = 0; $i -lt $S; $i++) { $g.FillRectangle($fade, 0, $i, $S, 1) }
    $fade.Dispose()

    # Ligne scan horizontale (glow subtil)
    $scan = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 0, 200, 255))
    $g.FillRectangle($scan, 0, 13, $S, 5)
    $scan.Dispose()

    # Separateur vertical centre (filigrane)
    $sep = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 0, 180, 255), 1)
    $g.DrawLine($sep, 16, 4, 16, 28)
    $sep.Dispose()

    # Lettre "B" - cyan avec glow (dessine 2x en semi-transparent pour simuler le glow)
    $font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $glowB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 0, 220, 255))
    $g.DrawString("B", $font, $glowB, -3.0, 6.0)
    $g.DrawString("B", $font, $glowB, -2.0, 7.0)
    $glowB.Dispose()
    $brushB = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 220, 255))
    $g.DrawString("B", $font, $brushB, -2.5, 6.5)
    $brushB.Dispose()

    # Lettre "Y" - vert matrix avec glow
    $glowY = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 0, 232, 120))
    $g.DrawString("Y", $font, $glowY, 14.0, 6.0)
    $g.DrawString("Y", $font, $glowY, 15.0, 7.0)
    $glowY.Dispose()
    $brushY = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 232, 120))
    $g.DrawString("Y", $font, $brushY, 14.5, 6.5)
    $brushY.Dispose()
    $font.Dispose()

    # Coins L epais - bleu electrique
    $ac = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 160, 255))
    $g.FillRectangle($ac, 0, 0, 5, 1); $g.FillRectangle($ac, 0, 0, 1, 5)
    $g.FillRectangle($ac, ($S-5), 0, 5, 1); $g.FillRectangle($ac, ($S-1), 0, 1, 5)
    $g.FillRectangle($ac, 0, ($S-1), 5, 1); $g.FillRectangle($ac, 0, ($S-5), 1, 5)
    $g.FillRectangle($ac, ($S-5), ($S-1), 5, 1); $g.FillRectangle($ac, ($S-1), ($S-5), 1, 5)
    $ac.Dispose()

    # Bordure fine
    $bd = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(0, 100, 200), 1)
    $g.DrawRectangle($bd, 0, 0, ($S-1), ($S-1))
    $bd.Dispose()

    $g.Dispose()
    Save-BitmapAsIco $bmp $path
    $bmp.Dispose()
}

function New-IconGaming($path) {
    # Icone Gaming v2 : fond violet sombre, eclair jaune-or avec glow orange, "BY" en bas
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $S   = 32
    $bmp = New-Object System.Drawing.Bitmap($S, $S)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    # Fond violet tres sombre
    $g.Clear([System.Drawing.Color]::FromArgb(18, 5, 30))

    # Halo central radial (simule avec ellipses concentriques)
    $h1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 255, 140, 0))
    $h2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 255, 80, 0))
    $g.FillEllipse($h1, 6, 4, 20, 24)
    $g.FillEllipse($h2, 2, 1, 28, 30)
    $h1.Dispose(); $h2.Dispose()

    # Eclair glow (semi-transparent, legerement elargi)
    $boltGlow = [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(12, 1),
        [System.Drawing.Point]::new(3,  16),
        [System.Drawing.Point]::new(9,  16),
        [System.Drawing.Point]::new(4,  31),
        [System.Drawing.Point]::new(19, 15),
        [System.Drawing.Point]::new(13, 15)
    )
    $glowFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 255, 160, 0))
    $g.FillPolygon($glowFill, $boltGlow)
    $glowFill.Dispose()

    # Eclair principal
    $bolt = [System.Drawing.Point[]]@(
        [System.Drawing.Point]::new(11, 2),
        [System.Drawing.Point]::new(4,  15),
        [System.Drawing.Point]::new(10, 15),
        [System.Drawing.Point]::new(5,  30),
        [System.Drawing.Point]::new(18, 14),
        [System.Drawing.Point]::new(12, 14)
    )
    $boltFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 210, 30))
    $g.FillPolygon($boltFill, $bolt)
    $boltFill.Dispose()

    # Contour eclair orange
    $boltPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 0), 1)
    $g.DrawPolygon($boltPen, $bolt)
    $boltPen.Dispose()

    # "BY" en bas a droite - violet clair
    $fSmall  = New-Object System.Drawing.Font("Consolas", 7, [System.Drawing.FontStyle]::Bold)
    $brushBY = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 130, 255))
    $g.DrawString("BY", $fSmall, $brushBY, 16.0, 23.0)
    $fSmall.Dispose(); $brushBY.Dispose()

    # Coins L - violet
    $ac = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 80, 255))
    $g.FillRectangle($ac, 0, 0, 4, 1); $g.FillRectangle($ac, 0, 0, 1, 4)
    $g.FillRectangle($ac, ($S-4), 0, 4, 1); $g.FillRectangle($ac, ($S-1), 0, 1, 4)
    $g.FillRectangle($ac, 0, ($S-1), 4, 1); $g.FillRectangle($ac, 0, ($S-5), 1, 4)
    $g.FillRectangle($ac, ($S-4), ($S-1), 4, 1); $g.FillRectangle($ac, ($S-1), ($S-5), 1, 4)
    $ac.Dispose()

    # Bordure violet sombre
    $bd = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 40, 180), 1)
    $g.DrawRectangle($bd, 0, 0, ($S-1), ($S-1))
    $bd.Dispose()

    $g.Dispose()
    Save-BitmapAsIco $bmp $path
    $bmp.Dispose()
}

function New-TaskbarShortcut {
    Write-Banner
    Write-Host "  BYOAN - Raccourci barre des taches + icones" -ForegroundColor Cyan
    Write-Host ""

    # Icones en local (Windows ne charge pas les .ico depuis un chemin reseau)
    $iconDir        = "C:\BYoan\icons"
    $mainIconPath   = "$iconDir\BYoan.ico"
    $gamingIconPath = "$iconDir\BYoanGaming.ico"
    New-Item -ItemType Directory -Path $iconDir -Force -ErrorAction SilentlyContinue | Out-Null

    # Generer les icones
    Write-INFO "Generation des icones BYoan + Gaming..."
    $iconsOk = $true
    try {
        New-IconBYoan  $mainIconPath
        Write-OK "BYoan.ico cree"
        New-IconGaming $gamingIconPath
        Write-OK "BYoanGaming.ico cree"
    } catch {
        Write-WARN "Erreur icone : $_ - icone systeme utilisee"
        $mainIconPath   = "shell32.dll,14"
        $gamingIconPath = "shell32.dll,43"
        $iconsOk        = $false
    }

    $scriptPath  = $PSCommandPath
    $wsh         = New-Object -ComObject WScript.Shell
    $desktop     = $userDesktop
    $taskbarPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    Write-INFO "Bureau detecte : $desktop"
    Write-INFO "Script : $scriptPath"
    New-Item -ItemType Directory -Path $taskbarPath -Force -ErrorAction SilentlyContinue | Out-Null

    # .bat en local (le script peut tourner depuis le NAS, raccourci doit pointer local)
    $batPath = if (Test-Path "C:\BYoan\Lancer-Optimizer.bat") { "C:\BYoan\Lancer-Optimizer.bat" } else { "$PSScriptRoot\Lancer-Optimizer.bat" }

    # Raccourci barre des taches
    $lnkTB                  = $wsh.CreateShortcut("$taskbarPath\BYoan.lnk")
    $lnkTB.TargetPath       = $batPath
    $lnkTB.WorkingDirectory = $PSScriptRoot
    $lnkTB.Description      = "BYoan - Windows Optimizer"
    $lnkTB.IconLocation     = "$mainIconPath,0"
    $lnkTB.WindowStyle      = 1
    $lnkTB.Save()
    Write-OK "Raccourci -> barre des taches"

    # Raccourci bureau BYoan
    $lnkDesk                  = $wsh.CreateShortcut("$desktop\BYoan.lnk")
    $lnkDesk.TargetPath       = $batPath
    $lnkDesk.WorkingDirectory = $PSScriptRoot
    $lnkDesk.Description      = "BYoan - Windows Optimizer"
    $lnkDesk.IconLocation     = "$mainIconPath,0"
    $lnkDesk.WindowStyle      = 1
    $lnkDesk.Save()
    Write-OK "Raccourci BYoan -> bureau ($desktop\BYoan.lnk)"

    # Mettre a jour les raccourcis Gaming existants
    foreach ($lnkPath in @("$desktop\GameBoost ON.lnk", "$desktop\GameBoost OFF.lnk")) {
        if (Test-Path $lnkPath) {
            $lnkG = $wsh.CreateShortcut($lnkPath)
            $lnkG.IconLocation = "$gamingIconPath,0"
            $lnkG.Save()
        }
    }
    if (Test-Path "$desktop\GameBoost ON.lnk") { Write-OK "Icone Gaming appliquee sur GameBoost ON/OFF" }

    # Notifier le shell (refresh sans tuer explorer)
    try {
        $shellCode = '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, IntPtr a, IntPtr b);'
        Add-Type -MemberDefinition $shellCode -Name WinShellNotify -Namespace BYoanSetup -ErrorAction SilentlyContinue
        [BYoanSetup.WinShellNotify]::SHChangeNotify(0x8000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    } catch {}

    # Marquer installe
    reg add "HKCU\SOFTWARE\WinOptimizer" /v TaskbarShortcut /t REG_DWORD /d 1 /f | Out-Null

    Write-Host ""
    Write-Host "  BYoan est pret sur ta barre des taches !" -ForegroundColor Cyan
    Write-INFO "Si le raccourci n'apparait pas encore : deconnecte/reconnecte ta session."
    Write-INFO "Ou : clic droit sur BYoan.lnk du bureau > Epingler a la barre des taches"
    Pause-Return
}

# ==================================================================
#  PROFIL SECURITE - Windows Hardening
# ==================================================================

function Invoke-ProfileSecu {
    Write-Banner
    Write-Host "  PROFIL SECURITE - Windows Hardening" -ForegroundColor Red
    Write-Host "  Inspire CIS Benchmark / ANSSI / STIG Microsoft" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  +------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  [1]  STANDARD   Zero impact usage - corrections     |" -ForegroundColor Green
    Write-Host "  |       critiques : SMBv1, LLMNR, WDigest, UAC, etc.   |" -ForegroundColor DarkGray
    Write-Host "  |                                                      |" -ForegroundColor DarkGray
    Write-Host "  |  [2]  RENFORCE   Standard + LSA, logging, audit,     |" -ForegroundColor Yellow
    Write-Host "  |       firewall log, RDP off, WinRM off, SMB signing  |" -ForegroundColor DarkGray
    Write-Host "  |                                                      |" -ForegroundColor DarkGray
    Write-Host "  |  [3]  PARANOID   Renforce + outbound block firewall, |" -ForegroundColor Red
    Write-Host "  |       PSv2 off, WSH off, DoH, anti-ransomware        |" -ForegroundColor DarkRed
    Write-Host "  |       ATTENTION : peut bloquer certaines apps !      |" -ForegroundColor DarkRed
    Write-Host "  |                                                      |" -ForegroundColor DarkGray
    Write-Host "  |  [4]  SCAN RESEAU - connexions actives + ports       |" -ForegroundColor Cyan
    Write-Host "  |  [5]  RESET FIREWALL - annuler Paranoid outbound     |" -ForegroundColor DarkYellow
    Write-Host "  |  [A]  TOUT (1 + 2 + 3)                              |" -ForegroundColor DarkYellow
    Write-Host "  |  [0]  Retour                                         |" -ForegroundColor DarkGray
    Write-Host "  +------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Ton choix"
    switch ($choice.ToUpper()) {
        "1" { Invoke-SecuStandard }
        "2" { Invoke-SecuStandard; Invoke-SecuRenforce }
        "3" { Invoke-SecuStandard; Invoke-SecuRenforce; Invoke-SecuParanoid }
        "A" { Invoke-SecuStandard; Invoke-SecuRenforce; Invoke-SecuParanoid }
        "4" { Invoke-SecuNetScan }
        "5" { Invoke-SecuFirewallReset }
        "0" { return }
        default { Write-WARN "Choix invalide."; Pause-Return }
    }
}

# ------------------------------------------------------------------
#  NIVEAU 1 - STANDARD
# ------------------------------------------------------------------

function Invoke-SecuStandard {
    Write-Title "SECU [1/3] STANDARD - Corrections critiques"

    # -- SMBv1 ------------------------------------------------------
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f | Out-Null
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-OK "SMBv1 desactive - faille WannaCry / NotPetya"

    # -- LLMNR ------------------------------------------------------
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "LLMNR desactive - attaques MITM sur reseau local"

    # -- NetBIOS over TCP/IP ----------------------------------------
    $nbAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    foreach ($a in $nbAdapters) { $a.SetTcpipNetbios(2) | Out-Null }
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v NodeType /t REG_DWORD /d 2 /f | Out-Null
    Write-OK "NetBIOS over TCP/IP desactive ($($nbAdapters.Count) interface(s))"

    # -- WDigest - no plaintext passwords in RAM --------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" /v UseLogonCredential /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "WDigest OFF - mots de passe ne sont plus en clair en RAM (anti-Mimikatz)"

    # -- UAC maximum ------------------------------------------------
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser  /t REG_DWORD /d 3 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop      /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA                  /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "UAC niveau maximum - confirmation admin sur bureau securise"

    # -- Autorun / Autoplay -----------------------------------------
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun     /t REG_DWORD /d 255 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoAutorun              /t REG_DWORD /d 1   /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun     /t REG_DWORD /d 255 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer"                 /v NoAutoplayfornonVolume /t REG_DWORD /d 1   /f | Out-Null
    $autoplay = Get-Service -Name "ShellHWDetection" -ErrorAction SilentlyContinue
    if ($autoplay) { Stop-Service "ShellHWDetection" -Force -ErrorAction SilentlyContinue; Set-Service "ShellHWDetection" -StartupType Disabled }
    Write-OK "Autorun/Autoplay desactives sur tous les lecteurs (USB, CD, reseau)"

    # -- Remote Assistance off --------------------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance"          /v fAllowToGetHelp   /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance"          /v fAllowFullControl /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"    /v fAllowToGetHelp   /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Remote Assistance desactivee"

    # -- Firewall ON tous profils -----------------------------------
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction SilentlyContinue
    Write-OK "Firewall Windows actif : Domain + Public + Private"

    # -- Windows Defender durci -------------------------------------
    Set-MpPreference -EnableNetworkProtection Enabled        -ErrorAction SilentlyContinue
    Set-MpPreference -PUAProtection           Enabled        -ErrorAction SilentlyContinue
    Set-MpPreference -CloudBlockLevel         High           -ErrorAction SilentlyContinue
    Set-MpPreference -CloudExtendedTimeout    50             -ErrorAction SilentlyContinue
    Set-MpPreference -DisableRealtimeMonitoring $false       -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $false       -ErrorAction SilentlyContinue
    Set-MpPreference -SubmitSamplesConsent    SendSafeSamples -ErrorAction SilentlyContinue
    reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 5 /f | Out-Null
    Write-OK "Defender : protection reseau + PUA + cloud HIGH + tamper protection"

    # -- WPAD off (Web Proxy Auto-Discovery) -----------------------
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"        /v AutoDetect    /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad"   /v WpadOverride  /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "WPAD desactive (Web Proxy Auto-Discovery - vecteur MITM)"

    # -- Taille logs evenements -------------------------------------
    wevtutil sl Security /ms:134217728  2>$null | Out-Null
    wevtutil sl System   /ms:67108864   2>$null | Out-Null
    Write-OK "Logs evenements : Security 128 MB, System 64 MB"

    Write-Host ""
    Write-Host "  [1] STANDARD applique - 10 vecteurs d'attaque bloques" -ForegroundColor Green
    Write-WARN "Redemarrage recommande (SMBv1, WDigest)."
    Pause-Return
}

# ------------------------------------------------------------------
#  NIVEAU 2 - RENFORCE
# ------------------------------------------------------------------

function Invoke-SecuRenforce {
    Write-Title "SECU [2/3] RENFORCE - Hardening avance"

    # -- LSA Protection (RunAsPPL) ----------------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL             /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags          /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymous    /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RestrictAnonymousSAM /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v NoLMHash             /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f | Out-Null
    Write-OK "LSA Protection (RunAsPPL) - protege contre vol de credentials"
    Write-OK "NTLMv2 only, LM hash off, acces anonyme SAM bloque"

    # -- PowerShell logging -----------------------------------------
    New-Item -Path "C:\PSLogs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockLogging          /t REG_DWORD /d 1        /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" /v EnableScriptBlockInvocationLogging /t REG_DWORD /d 1        /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"      /v EnableModuleLogging               /t REG_DWORD /d 1        /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"      /v EnableTranscripting               /t REG_DWORD /d 1        /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"      /v OutputDirectory                   /t REG_SZ    /d C:\PSLogs /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"      /v EnableInvocationHeader            /t REG_DWORD /d 1        /f | Out-Null
    Write-OK "PowerShell : ScriptBlock + Module + Transcription logging -> C:\PSLogs"

    # -- Audit policy (GUIDs locale-independants) -------------------
    auditpol /set /category:"{69979849-797A-11D9-BED3-505054503030}" /success:enable /failure:enable 2>$null | Out-Null  # Logon/Logoff
    auditpol /set /category:"{6997984E-797A-11D9-BED3-505054503030}" /success:enable /failure:enable 2>$null | Out-Null  # Account Management
    auditpol /set /category:"{69979848-797A-11D9-BED3-505054503030}" /success:enable /failure:enable 2>$null | Out-Null  # System
    auditpol /set /category:"{6997984C-797A-11D9-BED3-505054503030}" /success:enable                2>$null | Out-Null  # Detailed Tracking (process)
    auditpol /set /category:"{6997984B-797A-11D9-BED3-505054503030}" /failure:enable                2>$null | Out-Null  # Privilege Use
    auditpol /set /category:"{6997984D-797A-11D9-BED3-505054503030}" /success:enable /failure:enable 2>$null | Out-Null  # Policy Change
    Write-OK "Audit : connexions, creations processus, modifications compte, privilege"

    # -- Firewall logging -------------------------------------------
    Set-NetFirewallProfile -Profile Domain,Public,Private `
        -LogBlocked True `
        -LogMaxSizeKilobytes 32767 `
        -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" `
        -ErrorAction SilentlyContinue
    Write-OK "Firewall log : 32 MB - %SystemRoot%\System32\LogFiles\Firewall\pfirewall.log"

    # -- RDP off ----------------------------------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f | Out-Null
    Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
    Write-OK "RDP desactive + regles firewall bloquees"

    # -- WinRM off --------------------------------------------------
    $winrm = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    if ($winrm) {
        Stop-Service  -Name WinRM -Force -ErrorAction SilentlyContinue
        Set-Service   -Name WinRM -StartupType Disabled
        Disable-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue
        Write-OK "WinRM desactive + regles firewall bloquees"
    } else { Write-SKIP "WinRM deja absent" }

    # -- SMB signing obligatoire ------------------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"     /v RequireSecuritySignature /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"     /v EnableSecuritySignature  /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnableSecuritySignature  /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "SMB signing requis - protection relay/MITM SMB"

    # -- Desactiver partages cachees admin --------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareWks    /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v AutoShareServer /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Partages admin caches desactives (C`$, ADMIN`$, IPC`$)"

    # -- Securiser les sessions RPC ---------------------------------
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Rpc" /v EnableAuthEpResolution /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Rpc" /v RestrictRemoteClients  /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "RPC : authentification requise, clients distants restreints"

    # -- Proteger la memoire kernel (SEHOP) -------------------------
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "SEHOP active (protection contre corruption de la pile d'exception)"

    # -- Desactiver Print Spooler si pas d'imprimante ---------------
    $printers = Get-Printer -ErrorAction SilentlyContinue
    if ($printers.Count -eq 0) {
        $spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
        if ($spooler) {
            Stop-Service Spooler -Force -ErrorAction SilentlyContinue
            Set-Service  Spooler -StartupType Disabled
            Write-OK "Print Spooler desactive (aucune imprimante detectee - PrintNightmare)"
        }
    } else {
        Write-SKIP "Print Spooler conserve ($($printers.Count) imprimante(s) detectee(s))"
    }

    Write-Host ""
    Write-Host "  [2] RENFORCE applique - LSA, logging, audit, RDP/WinRM off, SMB signed" -ForegroundColor Yellow
    Write-WARN "Redemarrage requis pour LSA Protection (RunAsPPL)."
    Pause-Return
}

# ------------------------------------------------------------------
#  NIVEAU 3 - PARANOID
# ------------------------------------------------------------------

function Invoke-SecuParanoid {
    Write-Banner
    Write-Host "  SECU [3/3] PARANOID" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Ce niveau active :" -ForegroundColor White
    Write-Host "    * Firewall OUTBOUND BLOCK par defaut" -ForegroundColor Gray
    Write-Host "      Whitelist : DNS, HTTP, HTTPS, NTP, DHCP, ICMP" -ForegroundColor DarkGray
    Write-Host "    * PowerShell v2 legacy supprime" -ForegroundColor Gray
    Write-Host "    * Windows Script Host (WSH) desactive" -ForegroundColor Gray
    Write-Host "    * Clients Telnet / TFTP supprimes" -ForegroundColor Gray
    Write-Host "    * DNS over HTTPS (DoH) - Cloudflare chiffre" -ForegroundColor Gray
    Write-Host "    * Controlled Folder Access (anti-ransomware)" -ForegroundColor Gray
    Write-Host "    * Credential Guard (si Hyper-V dispo)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  RISQUE : certains jeux, VPN, apps metier peuvent etre bloques." -ForegroundColor DarkRed
    Write-Host "  Utilise [5] Reset Firewall pour annuler l'outbound block." -ForegroundColor DarkYellow
    Write-Host ""
    $confirm = Read-Host "  Confirmer niveau PARANOID ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    Write-Title "SECU PARANOID"

    # -- Firewall : OUTBOUND BLOCK + whitelist ----------------------
    Write-INFO "Firewall -> DEFAULT OUTBOUND BLOCK..."
    # Nettoyer les anciennes regles SECU si elles existent
    Get-NetFirewallRule -DisplayName "SECU-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    # Appliquer le block par defaut
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block -ErrorAction SilentlyContinue
    # Whitelist essentielle
    New-NetFirewallRule -DisplayName "SECU-Allow-DNS-UDP"   -Direction Outbound -Protocol UDP  -RemotePort 53      -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-DNS-TCP"   -Direction Outbound -Protocol TCP  -RemotePort 53      -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-HTTPS"     -Direction Outbound -Protocol TCP  -RemotePort 443     -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-HTTP"      -Direction Outbound -Protocol TCP  -RemotePort 80      -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-DoH"       -Direction Outbound -Protocol TCP  -RemotePort 853     -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-DHCP"      -Direction Outbound -Protocol UDP  -RemotePort 67      -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-NTP"       -Direction Outbound -Protocol UDP  -RemotePort 123     -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-ICMP"      -Direction Outbound -Protocol ICMPv4 -IcmpType Any     -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "SECU-Allow-ICMPv6"    -Direction Outbound -Protocol ICMPv6 -IcmpType Any     -Action Allow -Enabled True -ErrorAction SilentlyContinue | Out-Null
    Write-OK "Firewall OUTBOUND BLOCK actif"
    Write-OK "Whitelist : DNS(53), HTTP(80), HTTPS(443), DoH(853), DHCP, NTP, ICMP"
    Write-WARN "Pour debloquer une app : Panneau de config > Pare-feu > Autoriser une app"

    # -- PowerShell v2 supprime -------------------------------------
    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2     -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-OK "PowerShell v2 supprime (bypass logging via downgrade)"

    # -- WSH off ----------------------------------------------------
    reg add "HKLM\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 0 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows Script Host\Settings" /v Enabled /t REG_DWORD /d 0 /f | Out-Null
    Write-OK "Windows Script Host desactive (.vbs / .js / .wsf ne s'executent plus)"

    # -- Telnet / TFTP supprimes ------------------------------------
    Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Disable-WindowsOptionalFeature -Online -FeatureName TFTP         -NoRestart -ErrorAction SilentlyContinue | Out-Null
    Write-OK "Clients Telnet et TFTP supprimes"

    # -- DNS over HTTPS (Windows 11) --------------------------------
    try {
        Add-DnsClientDohServerAddress -ServerAddress "1.1.1.1" -DohTemplate "https://cloudflare-dns.com/dns-query" -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop
        Add-DnsClientDohServerAddress -ServerAddress "1.0.0.1" -DohTemplate "https://cloudflare-dns.com/dns-query" -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction SilentlyContinue
        $doHAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($a in $doHAdapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses @("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
        }
        Write-OK "DNS over HTTPS (DoH) - Cloudflare chiffre, pas de fallback UDP"
    } catch {
        Write-SKIP "DoH non disponible (Windows 10 ou cmdlet absente) - DNS normal conserve"
    }

    # -- Controlled Folder Access (anti-ransomware) -----------------
    Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction SilentlyContinue
    Write-OK "Controlled Folder Access ON - Documents/Bureau/Images proteges contre ransomware"
    Write-WARN "Si une app legit est bloquee : Defender > Protection ransomware > Autoriser"

    # -- Credential Guard -------------------------------------------
    $hvciState = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization" -ErrorAction SilentlyContinue).HypervisorEnforcedCodeIntegrity
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity      /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures        /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags                           /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v HypervisorEnforcedCodeIntegrity        /t REG_DWORD /d 1 /f | Out-Null
    Write-OK "Credential Guard configure (VBS + HVCI) - actif apres redemarrage si Hyper-V dispo"

    # -- Execution scripts Internet bloquee (Mark of the Web) -------
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1800 /t REG_DWORD /d 3 /f | Out-Null
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1802 /t REG_DWORD /d 3 /f | Out-Null
    Write-OK "Execution scripts zone Internet bloquee (Mark of the Web)"

    # -- LSASS : interdire les dumps --------------------------------
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LSASS.exe" /v AuditLevel /t REG_DWORD /d 8 /f | Out-Null
    Write-OK "LSASS : dump interdit, audit acces active"

    Write-Host ""
    Write-Host "  [3] PARANOID applique !" -ForegroundColor Red
    Write-WARN "REDEMARRAGE REQUIS pour Credential Guard, PSv2, Controlled Folder Access."
    Write-WARN "Si le reseau ne marche plus -> [17] > [5] Reset Firewall."
    Pause-Return
}

# ------------------------------------------------------------------
#  SCAN RESEAU
# ------------------------------------------------------------------

function Invoke-SecuNetScan {
    Write-Banner
    Write-Host "  SCAN RESEAU - Connexions actives et ports en ecoute" -ForegroundColor Cyan
    Write-Host ""

    Write-Title "Connexions TCP etablies"
    $conns = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" } | Sort-Object RemoteAddress
    if ($conns.Count -eq 0) {
        Write-INFO "Aucune connexion etablie en ce moment."
    } else {
        Write-Host "  Local                   Remote                  PID    Process" -ForegroundColor DarkGray
        Write-Host "  -----                   ------                  ---    -------" -ForegroundColor DarkGray
        foreach ($c in $conns) {
            $proc = try { (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).Name } catch { "?" }
            if (-not $proc) { $proc = "System" }
            $local  = "$($c.LocalAddress):$($c.LocalPort)".PadRight(23)
            $remote = "$($c.RemoteAddress):$($c.RemotePort)".PadRight(23)
            $color  = if ($proc -match "chrome|firefox|brave|msedge|opera") { "Green" }
                      elseif ($proc -match "svchost|System|lsass|wininit") { "DarkGray" }
                      else { "White" }
            Write-Host "  $local $remote $($c.OwningProcess.ToString().PadRight(6)) $proc" -ForegroundColor $color
        }
    }

    Write-Title "Ports en ecoute (listening)"
    $listening = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Sort-Object LocalPort
    if ($listening.Count -eq 0) {
        Write-INFO "Aucun port en ecoute."
    } else {
        foreach ($l in $listening) {
            $proc = try { (Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue).Name } catch { "?" }
            if (-not $proc) { $proc = "System" }
            $color = if ($l.LocalPort -notin @(135,445,5040,49152..65535)) { "Yellow" } else { "DarkGray" }
            Write-Host "    Port $($l.LocalPort.ToString().PadRight(7)) <- $proc  (PID $($l.OwningProcess))" -ForegroundColor $color
        }
    }

    Write-Title "Derniers blocs firewall"
    $fwLog = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"
    if (Test-Path $fwLog) {
        $drops = Get-Content $fwLog -ErrorAction SilentlyContinue |
                 Where-Object { $_ -match "^[\d-]+ [\d:]+ DROP" } |
                 Select-Object -Last 15
        if ($drops) {
            $drops | ForEach-Object {
                $parts = $_ -split " "
                if ($parts.Count -ge 7) {
                    Write-Host "  $($parts[0]) $($parts[1])  DROP  $($parts[4].PadRight(18)) -> $($parts[5])  port $($parts[7])" -ForegroundColor DarkYellow
                }
            }
        } else {
            Write-INFO "Aucun DROP recent dans le log firewall."
        }
    } else {
        Write-INFO "Log firewall absent - active le logging avec [17] > [2] Renforce."
    }

    Write-Title "Interfaces reseau actives"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        $dns = (Get-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join " / "
        Write-Host "  $($_.Name.PadRight(20)) IP: $($ip.PadRight(18)) DNS: $dns" -ForegroundColor White
    }

    Pause-Return
}

# ------------------------------------------------------------------
#  RESET FIREWALL (annuler Paranoid)
# ------------------------------------------------------------------

function Invoke-SecuFirewallReset {
    Write-Banner
    Write-Host "  RESET FIREWALL - Annuler l'outbound block Paranoid" -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  Cela va remettre le firewall en ALLOW par defaut en sortie" -ForegroundColor White
    Write-Host "  et supprimer les regles SECU-* ajoutees par le mode Paranoid." -ForegroundColor DarkGray
    Write-Host ""
    $confirm = Read-Host "  Confirmer le reset ? (oui/non)"
    if ($confirm.ToLower() -ne "oui") { Write-INFO "Annule."; Pause-Return; return }

    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow -ErrorAction SilentlyContinue
    Get-NetFirewallRule -DisplayName "SECU-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    Write-OK "Firewall outbound remis en ALLOW par defaut"
    Write-OK "Regles SECU-* supprimees"
    Write-INFO "Les autres configurations Paranoid (WSH, PSv2, DoH) restent actives."
    Pause-Return
}

# ==================================================================
#  DIAGNOSTIC SYSTEME
# ==================================================================

function Invoke-Diagnostic {
    Write-Banner
    Write-Host "  DIAGNOSTIC SYSTEME - Analyse complete" -ForegroundColor Cyan
    Write-Host ""

    # -- Init log ---------------------------------------------------
    $nasPath       = "\\192.168.2.21\Iron-Jarvis\Jarvis\windows-optimizer\logs"
    $logDate       = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $hostname      = $env:COMPUTERNAME
    $localLogsPath = "C:\BYoan\logs"
    New-Item -ItemType Directory -Path $localLogsPath -Force -ErrorAction SilentlyContinue | Out-Null
    $logFile = "$localLogsPath\Diag-$hostname-$logDate.txt"
    function Log($line) {
        $line | Add-Content -Path $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    Log "=== DIAGNOSTIC BYOAN v$SCRIPT_VERSION === $logDate === $hostname ==="
    Log ""

    # Collecte globale des events System (une seule fois, rapide)
    $allEvents = $null
    try { $allEvents = Get-WinEvent -LogName System -MaxEvents 5000 -ErrorAction Stop } catch {}
    $since24h = (Get-Date).AddHours(-24)
    $since7d  = (Get-Date).AddDays(-7)

    # -- Compteurs pour le resume -----------------------------------
    $cntCrash = 0; $cntWHEA = 0; $cntDisk = 0; $cntGPU = 0
    $cntBSOD  = 0; $cntSvc  = 0; $cntWU   = 0

    # ==============================================================
    # 1. RESUME SANTE (affiche en premier)
    # ==============================================================
    # on calcule d'abord puis on affiche
    if ($allEvents) {
        $cntCrash = ($allEvents | Where-Object { $_.Id -eq 41 }).Count
        $cntWHEA  = ($allEvents | Where-Object { $_.ProviderName -like "*WHEA*" }).Count
        $cntDisk  = ($allEvents | Where-Object { $_.Id -in @(7,11,51) -and $_.ProviderName -like "*disk*" }).Count
        $cntGPU   = ($allEvents | Where-Object { $_.ProviderName -like "*nvlddmkm*" -or $_.ProviderName -like "*dxgkrnl*" }).Count
        $cntBSOD  = ($allEvents | Where-Object { $_.Id -eq 1001 }).Count
        $cntSvc   = ($allEvents | Where-Object { $_.Id -in @(7034,7023) }).Count
        $cntWU    = ($allEvents | Where-Object { $_.Id -in @(20,25) -and $_.Level -le 3 }).Count
    }

    Write-Title "Resume sante systeme (depuis l'installation)"
    Log "[RESUME]"
    $items = @(
        @{ label="Crashes brutaux (Kernel-41)"; val=$cntCrash; seuil=1 },
        @{ label="Erreurs materiel (WHEA)    "; val=$cntWHEA;  seuil=1 },
        @{ label="BSOD enregistres           "; val=$cntBSOD;  seuil=1 },
        @{ label="Erreurs disque (EID 7/11)  "; val=$cntDisk;  seuil=1 },
        @{ label="Crash driver GPU           "; val=$cntGPU;   seuil=5 },
        @{ label="Services en echec          "; val=$cntSvc;   seuil=3 },
        @{ label="Mises a jour ratees        "; val=$cntWU;    seuil=2 }
    )
    foreach ($item in $items) {
        $col  = if ($item.val -eq 0) { "Green" } elseif ($item.val -lt $item.seuil * 3) { "Yellow" } else { "Red" }
        $mark = if ($item.val -eq 0) { "[OK]" } elseif ($item.val -lt $item.seuil * 3) { "[!] " } else { "[!!]" }
        Write-Host "  $mark  $($item.label) : $($item.val)" -ForegroundColor $col
        Log "  $mark $($item.label): $($item.val)"
    }

    # ==============================================================
    # 2. SYSTEME
    # ==============================================================
    Write-Title "Systeme"
    $os        = Get-WmiObject Win32_OperatingSystem
    $boot      = $os.ConvertToDateTime($os.LastBootUpTime)
    $uptime    = (Get-Date) - $boot
    $uptimeStr = "$([math]::Floor($uptime.TotalHours))h $($uptime.Minutes)min"
    $cs        = Get-WmiObject Win32_ComputerSystem
    $cpu       = Get-WmiObject Win32_Processor
    $ramTotal  = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $ramFree   = [math]::Round($os.FreePhysicalMemory / 1MB / 1024, 1)
    $ramUsed   = [math]::Round($ramTotal - $ramFree, 1)
    $disk      = Get-PSDrive -Name C -ErrorAction SilentlyContinue
    $freeGB    = [math]::Round($disk.Free / 1GB, 1)
    $usedGB    = [math]::Round($disk.Used / 1GB, 1)
    $totalGB   = [math]::Round(($disk.Free + $disk.Used) / 1GB, 1)
    $pctDisk   = [math]::Round($usedGB / $totalGB * 100, 0)

    $sysLines = @(
        "OS       : $($os.Caption) $($os.OSArchitecture)",
        "CPU      : $($cpu.Name.Trim())  (charge: $($cpu.LoadPercentage) %)",
        "RAM      : $ramUsed Go / $ramTotal Go utilise  ($ramFree Go libre)",
        "Disque C : $usedGB Go / $totalGB Go ($pctDisk %)  libre: $freeGB Go",
        "Uptime   : $uptimeStr  (boot $($boot.ToString('dd/MM/yyyy HH:mm')))"
    )
    foreach ($l in $sysLines) {
        Write-Host "  $l" -ForegroundColor White
        Log "  $l"
    }
    Log ""

    # RAM details
    Get-WmiObject Win32_PhysicalMemory | ForEach-Object {
        $cap = [math]::Round($_.Capacity / 1GB, 0)
        $s   = "  $($_.BankLabel)  $($_.Manufacturer.Trim())  $($_.PartNumber.Trim())  $($_.Speed) MHz  $cap Go"
        Write-Host $s -ForegroundColor DarkCyan
        Log $s
    }

    # ==============================================================
    # 3. CRASHES & BSOD
    # ==============================================================
    Write-Title "Crashes (Kernel-Power EID 41) - 10 derniers"
    Log "[CRASHES KERNEL-41]"
    if ($allEvents) {
        $crashes = $allEvents | Where-Object { $_.Id -eq 41 } | Select-Object -First 10
        if ($crashes) {
            $crashes | ForEach-Object {
                $ts  = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                $age = if ($_.TimeCreated -gt $since24h) { " <- RECENT (<24h)" } else { "" }
                Write-Host "  [CRASH] $ts$age" -ForegroundColor Red
                Log "  CRASH $ts$age"
            }
        } else { Write-OK "Aucun crash"; Log "  Aucun" }
    }

    Write-Title "BSOD enregistres (EID 1001)"
    Log "[BSOD]"
    if ($allEvents) {
        $bsods = $allEvents | Where-Object { $_.Id -eq 1001 } | Select-Object -First 5
        if ($bsods) {
            $bsods | ForEach-Object {
                $ts  = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                $msg = $_.Message -replace '\s+', ' '
                $short = if ($msg.Length -gt 80) { $msg.Substring(0,80) + "..." } else { $msg }
                Write-Host "  [BSOD] $ts  $short" -ForegroundColor Red
                Log "  BSOD $ts :: $short"
            }
        } else { Write-OK "Aucun BSOD"; Log "  Aucun" }
    }

    # ==============================================================
    # 4. ERREURS HARDWARE
    # ==============================================================
    Write-Title "Erreurs materiel WHEA (hardware)"
    Log "[WHEA]"
    if ($allEvents) {
        $whea = $allEvents | Where-Object { $_.ProviderName -like "*WHEA*" } | Select-Object -First 8
        if ($whea) {
            $whea | ForEach-Object {
                $ts  = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                $age = if ($_.TimeCreated -gt $since24h) { " <- RECENT" } else { "" }
                Write-Host "  [WHEA] $ts  EID=$($_.Id)$age" -ForegroundColor Yellow
                Log "  WHEA $ts EID=$($_.Id)$age"
            }
        } else { Write-OK "Aucune erreur WHEA"; Log "  Aucune" }
    }

    Write-Title "Erreurs disque (EID 7/11/51)"
    Log "[DISQUE ERREURS]"
    if ($allEvents) {
        $diskErr = $allEvents | Where-Object { $_.Id -in @(7,11,51) } | Select-Object -First 8
        if ($diskErr) {
            $diskErr | ForEach-Object {
                $ts = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                Write-Host "  [DISK] EID=$($_.Id)  $ts" -ForegroundColor Red
                Log "  DISK EID=$($_.Id) $ts"
            }
        } else { Write-OK "Aucune erreur disque"; Log "  Aucune" }
    }

    # ==============================================================
    # 5. GPU
    # ==============================================================
    Write-Title "Driver GPU (nvlddmkm / DxgKrnl)"
    Log "[GPU]"
    if ($allEvents) {
        $gpu = $allEvents | Where-Object {
            ($_.ProviderName -like "*nvlddmkm*" -or $_.ProviderName -like "*dxgkrnl*") -and $_.Level -le 3
        } | Select-Object -First 8
        if ($gpu) {
            $gpu | ForEach-Object {
                $ts  = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                $age = if ($_.TimeCreated -gt $since24h) { " <- RECENT" } else { "" }
                Write-Host "  [GPU] EID=$($_.Id)  $ts  $($_.ProviderName)$age" -ForegroundColor Yellow
                Log "  GPU EID=$($_.Id) $ts $($_.ProviderName)$age"
            }
        } else { Write-OK "Aucune erreur driver GPU"; Log "  Aucune" }
    }

    # ==============================================================
    # 6. SERVICES & WINDOWS UPDATE
    # ==============================================================
    Write-Title "Services en echec (EID 7034/7023)"
    Log "[SERVICES]"
    if ($allEvents) {
        $svcs = $allEvents | Where-Object { $_.Id -in @(7034,7023) } | Select-Object -First 8
        if ($svcs) {
            $svcs | ForEach-Object {
                $ts  = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                $msg = ($_.Message -split "`n")[0].Trim()
                $short = if ($msg.Length -gt 70) { $msg.Substring(0,70) } else { $msg }
                Write-Host "  [SVC] $ts  $short" -ForegroundColor Yellow
                Log "  SVC $ts :: $short"
            }
        } else { Write-OK "Aucun service en echec"; Log "  Aucun" }
    }

    Write-Title "Windows Update - echecs (EID 20/25)"
    Log "[WINDOWS UPDATE]"
    if ($allEvents) {
        $wu = $allEvents | Where-Object { $_.Id -in @(20,25) -and $_.Level -le 3 } | Select-Object -First 5
        if ($wu) {
            $wu | ForEach-Object {
                $ts = $_.TimeCreated.ToString("dd/MM/yyyy HH:mm:ss")
                Write-Host "  [WU] EID=$($_.Id)  $ts" -ForegroundColor Yellow
                Log "  WU EID=$($_.Id) $ts"
            }
        } else { Write-OK "Aucun echec Windows Update"; Log "  Aucun" }
    }

    # ==============================================================
    # 7. TOP SOURCES D'ERREURS (24h)
    # ==============================================================
    Write-Title "Top sources erreurs/warnings (24 dernieres heures)"
    Log "[TOP ERREURS 24H]"
    if ($allEvents) {
        $top = $allEvents | Where-Object { $_.Level -le 3 -and $_.TimeCreated -gt $since24h -and
            $_.ProviderName -notlike "*DCOM*" -and $_.Id -notin @(10010,10016) } |
            Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 8
        if ($top) {
            foreach ($g in $top) {
                $col = if ($g.Count -gt 20) { "Red" } elseif ($g.Count -gt 5) { "Yellow" } else { "DarkGray" }
                $line = "  $($g.Count.ToString().PadLeft(4))x  $($g.Name)"
                Write-Host $line -ForegroundColor $col
                Log $line
            }
        } else { Write-OK "Aucune erreur dans les 24h"; Log "  Aucune" }
    }

    # ==============================================================
    # FIN
    # ==============================================================
    Log ""
    Log "=== FIN DIAGNOSTIC ==="

    Write-Host ""
    Write-INFO "Log local : $logFile"
    if (Test-Path $nasPath -ErrorAction SilentlyContinue) {
        robocopy $localLogsPath $nasPath "Diag-$hostname-$logDate.txt" /njh /njs /nc /ns | Out-Null
        Write-OK "Log copie sur le NAS"
    } else {
        Write-SKIP "NAS non accessible - log local uniquement"
    }
    Pause-Return
}

# ==================================================================
#  ARGUMENTS EN LIGNE DE COMMANDE (pour les raccourcis .bat)

param(
    [switch]$GamingOn,
    [switch]$GamingOff
)

if ($GamingOn)  { Invoke-GamingOn;  exit }
if ($GamingOff) { Invoke-GamingOff; exit }

# ==================================================================
#  COPIE LOCALE AU DEMARRAGE (script tourne depuis le NAS)
# ==================================================================
$localDir = "C:\BYoan"
$localScript = "$localDir\windows-optimize.ps1"
New-Item -ItemType Directory -Path "$localDir\icons" -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path "$localDir\logs"  -Force -ErrorAction SilentlyContinue | Out-Null
# Copie le .ps1 et le .bat en local si le script tourne depuis un chemin reseau
if ($PSScriptRoot -like "\\*" -or $PSScriptRoot -like "//") {
    Copy-Item -Path $PSCommandPath -Destination $localScript -Force -ErrorAction SilentlyContinue
    $batSrc = "$PSScriptRoot\Lancer-Optimizer.bat"
    if (Test-Path $batSrc) {
        Copy-Item -Path $batSrc -Destination "$localDir\Lancer-Optimizer.bat" -Force -ErrorAction SilentlyContinue
    }
}

# ==================================================================
#  BOUCLE PRINCIPALE
# ==================================================================

# -- Premier lancement : proposer raccourci BYoan ------------------
$tbDone = (Get-ItemProperty "HKCU:\SOFTWARE\WinOptimizer" -Name "TaskbarShortcut" -ErrorAction SilentlyContinue).TaskbarShortcut
if (-not $tbDone) {
    Clear-Host
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host "  |   Bienvenue dans BYoan - Windows Optimizer !     |" -ForegroundColor Cyan
    Write-Host "  |   Premier lancement detecte.                     |" -ForegroundColor DarkCyan
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Je peux creer un raccourci BYoan sur ta barre des taches" -ForegroundColor White
    Write-Host "  avec une icone personnalisee generee par le script." -ForegroundColor DarkGray
    Write-Host ""
    $tbRep = Read-Host "  Creer le raccourci BYoan ? (O/N)"
    if ($tbRep.ToUpper() -eq "O") { New-TaskbarShortcut }
    else { reg add "HKCU\SOFTWARE\WinOptimizer" /v TaskbarShortcut /t REG_DWORD /d 1 /f | Out-Null }
}

$skipRestorePrompt = $false
$restoreResult     = Invoke-RestorePoint
if ($restoreResult -eq "skip") { $skipRestorePrompt = $true }

do {
    $choice = Show-MainMenu
    switch ($choice) {
        "1" {
            if (-not $skipRestorePrompt) {
                $r = Invoke-RestorePoint
                if ($r -eq "skip") { $skipRestorePrompt = $true }
                if ($r -eq $false) { break }
            }
            Invoke-ProfilePerso
        }
        "2" {
            if (-not $skipRestorePrompt) {
                $r = Invoke-RestorePoint
                if ($r -eq "skip") { $skipRestorePrompt = $true }
                if ($r -eq $false) { break }
            }
            Invoke-ProfileEntreprise
        }
        "3"  { Invoke-GamingOn }
        "4"  { Invoke-GamingOff }
        "5"  { Create-GamingShortcuts }
        "6"  { Write-Banner; Invoke-DiskClean; Pause-Return }
        "7"  { Invoke-CreateRestorePoint }
        "8"  { Invoke-RestoreWindows }
        "9"  { Invoke-RemoveBloatware }
        "10" { Invoke-RemoveLanguages }
        "11" { Invoke-DisableWindowsAI }
        "12" { Invoke-CleanInstall }
        "13" { Invoke-DNSSwitcher }
        "14" { Invoke-AppInstaller }
        "15" { Invoke-WindowsUpdateManager }
        "16" { Invoke-FullAuto }
        "17" { Invoke-ProfileSecu }
        "18" { New-TaskbarShortcut }
        "19" { Invoke-Diagnostic }
        "0"  { Write-Host "`n  A bientot !`n" -ForegroundColor DarkGray; exit }
        default { Write-WARN "Choix invalide, reessaie."; Start-Sleep 1 }
    }
} while ($true)
