# Color variables
COLOR_GREY=240
COLOR_BLUE=4
COLOR_RED=red
COLOR_GREEN=green
COLOR_MAGENTA=magenta

# Variables to store command timing information
LAST_COMMAND_START_TIME=""
LAST_COMMAND_END_TIME=""
LAST_COMMAND_DURATION=""

# Function to generate the prompt
generate_prompt() {
    # Elements
    local username="%n"
    local hostname="${CUSTOM_HOSTNAME:-"%m"}"
    local user_host="%F{$COLOR_GREY}$username@$hostname%f"
    local current_dir="%F{$COLOR_MAGENTA}%~%f"
    local security_color=$(get_security_color)
    local git_info="$(git_info)"
    local timestamp_info=""
    if [[ -n "$LAST_COMMAND_DURATION" && "$LAST_COMMAND_DURATION" != "0s" ]]; then 
        timestamp_info="%F{$COLOR_GREY}prev cmd: ${LAST_COMMAND_START_TIME_FORMATTED} (${LAST_COMMAND_DURATION}) ${LAST_COMMAND_START_TIME} - ${LAST_COMMAND_END_TIME}%f"
    fi
    local security_indicator="$(security_indicator $security_color)"
    local prompt_symbol="%F{$security_color}❯%f"

    # Construct the prompt
    PROMPT="$security_indicator $user_host $current_dir$git_info $timestamp_info"$'\n'"$prompt_symbol "
}

# Function to get the security color
get_security_color() {
    if [[ "$IS_SAFE_MACHINE" = true ]]; then
        echo $COLOR_GREEN
    else
        echo $COLOR_RED
    fi
}

# Function to display git information
git_info() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
        echo " %F{$COLOR_MAGENTA}$branch%f%F{$COLOR_GREY}*%f"
    fi
}

# Function to display security indicator
security_indicator() {
    local color=$1
    echo "%F{$color}●%f"  # Circle indicator (green for safe, red for unsafe)
}

# Function to format duration
format_duration() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    seconds=$((seconds % 60))
    minutes=$((minutes % 60))

    if (( hours > 0 )); then
        printf "%dh%dm%ds" $hours $minutes $seconds
    elif (( minutes > 0 )); then
        printf "%dm%ds" $minutes $seconds
    else
        printf "%ds" $seconds
    fi
}

# Precmd function to update the prompt
precmd() {
    LAST_COMMAND_END_TIME=$(date +%s)
    LAST_COMMAND_END_TIME_FORMATTED="$(date -u '+%H:%M:%S')" # Capture formatted end time

    if [[ -n $LAST_COMMAND_START_TIME ]]; then
        local duration=$((LAST_COMMAND_END_TIME - LAST_COMMAND_START_TIME))
        LAST_COMMAND_DURATION=$(format_duration $duration)
    else
        LAST_COMMAND_DURATION="0s"
    fi
    generate_prompt
}


# Preexec function to capture the start time of each command
preexec() {
    LAST_COMMAND_START_TIME=$(date +%s)
    LAST_COMMAND_START_TIME_FORMATTED="$(date -u '+%H:%M:%S')"
}

# Initial prompt setup
LAST_COMMAND_START_TIME_FORMATTED="$(date -u '+%H:%M:%S')"
LAST_COMMAND_DURATION="0s"
generate_prompt
