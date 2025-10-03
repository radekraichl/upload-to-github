# Set correct output encoding for UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Check if git and gh are installed
function Test-CommandExists {
    param (
        [string]$command
    )
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

if (-not (Test-CommandExists "git")) {
    Write-Host "Git is not installed. Please install Git and try again." -ForegroundColor Red
    Write-Host "You can install Git using winget with the following command:" -ForegroundColor Yellow
    Write-Host "winget install --id Git.Git" -ForegroundColor Cyan
    cmd /c pause
    exit 1
}

if (-not (Test-CommandExists "gh")) {
    Write-Host "GitHub CLI (gh) is not installed. Please install GitHub CLI and try again." -ForegroundColor Red
    Write-Host "You can install GitHub CLI using winget with the following command:" -ForegroundColor Yellow
    Write-Host "winget install --id GitHub.cli" -ForegroundColor Cyan
    Write-Host "Or download it from: https://cli.github.com/" -ForegroundColor Yellow
    cmd /c pause
    exit 1
}

# Check if gh is authenticated
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to GitHub CLI. Please login using 'gh auth login'." -ForegroundColor Red
    cmd /c pause
    exit 1
}

# Function to get available gitignore templates
function Get-AvailableTemplates {
    try {
        # Download list of files from GitHub gitignore repository
        $templates = Invoke-RestMethod -Uri "https://api.github.com/repos/github/gitignore/contents" -ErrorAction Stop |
        Where-Object { $_.name -match "\.gitignore$" } |
        ForEach-Object { $_.name -replace "\.gitignore$", "" } |
        Sort-Object

        # Rename .github to None if it exists in the templates
        if ($templates -contains ".github") {
            $templates = $templates | ForEach-Object { 
                if ($_ -eq ".github") { "None" } else { $_ }
            }
        }

        if ($templates.Count -eq 0) {
            throw "No templates found"
        }
        
        return $templates
    }
    catch {
        Write-Host "Failed to download template list. Using basic template list instead." -ForegroundColor Yellow
        # Backup list of popular templates
        return @(
            "Android", "C", "C++", "CMake", "CSharp", "Dart", "Delphi", "Go", "Java", "JavaScript", 
            "Kotlin", "Node", "Objective-C", "Perl", "PHP", "Python", "R", "Ruby", "Rust", "Swift", 
            "Unity", "UnrealEngine", "VisualStudio", "Vue", "WordPress"
        ) | Sort-Object
    }
}

# Function to select gitignore template
function Get-GitignoreTemplate {
    $templates = Get-AvailableTemplates
    
    while ($true) {
        do {
            $prompt = "Select a .gitignore template for your project:`n- Type 'none' for an empty file.`n- Type 'list' to see available templates.`n"
            $inp = Read-Host $prompt

            if ([string]::IsNullOrWhiteSpace($inp)) {
                Write-Host "Input cannot be empty. Please enter a template name or type 'list'." -ForegroundColor Yellow
            }
            if ($inp -ieq "none") {
                Out-File .gitignore -Encoding UTF8
                Write-Host "Created empty .gitignore file." -ForegroundColor Cyan
                return $inp
            }
        } while ([string]::IsNullOrWhiteSpace($inp))

        # Convert to lowercase for case-insensitive comparison
        $inputLower = $inp.ToLower()

        if ($inputLower -eq "list") {
            Write-Host "`nAvailable templates:" -ForegroundColor Cyan
        
            for ($i = 0; $i -lt $templates.Count; $i += 3) {
                $row = @()
                $row += $templates[$i]
                if ($i + 1 -lt $templates.Count) { $row += $templates[$i + 1] }
                if ($i + 2 -lt $templates.Count) { $row += $templates[$i + 2] }
        
                switch ($row.Count) {
                    3 { Write-Host ("- {0,-25} - {1,-25} - {2}" -f $row[0], $row[1], $row[2]) }
                    2 { Write-Host ("- {0,-25} - {1}" -f $row[0], $row[1]) }
                    1 { Write-Host ("- {0}" -f $row[0]) }
                }
            }
        
            Write-Host ""
            continue
        }
        
        # Search regardless of case
        $matchedTemplate = $templates | Where-Object { $_.ToLower() -eq $inputLower }
        
        if ($matchedTemplate) {
            return $matchedTemplate
        }
        else {
            # Offer similar templates
            $similarTemplates = $templates | Where-Object { $_.ToLower() -match $inputLower }
            
            if ($similarTemplates.Count -gt 0) {
                Write-Host "Template '$inp' not found. Did you mean:" -ForegroundColor Yellow
                $similarTemplates | ForEach-Object { Write-Host "- $_" }
            }
            else {
                Write-Host "Template '$inp' not found. Type 'list' to see all available templates." -ForegroundColor Red
            }
        }
    }
}

# Ask for repository name
$repoName = $null
while (-not $repoName) {
    $repoName = (Read-Host "Enter GitHub repository name").Trim()
    if (-not $repoName) {
        Write-Host "Repository name is required." -ForegroundColor Red
    }
}

# Inform user that templates are being loaded
Write-Host "`nLoading .gitignore templates..." -ForegroundColor Cyan
# Get templates
$template = Get-GitignoreTemplate

