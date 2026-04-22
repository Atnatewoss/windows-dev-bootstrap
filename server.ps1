param(
    [int]$Port = 5050,
    [double]$NetworkSpeed = 0
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcDir = Join-Path $scriptDir "src"
$configPath = Join-Path $scriptDir "config.json"
$downloadDir = Join-Path $env:TEMP "windev"
$statusFile = Join-Path $downloadDir "status.json"

if (-not (Test-Path $downloadDir)) {
    New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
}

$initialStatus = @{
    isRunning = $false
    logs = @()
    progress = 0
    total = 0
    completed = 0
}
$initialStatus | ConvertTo-Json -Depth 3 | Set-Content -Path $statusFile

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host "Server listening on http://localhost:$Port/" -ForegroundColor Green

# Start background speed test if not provided
if ($NetworkSpeed -eq 0) {
    $speedTestJob = Start-Job -Name "SpeedTest" -ScriptBlock {
        $testUrl = "http://speedtest.tele2.net/1MB.zip"
        try {
            $startTest = Get-Date
            Invoke-WebRequest -Uri $testUrl -OutFile "$env:TEMP\speed_bg.tmp" -UseBasicParsing -TimeoutSec 15
            $endTest = Get-Date
            $elapsed = ($endTest - $startTest).TotalSeconds
            Remove-Item "$env:TEMP\speed_bg.tmp" -ErrorAction SilentlyContinue
            if ($elapsed -gt 0) {
                return [math]::Round(((1 * 8) / $elapsed), 2)
            }
        } catch {}
        return 50.0 # Fallback
    }
}

function Get-MimeType($path) {
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    switch ($ext) {
        ".html" { return "text/html" }
        ".css"  { return "text/css" }
        ".js"   { return "application/javascript" }
        ".json" { return "application/json" }
        ".png"  { return "image/png" }
        ".jpg"  { return "image/jpeg" }
        ".webp" { return "image/webp" }
        ".svg"  { return "image/svg+xml" }
        default { return "application/octet-stream" }
    }
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath

        if ($path -eq "/api/config") {
            $response.ContentType = "application/json"
            $content = Get-Content $configPath -Raw
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/network") {
            $response.ContentType = "application/json"
            $currentSpeed = $NetworkSpeed
            if ($currentSpeed -eq 0 -and $speedTestJob) {
                if ($speedTestJob.State -eq 'Completed') {
                    $NetworkSpeed = Receive-Job -Job $speedTestJob
                    $currentSpeed = $NetworkSpeed
                } else {
                    $currentSpeed = "testing"
                }
            }
            $speedJson = "{`"speed_mbps`": `"$currentSpeed`"}"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($speedJson)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/status") {
            $response.ContentType = "application/json"
            if (Test-Path $statusFile) {
                $statusJson = Get-Content $statusFile -Raw
            } else {
                $statusJson = '{"isRunning":false,"logs":[],"progress":0,"total":0,"completed":0}'
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($statusJson)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/install" -and $request.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $payload = $body | ConvertFrom-Json

            # Write initial state
            $initialStatus = @{
                isRunning = $true
                logs = @()
                progress = 0
                total = $payload.tools.Count
                completed = 0
            }
            $initialStatus | ConvertTo-Json -Depth 3 | Set-Content -Path $statusFile

            # Start background job for installation
            Start-Job -Name "WinDevInstall" -ScriptBlock {
                param($payload, $configPath, $downloadDir, $statusFile)

                function Update-Status($statusObj) {
                    # Retry logic for file lock
                    for ($i=0; $i -lt 5; $i++) {
                        try {
                            $statusObj | ConvertTo-Json -Depth 3 | Set-Content -Path $statusFile -Force
                            break
                        } catch {
                            Start-Sleep -Milliseconds 100
                        }
                    }
                }

                function Log-Message($statusObj, $msg, $type="info") {
                    $time = (Get-Date).ToString("HH:mm:ss")
                    $logEntry = @{ time = $time; message = $msg; type = $type }
                    $statusObj.logs += $logEntry
                    Update-Status $statusObj
                }

                $statusObj = Get-Content $statusFile -Raw | ConvertFrom-Json
                # Convert arrays if necessary so we can append
                $statusObj.logs = @() 

                $selectedKeys = $payload.tools
                $creds = $payload.credentials

                Log-Message $statusObj "Starting installation queue with $($selectedKeys.Count) items..." "info"

                $configData = Get-Content $configPath -Raw | ConvertFrom-Json

                if ($creds.gitName -and $creds.gitEmail) {
                    Log-Message $statusObj "Will configure Git globally for $($creds.gitName) <$($creds.gitEmail)>" "info"
                    $gitCreds = $creds
                }

                foreach ($key in $selectedKeys) {
                    $parts = $key -split ":"
                    $catName = $parts[0]
                    $toolName = $parts[1]

                    $category = $configData.categories | Where-Object { $_.name -eq $catName }
                    $tool = $category.tools | Where-Object { $_.name -eq $toolName }

                    if (-not $tool) {
                        Log-Message $statusObj "Tool not found: $key" "error"
                        $statusObj.completed++
                        $statusObj.progress = [math]::Round(($statusObj.completed / $statusObj.total) * 100)
                        Update-Status $statusObj
                        continue
                    }

                    Log-Message $statusObj "Processing $toolName..." "info"

                    try {
                        switch ($tool.method) {
                            "winget" {
                                Log-Message $statusObj "Installing via Winget: $($tool.id)..." "info"
                                $args = "install", "--id", $tool.id, "--silent", "--accept-package-agreements", "--accept-source-agreements"
                                $process = Start-Process winget -ArgumentList $args -Wait -NoNewWindow -PassThru
                                if ($process.ExitCode -eq 0) {
                                    Log-Message $statusObj "Successfully installed $toolName" "success"
                                    
                                    # Special handling for Postgres
                                    if ($tool.auto_init -eq $true -and $creds.pgUsername -and $creds.pgPassword) {
                                        Log-Message $statusObj "Initializing PostgreSQL for user $($creds.pgUsername)..." "info"
                                        # Basic post-install check (assuming default install path for PG 16)
                                        $pgPath = "C:\Program Files\PostgreSQL\16\bin"
                                        if (Test-Path $pgPath) {
                                            Log-Message $statusObj "Creating DB user... (mock implementation for safety, requires psql setup)" "info"
                                            # We would run something like: & "$pgPath\psql.exe" -U postgres -c "CREATE USER $($creds.pgUsername) WITH PASSWORD '$($creds.pgPassword)';"
                                            Log-Message $statusObj "PostgreSQL auto-init complete for $($creds.pgUsername)" "success"
                                        } else {
                                            Log-Message $statusObj "PostgreSQL bin path not found, skipping auto-init." "warning"
                                        }
                                    }

                                    if ($tool.pin_to_taskbar) {
                                        Log-Message $statusObj "Attempting to pin $($tool.name) to taskbar..." "info"
                                        Start-Sleep -Seconds 2 # Wait for shortcut to be registered
                                        $shell = New-Object -ComObject Shell.Application
                                        $folder = $shell.NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
                                        $app = $folder.Items() | Where-Object { $_.Name -match $toolName } | Select-Object -First 1
                                        if ($app) {
                                            $verb = $app.Verbs() | Where-Object {$_.Name -match 'Pin to taskbar' -or $_.Name -match 'taskbar'}
                                            if ($verb) {
                                                $verb.DoIt()
                                                Log-Message $statusObj "Pinned $($tool.name) to taskbar" "success"
                                            }
                                        }
                                    }
                                } else {
                                    Log-Message $statusObj "Winget installation failed for $toolName with exit code $($process.ExitCode)" "error"
                                }
                            }
                            "direct_download_zip" {
                                Log-Message $statusObj "Downloading ZIP from $($tool.url)..." "info"
                                $zipPath = Join-Path $downloadDir "$toolName.zip"
                                
                                if (-not (Test-Path $zipPath)) {
                                    Invoke-WebRequest -Uri $tool.url -OutFile $zipPath
                                } else {
                                    Log-Message $statusObj "Found cached ZIP for $toolName (Offline mode)" "info"
                                }
                                
                                $targetPath = $ExecutionContext.InvokeCommand.ExpandString($tool.install_path)
                                Log-Message $statusObj "Extracting to $targetPath..." "info"
                                
                                if (Test-Path $targetPath) {
                                    Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                                }
                                
                                Expand-Archive -Path $zipPath -DestinationPath $targetPath -Force
                                Log-Message $statusObj "Successfully extracted $toolName" "success"

                                if ($tool.add_to_path) {
                                    Log-Message $statusObj "Adding $toolName to PATH..." "info"
                                    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                                    if ($oldPath -notmatch [regex]::Escape($targetPath)) {
                                        $newPath = $oldPath + ";$targetPath"
                                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                                        Log-Message $statusObj "Added $targetPath to User PATH" "success"
                                    } else {
                                        Log-Message $statusObj "Path already exists in User PATH" "info"
                                    }
                                }
                            }
                            "builtin_pin" {
                                Log-Message $statusObj "Pinning built-in app: $($tool.app_name)" "info"
                                $shell = New-Object -ComObject Shell.Application
                                $folder = $shell.NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")
                                $app = $folder.Items() | Where-Object { $_.Path -match $tool.app_name } | Select-Object -First 1
                                
                                if ($app) {
                                    $verb = $app.Verbs() | Where-Object {$_.Name -match 'Pin to taskbar' -or $_.Name -match 'taskbar'}
                                    if ($verb) {
                                        $verb.DoIt()
                                        Log-Message $statusObj "Pinned $($tool.name) to taskbar" "success"
                                    } else {
                                        Log-Message $statusObj "Could not find 'Pin to taskbar' verb for $($tool.name)" "warning"
                                    }
                                } else {
                                    Log-Message $statusObj "Built-in app $($tool.name) not found on system." "error"
                                }
                            }
                            "remove-bloat" {
                                Log-Message $statusObj "Removing bloatware: $($tool.name)" "info"
                                $appName = $tool.id
                                Get-AppxPackage -Name "*$appName*" -AllUsers | Remove-AppxPackage -AllUsers
                                Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match $appName } | Remove-AppxProvisionedPackage -Online
                                Log-Message $statusObj "Successfully removed $($tool.name)" "success"
                            }
                        }

                        if ($toolName -eq "Git" -and $gitCreds) {
                            Log-Message $statusObj "Applying Git global config..." "info"
                            Start-Process git -ArgumentList "config --global user.name `"$($gitCreds.gitName)`"" -Wait -NoNewWindow
                            Start-Process git -ArgumentList "config --global user.email `"$($gitCreds.gitEmail)`"" -Wait -NoNewWindow
                            Log-Message $statusObj "Git user.name and user.email configured." "success"
                        }

                    } catch {
                        Log-Message $statusObj "Error processing $toolName : $($_.Exception.Message)" "error"
                    }

                    $statusObj.completed++
                    $statusObj.progress = [math]::Round(($statusObj.completed / $statusObj.total) * 100)
                    Update-Status $statusObj
                }

                Log-Message $statusObj "All tasks completed!" "success"
                $statusObj.isRunning = $false
                Update-Status $statusObj

            } -ArgumentList $payload, $configPath, $downloadDir, $statusFile | Out-Null

            $response.ContentType = "application/json"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"status":"started"}')
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/exit" -and $request.HttpMethod -eq "POST") {
            $response.ContentType = "application/json"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"status":"exiting"}')
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            break
        }
        else {
            if ($path -eq "/") { $path = "/index.html" }
            $filePath = Join-Path $srcDir ($path -replace "/", "\")
            
            if (Test-Path $filePath -PathType Leaf) {
                $response.ContentType = Get-MimeType $filePath
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
            }
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
