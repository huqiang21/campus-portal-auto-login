# ============================================================
# Campus portal auto-login - generic, config-driven engine
# Targets "web-captive-portal" style campus/guest networks
# (Dr.COM and similar). Works on Windows PowerShell 5.1 and 7.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File auto-login.ps1
#   -Config <path>       alternative config file (default: ./config.ps1)
#   -Watch               stay resident, check every 30 s
#
# Config: copy config.example.ps1 to config.ps1 and edit.
# NEVER commit config.ps1 (see .gitignore).
# ============================================================

param(
    [switch]$Watch,
    [string]$Config = ""
)

if (-not $Config) { $Config = Join-Path $PSScriptRoot "config.ps1" }
if (-not (Test-Path $Config)) {
    Write-Host "[error] config not found: $Config"
    Write-Host "        copy config.example.ps1 to config.ps1 and edit it."
    exit 1
}
. $Config

# optional environment overrides (e.g. set by a shell script)
if ($env:CAMPUS_USER) { $cfg.User = $env:CAMPUS_USER }
if ($env:CAMPUS_PASS) { $cfg.Pass = $env:CAMPUS_PASS }

# ------------------------------------------------------------
function Test-Online {
    try {
        $r = Invoke-WebRequest -Uri $cfg.CheckUrl -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 3
        if ($r.StatusCode -lt 400 -and $r.Content -match $cfg.CheckNeedle) { return $true }
        return $false
    } catch {
        return $false
    }
}

function Expand-Vars([string]$s) {
    $t = $s.Replace("{user}", [uri]::EscapeDataString($cfg.User))
    return $t.Replace("{pass}", [uri]::EscapeDataString($cfg.Pass))
}

function Send-Login {
    try {
        if ($cfg.LoginMethod -ieq 'GET') {
            # GET style, e.g. old Dr.COM:
            #   /drcom/login?callback=dr1003&DDDDD={user}&upass={pass}&0MKKey=123456
            $url = Expand-Vars $cfg.LoginUrl
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 12 -MaximumRedirection 5
        } else {
            # POST style, e.g. current BUPT:
            #   POST <Portal><LoginPath>  body user=..&pass=..
            $target = $cfg.Portal + $cfg.LoginPath
            $parts = @()
            foreach ($k in $cfg.LoginFields.Keys) {
                $parts += ($k + "=" + (Expand-Vars ([string]$cfg.LoginFields[$k])))
            }
            $body = $parts -join "&"
            $r = Invoke-WebRequest -Uri $target -Method Post -Body $body `
                -ContentType "application/x-www-form-urlencoded" -UseBasicParsing `
                -TimeoutSec 12 -MaximumRedirection 5
        }
        $resp = [string]$r.Content
        $snip = ""
        if ($resp.Length -gt 0) { $snip = $resp.Substring(0, [Math]::Min(160, $resp.Length)) }
        Write-Host ("[log] login endpoint HTTP " + $r.StatusCode + " | " + $snip)
        # If the portal re-rendered its own login page, the login did not take.
        if ($cfg.LoginFailMarker -and $resp -match $cfg.LoginFailMarker) {
            Write-Host "[log] auth page re-rendered -> id/pass likely wrong (or the form changed)."
            return $false
        }
        return $true
    } catch {
        Write-Host ("[log] login request failed: " + $_.Exception.Message)
        return $false
    }
}

function Do-Once {
    $ts = (Get-Date).ToString("HH:mm:ss")
    if ($cfg.OnlineSSIDs.Count -gt 0) {
        $ssid = (Get-NetConnectionProfile -ErrorAction SilentlyContinue |
                 Where-Object { $_.InterfaceAlias -like 'WLAN*' } | Select-Object -First 1).Name
        if ($ssid -and $ssid -notin $cfg.OnlineSSIDs) {
            Write-Host ("[" + $ts + "] wifi '" + $ssid + "' not in target list, skip.")
            return
        }
    }
    if (Test-Online) {
        Write-Host ("[" + $ts + "] already online, no action needed.")
        return
    }
    Write-Host ("[" + $ts + "] offline -> trying portal login ...")
    $ok = Send-Login
    Start-Sleep -Seconds 3
    if (Test-Online) {
        Write-Host "[OK] login successful, now online."
    } elseif ($ok) {
        Write-Host "[?] login submitted but online check failed - verify config."
    } else {
        Write-Host "[x] login failed - capture the real login request with F12 (see README)."
    }
}

if ($Watch) {
    Write-Host "Watch mode: check every 30 seconds. Ctrl+C to stop."
    while ($true) { Do-Once; Start-Sleep -Seconds 30 }
} else {
    Do-Once
}
