param(
    [string]$Notebook = "",
    [string]$Style = "classic"
)

# Usage: .\start_jupyter.ps1 [notebook] [classic|lab]

$ErrorActionPreference = "Stop"

if ($Notebook -eq "classic" -or $Notebook -eq "lab") {
    $Style = $Notebook
    $Notebook = ""
}

if ($Style -ne "classic" -and $Style -ne "lab") {
    throw "Style must be classic or lab"
}

# Resolve relative notebook paths from the caller's current PowerShell folder.
if ($Notebook) {
    $Notebook = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Notebook)
}

Set-Location $PSScriptRoot

# Separate name from the Linux/macOS .venv, so a folder shared with aisa keeps both.
$Venv = ".venv-win"
$VenvPython = "$Venv\Scripts\python.exe"
$Marker = "$Venv\.installed"
$RequirementsHash = (Get-FileHash requirements.txt -Algorithm SHA256).Hash
$InstalledHash = ""

if (Test-Path $Marker) {
    $InstalledHash = ([string](Get-Content $Marker -Raw)).Trim()
}

# Rebuild the venv when it is missing or its base Python was removed or changed.
$VenvWorks = $false
if (Test-Path $VenvPython) {
    & $VenvPython --version *> $null
    $VenvWorks = $LASTEXITCODE -eq 0
}

if (-not $VenvWorks) {
    # Prefer the py launcher; fall back to python, skipping the Microsoft Store stub,
    # which exists on PATH but fails to run.
    $PyExe = $null
    $PyArgs = @()
    foreach ($Candidate in @(@("py", "-3"), @("python"))) {
        if (Get-Command $Candidate[0] -ErrorAction SilentlyContinue) {
            $CandidateArgs = @($Candidate | Select-Object -Skip 1)
            # try/catch: with Stop, Windows PowerShell turns redirected stderr into an error
            try { & $Candidate[0] @CandidateArgs --version *> $null } catch { continue }
            if ($LASTEXITCODE -eq 0) {
                $PyExe = $Candidate[0]
                $PyArgs = $CandidateArgs
                break
            }
        }
    }
    if (-not $PyExe) {
        throw "Python 3 not found - install it from python.org (tick 'Add python.exe to PATH')"
    }

    & $PyExe @PyArgs -m venv --clear $Venv
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the virtual environment"
    }
    $InstalledHash = ""
}

if ($InstalledHash -ne $RequirementsHash) {
    & $VenvPython -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        throw "Could not install requirements.txt"
    }

    Set-Content -Path $Marker -Value $RequirementsHash -NoNewline
}

# Notebooks call !openssl; Git for Windows ships it, so borrow Git's copy when none is on PATH.
# Appended, not prepended, so Git's Unix tools do not shadow Windows ones like find and sort.
if (-not (Get-Command openssl -ErrorAction SilentlyContinue)) {
    $Git = Get-Command git -ErrorAction SilentlyContinue
    $GitRoots = @("$env:ProgramFiles\Git", "$env:LOCALAPPDATA\Programs\Git")
    if ($Git) {
        # git.exe lives in <root>\cmd or <root>\bin
        $GitRoots = @((Split-Path (Split-Path $Git.Source))) + $GitRoots
    }
    foreach ($Root in $GitRoots) {
        $Dir = @("$Root\mingw64\bin", "$Root\usr\bin") | Where-Object { Test-Path "$_\openssl.exe" } | Select-Object -First 1
        if ($Dir) {
            $env:PATH = "$env:PATH;$Dir"
            break
        }
    }
}
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-Host "Using OpenSSL: $((Get-Command openssl).Source)"
} else {
    Write-Warning "OpenSSL not found - !openssl cells will fail. Install Git for Windows or use keys_sample."
}

if ($Style -eq "lab") {
    $Command = "lab"
} else {
    $Command = "nbclassic"
}

if ($Notebook) {
    & "$Venv\Scripts\jupyter.exe" $Command $Notebook
} else {
    & "$Venv\Scripts\jupyter.exe" $Command
}
