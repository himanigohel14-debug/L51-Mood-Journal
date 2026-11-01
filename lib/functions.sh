#!/bin/bash
# lib/functions.sh – all functions for Mood Journal
DATA="data/journal"

LOG="logs/activity.log"

# write one line to the activity log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOG"
}

# check the data file / folder exists before using it
check_data() {
    if [ ! -e "$DATA" ]; then
        echo "Data not found: $DATA"
        return 1
    fi
}

show_help() {
    echo "Usage: ./main.sh            -> open the menu"
    echo "       ./main.sh --help     -> show this help"
    echo "       ./main.sh --backup   -> backup data/ now"
    echo "       ./main.sh --cron     -> run the scheduled (crontab) task"
}

view_data() {
    if [ ! -d "$DATA" ]; then
        echo "Journal data not found."
        return 1
    fi

    for file in "$DATA"/*.txt; do
        [ -f "$file" ] || continue
        echo
        echo "========== $(basename "$file") =========="
        cat -n "$file"
    done

    log "All journal data viewed"
}

do_backup() {
    f="backups/data_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$f" data/
    echo "Backup saved: $f ($(du -h "$f" | cut -f1))"
    log "backup created $f"
}

view_log() {
    if [ -f "$LOG" ]; then tail -n 15 "$LOG"; else echo "No activity yet."; fi
}

# ------------------------------------------------------------
# FEATURE 1: Write today's entry with mood 1–5
# Commands you can use: date, awk, grep, wc, ls
# ------------------------------------------------------------
# FEATURE 1: Write today's entry with mood 1–5
feature_1() {
    echo "== Write today's entry with mood 1–5 =="

    today=$(date '+%Y-%m-%d')
    mkdir -p data/journal
    file="data/journal/${today}.txt"

    while true; do
        read -p "Enter your mood (1-5): " mood

        if [[ "$mood" =~ ^[1-5]$ ]]; then
            break
        else
            echo "Invalid mood! Please enter a number from 1 to 5."
        fi
    done

    read -p "Write your journal entry: " entry

    {
        echo "Date: $today"
        echo "Mood: $mood"
        echo "Entry: $entry"
        echo "------------------------------"
    } >> "$file"

    echo "Your journal entry has been saved successfully!"
    log "Mood entry saved for $today with mood $mood"
}

# ------------------------------------------------------------
# FEATURE 2: Weekly mood average
# Commands you can use: date, awk, grep, wc, ls
# ------------------------------------------------------------
feature_2() {
    echo "== Weekly mood average =="

    total=0
    count=0
    today=$(date +%F)

    for file in data/journal/*.txt; do
        [ -f "$file" ] || continue

        filename=$(basename "$file" .txt)
        entry_date=$(date -d "$filename" +%F 2>/dev/null) || continue

        days_ago=$(( ($(date -d "$today" +%s) - $(date -d "$entry_date" +%s)) / 86400 ))

        if [ "$days_ago" -ge 0 ] && [ "$days_ago" -lt 7 ]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^Mood:\ ([1-5])$ ]]; then
                    mood="${BASH_REMATCH[1]}"
                    total=$((total + mood))
                    count=$((count + 1))
                fi
            done < "$file"
        fi
    done

    if [ "$count" -gt 0 ]; then
        average=$(awk -v total="$total" -v count="$count" \
            'BEGIN { printf "%.2f", total/count }')
        echo "Entries found: $count"
        echo "Average mood: $average / 5"
    else
        echo "No mood entries found in the last 7 days."
    fi

    log "feature_2 used"
}  

# ------------------------------------------------------------
# FEATURE 3: Best and worst days
# Commands you can use: date, awk, grep, wc, ls
# ------------------------------------------------------------
# FEATURE 3: Best and worst days
feature_3() {
    echo "== Best and worst days =="

    best=0
    worst=6
    found=0

    for file in data/journal/*.txt; do
        [ -f "$file" ] || continue

        filename=$(basename "$file" .txt)
        entry_date=$(date -d "$filename" +%F 2>/dev/null) || continue

        today=$(date +%F)
        days_ago=$(( ($(date -d "$today" +%s) - $(date -d "$entry_date" +%s)) / 86400 ))

        if [ "$days_ago" -ge 0 ] && [ "$days_ago" -lt 7 ]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^Mood:\ ([1-5])$ ]]; then
                    mood="${BASH_REMATCH[1]}"
                    found=1

                    if [ "$mood" -ge "$best" ]; then
                        best="$mood"
                        best_file="$filename"
                    fi

                    if [ "$mood" -lt "$worst" ]; then
                        worst="$mood"
                        worst_file="$filename"
                    fi
                fi
            done < "$file"
        fi
    done

    if [ "$found" -eq 1 ]; then
        echo "Best mood: $best/5 on $best_file"
        echo "Worst mood: $worst/5 on $worst_file"
    else
        echo "No mood entries found in the last 7 days."
    fi

    log "feature_3 used"
}

# ------------------------------------------------------------
# FEATURE 4: Search entries by word
# Commands you can use: date, awk, grep, wc, ls
# ------------------------------------------------------------
# FEATURE 4: Search entries by word
feature_4() {
    echo "== Search entries by word =="

    read -r -p "Enter word to search: " word

    if [ -z "$word" ]; then
        echo "Please enter a word to search."
        log "Feature 4: Empty search"
        return
    fi

    found=0

    for file in data/journal/*.txt; do
        [ -f "$file" ] || continue

        if grep -inF -- "$word" "$file"; then
            echo "File: $(basename "$file")"
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "No matching entries found."
    fi

    log "Feature 4 search: $word"
}
    

# ------------------------------------------------------------
# FEATURE 5: Word count per entry
# Commands you can use: date, awk, grep, wc, ls
# ------------------------------------------------------------
# FEATURE 5: Word count per entry
feature_5() {
    echo "== Word count per entry =="

    found=0

    for file in data/journal/*.txt; do
        [ -f "$file" ] || continue

        echo
        echo "Date: $(basename "$file" .txt)"

        while IFS= read -r line; do
            if [[ "$line" == "Entry: "* ]]; then
                entry="${line#Entry: }"
                words=$(printf '%s\n' "$entry" | wc -w)

                echo "Entry: $entry"
                echo "Word count: $words"

                found=1
            fi
        done < "$file"
    done

    if [ "$found" -eq 0 ]; then
        echo "No journal entries found."
    fi

    log "feature_5 used"
}

   

# ------------------------------------------------------------
# CRON TASK: Every day at 9 PM, append a 'write your journal' reminder; every Sunday write the mood report
# Runs when crontab calls:  ./main.sh --cron
# ------------------------------------------------------------
cron_task() {
    today=$(date +%F)
    day=$(date +%u)

    mkdir -p reports

    if [ "$day" -eq 7 ]; then
        report="reports/weekly_mood_report_$today.txt"

        {
            echo "Weekly Mood Report"
            echo "Generated on: $today"
            echo "-------------------------"

            total=0
            count=0

            for file in data/journal/*.txt; do
                [ -f "$file" ] || continue

                filename=$(basename "$file" .txt)
                entry_date=$(date -d "$filename" +%F 2>/dev/null) || continue

                days_ago=$(( ($(date -d "$today" +%s) - $(date -d "$entry_date" +%s)) / 86400 ))

                if [ "$days_ago" -ge 0 ] && [ "$days_ago" -lt 7 ]; then
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^Mood:\ ([1-5])$ ]]; then
                            mood="${BASH_REMATCH[1]}"
                            total=$((total + mood))
                            count=$((count + 1))
                        fi
                    done < "$file"
                fi
            done

            if [ "$count" -gt 0 ]; then
                awk -v total="$total" -v count="$count" \
                    'BEGIN { printf "Entries: %d\nAverage mood: %.2f/5\n", count, total/count }'
            else
                echo "No mood entries found."
            fi
        } > "$report"

        echo "Weekly report created: $report"
    else
        echo "$today: Reminder - Write your daily mood journal." >> reports/cron_output.txt
        echo "Daily journal reminder saved."
    fi

    log "Cron task ran on $today"
}
