# 1. Если Docker Desktop не запущен, запускаем и ждём
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Starting Docker Desktop..."
   Start-Process "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe"
  do { Start-Sleep 3; docker info 2>$null | Out-Null } while ($LASTEXITCODE -ne 0)
}

# 2. Если контейнер с базой не работает, запускаем
$running = docker ps --filter "name=messenger-db" --filter "status=running" -q
if (-not $running) { docker start messenger-db | Out-Null }

# 3. Ждём, пока Postgres начнёт принимать подключения
do { Start-Sleep 1; docker exec messenger-db pg_isready -U postgres 2>$null | Out-Null } while ($LASTEXITCODE -ne 0)

# 4. Запускаем сервер из папки backend
Set-Location "$PSScriptRoot\backend"
flint run