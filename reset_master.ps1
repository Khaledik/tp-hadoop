# reset_master.ps1
# Nettoie /home du master (bind mount de scripts/master/ -> /home) pour les apprenants.
# Rien n'est supprimé : les fichiers sont déplacés dans archives/master/<horodatage>/,
# c'est-à-dire HORS du montage => invisibles du conteneur, /home redevenu propre.
# Usage : pwsh .\reset_master.ps1

$ErrorActionPreference = 'Stop'
$root     = $PSScriptRoot
$homeD    = Join-Path $root 'scripts\master'
$stamp    = Get-Date -Format 'yyyyMMdd-HHmmss'
$dest     = Join-Path $root ('archives\master\{0}' -f $stamp)
$destHome = Join-Path $dest 'home'
New-Item -ItemType Directory -Path $destHome -Force | Out-Null

# Ce qui reste dans /home : documentation + scripts de démarrage du cluster
# + squelettes de TP versionnés (mapper/reducer/TSV) livrés aux apprenants.
$keep = @(
    'README.md',
    'start-all.sh', 'start-dfs.sh', 'start-hbase.sh', 'start-hive.sh',
    'start-jobhistory.sh', 'start-rest.sh', 'start-thrift.sh',
    'start-yarn.sh', 'start-zookeeper.sh',
    'mapper.py', 'reducer.py', '7-prepare-spotify-tsv.py'
)
# Montages Docker présents comme dossiers dans scripts/master : on n'y touche pas.
$mountPoints = @('src', 'staging', 'metastore_db')

$moved = 0
Get-ChildItem -LiteralPath $homeD -Force | Where-Object {
    $_.Name -notin $mountPoints -and $_.Name -notin $keep
} | ForEach-Object {
    Move-Item -LiteralPath $_.FullName -Destination $destHome -Force
    $moved++
}

# Dépotoir du flux NiFi (visible côté master sous /home/staging).
foreach ($sub in 'input', 'output', 'errors') {
    $d   = Join-Path $dest ('nifi-' + $sub)
    $src = Join-Path $root ('nifi\{0}' -f $sub)
    if (Test-Path -LiteralPath $src) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Get-ChildItem -LiteralPath $src -Force | Where-Object { $_.Name -ne '.gitkeep' } | ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination $d -Force
            $moved++
        }
    }
}

Write-Host ("Terminé : {0} élément(s) archivé(s) dans {1}" -f $moved, $dest)
Write-Host "Le /home du master est maintenant réduit à :"
Get-ChildItem -LiteralPath $homeD -Force | ForEach-Object {
    '  ' + $(if ($_.PSIsContainer) { '/' + $_.Name } else { $_.Name })
}