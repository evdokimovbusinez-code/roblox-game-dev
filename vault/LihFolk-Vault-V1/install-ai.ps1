# Installs the vault's ten Roblox AI skills for Claude Code, pointed at this vault, so the AI uses the vault
# by itself whenever you work on Roblox. Run from anywhere:  powershell -ExecutionPolicy Bypass -File install-ai.ps1
#   -Global   also add a short always-on note to your ~/.claude/CLAUDE.md (so every project knows the vault exists)
param([switch]$Global)
$vault = Split-Path -Parent $MyInvocation.MyCommand.Path
$src = Join-Path $vault "31 AI Skills for Roblox\skills"
$dst = Join-Path $HOME ".claude\skills"
New-Item -ItemType Directory -Force $dst | Out-Null
$vaultFwd = $vault -replace '\\', '/'
foreach ($dir in Get-ChildItem $src -Directory) {
    $target = Join-Path $dst $dir.Name
    Copy-Item $dir.FullName $target -Recurse -Force
    foreach ($f in Get-ChildItem $target -Recurse -File -Filter *.md) {
        $text = [IO.File]::ReadAllText($f.FullName).Replace('{{VAULT}}', $vaultFwd)
        [IO.File]::WriteAllText($f.FullName, $text, (New-Object Text.UTF8Encoding $false))
    }
    Write-Host "installed skill: $($dir.Name)"
}
[Environment]::SetEnvironmentVariable("ROBLOX_VAULT", $vault, "User")
Write-Host "set ROBLOX_VAULT = $vault"
if ($Global) {
    $md = Join-Path $HOME ".claude\CLAUDE.md"
    $block = "`n<!-- roblox-vault -->`n# Roblox knowledge vault`nA Roblox game-development knowledge vault is at ``$vaultFwd``. For any Roblox task (Luau, Studio, remotes, DataStores, UI, physics, VFX, monetization, assets), first grep ``$vaultFwd/VAULT_INDEX.md`` and apply the matching notes, without waiting to be asked. See ``$vaultFwd/AGENTS.md``.`n<!-- /roblox-vault -->`n"
    $existing = if (Test-Path $md) { [IO.File]::ReadAllText($md) } else { "" }
    if ($existing -notmatch "<!-- roblox-vault -->") { [IO.File]::AppendAllText($md, $block); Write-Host "added the vault note to $md" }
    else { Write-Host "$md already mentions the vault" }
}
Write-Host ""
Write-Host "Done. Other AI tools (Cursor, Copilot, Windsurf): add this line to your project's AGENTS.md or rules file:"
Write-Host "  For Roblox work, grep $vaultFwd/VAULT_INDEX.md first and follow $vaultFwd/AGENTS.md."
