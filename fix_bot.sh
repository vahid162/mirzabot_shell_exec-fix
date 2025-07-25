#!/bin/bash

# --- Automatic Security Fix Script for Telegram Bot (v3 - Final) ---

# --- Configuration ---
HELPER_SCRIPT_PATH="/usr/local/bin/cron_helper.sh"
SUDOERS_FILE="/etc/sudoers.d/99-bot-helper"

# --- Functions ---
print_info() { echo "INFO: $1"; }
print_success() { echo "SUCCESS: $1"; }
print_error() { echo "ERROR: $1" >&2; exit 1; }

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
    print_success "Helper script created."
}

set_permissions() {
    print_info "Setting permissions for helper script..."
    chown root:root "${HELPER_SCRIPT_PATH}"
    chmod 750 "${HELPER_SCRIPT_PATH}"
    print_success "Permissions set correctly."
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

patch_php_files() {
    local bot_dir=$1
    local admin_file="${bot_dir}/admin.php"; local index_file="${bot_dir}/index.php"
    print_info "Starting to patch files in ${bot_dir}..."
    if [[ ! -f "$admin_file" || ! -f "$index_file" ]]; then
        print_error "Could not find admin.php or index.php in the current directory."
    fi
    
    # Create backups first, in case of failure
    cp "$index_file" "$index_file.bak"
    cp "$admin_file" "$admin_file.bak"

    # Patch index.php & admin.php
    perl -i -0777 -pe 's{if \(function_exists\x28\x27shell_exec\x27\)\s*&&\s*is_callable\x28\x27shell_exec\x27\)\)\s*\{.*?shell_exec\(\$command\);\s*\}\s*\}}{if (function_exists(\x27shell_exec\x27) \&\& is_callable(\x27shell_exec\x27)) {\n        \$phpFilePath = "https:\/\/{\$domainhosts}\/cron\/sendmessage.php";\n        \$cronCommand = "*\/1 * * * * curl {\$phpFilePath}";\n        shell_exec("sudo /usr/local/bin/cron_helper.sh add " . escapeshellarg(\$cronCommand));\n    }}sg' "$index_file" || print_error "Failed to patch index.php"
    
    perl -i -0777 -pe 's{if\s*\(\s*!\(function_exists\(\x27shell_exec\x27\)\s*\&\&\s*is_callable\(\x27shell_exec\x27\)\)\)\s*\{.*?sendmessage.*?;\s*\}}{}sg' "$admin_file" || print_error "Failed to patch admin.php (initial check)"
    
    perl -i -0777 -pe 's{if\s*\(\$text\s*==\s*\$textbotlang\[\x27Admin\x27\]\[\x27keyboardadmin\x27\]\[\x27settingscron\x27\]\)\s*\{.*?return;\s*\}\s*sendmessage\(\$from_id,\s*\$textbotlang\[\x27users\x27\]\[\x27selectoption\x27\],\s*\$keyboardcronjob,\s*\x27HTML\x27\);\s*\}}{if (\$text == \$textbotlang[\x27Admin\x27][\x27keyboardadmin\x27][\x27settingscron\x27]) {\n        sendmessage(\$from_id, \$textbotlang[\x27users\x27][\x27selectoption\x27], \$keyboardcronjob, \x27HTML\x27);\n    }}sg' "$admin_file" || print_error "Failed to patch admin.php (menu check)"
    
    for cron_type in test volume time remove; do
        perl -i -0777 -pe 's{(\$text\s*==\s*\$textbotlang\[\x27Admin\x27\]\[\x27cron\x27\]\[\x27'"$cron_type"'\x27\]\[\x27active\x27\])\s*\{.*?shell_exec\(\$command\);}{sprintf("%s) { shell_exec(\"sudo /usr/local/bin/cron_helper.sh add \" . escapeshellarg(\$cronCommand));", $1)}esg' "$admin_file" || print_error "Failed to patch admin.php (add $cron_type)"
        perl -i -0777 -pe 's{(\$text\s*==\s*\$textbotlang\[\x27Admin\x27\]\[\x27cron\x27\]\[\x27'"$cron_type"'\x27\]\[\x27disable\x27\])\s*\{.*?(\$jobToRemove\s*=\s*.*?);.*?shell_exec\(\x27crontab\s*\/tmp\/crontab\.txt\x27\);.*?unlink.*?;\s*\}}{sprintf("%s) { %s; shell_exec(\"sudo /usr/local/bin/cron_helper.sh remove \" . escapeshellarg(\$jobToRemove)); }", $1, $2)}esg' "$admin_file" || print_error "Failed to patch admin.php (disable $cron_type)"
    done
    
    print_success "PHP files patched successfully."
}

# --- Main Logic ---
if [ "$(id -u)" -ne 0 ]; then print_error "This script must be run with sudo. Example: curl ... | sudo bash"; fi
BOT_DIRECTORY=$(pwd)
print_info "Operating in directory: ${BOT_DIRECTORY}"
if [ ! -f "${HELPER_SCRIPT_PATH}" ]; then create_helper_script; set_permissions; else
    print_info "Helper script already exists. Skipping creation."
fi
if [ ! -f "${SUDOERS_FILE}" ]; then configure_sudo; else
    print_info "Sudoers file already exists. Skipping creation."
fi
patch_php_files "$BOT_DIRECTORY"
echo
print_success "Script finished for directory: ${BOT_DIRECTORY}"
print_success "Backup files (.bak) have been created."
echo
print_info "FINAL MANUAL STEP: Go to your aapanel, select your PHP version,"
print_info "go to 'Disable functions', and add 'shell_exec' to the list to finalize the security."
