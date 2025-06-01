#!/usr/bin/env bash
# migrate-to-mokka.sh
# Thoroughly reviewed Garuda Mokka migration script.
# No automatic reboots until the very end. Prompts at each critical step.
set -euo pipefail

# Utility: print to stderr
_err() { printf "%s\n" "$*" >&2; }

# Check for Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    _err "Error: This script is for Linux systems only."
    exit 1
fi

echo "=== Garuda Mokka Migration Script ==="
echo "This script will migrate your Garuda system from Dr460nized to Mokka."
echo "Each step is confirmed. No automatic reboots until the end."
echo

############################################
# 1. Remove Dr460nized (if installed)
############################################
if pacman -Qs garuda-dr460nized > /dev/null 2>&1; then
    read -rp "Step 1/16: Remove 'garuda-dr460nized'? [y/N]: " confirm_dragon
    if [[ "$confirm_dragon" =~ ^[Yy]$ ]]; then
        # Use -Rs to remove unneeded dependencies as well
        sudo pacman -Rs --noconfirm garuda-dr460nized           && echo "Removed 'garuda-dr460nized'."           || _err "Warning: Failed to remove 'garuda-dr460nized'."
    else
        echo "Skipping Dr460nized removal."
    fi
else
    echo "Step 1/16: 'garuda-dr460nized' not installed; nothing to remove."
fi

############################################
# 2. System Update
############################################
read -rp "Step 2/16: Run 'sudo pacman -Syu' to update the system? [Y/n]: " confirm_update
if [[ ! "$confirm_update" =~ ^[Nn]$ ]]; then
    echo "Updating system..."
    sudo pacman -Syu --noconfirm       && echo "System updated."       || _err "Warning: System update encountered errors."
else
    echo "Skipping system update."
fi

############################################
# 3. Install Mokka & Firedragon
############################################
read -rp "Step 3/16: Install 'garuda-mokka' and 'firedragon-catppuccin'? [Y/n]: " confirm_install
if [[ ! "$confirm_install" =~ ^[Nn]$ ]]; then
    echo "Installing Mokka components..."
    sudo pacman -S --noconfirm garuda-mokka firedragon-catppuccin       && echo "Installed 'garuda-mokka' and 'firedragon-catppuccin'."       || _err "Warning: Failed to install Mokka or Firedragon."
else
    echo "Skipping Mokka & Firedragon installation."
fi

############################################
# 4. Apply Global Theme (Manual)
############################################
echo
echo "Step 4/16: [Manual] Apply Global Theme → Select 'Mokka' in System Settings."
echo "  1) Open System Settings → Global Theme"
echo "  2) Select 'Mokka' and ensure BOTH Appearance and Layout are checked"
echo "  3) Click 'Apply' and wait for it to finish"
read -rp "Press Enter once you have applied the Global Theme..."

############################################
# 5. Kvantum Theme Setup
############################################
echo
echo "Step 5/16: Kvantum Theme (Automatic + Manual)"
# Copy Mokka Kvantum config if it exists
if [[ -f /etc/skel/.config/Kvantum/Mokka.kvconfig ]]; then
    mkdir -p ~/.config/Kvantum/
    cp /etc/skel/.config/Kvantum/Mokka.kvconfig ~/.config/Kvantum/       && echo "Copied Kvantum 'Mokka.kvconfig' to ~/.config/Kvantum/."       || _err "Warning: Failed to copy Kvantum config."
else
    echo "  Note: '/etc/skel/.config/Kvantum/Mokka.kvconfig' not found; skipping copy."
fi

echo "  [Manual] Launch 'kvantummanager' and select 'Mokka' theme in Kvantum Manager."
read -rp "Press Enter once Kvantum theme is set to 'Mokka'..."

############################################
# 6. Fonts (Manual)
############################################
echo
echo "Step 6/16: [Manual] Set Fonts in System Settings → Fonts"
echo "  • Set 'Font' to 'Inter'"
echo "  • Set 'Fixed Width Font' to 'JetBrainsMono Nerd Font, 12pt, Bold'"
read -rp "Press Enter once the fonts are configured..."

