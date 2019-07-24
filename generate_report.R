library(gmailr)
use_secret_file('gmailr.json')
rmarkdown::render('report.Rmd')

email <-
  mime(
    To = 'kevinmacdonald4@gmail.com',
    From = 'kevinmacdonald4@gmail.com'
  ) %>%
  subject(paste0("Report for ", format(Sys.time(), '%d %B, %Y'))) %>%
  attach_file("report.pdf")

send_message(email)
