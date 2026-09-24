param([string]$Mode = '')
$ErrorActionPreference = 'Stop'
$silent = $Mode -in @('/silent', '/s', '-silent', '-s')

function Confirm-Yes([string]$prompt) {
    return ((Read-Host $prompt).Trim() -match '^(?i:y|yes)$')
}

try {
    $target = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\JA_Route')).TrimEnd('\')
    $origin = [IO.Path]::GetFullPath($env:UNINSTALL_ORIGIN).TrimEnd('\')
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\JA_Route'
    
    # Kiem tra xem co dang chay tu thu muc cai dat da dang ky khong
    if (Test-Path -LiteralPath $key) {
        $registered = (Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue).InstallLocation
        if ($registered) {
            $registered = [IO.Path]::GetFullPath($registered).TrimEnd('\')
            if ($origin -ne $registered -and $origin -ne $target) {
                throw 'Vui long chay trinh go cai dat tu thu muc da cai dat, khong chay tu thu muc portable.'
            }
        }
    }
    
    $purge = $false
    if (-not $silent) {
        Write-Host '==============================================================================='
        Write-Host '   TRINH GO CAI DAT JA_ROUTE'
        Write-Host '==============================================================================='
        Write-Host ''
        if (-not (Confirm-Yes 'Ban co chac chan muon go cai dat JA_Route? (Yes/No)')) {
            Write-Host 'Da huy thao tac go cai dat.'
            exit 0
        }
        $purge = Confirm-Yes 'Xoa toan bo cau hinh va nhat ky nguoi dung (config/logs)? (Yes/No; default No)'
    }
    
    # 1. Dong tien trinh ja_route neu dang chay
    $exe = Join-Path $target 'ja_route.exe'
    $running = @(Get-Process ja_route -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe })
    foreach ($app in $running) {
        Stop-Process -Id $app.Id -Force
    }
    
    # 2. Xoa thu muc cai dat trong LOCALAPPDATA
    Set-Location -LiteralPath $env:TEMP
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }
    
    # 3. Xoa du lieu bo sung neu nguoi dung chon purge
    if ($purge) {
        foreach ($d in @((Join-Path $env:APPDATA 'JA_Route'), (Join-Path $env:LOCALAPPDATA 'JA_Route'))) {
            if (Test-Path -LiteralPath $d) {
                Remove-Item -LiteralPath $d -Recurse -Force
            }
        }
    }
    
    # 4. Xoa shortcuts tren Desktop va Start Menu
    $desktop = Join-Path ([Environment]::GetFolderPath('Desktop')) 'JA_Route.lnk'
    $menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\JA_Route'
    if (Test-Path -LiteralPath $desktop) {
        Remove-Item -LiteralPath $desktop -Force
    }
    if (Test-Path -LiteralPath $menu) {
        Remove-Item -LiteralPath $menu -Recurse -Force
    }
    
    # 5. Xoa dang ky Control Panel
    Remove-Item -LiteralPath $key -Recurse -ErrorAction SilentlyContinue
    
    Write-Host ''
    Write-Host '[SUCCESS] Da go cai dat JA_Route thanh cong khoi may tinh!'
    if (-not $silent) {
        Start-Sleep -Seconds 2
    }
    exit 0
} catch {
    Write-Host ''
    Write-Host ('[ERROR] Go cai dat that bai: ' + $_.Exception.Message)
    if (-not $silent) {
        Read-Host 'Nhan Enter de dong' | Out-Null
    }
    exit 1
}
