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


test <- read.csv("data/01 Peffermill Road/bin_2010-01-01_365d.csv")

glimpse(test)

list_of_dirs <-
  dir("data/", full.names = TRUE, recursive = TRUE) %>%
  str_subset(".csv") %>%
  str_subset("bin_") %>% 
  as.list()

read_counter_data <- function(path) {
  df <- read_csv(path) %>%
    select(Sdate,
           LaneDirection,
           Volume,
           flag = Flags,
           flag_text = `Flag Text`)
  
}

test <- map_df(list_of_dirs[1],
            read_csv,
            col_types = cols(`Flag Text` = col_character(),
                             `LaneDescription` = col_character(),
                             `#Bins` = col_ski
                              Bins = col_skip() ))


pathtest <- 'data//52 A8 Wester Coates/pvr_2019-01-01_365d.csv'

read_csv(pathtest,col_types =cols(`Flag Text` = col_character()))
