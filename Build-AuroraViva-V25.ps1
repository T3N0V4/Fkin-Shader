# Aurora Viva V25 - Fase 2.2: Iris build from modular source.
# The generated ZIP always gets a NEW name (_r001, _r002, ...).
# No code changes to the compiled deferred1.fsh: strict V24.1 SHA256 guard.
param(
    [string]$RepoPath = 'C:\Proyectos\Fkin-Shader',
    [switch]$InstallToModrinth
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = (Resolve-Path -LiteralPath $RepoPath -ErrorAction Stop).Path
$srcShader = Join-Path $root 'shaders'
$srcProgram = Join-Path $srcShader 'program\deferred1.fsh'
$profileShaderpacks = Join-Path $env:APPDATA 'ModrinthApp\profiles\server real\shaderpacks'
if (-not (Test-Path -LiteralPath $srcProgram -PathType Leaf)) { throw "No existe: $srcProgram" }
if ($InstallToModrinth -and -not (Test-Path -LiteralPath $profileShaderpacks -PathType Container)) {
    throw "No existe la carpeta shaderpacks: $profileShaderpacks"
}

# Allocate a unique ZIP filename WITHOUT ever overwriting earlier versions.
$outputZip = $null
for ($n = 1; $n -le 999; $n++) {
    $fileName = ('AuroraViva_V25_2_Atmosfera_r{0:D3}.zip' -f $n)
    $candidate = Join-Path $root $fileName
    $installed = Join-Path $profileShaderpacks $fileName
    if (-not (Test-Path -LiteralPath $candidate) -and -not (Test-Path -LiteralPath $installed)) {
        $outputZip = $candidate
        break
    }
}
if ($null -eq $outputZip) { throw 'Se agotaron los nombres de ZIP r001..r999.' }

# Do not modify the source tree; expand includes only in a temporary build tree.
$stage = Join-Path $env:TEMP ('AuroraViva_V25_2_build_' + [guid]::NewGuid().ToString('N'))
$tempZip = Join-Path $root ('AuroraViva_TEMP_' + [guid]::NewGuid().ToString('N') + '.zip')
$expected = 'f56a5ab5a5e21221321ef5a09fa90822ccbe8a2887b387c77b04968ef99f5c70'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    Copy-Item -LiteralPath $srcShader -Destination $stage -Recurse -Force
    $stageProgram = Join-Path $stage 'shaders\program\deferred1.fsh'
    $content = [System.IO.File]::ReadAllText($srcProgram, $utf8).Replace("`r`n", "`n")

    # Expand in SOURCE ORDER: the atmosphere include occurs before the other 4 modules.
    foreach ($mod in @('atmosphere', 'core', 'planets', 'blackhole', 'renderer')) {
        $relative = "/lib/auroraviva/celestial/$mod.glsl"
        $marker = '#include "' + $relative + '"' + "`n"
        $path = Join-Path $srcShader ("lib\auroraviva\celestial\$mod.glsl")
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Falta modulo: $path" }
        $source = [System.IO.File]::ReadAllText($path, $utf8).Replace("`r`n", "`n")
        if (-not $source.StartsWith('// Aurora Viva V25')) { throw "Cabecera inesperada en modulo: $mod" }
        $eol = $source.IndexOf("`n")
        if ($eol -lt 0) { throw "Modulo vacio: $mod" }
        $source = $source.Substring($eol + 1)
        if (-not $content.Contains($marker)) { throw "Falta include: $relative" }
        $content = $content.Replace($marker, $source)
    }
    if ($content.Contains('#include "/lib/auroraviva/celestial/')) { throw 'Quedaron includes celestes sin expandir.' }
    [System.IO.File]::WriteAllText($stageProgram, $content, $utf8)
    $hash = (Get-FileHash -LiteralPath $stageProgram -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $expected) { throw "Shader reconstruido difiere de V24.1. SHA: $hash. ZIP cancelado." }
    foreach ($extra in @('LICENSE', 'LICENSE-APACHE', 'README_AURORA_VIVA.txt')) {
        $p = Join-Path $root $extra
        if (Test-Path -LiteralPath $p -PathType Leaf) { Copy-Item -LiteralPath $p -Destination $stage -Force }
    }

    # IMPORTANT: Windows paths MUST be turned into forward slash paths INSIDE ZIP.
    $zipStream = [System.IO.File]::Open($tempZip, [System.IO.FileMode]::CreateNew)
    try {
        $archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($file in (Get-ChildItem -LiteralPath $stage -File -Recurse)) {
                $relativePath = $file.FullName.Substring($stage.Length).TrimStart('\', '/')
                $entryName = $relativePath.Replace('\', '/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $archive, $file.FullName, $entryName,
                    [System.IO.Compression.CompressionLevel]::Optimal
                ) | Out-Null
            }
        } finally { $archive.Dispose() }
    } finally { $zipStream.Dispose() }

    # Inspect the ZIP itself, not just the source directory.
    $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
    try {
        $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.Contains('\')) { throw "Ruta interna invalida: $($entry.FullName)" }
            if (-not $names.Add($entry.FullName)) { throw "Ruta duplicada: $($entry.FullName)" }
        }
        foreach ($needed in @(
            'shaders/shaders.properties',
            'shaders/program/deferred1.fsh',
            'shaders/lib/auroraviva/celestial/atmosphere.glsl',
            'shaders/global/atmosphere/sky.glsl'
        )) {
            if (-not $names.Contains($needed)) { throw "Falta dentro del ZIP: $needed" }
        }
        $entryShader = $zip.GetEntry('shaders/program/deferred1.fsh')
        if ($null -eq $entryShader) { throw 'No se pudo abrir deferred1.fsh del ZIP.' }
        $stream = $entryShader.Open()
        try {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try { $insideHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
        } finally { $stream.Dispose() }
        if ($insideHash -ne $expected) { throw "SHA256 incorrecto dentro del ZIP: $insideHash" }
        Write-Host "Validacion correcta: $($zip.Entries.Count) entradas y SHA256 original del shader." -ForegroundColor Green
    } finally { $zip.Dispose() }

    Move-Item -LiteralPath $tempZip -Destination $outputZip -ErrorAction Stop
    Write-Host "ZIP NUEVO: $outputZip" -ForegroundColor Green
    if ($InstallToModrinth) {
        Copy-Item -LiteralPath $outputZip -Destination $profileShaderpacks -ErrorAction Stop
        Write-Host "COPIADO A MODRINTH: $(Join-Path $profileShaderpacks (Split-Path $outputZip -Leaf))" -ForegroundColor Green
    }
} finally {
    if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
