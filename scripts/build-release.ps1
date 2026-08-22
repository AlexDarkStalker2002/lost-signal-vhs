param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+\.zip$')]
    [string]$OutputName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'Lost_Signal_VHS'
$outputPath = Join-Path $repoRoot $OutputName

if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Shader-pack source directory was not found: $sourceRoot"
}

# OutputName is deliberately restricted to a plain filename. This keeps the
# replacement target inside the repository and makes rebuilding deterministic.
if ([System.IO.Path]::GetFileName($outputPath) -ne $OutputName) {
    throw 'OutputName must not contain a directory path.'
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$files = @(
    Get-ChildItem -LiteralPath $sourceRoot -File -Recurse |
        Sort-Object FullName
)
$directories = @(
    Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse |
        Sort-Object FullName
)

if ($files.Count -eq 0) {
    throw "No release files were found under $sourceRoot"
}

if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

$fileStream = [System.IO.File]::Open(
    $outputPath,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None
)

try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $fileStream,
        [System.IO.Compression.ZipArchiveMode]::Create,
        $false
    )

    try {
        foreach ($directory in $directories) {
            $relativePath = [System.IO.Path]::GetRelativePath(
                $sourceRoot,
                $directory.FullName
            ).Replace('\', '/') + '/'

            $entry = $archive.CreateEntry($relativePath)
            $entry.LastWriteTime = $directory.LastWriteTime
        }

        foreach ($file in $files) {
            # ZIP entry names always use '/', even when this script runs on
            # Windows. Iris treats entries containing '\\' as ordinary file
            # names and therefore cannot discover the required shaders/ root.
            $relativePath = [System.IO.Path]::GetRelativePath(
                $sourceRoot,
                $file.FullName
            ).Replace('\', '/')

            $entry = $archive.CreateEntry(
                $relativePath,
                [System.IO.Compression.CompressionLevel]::Optimal
            )
            $entry.LastWriteTime = $file.LastWriteTime

            $inputStream = [System.IO.File]::OpenRead($file.FullName)
            $entryStream = $entry.Open()
            try {
                $inputStream.CopyTo($entryStream)
            }
            finally {
                $entryStream.Dispose()
                $inputStream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $fileStream.Dispose()
}

$requiredEntries = @(
    'README.md',
    'LICENSE.txt',
    'shaders/',
    'shaders/shaders.properties',
    'shaders/composite.vsh',
    'shaders/composite.fsh',
    'shaders/composite1.vsh',
    'shaders/composite1.fsh',
    'shaders/final.vsh',
    'shaders/final.fsh',
    'shaders/gbuffers_basic.vsh',
    'shaders/gbuffers_basic.fsh',
    'shaders/gbuffers_textured.vsh',
    'shaders/gbuffers_textured.fsh',
    'shaders/gbuffers_textured_lit.vsh',
    'shaders/gbuffers_textured_lit.fsh',
    'shaders/lang/en_us.lang',
    'shaders/lang/ru_ru.lang',
    'shaders/lib/settings.glsl',
    'shaders/lib/analog_color.glsl'
)

$checkArchive = [System.IO.Compression.ZipFile]::OpenRead($outputPath)
try {
    $entryNames = @($checkArchive.Entries | ForEach-Object FullName)

    $backslashEntries = @($entryNames | Where-Object { $_.Contains('\') })
    if ($backslashEntries.Count -gt 0) {
        throw "ZIP contains invalid Windows separators: $($backslashEntries -join ', ')"
    }

    $unsafeEntries = @(
        $entryNames | Where-Object {
            $_.StartsWith('/') -or $_.Contains('../') -or $_.Contains('/../')
        }
    )
    if ($unsafeEntries.Count -gt 0) {
        throw "ZIP contains unsafe paths: $($unsafeEntries -join ', ')"
    }

    $missingEntries = @(
        $requiredEntries | Where-Object { $_ -notin $entryNames }
    )
    if ($missingEntries.Count -gt 0) {
        throw "ZIP is missing required shader-pack entries: $($missingEntries -join ', ')"
    }

    $expectedEntryCount = $files.Count + $directories.Count
    if ($entryNames.Count -ne $expectedEntryCount) {
        throw "ZIP entry count $($entryNames.Count) does not match expected entry count $expectedEntryCount."
    }
}
finally {
    $checkArchive.Dispose()
}

$hash = Get-FileHash -LiteralPath $outputPath -Algorithm SHA256
[pscustomobject]@{
    Path = $outputPath
    Files = $files.Count
    Directories = $directories.Count
    Bytes = (Get-Item -LiteralPath $outputPath).Length
    SHA256 = $hash.Hash
}
