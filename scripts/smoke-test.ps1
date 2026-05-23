# Gearsh API smoke test (production)
$Base = if ($env:GEARSH_BASE_URL) { $env:GEARSH_BASE_URL } else { "https://www.thegearsh.com" }

Write-Host "Testing $Base ..."

function Test-Url {
    param([string]$Path, [int[]]$ExpectStatus = @(200))
    $url = "$Base$Path"
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 0 -ErrorAction SilentlyContinue
        $code = [int]$resp.StatusCode
    } catch {
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
        } else {
            Write-Host "FAIL $Path - $($_.Exception.Message)"
            return $false
        }
    }
    if ($ExpectStatus -contains $code) {
        Write-Host "OK   $Path ($code)"
        return $true
    }
    Write-Host "FAIL $Path (got $code, expected $($ExpectStatus -join '/'))"
    return $false
}

$ok = $true
$ok = (Test-Url "/sign-in") -and $ok
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
