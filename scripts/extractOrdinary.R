# load packages
packages <-
  c("dplyr",
    "lubridate")

load.packages <- lapply(packages, library, character.only = TRUE)

# read data
data <-
  read.csv("Boston-harmonics.csv")
data <- data[, c(1, 4)]

# group data by date
data <-
  data %>% group_by(Time =  date(Time)) %>% summarise(Surge = max(Surge, na.rm = TRUE))

# make a copy of data
bunch <- data

# get ("ordinary") surge data seperated by 3-day lag
ntr <- c()
timing <- c()

while (max(bunch[["Surge"]], na.rm = TRUE) > 0.0) {
  max.ntr <- max(bunch[["Surge"]], na.rm = TRUE)
  ntr <- append(ntr, max.ntr)
  max.idx <- which.max(bunch[["Surge"]])
  max.time <- bunch[["Time"]][max.idx]
  timing <- append(timing, max.time)
  plus <- max.time + days(3)
  minus <- max.time - days(3)
  idc <- which(bunch[["Time"]] >= minus & bunch[["Time"]] <= plus)
  bunch <- bunch[-idc, ]
}

ntr.data <- data.frame(Time = timing, Surge = ntr)

# save "ordinary" surge data
write.csv(ntr.data, "Boston-surge-ordinary.csv", row.names = FALSE)