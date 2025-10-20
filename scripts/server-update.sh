#!/bin/bash

# ==========================================
# 🚀 Server Update Script
# Автоматическое обновление Ubuntu Server
# ==========================================

set -e  # Выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции логирования
log_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
}

# Заголовок
print_header() {
    echo " "
    echo "=========================================="
    echo "🚀 $1"
    echo "=========================================="
    echo " "
}

# ==========================================
# ОСНОВНАЯ ЛОГИКА ОБНОВЛЕНИЯ
# ==========================================

main() {
    print_header "STARTING SERVER UPDATE PROCESS"
    
    log_info "Tag: ${TAG_NAME:-Not specified}"
    log_info "Start time: $(date)"
    log_info "Server: $(hostname)"
    log_info "User: $(whoami)"

    # 1. Обновление списка пакетов
    print_header "STEP 1: UPDATING PACKAGE LISTS"
    log_info "Running: sudo apt update"
    
    if sudo apt update; then
        log_success "Package lists updated successfully"
    else
        log_error "Failed to update package lists"
        exit 1
    fi

    # 2. Проверка доступных обновлений
    print_header "STEP 2: CHECKING AVAILABLE UPGRADES"
    log_info "Available upgrades:"
    
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ "$UPGRADABLE" -gt 1 ]; then
        log_info "Found $((UPGRADABLE-1)) packages to upgrade"
        sudo apt list --upgradable
    else
        log_success "No packages available for upgrade"
    fi

    # 3. Выполнение обновления
    print_header "STEP 3: PERFORMING SYSTEM UPGRADE"
    log_info "Running: sudo apt upgrade -y"
    
    if sudo apt upgrade -y; then
        log_success "System upgrade completed successfully"
    else
        log_warning "Upgrade completed with warnings"
    fi

    # 4. Очистка системы
    print_header "STEP 4: CLEANING UP SYSTEM"
    log_info "Removing unnecessary packages..."
    
    sudo apt autoremove -y
    sudo apt autoclean
    log_success "System cleanup completed"

    # 5. Проверка необходимости перезагрузки
    print_header "STEP 5: CHECKING REBOOT REQUIREMENT"
    
    if [ -f /var/run/reboot-required ]; then
        log_warning "SYSTEM REBOOT IS REQUIRED"
        
        if [ -f /var/run/reboot-required.pkgs ]; then
            log_info "Packages requiring reboot:"
            cat /var/run/reboot-required.pkgs
        fi
        
        # ЗАКОММЕНТИРОВАННАЯ перезагрузка
        log_warning "AUTO-REBOOT IS DISABLED FOR SAFETY"
        log_info "To enable reboot, uncomment the reboot section in this script"
        
        # === РАЗКОММЕНТИРУЙТЕ ДЛЯ АВТОМАТИЧЕСКОЙ ПЕРЕЗАГРУЗКИ ===
        # log_warning "Server will reboot in 60 seconds..."
        # sleep 60
        # log_info "Rebooting now..."
        # sudo reboot
        # =========================================================
        
    else
        log_success "No reboot required - all updates applied successfully"
    fi

    # Финальный отчет
    print_header "UPDATE PROCESS COMPLETED"
    log_success "Server update finished successfully"
    log_info "Finish time: $(date)"
    log_info "Kernel version: $(uname -r)"
    log_info "Uptime: $(uptime -p)"
}

# ==========================================
# ОБРАБОТКА АРГУМЕНТОВ
# ==========================================

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            TAG_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -t, --tag TAG_NAME    Set the deployment tag name"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Запуск основной функции
main "$@"