############################################
# 7. Window Effects: Blur & Rounded Corners
############################################
read -rp "Step 7/16: Install blur & rounded corners effects? [Y/n]: " confirm_effects
if [[ ! "$confirm_effects" =~ ^[Nn]$ ]]; then
    echo "Attempting to install KWin blur/rounded-corners AUR packages..."
    # Prefer kwin-effects-forceblur if available; else fallback
    if yay -Qs kwin-effects-forceblur > /dev/null 2>&1; then
        sudo pacman -S --noconfirm kwin-effects-forceblur           && echo "Installed 'kwin-effects-forceblur'."           || _err "Warning: Failed to install 'kwin-effects-forceblur'."
    else
        echo "  'kwin-effects-forceblur' not in repos; installing 'kwin-effects-blur-respect-rounded-decorations-git' from AUR"
        yay -S --noconfirm kwin-effects-blur-respect-rounded-decorations-git           && echo "Installed 'kwin-effects-blur-respect-rounded-decorations-git'."           || _err "Warning: Failed to install 'kwin-effects-blur-respect-rounded-decorations-git'."
    fi

    echo
    echo "  [Manual] Now open System Settings → Window Management → Desktop Effects"
    echo "    • Disable 'Blur' (the default) and enable 'BetterBlur' or 'ForceBlur'"
    echo "    • Click 'Configure' next to 'Rounded Corners'"
    echo "      – Under 'Inclusions & Exclusions', add 'xwaylandvideobridge' (hit 'Refresh' first if needed)"
    echo "      – Under 'Outlines', set Decoration Colors to: '#cba6f7' and '#b4befe'"
    read -rp "Press Enter once you've configured blur & rounded corners..."
else
    echo "Skipping blur & rounded corners installation."
fi

############################################
# 8. Starship Prompt Config
############################################
read -rp "Step 8/16: Copy Starship config for Mokka? [Y/n]: " confirm_starship
if [[ ! "$confirm_starship" =~ ^[Nn]$ ]]; then
    if [[ -f /etc/skel/.config/starship-mokka.toml ]]; then
        mkdir -p ~/.config
        cp /etc/skel/.config/starship-mokka.toml ~/.config/starship.toml           && echo "Starship config copied to ~/.config/starship.toml."           || _err "Warning: Failed to copy Starship config."
    else
        echo "  Note: '/etc/skel/.config/starship-mokka.toml' not found; skipping."
    fi
else
    echo "Skipping Starship config setup."
fi

############################################
# 9. Fastfetch (“rustfetch”) Fix & Config
############################################
read -rp "Step 9/16: Fix Fastfetch alias and apply Mokka config? [Y/n]: " confirm_fastfetch
if [[ ! "$confirm_fastfetch" =~ ^[Nn]$ ]]; then
    echo "Applying Fastfetch / rustfetch fixes..."

    # 9a. Remove old rustfetch alias in Bash
    if grep -qE 'alias rustfetch=' ~/.bashrc 2>/dev/null; then
        sed -i '/alias rustfetch=/d' ~/.bashrc
        echo "  Removed 'rustfetch' alias from ~/.bashrc."
    fi

    # 9b. Remove old rustfetch alias in Fish
    if [[ -f ~/.config/fish/config.fish ]] && grep -qE 'alias rustfetch=' ~/.config/fish/config.fish; then
        sed -i '/alias rustfetch=/d' ~/.config/fish/config.fish
        echo "  Removed 'rustfetch' alias from Fish config."
    fi

    # 9c. Replace /usr/bin/rustfetch symlink if it exists
    if [[ -L /usr/bin/rustfetch ]]; then
        sudo ln -sf /usr/bin/fastfetch /usr/bin/rustfetch           && echo "  Replaced '/usr/bin/rustfetch' symlink to point at 'fastfetch'."
    fi

    # 9d. Copy Mokka Fastfetch config
    if [[ -f /etc/skel/.config/fastfetch/mokka.jsonc ]]; then
        mkdir -p ~/.config/fastfetch
        cp /etc/skel/.config/fastfetch/mokka.jsonc ~/.config/fastfetch/           && echo "  Copied 'mokka.jsonc' to '~/.config/fastfetch/'."
    else
        echo "  Note: '/etc/skel/.config/fastfetch/mokka.jsonc' not found; skipping copy."
    fi

    # 9e. Update Fish or Bash to load Mokka Fastfetch
    if [[ -f ~/.config/fish/config.fish ]] && grep -qE 'fastfetch' ~/.config/fish/config.fish; then
        # Replace any fastfetch invocation to load mokka.jsonc
        sed -i 's#fastfetch.*#fastfetch --load-config ~/.config/fastfetch/mokka.jsonc#' ~/.config/fish/config.fish           && echo "  Updated Fish config to launch Fastfetch with 'mokka.jsonc'."
    fi
    if [[ -f ~/.bashrc ]] && grep -qE 'fastfetch' ~/.bashrc; then
        sed -i 's#fastfetch.*#fastfetch --load-config ~/.config/fastfetch/mokka.jsonc#' ~/.bashrc           && echo "  Updated Bash config to launch Fastfetch with 'mokka.jsonc'."
    fi
