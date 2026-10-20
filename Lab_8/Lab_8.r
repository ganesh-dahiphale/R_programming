# Install required packages if not already installed
options(repos = c(CRAN = "https://cloud.r-project.org"))


install.packages(c("data.table", "ggplot2", "foreach", "doParallel", "microbenchmark", "purrr", "lubridate", "arrow"))

install.packages(c("ggplot2", "foreach", "doParallel", "microbenchmark", "purrr"))


library(data.table)
library(lubridate)
library(arrow) # Required to read modern TLC parquet files
library(ggplot2)
library(purrr)
library(foreach)
library(doParallel)
library(microbenchmark)

# 1. Load Data
# Note: TLC data is in Parquet format. arrow::read_parquet is highly efficient.
cat("Loading datasets...\n")
df <- read_parquet("C:\\Users\\YASH\\Desktop\\Yash\\R_programming\\R_Programming_1\\Lab_8\\yellow_tripdata_2026-01.parquet")
dt <- as.data.table(df)
zones <- fread("C:\\Users\\YASH\\Desktop\\Yash\\R_programming\\R_Programming_1\\Lab_8\\taxi_zone_lookup.csv")

# 2. Inspect Structure
str(dt)
summary(dt)

# 3. Data Cleaning & Preparation
# Remove missing/invalid coordinates or zero-passenger trips
dt <- dt[!is.na(tpep_pickup_datetime) & passenger_count > 0 & total_amount > 0]

# Extract temporal attributes
dt[, pickup_hour := hour(tpep_pickup_datetime)]
dt[, pickup_day := day(tpep_pickup_datetime)]
dt[, pickup_wday := wday(tpep_pickup_datetime, label = TRUE)]
dt[, pickup_month := month(tpep_pickup_datetime, label = TRUE)]

# Remove heavy, unnecessary attributes to save memory
set(dt, j = c("store_and_fwd_flag", "extra", "mta_tax"), value = NULL)

# 4. Join with Zone Lookup Table (Pickup & Drop-off)
dt <- merge(dt, zones, by.x = "PULocationID", by.y = "LocationID", all.x = TRUE)
setnames(dt, c("Borough", "Zone", "service_zone"), c("PU_Borough", "PU_Zone", "PU_service_zone"))

dt <- merge(dt, zones, by.x = "DOLocationID", by.y = "LocationID", all.x = TRUE)
setnames(dt, c("Borough", "Zone", "service_zone"), c("DO_Borough", "DO_Zone", "DO_service_zone"))

# 5. Transportation Analytics
# A. Trips by hour
trips_by_hour <- dt[, .(Total_Trips = .N), by = pickup_hour]
setorder(trips_by_hour, pickup_hour)

# B. Trips by day of week
trips_by_day <- dt[, .(Total_Trips = .N), by = pickup_wday]
setorder(trips_by_day, pickup_wday)

# C. Most frequently travelled routes
top_routes <- dt[, .(Trips = .N), by = .(PU_Zone, DO_Zone)]
setorder(top_routes, -Trips)
top_routes <- head(top_routes, 10)

# D. Highest revenue routes
revenue_routes <- dt[, .(Total_Revenue = sum(total_amount, na.rm = TRUE)), by = .(PU_Zone, DO_Zone)]
setorder(revenue_routes, -Total_Revenue)
revenue_routes <- head(revenue_routes, 10)


# Create a sample to make benchmarking run in a reasonable time
dt_sample <- dt[sample(.N, 500000)]
split_data <- split(dt_sample$fare_amount, dt_sample$pickup_hour)

# Task 5: Execute microbenchmark
# We use eval(parse()) for data.table to completely bypass RStudio's static parser
benchmark_methods <- microbenchmark(
  Base_tapply = tapply(dt_sample$fare_amount, dt_sample$pickup_hour, mean, na.rm = TRUE),
  Purrr_map = map_dbl(split_data, mean, na.rm = TRUE),
  DataTable = eval(parse(text = "dt_sample[, .(mean_fare = mean(fare_amount, na.rm = TRUE)), by = pickup_hour]")),
  times = 10
)

print(benchmark_methods)
autoplot(benchmark_methods) + theme_minimal() + labs(title="Execution Time: Functional vs data.table")

# Task 4: Parallel Computing

# Get unique days
days <- unique(dt$pickup_day)
days <- days[!is.na(days)]

# A. Sequential Processing
cat("Running Sequential Processing...\n")
start_seq <- Sys.time()
seq_results <- lapply(days, function(d) {
  subset_dt <- subset(dt, pickup_day == d) 
  data.frame(
    Day = d,
    Avg_Amount = mean(subset_dt$total_amount, na.rm = TRUE),
    Max_Amount = max(subset_dt$total_amount, na.rm = TRUE)
  )
})
seq_results <- do.call(rbind, seq_results)
end_seq <- Sys.time()
time_seq <- as.numeric(difftime(end_seq, start_seq, units = "secs"))

# B. Parallel Processing using foreach and doParallel
cat("Running Parallel Processing...\n")
cores_to_use <- detectCores() - 1
cl <- makeCluster(cores_to_use)
registerDoParallel(cl)

start_par <- Sys.time()
par_results <- foreach(d = days, .combine = rbind, .packages = "data.table") %dopar% {
  subset_dt <- subset(dt, pickup_day == d)
  data.frame(
    Day = d,
    Avg_Amount = mean(subset_dt$total_amount, na.rm = TRUE),
    Max_Amount = max(subset_dt$total_amount, na.rm = TRUE)
  )
}
end_par <- Sys.time()
time_par <- as.numeric(difftime(end_par, start_par, units = "secs"))

stopCluster(cl)

# C. Calculate Speedup
speedup <- time_seq / time_par
cat(sprintf("Sequential Time: %.2f seconds\n", time_seq))
cat(sprintf("Parallel Time: %.2f seconds\n", time_par))
cat(sprintf("Parallel Speedup: %.2fx\n", speedup))



# 1. Number of trips by hour
ggplot(trips_by_hour, aes(x = pickup_hour, y = Total_Trips)) +
  geom_line(color = "steelblue", size = 1.2) +
  geom_point(color = "darkred", size = 2) +
  theme_minimal() +
  labs(title = "Total Taxi Trips by Hour of Day",
       x = "Hour of Day (0-23)",
       y = "Total Trips",
       caption = "Peak demand occurs in the evening hours.")

# 2. Taxi demand by day of week
ggplot(trips_by_day, aes(x = pickup_wday, y = Total_Trips, fill = pickup_wday)) +
  geom_bar(stat = "identity", color = "black") +
  theme_minimal() +
  labs(title = "Taxi Demand by Day of the Week",
       x = "Day of Week",
       y = "Total Trips") +
  theme(legend.position = "none")

# 3. Trip Distance vs Fare Amount 
# We sample 10,000 random rows to prevent overplotting and filter extreme outliers
ggplot(dt[sample(.N, 10000)], aes(x = trip_distance, y = fare_amount)) +
  geom_point(alpha = 0.4, color = "forestgreen") +
  theme_minimal() +
  coord_cartesian(xlim = c(0, 25), ylim = c(0, 100)) + 
  labs(title = "Trip Distance vs. Fare Amount",
       x = "Trip Distance (Miles)",
       y = "Fare Amount (USD)",
       caption = "Linear relationship with visible flat-fare airport routes.")