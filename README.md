# Garuda Mokka Migration

This repository provides a script to migrate an existing Garuda Linux installation from the Dr460nized edition to the Mokka (Catppuccin) edition. It automates most steps, including package installation, theme configuration, and various fixes, while prompting the user for manual actions where necessary.

## Files

- **migrate-to-mokka.sh**: Main Bash script that performs the migration.
- **README.md**: This file, containing instructions and details.

## Usage

1. **Clone or Download the Repository**
   ```bash
   git clone <repository_url>
   cd garuda-mokka-migration
   ```

2. **Make the Script Executable**
   ```bash
   chmod +x migrate-to-mokka.sh
   ```

3. **Run the Script**
   ```bash
   ./migrate-to-mokka.sh
   ```

   The script will guide you through the process step by step. It includes:
   - Safe removal of `garuda-dr460nized` (if installed)
   - System update (`sudo pacman -Syu`)
   - Installation of `garuda-mokka` and `firedragon-catppuccin`
   - Manual prompts for applying Global Theme, Kvantum, Fonts, GTK theme, and window effects
   - Automatic configuration for SDDM, Fastfetch (rustfetch alias), bat syntax theme, and Konsole profile
   - Optional installation of gaming meta-packages
   - Final reboot prompt

## Prerequisites

- Garuda Linux (Dr460nized or any other edition)
- `sudo` privileges
- `yay` (for AUR package installation) if KWin blur/rounded-corners effects are not in the official repos

## Notes

- The script checks for the existence of configuration files in `/etc/skel/` and only copies them if present.
- Manual steps are clearly indicated. You must open System Settings and apply themes or effects as instructed.
- No automatic reboot will occur until you confirm at the end.

## Troubleshooting

- If a required file (e.g., a Kvantum config or Fastfetch config) is missing, the script will skip that step with a warning.
- Make sure you have an active internet connection for package installations.
- If you encounter errors related to missing packages (e.g., `kwin-effects-forceblur`), ensure `yay` is installed, or adjust the script to use a different AUR helper.

## License

MIT License
