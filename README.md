# ai-automation
AI Automation Scripts for Windows and Linux

## Model Maintenance Utilities
Located in `model_maintenance_utilities/`

### Ollama Updater (Power Automate)
Tired of not knowing if you have the latest Ollama models running on Windows?
Here's a Power Automate script designed to automatically manage the process.
1. Create a new Power Automate flow called "Ollama Updater".
2. Paste the content of `power-automate-ollama-updates.pa` in.
3. Run! Check `C:\ollama_logs` for log files.

### Node-RED Ollama Model Updater
A Node-RED flow to update Ollama models. Import `NodeRed-Ollama-Model-Updater.json` into your Node-RED instance.

## Docker Utilities
Located in `docker_utilities/`

Scripts to keep Docker Desktop clean by pruning unused resources, identifying active containers, checking for newer image versions, and optionally auto-updating containers.

### Windows (PowerShell)
Run `docker_maintenance.ps1` in PowerShell.
```powershell
.\docker_maintenance.ps1
```

### Linux (Bash)
Run `docker_maintenance.sh` in Bash.
```bash
chmod +x docker_maintenance.sh
./docker_maintenance.sh
```
