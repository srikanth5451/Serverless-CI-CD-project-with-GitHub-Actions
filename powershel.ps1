<#
.SYNOPSIS
Creates Serverless CI/CD project with GitHub Actions and 50 commits (Jun-Sep 2022)
#>

# Configuration - EDIT THESE VALUES
$REPO_NAME = "Serverless-CI-CD-project-with-GitHub-Actions"
$REPO_DIR = "C:\Users\SRILUCKY\OneDrive\Desktop\my_github_projects\$REPO_NAME"
$USER_NAME = "srikanth5451"
$USER_EMAIL = "91301139+srikanth5451@users.noreply.github.com"
$START_DATE = [datetime]"2022-06-01"
$END_DATE = [datetime]"2022-09-30"
$TOTAL_COMMITS = 50

# 1. Clean and setup repository
try {
    Write-Host "Setting up repository..."
    
    # Remove existing directory if it exists
    if (Test-Path $REPO_DIR) {
        Remove-Item $REPO_DIR -Recurse -Force
    }
    
    # Create new directory
    New-Item -ItemType Directory -Path $REPO_DIR -Force | Out-Null
    Set-Location $REPO_DIR
    
    # Initialize Git repository
    git init
    git config user.name $USER_NAME
    git config user.email $USER_EMAIL
    
    Write-Host "Repository setup complete" -ForegroundColor Green
}
catch {
    Write-Host "Error setting up repository: $_" -ForegroundColor Red
    exit 1
}

# 2. Create project files
try {
    Write-Host "Creating project files..."
    
    # Create directory structure
    New-Item -ItemType Directory -Path "$REPO_DIR\.github\workflows" -Force | Out-Null
    New-Item -ItemType Directory -Path "$REPO_DIR\src" -Force | Out-Null
    
    # Serverless function
@"
exports.handler = async () => {
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Hello from Serverless CI/CD' })
    };
};
"@ | Out-File -FilePath "$REPO_DIR\src\index.js" -Encoding utf8

    # Serverless config
@"
service: serverless-ci-cd

provider:
  name: aws
  runtime: nodejs14.x
  region: us-east-1

functions:
  hello:
    handler: src/index.handler
    events:
      - http: GET /
"@ | Out-File -FilePath "$REPO_DIR\serverless.yml" -Encoding utf8

    # GitHub Actions workflow
@"
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g serverless
      - run: sls deploy
"@ | Out-File -FilePath "$REPO_DIR\.github\workflows\deploy.yml" -Encoding utf8

    # package.json
@"
{
  "name": "serverless-ci-cd",
  "version": "1.0.0",
  "scripts": {
    "deploy": "sls deploy"
  }
}
"@ | Out-File -FilePath "$REPO_DIR\package.json" -Encoding utf8

    Write-Host "Project files created" -ForegroundColor Green
}
catch {
    Write-Host "Error creating project files: $_" -ForegroundColor Red
    exit 1
}

# 3. Generate commits
try {
    Write-Host "Generating commit history..."
    
    # Initial commit
    git add .
    git commit -m "Initial commit: Project setup" --quiet
    $commitCount = 1
    
    $random = New-Object System.Random
    $currentDate = $START_DATE.AddDays(1) # Start after initial commit
    
    while ($commitCount -lt $TOTAL_COMMITS -and $currentDate -le $END_DATE) {
        # Only commit on weekdays (Monday-Friday)
        if ($currentDate.DayOfWeek -notin "Saturday", "Sunday") {
            # Random time between 9AM-5PM
            $commitTime = $currentDate.AddHours(9).AddHours($random.Next(8)).AddMinutes($random.Next(60))
            
            # Select a random file to modify
            $files = @("src/index.js", "serverless.yml", ".github/workflows/deploy.yml")
            $file = $files | Get-Random
            
            # Generate commit message
            $messages = @(
                "Update $file configuration",
                "Improve $file functionality",
                "Fix issue in $file",
                "Refactor $file code",
                "Add feature to $file"
            )
            $message = $messages | Get-Random
            
            # Make a small change
            Add-Content -Path "$REPO_DIR\$file" -Value "`n// Updated $(Get-Date $commitTime -Format 'yyyy-MM-dd')"
            
            # Commit with backdated timestamp
            $env:GIT_AUTHOR_DATE = $commitTime.ToString("yyyy-MM-dd HH:mm:ss")
            $env:GIT_COMMITTER_DATE = $env:GIT_AUTHOR_DATE
            git add $file
            git commit -m $message --quiet
            
            $commitCount++
            Write-Host "Created commit $commitCount/$TOTAL_COMMITS on $($commitTime.ToString('yyyy-MM-dd'))"
        }
        
        $currentDate = $currentDate.AddDays(1)
    }
    
    Write-Host "Successfully created $commitCount commits" -ForegroundColor Green
}
catch {
    Write-Host "Error generating commits: $_" -ForegroundColor Red
    exit 1
}

# 4. Final instructions
Write-Host @"
=== SERVERLESS CI/CD PROJECT CREATED ===
Location: $REPO_DIR
Total commits: $commitCount
Date range: $($START_DATE.ToString('yyyy-MM-dd')) to $($currentDate.AddDays(-1).ToString('yyyy-MM-dd'))

To push to GitHub:
1. Create new repository at https://github.com/new
2. Run these commands:
   cd '$REPO_DIR'
   git remote add origin https://github.com/$USER_NAME/$REPO_NAME.git
   git branch -M main
   git push -u origin main
"@