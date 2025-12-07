#!/bin/bash

# Конфигурация
LOG_FILE=""
ERROR_LOG_FILE=""
OUTPUT_TO_FILE=false
ERRORS_TO_FILE=false

# Функция вывода справки
show_help() {
    cat << EOF
Использование: $0 [ПАРАМЕТР]...

Параметры:
    -u, --users              Вывести список пользователей и их домашние директории
    -p, --processes          Вывести список процессов, отсортированных по PID
    -l, --log PATH           Перенаправить вывод в файл PATH
    -e, --errors PATH        Перенаправить ошибки (stderr) в файл PATH
    -h, --help               Показать эту справку

Пример:
    $0 --users --log /tmp/output.txt
    $0 -p -e /tmp/errors.log
EOF
    exit 0
}

# Функция проверки доступности пути
check_path() {
    local path="$1"
    local type="$2"  # "log" или "error"

    if [[ -z "$path" ]]; then
        echo "Ошибка: путь для $type не указан." >&2
        exit 1
    fi

    local dir=$(dirname "$path")
    if [[ ! -d "$dir" ]]; then
        echo "Ошибка: директория $dir не существует." >&2
        exit 1
    fi

    if [[ ! -w "$dir" ]]; then
        echo "Ошибка: нет прав на запись в $dir." >&2
        exit 1
    fi
}

# Функция вывода пользователей
show_users() {
    local output=$(getent passwd | cut -d: -f1,6 | sort)
    if [[ "$OUTPUT_TO_FILE" == true && -n "$LOG_FILE" ]]; then
        echo "$output" > "$LOG_FILE"
    else
        echo "$output"
    fi
}

# Функция вывода процессов
show_processes() {
    local output=$(ps -e --sort=pid -o pid,comm)
    if [[ "$OUTPUT_TO_FILE" == true && -n "$LOG_FILE" ]]; then
        echo "$output" > "$LOG_FILE"
    else
        echo "$output"
    fi
}

# Функция перенаправления вывода
setup_output() {
    if [[ "$OUTPUT_TO_FILE" == true && -n "$LOG_FILE" ]]; then
        exec > >(tee -a "$LOG_FILE")
    fi
}

# Функция перенаправления ошибок
setup_errors() {
    if [[ "$ERRORS_TO_FILE" == true && -n "$ERROR_LOG_FILE" ]]; then
        exec 2> >(tee -a "$ERROR_LOG_FILE")
    fi
}

# Основная функция обработки аргументов
main() {
    # Если нет аргументов, выводим справку
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    # Парсинг аргументов с помощью getopt
    OPTS=$(getopt -o u,p,l:,e:,h --long users,processes,log:,errors:,help -n "$0" -- "$@")
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -u|--users)
                show_users
                shift
                ;;
            -p|--processes)
                show_processes
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                OUTPUT_TO_FILE=true
                check_path "$LOG_FILE" "log"
                shift 2
                ;;
            -e|--errors)
                ERROR_LOG_FILE="$2"
                ERRORS_TO_FILE=true
                check_path "$ERROR_LOG_FILE" "error"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Неизвестный аргумент: $1" >&2
                exit 1
                ;;
        esac
    done

    # Настройка перенаправлений
    setup_output
    setup_errors
}

# Запуск основной функции
main "$@"
