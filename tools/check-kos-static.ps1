param(
    [string]$KosRoot = "kos"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$kosPath = Join-Path $workspaceRoot $KosRoot

if (-not (Test-Path -LiteralPath $kosPath)) {
    Write-Error "kOS folder not found: $kosPath"
    exit 1
}

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-CheckError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Add-CheckWarning {
    param([string]$Message)
    $script:warnings.Add($Message)
}

function Strip-Comment {
    param([string]$Line)

    $inString = $false
    for ($i = 0; $i -lt $Line.Length - 1; $i++) {
        $ch = $Line[$i]
        if ($ch -eq '"') {
            $inString = -not $inString
            continue
        }

        if (-not $inString -and $ch -eq '/' -and $Line[$i + 1] -eq '/') {
            return $Line.Substring(0, $i)
        }
    }

    return $Line
}

function Test-BracesAndBlockClosers {
    param([string]$FilePath)

    $lineNumber = 0
    $braceDepth = 0

    foreach ($rawLine in Get-Content -LiteralPath $FilePath) {
        $lineNumber++
        $line = Strip-Comment -Line $rawLine

        if ($line -match '^\s*}\s*$') {
            Add-CheckWarning "${FilePath}:$lineNumber uses bare '}' (legacy style); prefer '}.'."
        }

        $inString = $false
        for ($i = 0; $i -lt $line.Length; $i++) {
            $ch = $line[$i]
            if ($ch -eq '"') {
                $inString = -not $inString
                continue
            }

            if ($inString) {
                continue
            }

            if ($ch -eq '{') {
                $braceDepth++
            } elseif ($ch -eq '}') {
                $braceDepth--
                if ($braceDepth -lt 0) {
                    Add-CheckError "${FilePath}:$lineNumber has an unmatched closing brace."
                    $braceDepth = 0
                }
            }
        }
    }

    if ($braceDepth -ne 0) {
        Add-CheckError "$FilePath has unmatched braces (depth=$braceDepth)."
    }
}

function Test-HelperScriptSafety {
    param([string]$FilePath)

    $raw = Get-Content -LiteralPath $FilePath -Raw

    if ($raw -match '(?im)^\s*stage\b') {
        Add-CheckError "$FilePath contains a direct stage command; helper scripts must be stage-safe."
    }

    if ($raw -notmatch '(?im)^\s*if\s+not\s+hastarget\b') {
        Add-CheckError "$FilePath is missing a target-selected guard (if not hastarget)."
    }

    if ($raw -notmatch '(?i)target:body:name\s*<>\s*ship:body:name') {
        Add-CheckError "$FilePath is missing a same-body guard (target:body:name <> ship:body:name)."
    }
}

$kosFiles = Get-ChildItem -LiteralPath $kosPath -Recurse -File -Filter '*.ks' | Sort-Object FullName
if ($kosFiles.Count -eq 0) {
    Add-CheckError "No .ks files found under $kosPath"
}

foreach ($file in $kosFiles) {
    Test-BracesAndBlockClosers -FilePath $file.FullName
}

$helperScripts = @(
    (Join-Path $kosPath 'set_intercept.ks')
    (Join-Path $kosPath 'match_velocity.ks')
)

foreach ($helper in $helperScripts) {
    if (-not (Test-Path -LiteralPath $helper)) {
        Add-CheckError "Expected helper script missing: $helper"
        continue
    }

    Test-HelperScriptSafety -FilePath $helper
}

if ($errors.Count -gt 0) {
    Write-Host "kOS static checks FAILED:" -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host " - $err"
    }
    exit 1
}

if ($warnings.Count -gt 0) {
    Write-Host "kOS static checks warnings:" -ForegroundColor Yellow
    foreach ($warn in $warnings) {
        Write-Host " - $warn"
    }
}

Write-Host "kOS static checks passed for $($kosFiles.Count) script(s)." -ForegroundColor Green
exit 0
