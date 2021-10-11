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
ecc_counter_db <- DBI::dbConnect(drv = RSQLite::SQLite(), dbname =  ecc_counter_db_file)


# Function reads in data from across folders and writes to table.
# Table distinguished by the leading prefix of filename, which must be supplied.
# prefix  =   pvr or bin
# ecc_counter_db = ecc_counter_db defined above
write_cycle_count_db <- function(prefix, ecc_counter_db){
  
  # Gets all the sub-dir names containing csv files which start with bin_.
  list_of_dirs<-
    dir("data/", full.names = TRUE, recursive = TRUE) %>%
    str_subset(".csv") %>%
    str_subset(paste0(prefix,"_")) 

# separates out some identifying information on each counter station from filenames and paths
counters <- tibble(path = dir("data/", recursive = TRUE) %>%
                     str_subset(".csv") %>%
                     str_subset(paste0(prefix,"_"))) %>% 
  separate(col = path, into = c("station_name","filename"), sep = "/", remove = FALSE) %>% 
  separate(col= station_name, c("station_num","station_name"), sep = "\\s", extra = "merge")
  
# Carry out some checks of counters
counters %>% count(station_name) 


# Deal with the bin files first
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
    dbWriteTable(ecc_counter_db, paste0("station_counts_hour_",prefix), df, overwrite = TRUE)
    first_run = FALSE
  }
  else {
    dbWriteTable(ecc_counter_db, paste0("station_counts_hour_",prefix), df, append = TRUE)
  }  
  
  rm(df)
  
  
}

}

write_cycle_count_db("bin",  ecc_counter_db)
write_cycle_count_db("pvr",  ecc_counter_db)


dbDisconnect(ecc_counter_db)

# Merging the two datasets

# Load the data

con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "data/ecc-counter-database-output.sqlite")

df_bin <- tbl(con, "station_counts_hour_bin") %>% collect()

df_pvr <- tbl(con, "station_counts_hour_pvr") %>% collect()

dbDisconnect(con)


df_bin <- df_bin %>% group_by(date, direction_description)
df_pvr <- df_pvr %>% group_by(date, direction_description)



