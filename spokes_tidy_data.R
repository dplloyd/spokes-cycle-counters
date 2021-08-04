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
##
## ---------------------------


## Packages
library(tidyverse)
library(dbplyr)
library(janitor)
library(DBI)

# Create SQLite database in which we'll store our data
ecc_counter_db_file <- "data/ecc-counter-database-output.sqlite"
ecc_counter_db <- DBI::dbConnect(drv = RSQLite::SQLite(),dbname =  ecc_counter_db_file)

# Gets all the sub-dir names containing csv files which start with bin_.
list_of_dirs <-
  dir("data/", full.names = TRUE, recursive = TRUE) %>%
  str_subset(".csv") %>%
  str_subset("bin_") %>% 
  as.list()

# separates out some identifying information on each counter station from filenames and paths
counters <- tibble(path = dir("data/", recursive = TRUE) %>%
                     str_subset(".csv") %>%
                     str_subset("bin_")) %>% 
  separate(col = path, into = c("station_name","filename"), sep = "/", remove = FALSE) %>% 
  separate(col= station_name, c("station_num","station_name"), sep = "\\s", extra = "merge")
  
# Carry out some checks of counters
counters %>% count(station_name) 


# Function for reading the columns of (probable) interest and use.
add_to_db <- function(path) {
  df <- read_csv(
    path,
    col_types = cols(
      `Flag Text` = col_character(),
      `LaneDescription` = col_character(),
      `#Bins` = col_skip(),
      Bins = col_skip()
    )
  )
}

all_data <- map_df(list_of_dirs[1:100],
            read_csv,
            col_types = cols(`Flag Text` = col_character(),
                             `LaneDescription` = col_character(),
                             `#Bins` = col_skip(),
                              Bins = col_skip() ))

all_data <- all_data %>% mutate(DirectionDescription = as_factor(DirectionDescription))

all_data %>% count(DirectionDescription)





