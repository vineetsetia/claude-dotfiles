# Claude dotfiles auto-sync agent for Windows
# Pulls remote changes, pushes local changes, notifies on updates
# Run via Task Scheduler every 15 minutes

$dotfilesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dotfilesDir

$logFile = Join-Path $dotfilesDir ".sync.log"

function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $msg" | Out-File -Append -FilePath $logFile
}

function Send-Notification($title, $message) {
    try {
        # Windows 10/11 toast notification via PowerShell
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($template.CreateTextNode($title)) | Out-Null
        $textNodes.Item(1).AppendChild($template.CreateTextNode($message)) | Out-Null
        $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Dotfiles").Show($toast)
    } catch {
        # Fallback: BalloonTip
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.Visible = $true
        $notify.ShowBalloonTip(5000, $title, $message, [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep -Seconds 6
        $notify.Dispose()
    }
}

# Fetch remote
git fetch origin 2>$null

$local = git rev-parse HEAD
$remote = git rev-parse origin/master 2>$null
if (-not $remote) { $remote = $local }

if ($local -ne $remote) {
    $result = git pull --rebase origin master 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "PULLED: synced from remote"
        Send-Notification "Claude Dotfiles" "Settings updated from another device"
    } else {
        Log "ERROR: pull failed - $result"
    }
}

# Check for local changes
$diff = git status --porcelain
if ($diff) {
    git add -A
    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "Auto-sync settings $dateStr" 2>&1 | Out-File -Append $logFile
    git push origin master 2>&1 | Out-File -Append $logFile
    if ($LASTEXITCODE -eq 0) {
        Log "PUSHED: local changes synced to remote"
    } else {
        Log "ERROR: push failed"
    }
} else {
    Log "OK: no changes"
}

# Trim log
if (Test-Path $logFile) {
    $lines = Get-Content $logFile | Select-Object -Last 100
    $lines | Set-Content $logFile
}
