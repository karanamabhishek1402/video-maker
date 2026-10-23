# Installs the video-maker skill for Claude Code into ~\.claude\skills
$ErrorActionPreference = "Stop"
$repo = if ($env:SKILL_REPO) { $env:SKILL_REPO } else { "karanamabhishek1402/video-maker" }
$dest = Join-Path $HOME ".claude\skills"
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("video-maker-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp "repo.zip"
Invoke-WebRequest "https://codeload.github.com/$repo/zip/refs/heads/main" -OutFile $zip -UseBasicParsing
Expand-Archive $zip -DestinationPath $tmp
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Remove-Item (Join-Path $dest "video-maker") -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item (Get-ChildItem $tmp -Directory | Select-Object -First 1 | ForEach-Object { Join-Path $_.FullName "skills\video-maker" }) (Join-Path $dest "video-maker") -Recurse
Remove-Item $tmp -Recurse -Force
Write-Host "Installed video-maker skill to $dest\video-maker. Restart Claude Code, then type /video-maker."
