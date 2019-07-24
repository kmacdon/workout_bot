# workout_bot
A telegram bot implemented in R for tracking workouts

## Usage 

I store my workouts in my phone notes using the format:

\<Name of workout day\> \<Date\>
  
\<Exercise\>

\<Weight\> \<Rep\>
  
This program allows me to send my workouts to a Telegram bot which then parses them into a data frame and saves it as a csv. Using the command `/report` will generate a html file and send it to me displaying charts for my various exercises over the previous month while the command `/last <workout_day>` will send me the workout information from the last time I did the specified day of workouts.
