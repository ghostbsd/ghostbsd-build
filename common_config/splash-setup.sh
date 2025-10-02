#!/bin/sh

set -e -u

# Shared logo function to reduce duplication
create_logo_function() {
    cat << 'EOF'
show_ghostbsd_logo() {
    cat << 'LOGO_EOF'
╔═══════════════════════════════════╗
║                                   ║
║         G h o s t B S D           ║
║            ──────────             ║
║           Live  System            ║
║                                   ║
╚═══════════════════════════════════╝
LOGO_EOF
}

EOF
}

setup_interactive_splash()
{
  echo "Current working directory: $(pwd)"
  echo "cwd variable: ${cwd}"
  
  # Splash configuration - no bootloader logo modifications
  echo "Console splash system configured (init.sh.in handles early boot splash)"
}

create_extended_boot_script()
{
  echo "Creating extended boot script at ${release}/usr/local/bin/ghostbsd-extended-boot"
  
  cat > "${release}/usr/local/bin/ghostbsd-extended-boot" << 'EOF'
#!/bin/sh
# Extended boot splash - SIMPLIFIED for late boot phase (post init.sh.in)

EOF
  # Add the logo function to the script
  create_logo_function >> "${release}/usr/local/bin/ghostbsd-extended-boot"
  
  cat >> "${release}/usr/local/bin/ghostbsd-extended-boot" << 'EOF'
# Check if we're in a proper terminal environment
if [ ! -t 0 ] || [ ! -t 1 ]; then
    # Not in interactive terminal, skip splash
    exit 0
fi

# Redirect stderr to avoid boot message conflicts
exec 2>/dev/null

SPLASH_DURATION=3

show_boot_phases() {
    _counter=0
    
    while [ $_counter -lt $((SPLASH_DURATION * 10)) ]; do
        # Update display
        if command -v clear >/dev/null 2>&1; then
            clear 2>/dev/null || printf "\033[2J\033[H" 2>/dev/null || true
        else
            printf "\033[2J\033[H" 2>/dev/null || true
        fi
        printf "\033[?25l" 2>/dev/null || true  # Hide cursor
        
        show_ghostbsd_logo
        
        echo ""
        echo " Finalizing Desktop Setup..."
        echo ""
        
        # Progress indicator
        PROGRESS=$(($_counter * 100 / (SPLASH_DURATION * 10)))
        if [ $PROGRESS -gt 100 ]; then
            PROGRESS=100
        fi
        
        printf " ["
        FILLED=$((PROGRESS / 5))
        p=1
        while [ $p -le 20 ]; do
            if [ $p -le $FILLED ]; then
                printf "█"
            else
                printf "░"
            fi
            p=$((p + 1))
        done
        printf "] %d%%\n" $PROGRESS
        echo ""
        
        sleep 0.1
        _counter=$(($_counter + 1))
    done
    
    # Restore terminal
    printf "\033[?25h" 2>/dev/null || true  # Show cursor
}

# Check if verbose boot was requested
if [ -f /tmp/.verbose_boot ]; then
    clear 2>/dev/null || true
    echo "GhostBSD Bootstrap Messages:"
    echo "=================================="
    exit 0
fi

# Run splash
show_boot_phases

# Clean exit
clear 2>/dev/null || true

exit 0
EOF

  chmod +x "${release}/usr/local/bin/ghostbsd-extended-boot"
  echo "Extended boot script created (late-boot phase only)"
}

create_interactive_boot_script()
{
  echo "Creating interactive boot script at ${release}/usr/local/bin/ghostbsd-interactive-boot"
  
  cat > "${release}/usr/local/bin/ghostbsd-interactive-boot" << 'EOF'
#!/bin/sh
# Interactive boot screen - SIMPLIFIED for late boot phase

EOF
  # Add the logo function to the script
  create_logo_function >> "${release}/usr/local/bin/ghostbsd-interactive-boot"
  
  cat >> "${release}/usr/local/bin/ghostbsd-interactive-boot" << 'EOF'
# Check if we're in a proper terminal environment
if [ ! -t 0 ] || [ ! -t 1 ]; then
    # Not in interactive terminal, skip splash
    exit 0
fi

# Redirect stderr to avoid boot message conflicts
exec 2>/dev/null

SPLASH_DURATION=2

show_logo_with_message() {
    _counter=0
    
    while [ $_counter -lt $((SPLASH_DURATION * 10)) ]; do
        # Update display
        if command -v clear >/dev/null 2>&1; then
            clear 2>/dev/null || printf "\033[2J\033[H" 2>/dev/null || true
        else
            printf "\033[2J\033[H" 2>/dev/null || true
        fi
        printf "\033[?25l" 2>/dev/null || true  # Hide cursor
        
        show_ghostbsd_logo
        
        echo ""
        echo " Starting Desktop..."
        echo ""
        
        sleep 0.1
        _counter=$(($_counter + 1))
    done
    
    # Restore terminal
    printf "\033[?25h" 2>/dev/null || true  # Show cursor
}

# Check if verbose boot was requested or skip splash flag
if [ -f /tmp/.verbose_boot ] || [ "${1:-}" = "--no-splash" ]; then
    clear 2>/dev/null || true
    echo "GhostBSD Bootstrap Messages:"
    echo "=================================="
    exit 0
fi

# Run splash
show_logo_with_message

# Clean exit
clear 2>/dev/null || true

exit 0
EOF

  chmod +x "${release}/usr/local/bin/ghostbsd-interactive-boot"
  echo "Interactive boot script created (late-boot phase only)"
}

create_console_logo_script()
{
  echo "Creating console logo script at ${release}/usr/local/bin/ghostbsd-ascii-logo"
  
  cat > "${release}/usr/local/bin/ghostbsd-ascii-logo" << 'EOF'
#!/bin/sh
# Display GhostBSD ASCII logo - SIMPLIFIED

EOF
  # Add the logo function to the script
  create_logo_function >> "${release}/usr/local/bin/ghostbsd-ascii-logo"
  
  cat >> "${release}/usr/local/bin/ghostbsd-ascii-logo" << 'EOF'
# Check if we're in a proper terminal environment
if [ ! -t 1 ]; then
    # Not in interactive terminal, just show simple message
    echo "GhostBSD Loading..."
    sleep 1
    exit 0
fi

# Safe terminal clear
if command -v clear >/dev/null 2>&1; then
    clear 2>/dev/null || printf "\033[2J\033[H" 2>/dev/null || true
else
    printf "\033[2J\033[H" 2>/dev/null || true
fi

show_ghostbsd_logo

echo ""
echo "Starting Desktop..."
echo "Please wait..."

sleep 2
printf "\n"
EOF

  chmod +x "${release}/usr/local/bin/ghostbsd-ascii-logo"
  echo "Console logo script created (simplified)"
}

# NOTE: No boot monitor service since init.sh.in handles early boot splash
create_boot_monitor_service()
{
  echo "Skipping boot monitor service - init.sh.in handles early boot splash"
  
  # Create a minimal service for consistency if needed
  cat > "${release}/usr/local/bin/ghostbsd-service-splash" << 'EOF'
#!/bin/sh
# Minimal service splash placeholder - init.sh.in handles the real work

echo "ghostbsd desktop loading..."
sleep 1
EOF

  chmod +x "${release}/usr/local/bin/ghostbsd-service-splash"
  echo "Created minimal service placeholder"
}
