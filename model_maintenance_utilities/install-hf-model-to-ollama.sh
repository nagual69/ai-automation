#!/usr/bin/env bash
set -euo pipefail

MODEL_NAME="llama-xlam-2-8b-fc-r"
GGUF_FILE="Llama-xLAM-2-8B-fc-r-Q4_K_M.gguf"
HF_REPO="your-hf-username-or-org/your-model-repo"   # <-- update this
OLLAMA_DIR="$HOME/.ollama/models"

# Create model directory
mkdir -p "$OLLAMA_DIR/$MODEL_NAME"

# Download from Hugging Face
echo "Downloading $GGUF_FILE from Hugging Face..."
curl -L "https://huggingface.co/$HF_REPO/resolve/main/$GGUF_FILE" \
  -o "$OLLAMA_DIR/$MODEL_NAME/$GGUF_FILE"

# Create Modelfile
cat > "$OLLAMA_DIR/$MODEL_NAME/Modelfile" <<EOF
FROM ./$GGUF_FILE
TEMPLATE """{{ .Prompt }}"""
EOF

# Register model with Ollama
echo "Registering model with Ollama..."
ollama create "$MODEL_NAME" -f "$OLLAMA_DIR/$MODEL_NAME/Modelfile"

echo "Done. Run it with:"
echo "  ollama run $MODEL_NAME"