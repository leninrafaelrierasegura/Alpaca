# 
# # This chunk of code was used to format the historic data from 2025-04-02 to 2025-04-22 and append it to 
# # the cummulative_stock_data.RDS file.
# ##################################################################################################
# library(readr)
# library(dplyr)
# library(zoo) # to use na.locf
# library(tidyr) # to use pivot_wider
# library(here)
# 
# cummulative_stock_data <- readRDS(here::here("data/cummulative_stock_data.RDS"))
# 
# initial_date <- as.Date("2025-04-02")
# final_date <- as.Date("2025-04-22")
# 
# stock_data_order <- readRDS(here::here("data/stocks_data.RDS")) |>
#   select(symbol, date, close, volume) |>
#   rename(lastsale = close) |>
#   arrange(symbol, date) |>
#   filter(date >= initial_date & date <= final_date) |>
#   filter(nchar(symbol)<5) |> # filter out stocks with more than 4 characters (not tradeable)
#   filter(!grepl("\\^", symbol))  # remove symbols containing ^
# 
# clean_cummulative_stock_data <- bind_rows(cummulative_stock_data, stock_data_order) |>
#   arrange(symbol, date) 
# 
# # Get unique dates from the dataset
# unique_dates <- sort(unique(clean_cummulative_stock_data$date))
# 
# # Step 1: Expand each symbol to all existing dates
# stock_data_expanded <- clean_cummulative_stock_data |>
#   group_by(symbol) |>
#   complete(date = unique_dates) |>
#   ungroup()
# 
# # Step 2: Fill backward for multiple columns
# columns_to_fill <- c(
#   "lastsale", "marketCap", "country", "industry", 
#   "sector", "ipoyear", "volume", "name"
# )
# 
# stock_data_filled <- stock_data_expanded |>
#   group_by(symbol) |>
#   arrange(date, .by_group = TRUE) |>
#   mutate(across(all_of(columns_to_fill),
#                 ~ zoo::na.locf(.x, fromLast = TRUE, na.rm = FALSE))) |> # filling from the last available value backward
#   mutate(across(all_of(columns_to_fill),
#                 ~ zoo::na.locf(.x, fromLast = FALSE, na.rm = FALSE))) |> # filling from the first available value forward
#   ungroup() |>
#   arrange(symbol, date)
# 
# stock_data_to_save <- stock_data_filled |>
#   group_by(symbol) |>
#   arrange(date, .by_group = TRUE) |>
#   filter(!any(is.na(lastsale))) |>
#   ungroup() |>
#   arrange(symbol, date)
# 
# saveRDS(stock_data_to_save, here("data/cummulative_stock_data.RDS"))
# #############################################################################################

# # This chunk of code was used to download historic data from 2025-04-02 to 2025-04-28
################################################################################################
# initial_date <- as.Date("2025-04-02")
# final_date <- Sys.Date()
# stock_data_symbols <- readr::read_csv(here::here("data/nasdaq_screener_2025-04-23.csv")) |>
#   dplyr::pull(symbol)
# 
# stocks_data <- tidyquant::tq_get(stock_data_symbols, from = initial_date, to = final_date)
# saveRDS(stocks_data, here::here("data/stocks_data.RDS"))
################################################################################################