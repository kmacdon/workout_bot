# Workout bot API token
token <- keyring::key_get("telegram", "workout_tracker")
source("functions.R")

# Create filter for workouts
MessageFilters$workout <- BaseFilter(filter = filter_workout)

# Connect to bot and add handler
updater <- Updater(token = token)
updater <- updater + MessageHandler(get_workout, MessageFilters$workout)


updater <- updater + CommandHandler("kill", kill)

updater <- updater + CommandHandler("report", send_report)

updater <- updater + CommandHandler("last", last, pass_args = TRUE)
# Start watching
updater$start_polling()

