## ---------------------------
##
## Script name:
##
## Purpose of script: Create a tidy dataset from raw counter data
##
## Author: Diarmuid Lloyd
##
## Date Created: 2021-08-03
##
## Email: diarmuid.lloyd@gmail.com
##
## ---------------------------
##
## Notes:
##
## Builds database holding all ECC data in one place.
## 
## ---------------------------


## Packages
library(tidyverse)
library(dbplyr)
library(DBI)

# Create SQLite database in which we'll store our data
ecc_counter_db_file <- "data/ecc-counter-database-output.sqlite"
ecc_counter_db <- DBI::dbConnect(drv = RSQLite::SQLite(),dbname =  ecc_counter_db_file)

# Gets all the sub-dir names containing csv files which start with bin_.
list_of_dirs <-
  dir("data/", full.names = TRUE, recursive = TRUE) %>%
  str_subset(".csv") %>%
  str_subset("bin_") 

# separates out some identifying information on each counter station from filenames and paths
counters <- tibble(path = dir("data/", recursive = TRUE) %>%
                     str_subset(".csv") %>%
                     str_subset("bin_")) %>% 
  separate(col = path, into = c("station_name","filename"), sep = "/", remove = FALSE) %>% 
  separate(col= station_name, c("station_num","station_name"), sep = "\\s", extra = "merge")
  
# Carry out some checks of counters
counters %>% count(station_name) 



#do as a loop, as purrr resulting in memory issues
first_run <- TRUE
for (i in 1:length(list_of_dirs)) {
 print(list_of_dirs[i])
  #files don't have constant header and fields, so don't read colnames
  df <- read.table(list_of_dirs[i],sep=",", fill = TRUE, header = FALSE) 
  
  #Now assign colnames, and delete first row which held the names
  colnames(df) = df[1,]
  df <- df[-1,]
  
  # Choose the fields of interest.
  df <- df %>%
    select(
      date = Sdate,
      direction_description = DirectionDescription,
      volume = Volume,
      flag = Flags,
      flag_text = `Flag Text`
    ) %>%
    type_convert(col_types = cols(date=col_datetime())) %>% 
    mutate(#path = counters$path[i],
           station_num = counters$station_num[i],
           station_name = counters$station_name[i],
           filename = counters$filename[i])
  
  if (first_run == TRUE) {
    dbWriteTable(ecc_counter_db, "station_counts_hour", df, overwrite = TRUE)
    first_run = FALSE
  }
  else {
    dbWriteTable(ecc_counter_db, "station_counts_hour", df, append = TRUE)
  }  
  
  rm(df)
}

# Disconnect
dbDisconnect(ecc_counter_db)