# Ask if repo should be private
$validResponse = $false
while (-not $validResponse) {
    $visibility = Read-Host "`nShould the repository be private? (yes/no)"
    if ($visibility -eq "yes" -or $visibility -eq "y") {
        $repoVisibility = "private"
        $validResponse = $true
    }
    elseif ($visibility -eq "no" -or $visibility -eq "n") {
        $repoVisibility = "public"
        $validResponse = $true
    }
    else {
        Write-Host "Invalid response. Please use 'yes' or 'no'." -ForegroundColor Yellow
    }
}

# Initialize git repo
Write-Host "`nInitializing Git repository..." -ForegroundColor Cyan
git init
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error initializing Git repository." -ForegroundColor Red
    cmd /c pause
    exit 1
}

# Download .gitignore
if ($template -ine "none") {
    Write-Host "Downloading .gitignore template for $template..." -ForegroundColor Cyan
    $gitignoreUrl = "https://raw.githubusercontent.com/github/gitignore/main/$template.gitignore"
    try {
        Invoke-WebRequest -Uri $gitignoreUrl -OutFile ".gitignore" -ErrorAction Stop
        Write-Host ".gitignore file successfully downloaded." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download .gitignore template from $gitignoreUrl." -ForegroundColor Red
        Write-Host "Creating empty .gitignore file instead." -ForegroundColor Yellow
        New-Item -Path ".gitignore" -ItemType "file" -Force | Out-Null
    }
}

# Load .gitignore content
$gitignoreContent = Get-Content -Raw ".gitignore"
# Replace all LF with CRLF
$gitignoreContent = $gitignoreContent -replace "`n", "`r`n"
# Save back with UTF8 (no BOM)
Set-Content -Path ".gitignore" -Value $gitignoreContent -Encoding UTF8

# Ask for README content
Write-Host "`nEnter README content (leave empty for default, type 'END' on a new line to finish):" -ForegroundColor Cyan
$readmeLines = @()
do {
    $line = Read-Host
    if ($line -ne "END") {
        $readmeLines += $line
    }
} while ($line -ne "END")

# Create README.md with custom content or default
Write-Host "Creating README.md..." -ForegroundColor Cyan
if ($readmeLines.Count -gt 0) {
    $readmeContent = "# $repoName`n`n" + ($readmeLines -join "`n")
}
else {
    $readmeContent = "# $repoName`n"
}
# Replace all LF with CRLF
$readmeContent = $readmeContent -replace "`n", "`r`n"
# Save with UTF8 (no BOM)
Set-Content -Path "README.md" -Value $readmeContent -Encoding UTF8

# Git add & commit
Write-Host "Adding files to Git..." -ForegroundColor Cyan
git add . ':!upload_to_github.bat' ':!upload_to_github.ps1' ':!upload_to_github.exe' 2>&1 | Out-String | Tee-Object -Variable gitAddOutput

if ($LASTEXITCODE -ne 0) {
    # Check if this is a "dubious ownership" error
    if ($gitAddOutput -match "detected dubious ownership") {
        $currentDir = Get-Location
        Write-Host "Detected Git ownership issue. Attempting to fix..." -ForegroundColor Yellow
        git config --global --add safe.directory $currentDir
        
        # Try again after fixing
        Write-Host "Retrying to add files to Git..." -ForegroundColor Cyan
        git add . :!upload_to_github.bat :!upload_to_github.ps1 :!upload_to_github.exe
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error adding files to Git even after fixing ownership." -ForegroundColor Red
            cmd /c pause
            exit 1
        }
    }
    else {
        Write-Host "Error adding files to Git." -ForegroundColor Red
        cmd /c pause
        exit 1
    }
}

# Create commit
Write-Host "Creating initial commit..." -ForegroundColor Cyan
git commit -m "Initial commit" 2>&1 | Out-String | Tee-Object -Variable gitCommitOutput

if ($LASTEXITCODE -ne 0) {
    # Check for common git commit issues like user.name and user.email not set
    if ($gitCommitOutput -match "Please tell me who you are") {
        Write-Host "Git user identity not configured. Setting temporary identity..." -ForegroundColor Yellow
        git config --local user.email "temporary@example.com"
        git config --local user.name "Temporary User"
        
        # Try again after setting identity
        Write-Host "Retrying to create commit..." -ForegroundColor Cyan
        git commit -m "Initial commit with $template .gitignore"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error creating initial commit even after setting identity." -ForegroundColor Red
            cmd /c pause
            exit 1
        }
    }
    else {
        Write-Host "Error creating initial commit." -ForegroundColor Red
        cmd /c pause
        exit 1
    }
}

# Create GitHub repo using CLI and push
Write-Host "Creating GitHub repository '$repoName' ($repoVisibility)..." -ForegroundColor Cyan
# Use --add-readme=false to prevent conflicts with our own README
gh repo create $repoName --$repoVisibility --source=. --remote=origin --push --add-readme=false
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error creating GitHub repository." -ForegroundColor Red
    Write-Host "Check if a repository with this name already exists." -ForegroundColor Yellow
    cmd /c pause
    exit 1
}

Write-Host "`nSuccessfully created GitHub repository '$repoName'!" -ForegroundColor Green
Write-Host "Repository URL: https://github.com/$((gh api user).login)/$repoName" -ForegroundColor Cyan

Write-Host ""
cmd /c pause
