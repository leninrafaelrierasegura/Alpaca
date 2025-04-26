today_stock_data <- read_csv(here("data/nasdaq_screener_24-04-2025.csv")) |>
  filter(nchar(symbol)<5) |> # filter out stocks with more than 4 characters (not tradeable)
  filter(!grepl("\\^", symbol)) |> # remove symbols containing ^
  select(-url, -netchange, -pctchange) |> # remove unnecessary columns
  mutate(lastsale = as.numeric(gsub("[$,]", "", lastsale))) |># remove $ and , from lastsale and make it numeric
  select(symbol, date, lastsale, everything()) # reorder columns

# Remove symbols that are not longer being traded
cummulative_stock_data <- readRDS(here("data/cummulative_stock_data.RDS")) |>
  filter(symbol %in% today_stock_data$symbol)

# The following two instructions deals with new_data being added when it is already there.
# This might happen when the stock market is closed during weekdays
clean_cummulative_stock_data <- bind_rows(cummulative_stock_data, today_stock_data) |>
  distinct() |> # remove duplicates
  arrange(symbol, date) |>
  select(symbol, date, lastsale, marketCap, country, industry, sector, ipoyear, volume, name)

# Get unique dates from the dataset
unique_dates <- sort(unique(clean_cummulative_stock_data$date))

# Step 1: Expand each symbol to all existing dates
stock_data_expanded <- clean_cummulative_stock_data %>%
  group_by(symbol) %>%
  complete(date = unique_dates) %>%
  ungroup()

# Step 2: Fill backward for multiple columns
columns_to_fill <- c(
  "lastsale", "marketCap", "country", "industry", 
  "sector", "ipoyear", "volume", "name"
)

stock_data_filled <- stock_data_expanded %>%
  group_by(symbol) %>%
  arrange(date, .by_group = TRUE) %>%
  mutate(across(all_of(columns_to_fill),
                ~ zoo::na.locf(.x, fromLast = TRUE, na.rm = FALSE))) %>%
  ungroup() %>%
  arrange(symbol, date)

# saveRDS(stock_data_filled, here("data/cummulative_stock_data.RDS"))
