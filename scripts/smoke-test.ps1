# Gearsh API smoke test (production)
$Base = if ($env:GEARSH_BASE_URL) { $env:GEARSH_BASE_URL } else { "https://www.thegearsh.com" }

Write-Host "Testing $Base ..."

function Test-Url {
    param([string]$Path, [int[]]$ExpectStatus = @(200))
    $url = "$Base$Path"
    $raw = curl.exe -sI -m 15 -o NUL -w "%{http_code}" $url 2>$null
    if (-not $raw) {
        Write-Host "FAIL $Path - no response"
        return $false
    }
    $code = [int]$raw
    if ($ExpectStatus -contains $code) {
        Write-Host "OK   $Path ($code)"
        return $true
    }
    Write-Host "FAIL $Path (got $code, expected $($ExpectStatus -join '/'))"
    return $false
}

$ok = $true
$ok = (Test-Url "/auth.html" @(200, 308)) -and $ok
$ok = (Test-Url "/auth" @(200)) -and $ok
$ok = (Test-Url "/join-gig.html" @(200, 308)) -and $ok
$ok = (Test-Url "/api/health") -and $ok
$ok = (Test-Url "/api/payfast/notify" @(200, 405)) -and $ok

if ($ok) {
    Write-Host "`nSmoke tests passed."
    exit 0
} else {
    Write-Host "`nSome smoke tests failed."
    exit 1
}
