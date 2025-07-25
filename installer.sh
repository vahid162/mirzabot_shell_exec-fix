#!/bin/bash

# --- Secure Bot Installer Script (v5 - Download Method) ---
# This script downloads pre-patched files from a GitHub repo and sets up the server.

# ┌─┐┬─┐┌─┐┌─┐┌─┐┌┬┐┌─┐┬─┐
# │ ┬├┬┘├┤ │  │ ││││├┤ ├┬┘
# └─┘┴└─└─┘└─┘└─┘┴ ┴└─┘┴└─
# PLEASE EDIT THE TWO LINES BELOW WITH YOUR GITHUB RAW URLs
# ----------------------------------------------------------------
FIXED_INDEX_URL="https://raw.githubusercontent.com/vahid162/mirzabot_shell_exec-fix/refs/heads/main/index.php"
FIXED_ADMIN_URL="https://raw.githubusercontent.com/vahid162/mirzabot_shell_exec-fix/refs/heads/main/admin.php"
# ----------------------------------------------------------------


# --- Script Internals ---
HELPER_SCRIPT_PATH="/usr/local/bin/cron_helper.sh"
SUDOERS_FILE="/etc/sudoers.d/99-bot-helper"

print_info() { echo "✅ INFO: $1"; }
print_success() { echo "🚀 SUCCESS: $1"; }
print_error() { echo "❌ ERROR: $1" >&2; exit 1; }

# ... (Helper functions remain the same as previous versions) ...
create_helper_script() {
    print_info "Creating helper script at ${HELPER_SCRIPT_PATH}..."
    cat <<'EOF' | tee "${HELPER_SCRIPT_PATH}" > /dev/null
#!/bin/bash
set -e
ACTION=$1
JOB_COMMAND="${@:2}"
if [[ "$ACTION" == "add" && ! "$JOB_COMMAND" =~ ^(\*\/[0-9]+|\*)\s+\*\s+\*\s+\*\s+\*\s+curl\s+https:\/\/.*$ ]]; then
    echo "Error: Invalid or insecure cron job command provided." >&2; exit 1;
fi
case "$ACTION" in
    add) (crontab -l 2>/dev/null | grep -vF -- "$JOB_COMMAND" ; echo "$JOB_COMMAND") | crontab - ;;
    remove) (crontab -l 2>/dev/null | grep -vF -- "$JOB_COMMAND") | crontab - ;;
    list) crontab -l ;;
    *) echo "Error: Invalid action." >&2; exit 1 ;;
esac
exit 0
EOF
    chown root:root "${HELPER_SCRIPT_PATH}"
    chmod 750 "${HELPER_SCRIPT_PATH}"
    print_success "Helper script created and permissions set."
}

configure_sudo() {
    print_info "Configuring sudoers rule..."
    WEB_USER="www-data"
    if ! id -u "$WEB_USER" >/dev/null 2>&1; then
        if id -u "apache" >/dev/null 2>&1; then WEB_USER="apache"; else
            print_error "Could not determine web server user (www-data or apache)."
        fi
    fi
    echo "${WEB_USER} ALL=(root) NOPASSWD: ${HELPER_SCRIPT_PATH}" | tee "${SUDOERS_FILE}" > /dev/null
    chmod 440 "${SUDOERS_FILE}"
    print_success "Sudoers rule created for user '${WEB_USER}'."
}

download_and_replace_files() {
    local bot_dir=$1
    print_info "Downloading and replacing files in ${bot_dir}..."

    # Backup original files
    cp "${bot_dir}/index.php" "${bot_dir}/index.php.bak.$(date +%s)"
    cp "${bot_dir}/admin.php" "${bot_dir}/admin.php.bak.$(date +%s)"
    print_info "Backup of original files created."

    # Download and replace
    curl -sSL -o "${bot_dir}/index.php" "$FIXED_INDEX_URL" || print_error "Failed to download index.php"
    curl -sSL -o "${bot_dir}/admin.php" "$FIXED_ADMIN_URL" || print_error "Failed to download admin.php"

    print_success "index.php and admin.php have been replaced with the secure versions."
}

# --- Main Logic ---
set -e 
if [ "$(id -u)" -ne 0 ]; then print_error "This script must be run with sudo."; fi

# URL Check
if [[ "$FIXED_INDEX_URL" == *"YOUR_USERNAME"* || "$FIXED_ADMIN_URL" == *"YOUR_USERNAME"* ]]; then
    print_error "You must edit the installer.sh script and replace the placeholder URLs with your actual GitHub Raw URLs."
fi

BOT_DIRECTORY=$(pwd)
print_info "Operating in directory: ${BOT_DIRECTORY}"

if [ ! -f "${HELPER_SCRIPT_PATH}" ]; then create_helper_script; else
    print_info "Helper script already exists."
fi

if [ ! -f "${SUDOERS_FILE}" ]; then configure_sudo; else
    print_info "Sudoers rule already exists."
fi

download_and_replace_files "$BOT_DIRECTORY"

echo
print_success "Script finished successfully for ${BOT_DIRECTORY}!"
echo
print_info "FINAL STEP: Go to aapanel and disable the 'shell_exec' function in PHP settings."
