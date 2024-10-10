#!/bin/bash

if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

# Check if WEBHOOK_URL is set
if [ -z "$WEBHOOK_URL" ]; then
    echo "WEBHOOK_URL is not set in the .env file!"
    exit 1
fi

send_discord_notification() {
    local notification_type="$1"
    local notification_title="$2"
    local notification_message="$3"

    local color
    case "$notification_type" in
        startup) color=3447003 ;;      # Blue
        download) color=3066993 ;;     # Green
        pp) color=10181046 ;;          # Purple
        complete) color=3066993 ;;     # Green
        failed) color=15158332 ;;      # Red
        warning) color=15105570 ;;     # Orange
        error) color=15158332 ;;       # Red
        disk_full) color=15158332 ;;   # Red
        queue_done) color=3066993 ;;   # Green
        new_login) color=3447003 ;;    # Blue
        other) color=9807270 ;;        # Gray
        *) color=9807270 ;;            # Default to gray
    esac

    local mention=""
    if [[ "$notification_type" == "error" || "$notification_type" == "failed" || "$notification_type" == "warning" || "$notification_type" == "disk_full" ]]; then
        mention="@everyone"
    fi

    JSON=$(jq -n \
    --arg mention "$mention" \
    --arg title "$notification_title" \
    --arg description "$notification_message" \
    --argjson color "$color" \
    '{
      content: $mention,
      embeds: [
        {
          title: $title,
          description: $description,
          color: $color,
          author: {
            name: "📁 SABnzbd"
          }
        }
      ],
      "username": "SABnzbd",
      "attachments": []
    }')

    curl -H "Content-Type: application/json" \
         -X POST \
         -d "$JSON" \
         "$WEBHOOK_URL"
}

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <notification_type> <notification_title> <notification_message>"
    exit 1
fi

notification_type="$1"
notification_title="$2"
notification_message="$3"

send_discord_notification "$notification_type" "$notification_title" "$notification_message"

exit 0
