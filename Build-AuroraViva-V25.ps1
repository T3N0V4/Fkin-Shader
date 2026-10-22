# Aurora Viva V25 Fase 1 - exportacion compatible con Iris
# Conserva los modulos en el repositorio; expande sus includes SOLO en el ZIP publicado.
param(
    [string]$RepoPath = 'C:\Proyectos\Fkin-Shader',
    [string]$OutputZip = ''
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$root = (Resolve-Path -LiteralPath $RepoPath -ErrorAction Stop).Path
if ([string]::IsNullOrWhiteSpace($OutputZip)) { $OutputZip = Join-Path $root 'AuroraViva_V25_Iris_Fix.zip' }
if (-not [System.IO.Path]::IsPathRooted($OutputZip)) { $OutputZip = Join-Path $root $OutputZip }
$stage = Join-Path $env:TEMP 'AuroraViva_V25_Iris_Build'
$srcShader = Join-Path $root 'shaders'
$srcProgram = Join-Path $srcShader 'program\deferred1.fsh'
if (-not (Test-Path -LiteralPath $srcProgram -PathType Leaf)) { throw "Falta: $srcProgram" }
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -LiteralPath $srcShader -Destination $stage -Recurse -Force
$stageProgram = Join-Path $stage 'shaders\program\deferred1.fsh'
$content = [System.IO.File]::ReadAllText($srcProgram, $utf8).Replace("`r`n", "`n")
foreach ($mod in @('core', 'planets', 'blackhole', 'renderer')) {
    $relative = "/lib/auroraviva/celestial/$mod.glsl"
    $marker = '#include "' + $relative + '"' + "`n"
    $modulePath = Join-Path $srcShader ("lib\auroraviva\celestial\$mod.glsl")
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) { throw "Falta modulo: $modulePath" }
    $source = [System.IO.File]::ReadAllText($modulePath, $utf8).Replace("`r`n", "`n")
    if (-not $source.StartsWith('// Aurora Viva V25 Celestial Foundation')) { throw "Cabecera de modulo inesperada: $mod" }
    $eol = $source.IndexOf("`n")
    if ($eol -lt 0) { throw "Modulo sin contenido: $mod" }
    $source = $source.Substring($eol + 1)
    if (-not $content.Contains($marker)) { throw "Include no encontrado: $marker" }
    $content = $content.Replace($marker, $source)
}
if ($content.Contains('#include "/lib/auroraviva/celestial/')) { throw 'Quedaron includes celestes sin expandir.' }
[System.IO.File]::WriteAllText($stageProgram, $content, $utf8)
# Fase 1: debe recuperar byte por byte el deferred1.fsh de V24.1.
$expected = 'f56a5ab5a5e21221321ef5a09fa90822ccbe8a2887b387c77b04968ef99f5c70'
$hash = (Get-FileHash -LiteralPath $stageProgram -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hash -ne $expected) {
    throw "El shader expandido difiere del baseline V24.1. SHA256 actual: $hash (esperado: $expected). No se crea ZIP."
}
foreach ($extra in @('LICENSE', 'LICENSE-APACHE', 'README_AURORA_VIVA.txt')) {
    $item = Join-Path $root $extra
    if (Test-Path -LiteralPath $item -PathType Leaf) { Copy-Item -LiteralPath $item -Destination $stage -Force }
}
# Empaquetado .NET: preserva el arbol del shader sin ambiguedades de Compress-Archive.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipDir = Split-Path -Parent $OutputZip
if (-not (Test-Path -LiteralPath $zipDir -PathType Container)) {
    New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
}
# Generar ZIP en archivo temporal. Nunca reemplazar el ultimo ZIP bueno si falla.
$tempZip = Join-Path $zipDir ('AuroraViva_build_' + [guid]::NewGuid().ToString('N') + '.zip')
try {
    $zipStream = [System.IO.File]::Open($tempZip, [System.IO.FileMode]::CreateNew)
    try {
        $archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($file in (Get-ChildItem -LiteralPath $stage -Recurse -File)) {
                $relativePath = $file.FullName.Substring($stage.Length).TrimStart('\', '/')
                # IMPORTANTE: ZIP requiere '/' incluso en Windows PowerShell 5.1.
                $entryName = $relativePath.Replace('\', '/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $archive, $file.FullName, $entryName,
                    [System.IO.Compression.CompressionLevel]::Optimal
                ) | Out-Null
            }
        } finally { $archive.Dispose() }
    } finally { $zipStream.Dispose() }

    # Verificar rutas REALES del ZIP (sin normalizarlas previamente).
    $zip = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
    try {
        $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.Contains('\')) { throw "Ruta invalida con barra invertida: $($entry.FullName)" }
            [void]$names.Add($entry.FullName)
        }
        foreach ($needed in @('shaders/shaders.properties', 'shaders/program/deferred1.fsh')) {
            if (-not $names.Contains($needed)) { throw "El ZIP no contiene $needed en la raiz correcta" }
        }
        $entryShader = $zip.GetEntry('shaders/program/deferred1.fsh')
        if ($null -eq $entryShader) { throw 'No se pudo abrir deferred1.fsh del ZIP' }
        $stream = $entryShader.Open()
        try {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try { $insideHash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
            finally { $sha.Dispose() }
        } finally { $stream.Dispose() }
        if ($insideHash -ne $expected) { throw "SHA256 incorrecto dentro del ZIP: $insideHash" }
        Write-Host "Validacion OK: $($zip.Entries.Count) entradas; rutas con '/', shader SHA256 correcto." -ForegroundColor Green
    } finally { $zip.Dispose() }

    if (Test-Path -LiteralPath $OutputZip) { Remove-Item -LiteralPath $OutputZip -Force }
    Move-Item -LiteralPath $tempZip -Destination $OutputZip
} finally {
    if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }
}
Write-Host "ZIP creado y validado: $OutputZip" -ForegroundColor Green
Write-Host "deferred1.fsh identico al V24.1 - SHA256 $hash" -ForegroundColor Green
Write-Host 'El repositorio conserva los cuatro modulos; solo el ZIP contiene codigo expandido.'