else
    echo "Skipping Fastfetch / rustfetch fixes."
fi

############################################
# 10. bat Syntax Theme & Cache
############################################
read -rp "Step 10/16: Copy bat theme and rebuild cache? [Y/n]: " confirm_bat
if [[ ! "$confirm_bat" =~ ^[Nn]$ ]]; then
    # Copy bat config if present
    if [[ -f /etc/skel/.config/bat/config ]]; then
        mkdir -p ~/.config/bat
        cp /etc/skel/.config/bat/config ~/.config/bat/           && echo "  Copied bat config to '~/.config/bat/'."
    else
        echo "  Note: '/etc/skel/.config/bat/config' not found; skipping."
    fi

    # Copy bat theme if present
    if [[ -d /etc/skel/.config/bat/themes ]]; then
        mkdir -p ~/.config/bat/themes
        cp -r /etc/skel/.config/bat/themes/* ~/.config/bat/themes/           && echo "  Copied bat themes to '~/.config/bat/themes/'."
    else
        echo "  Note: '/etc/skel/.config/bat/themes/' not found; skipping."
    fi

    # Rebuild bat cache
    if command -v bat >/dev/null 2>&1; then
        bat cache --build           && echo "  Rebuilt bat cache."           || _err "Warning: 'bat cache' failed."
    fi
else
    echo "Skipping bat theme & cache."
fi

############################################
# 11. Screen Locker Wallpaper
############################################
read -rp "Step 11/16: Copy kscreenlockerrc for Mokka wallpaper? [Y/n]: " confirm_lock
if [[ ! "$confirm_lock" =~ ^[Nn]$ ]]; then
    if [[ -f /etc/skel/.config/kscreenlockerrc ]]; then
        mkdir -p ~/.config
        cp /etc/skel/.config/kscreenlockerrc ~/.config/kscreenlockerrc           && echo "Copied 'kscreenlockerrc' for Mokka screen locker."
    else
        echo "  Note: '/etc/skel/.config/kscreenlockerrc' not found; skipping."
    fi
else
    echo "Skipping screen locker wallpaper."
fi

############################################
# 12. SDDM Theme Auto-Config
############################################
echo
echo "Step 12/16: Configuring SDDM Theme → Setting 'Theme=Mokka' & 'CursorTheme=Catppuccin'."
# Try to find a file in /etc/sddm.conf.d/ containing a [Theme] section
sddm_conf_file=""
for file in /etc/sddm.conf.d/*.conf; do
    if grep -q "^\[Theme\]" "$file"; then
        sddm_conf_file="$file"
        break
    fi
done

if [[ -n "$sddm_conf_file" ]]; then
    echo "  Found existing SDDM config: $sddm_conf_file"
    # Ensure Theme and CursorTheme are set
    sudo sed -i '/^Theme=/d' "$sddm_conf_file"
    sudo sed -i '/^CursorTheme=/d' "$sddm_conf_file"
    sudo sed -i '/^\[Theme\]/a Theme=Mokka
CursorTheme=Catppuccin' "$sddm_conf_file"
    echo "  Updated '$sddm_conf_file' with Mokka theme settings."
else
    echo "  No existing [Theme] block found in /etc/sddm.conf.d/."
    echo "  Creating '/etc/sddm.conf.d/00-mokka.conf'."
    sudo tee /etc/sddm.conf.d/00-mokka.conf > /dev/null <<EOF
[Theme]
Theme=Mokka
CursorTheme=Catppuccin
EOF
    echo "  Created '/etc/sddm.conf.d/00-mokka.conf'."
fi

############################################
# 13. GTK Theme (Manual)
############################################
echo
echo "Step 13/16: [Manual] Apply GTK Theme in System Settings → GNOME Application Style."
echo "  • Select 'Mokka' (Catppuccin GTK theme)."
echo "  • If 'Mokka' doesn’t appear, install via: sudo pacman -S gtk-theme-catppuccin-mocha"
read -rp "Press Enter once GTK theme is applied..."

############################################
# 14. Konsole Profile Setup
############################################
read -rp "Step 14/16: Configure Konsole to use Mokka colorscheme? [Y/n]: " confirm_konsole
if [[ ! "$confirm_konsole" =~ ^[Nn]$ ]]; then
    # If /usr/share/konsole/Mokka.profile exists, copy it; else edit Garuda.profile
    if [[ -f /usr/share/konsole/Mokka.profile ]]; then
        mkdir -p ~/.local/share/konsole
        cp /usr/share/konsole/Mokka.profile ~/.local/share/konsole/Mokka.profile           && echo "  Copied '/usr/share/konsole/Mokka.profile' to '~/.local/share/konsole/'."
        # Also set the default profile in konsolerc
        mkdir -p ~/.config
        {
            echo "[Desktop Entry]"
            echo "DefaultProfile=Mokka.profile"
        } > ~/.config/konsolerc
        echo "  Set DefaultProfile in '~/.config/konsolerc'."
    elif [[ -f ~/.local/share/konsole/Garuda.profile ]]; then
        # Edit existing Garuda.profile
        sed -i 's/^ColorScheme=.*$/ColorScheme=Mokka/' ~/.local/share/konsole/Garuda.profile
        sed -i 's|^Font=.*$|Font=JetBrainsMono Nerd Font,12,-1,5,700,0,0,0,0,0,0,0,0,0,0,1,Bold|' ~/.local/share/konsole/Garuda.profile
        echo "  Edited '~/.local/share/konsole/Garuda.profile' to use Mokka colorscheme & font."
    else
        echo "  Warning: No Konsole profile found to edit or copy. Please set Konsole colorscheme & font manually:"
        echo "    1) In Konsole, go to Settings → Edit Current Profile → Appearance"
        echo "    2) Under 'Color Scheme & Font', load 'Mokka' and set font to 'JetBrainsMono Nerd Font, 12pt, Bold'"
    fi
else
    echo "Skipping Konsole configuration."
fi

############################################
# 15. Optional: Gaming Meta-Packages
############################################
read -rp "Step 15/16: Install gaming meta-packages (garuda-rani-games, garuda-games-meta)? [y/N]: " confirm_games
if [[ "$confirm_games" =~ ^[Yy]$ ]]; then
    sudo pacman -S --noconfirm garuda-rani-games garuda-games-meta       && echo "Installed gaming meta-packages."       || _err "Warning: Failed to install gaming meta-packages."
else
    echo "Skipping gaming meta-packages."
fi

############################################
# 16. Final Reboot Prompt
############################################
echo
echo "✅ All migration steps completed."
read -rp "Would you like to reboot now to apply all changes? [y/N]: " confirm_reboot
if [[ "$confirm_reboot" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "No reboot performed. Remember to reboot manually for all changes to take effect."
fi

echo "=== Migration to Mokka complete. Enjoy your new desktop! ==="
