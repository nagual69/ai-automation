# Requires: PowerShell 7+
# Purpose: Download a GGUF model from Hugging Face and register it with Ollama

$ModelName = "llama-xlam-2-8b-fc-r"
$GgufFile  = "Llama-xLAM-2-8B-fc-r-Q4_K_M.gguf"
$HfRepo    = "Salesforce/Llama-xLAM-2-8b-fc-r-gguf"   # <-- update this
$OllamaDir = "$env:USERPROFILE\.ollama\models\$ModelName"

# Create model directory
if (-not (Test-Path $OllamaDir)) {
    New-Item -ItemType Directory -Path $OllamaDir | Out-Null
}

# Download model from Hugging Face
$Url = "https://huggingface.co/$HfRepo/resolve/main/$GgufFile"
$Dest = Join-Path $OllamaDir $GgufFile

Write-Host "Downloading $GgufFile..."
Invoke-WebRequest -Uri $Url -OutFile $Dest

# Create Modelfile
$ModelfilePath = Join-Path $OllamaDir "Modelfile"
@"
FROM ./$GgufFile
TEMPLATE """{{ .Prompt }}"""
"@ | Set-Content -Path $ModelfilePath -Encoding UTF8

# Register model with Ollama
Write-Host "Registering model with Ollama..."
ollama create $ModelName -f $ModelfilePath

Write-Host "`nDone. Run it with:"
Write-Host "  ollama run $ModelName"