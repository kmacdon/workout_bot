library(stringr)
library(lubridate)
library(telegram.bot)
library(magrittr)
library(dplyr)

# Checks to see if the message is for workout data
filter_workout <- function(message){
  header <- unlist(str_split(message$text, " "))[1]
  header %in% c("Chest", "Legs", "Back")
}

# Convert message into data frame of exercises and save
get_workout <- function(bot, update){
  text <- unlist(str_split(update$message$text, "\n"))

  # First line contains date and workout label
  header <- text[1]
  day <- unlist(str_split(header, " "))[1]

  # Assumes year is current
  date <- unlist(str_split(header, " "))[-1]
  date <- lubridate::mdy(paste(date[1], date[2], lubridate::year(Sys.Date()), sep ="/"))

  # New lines separate workouts
  text <- text[-c(1, 2)]

  workouts <- list()

  cuts <- c(0, which(text == ""), length(text) + 1)

  # Split text into list of workouts
  for(i in 1:(length(cuts) - 1)){
    workouts[[i]] <- text[(cuts[i] + 1):(cuts[i + 1] - 1)]
  }

  # Each element in workouts is now vector of name and reps
  # This converts the lists to one data frame
  convert <- function(x){
    x <- str_trim(x)
    name <- str_remove_all(str_to_lower(x[1]), " ")

    # Check that name is valid
    full_names <-
      readr::read_csv("workout_names.csv") %>%
      filter(Workout == day) %>%
      .$Exercise

    comparisons <-
      full_names %>%
      str_to_lower() %>%
      str_remove_all(" ")

    where <- which(name == comparisons)

    # Condition if no matches
    if(length(where) == 0){
      # Suggest closest name
      possible <- full_names[which.min(stringdist::stringdist(name, comparisons))]
      msg <- paste0(" Did not recognize \'", x[1], "\'. Correcting to ", possible)
      bot$sendMessage(chat_id = update$message$chat_id,
                      text = msg)
      name <- possible
    } else {
      name <- full_names[where]
    }

    x <- unlist(str_split(x[-1], " "))
    weight <- x[c(T, F)]
    reps <- x[c(F, T)]
    n <- max(length(reps), length(weight))

    # Check for forgotten numbers, usually the last rep
    if(length(weight) != length(reps)){
      reps = rep(reps[1], length(weight))
    }

    data.frame(Date = as.character(rep(date, n)),
               Day = rep(day, n),
               Workout = rep(name, n),
               Reps = as.numeric(reps),
               Weight = as.numeric(weight)
    )
  }

  # Create Data Frame, use append = TRUE for real
  workouts <- purrr::map_dfr(workouts, convert)
  readr::write_csv(workouts, path = "workouts.csv", append = TRUE)


  # Send confirmation
  bot$sendMessage(chat_id = update$message$chat_id,
                  text = "Got it")

  # Clean message update
  bot$getUpdates(offset = update$update_id + 1L)
  #bot$stop_polling()
}


# Add kill command
kill <- function(bot, update){
  bot$sendMessage(chat_id = update$message$chat_id,
                  text = "Dead")

  # Clean 'kill' update
  bot$getUpdates(offset = update$update_id + 1L)

  # Stop the updater polling
  updater$stop_polling()
}


# Function that will send Rmarkdown report as pdf

send_report <- function(bot, update){
  bot$sendMessage(chat_id = update$message$chat_id,
                  text = "Generating Report")
  bot$sendChatAction(chat_id = update$message$chat_id,
                     "typing")
  rmarkdown::render("report.Rmd")
  bot$sendDocument(chat_id = update$message$chat_id,
                   "./report.html")
  bot$getUpdates(offset = update$update_id + 1L)
}

# Send last workout for the specified day

last <- function(bot, update, args){
  if (length(args > 0)){
    workout <- args[1]
    data <- readr::read_csv("workouts.csv") %>%
      filter(tolower(Day) == tolower(workout)) %>%
      filter(Date == max(Date)) %>%
      select(Workout, Weight, Reps)

    if (nrow(data) == 0){
      bot$sendMessage(chat_id = update$message$chat_id,
                      text = "Did not recognize that day")
      # Clean 'last' update
      bot$getUpdates(offset = update$update_id + 1L)
      return()
    }

    msg <- NULL
    last <- ""
    for (i in 1:nrow(data)){
      # Formatting as
      # <Name>
      # <weight> <rep>

      if(last != data[i, 1]){
        msg <- paste(msg, paste0("\n", data[i, 1]), sep = "\n")
        last <- data[i, 1]
      }

      msg <- paste(msg, paste(data[i, 2], data[i, 3]), sep = "\n")
    }

    bot$sendMessage(chat_id = update$message$chat_id,
                    text = msg)
  }

  # Clean 'last' update
  bot$getUpdates(offset = update$update_id + 1L)
}
