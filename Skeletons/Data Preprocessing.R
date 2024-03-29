############################################################################### -
# Project:    "JUSTMASTERARBEIT"
# Author:     Juliana Schneider
# Dataset:    data SA90 NeuroNet
# Topic:      "Preliminaries"
################################################################################ -

#####################################################
#################### PART ONE: ######################
######## INSTALL AND LOAD NECESSARY PACKAGES ########
###########  + FIRST LOOK AT RAW DATA   #############
#####################################################

# install and load packages

packs <- c("tseries", "forecast", "reshape2", "zoo", "lubridate", "tidyverse", "e1071", "openxlsx", "caret")

Install_And_Load <- function(packages) {
  k <- packages[!(packages %in% installed.packages()[,"Package"])];
  if(length(k))
  {install.packages(k, repos='https://cran.rstudio.com/');}
  
  for(package_name in packages)
  {library(package_name,character.only=TRUE, quietly = TRUE);}
}

Install_And_Load(packs)

# set seed
set.seed(123)


# set working directory
getwd()

setwd("D:/KIVAS/Daten")

# Save current workspace
#save.image()

# Load current workspace
# load(paste(getwd(),"/.RData",sep = ""))

# load data
data_SA_90_NeuroNet_raw <- read.csv2(paste(
  
  # If the data files are in a subdirectory of the R-files, run the next line.
  getwd()
  ,"data_SA90_NeuroNet.csv"
  , sep = "/")
  , header = T
  , check.names = F
  , sep = ";"
  , dec = ",")

data_SA_90_NeuroNet_pre <- data_SA_90_NeuroNet_raw


colnames(data_SA_90_NeuroNet_pre)
# Check dimensions, data structure and missing values 

dim(data_SA_90_NeuroNet_raw)
str(data_SA_90_NeuroNet_raw)
summary(data_SA_90_NeuroNet_raw)

# missings??

colnames(data_SA_90_NeuroNet_raw[ sapply(data_SA_90_NeuroNet_raw, function(x) any(is.na(x)))])

table(is.na(data_SA_90_NeuroNet_raw))
# Conclusion:
# - All data entries are of equal dimensions, i.e. 30 variables with 472,137
#   observations each.
# - There are 49 missing values in the weight column "gewicht"
# - "ABS_REL" is denoted as an integer, but should be a factor with only one level
# - There are 5,525 different Senders.
# - There are 15,576 different Customers/Recipients.
# - "Ziel_REL" is denoted as integer, but should be a factor. Thus, we cannot 
#   know how many destinies there are.
# - The dataset includes 13 events.
# - The binary event columns do not contain additional information.
#   We may consider deleting the columns.
# - "WetterStationID" is denoted as integer, but could also be a factor.


# Track the row number of NAs
Weight_NA_Number <- which(is.na(data_SA_90_NeuroNet_pre$gewicht))

# Check for patterns in senders, receiver, destination_REL, 

# Sender-ID
table( levels(data_SA_90_NeuroNet_raw[[2]])[data_SA_90_NeuroNet_raw[[2]] ][Weight_NA_Number] )
# - No pattern

# Receiver-ID
table( levels(data_SA_90_NeuroNet_raw[[3]])[data_SA_90_NeuroNet_raw[[3]] ][Weight_NA_Number] )
# - No patttern

# Destination Relation
table( data_SA_90_NeuroNet_raw[[4]][Weight_NA_Number] )
# - Most NAs occur in the following relations (desc. order):
#   - 90-90 (37)
#   - 90-80 (4)
#   - 90-94 (3)
#   - 90-97 (2)

plot(table( data_SA_90_NeuroNet_raw[[8]][Weight_NA_Number] )) # calenderweek
# NAs started ocurring in kw 40 which is the beginning of october



# Calender Information
table( data_SA_90_NeuroNet_raw[[8]][Weight_NA_Number] )    # calenderweek
table( data_SA_90_NeuroNet_raw[[12]][Weight_NA_Number] )   # month
table( data_SA_90_NeuroNet_raw[[13]][Weight_NA_Number] )   # quarter
table( data_SA_90_NeuroNet_raw[[15]][Weight_NA_Number] )   # Event
# Most NAs occur in the weeks before christmas.

# Year
table( data_SA_90_NeuroNet_raw[[10]][Weight_NA_Number] )
# Most NAs occured in 2015


####################################
########### PART TWO:   ############
########### CORRECTIONS ############
####################################


# correct quarterly values

range(data_SA_90_NeuroNet_pre[[13]])
# quartale gehen nur von 1 bis 3???

# quartale reparieren 
# https://stackoverflow.com/questions/21571703/format-date-as-year-quarter
splitdate <- colsplit(data_SA_90_NeuroNet_pre$LST_D," ",names=c("date","time"))
data_SA_90_NeuroNet_qtr <- cbind(data_SA_90_NeuroNet_pre, splitdate)
data_SA_90_NeuroNet_qtr$date <- as.Date(as.character(data_SA_90_NeuroNet_qtr$date), format="%d.%m.%Y")

yq <- as.yearqtr(data_SA_90_NeuroNet_qtr$date,format="%d.%m.%Y")
splityq <- colsplit(yq," ",names=c("yr","qtr"))
splityq <- gsub("Q", "",splityq$qtr)
range(splityq)

data_SA_90_NeuroNet_pre$quartal <- splityq
# corrected for quartals 



# Transform series to correct class
data_SA_90_NeuroNet_pre[[1]] <- as.factor(data_SA_90_NeuroNet_pre[[1]])
data_SA_90_NeuroNet_pre[[4]] <- as.factor(data_SA_90_NeuroNet_pre[[4]])
data_SA_90_NeuroNet_pre[[29]] <- as.factor(data_SA_90_NeuroNet_pre[[29]])

############################
############################
# check for missings once more:
table( data_SA_90_NeuroNet_pre[[13]][Weight_NA_Number] ) # most missings in 4th quarter

str(data_SA_90_NeuroNet_pre)
# Conclusion:
# - There are 28 different destination relations in "Ziel_REL"
# - There are 26 different weather stations.
# - Why are there fewer weather stations than destinations?

# Earliest Date in the data set
min(data_SA_90_NeuroNet_pre$Date)
max(data_SA_90_NeuroNet_pre$Date)
# -> 2015 is incomplete.

########################################
############# PART TWO: ################
####### PREPARING DATAFRAME ############
########## FOR ANALYSIS ################
########################################



# Store variables names
data_names <- names(data_SA_90_NeuroNet_pre)

# Create Date column in correct date format
data_SA_90_NeuroNet_pre$Date <- as.Date(data_SA_90_NeuroNet_pre$LST_D, "%d.%m.%Y")

splitdate <- colsplit(data_SA_90_NeuroNet_pre$LST_D," ",names=c("date","time"))
#data_2016 <- cbind(data_2016, splitdate)

#library(lubridate)
cal <- data.frame(Date = seq(as.Date("2015-09-17"), as.Date("2016-12-31"), "day" ))
cal$Weekday <- weekdays(cal$Date)
cal$Weekday_No <- wday(cal$Date, week_start=1)
cal$Month <- month(cal$Date)
cal$Quarter <- quarter(cal$Date)
cal$Weekend <- 0
cal$Weekend[ cal$Weekday_No %in% c(6,7) ] <- 1
cal$Weekend <- as.factor(cal$Weekend)
cal$Holiday <- 0
# This variable will be filled in later
cal$HolidayWeek <- 0
for (i in seq(dim(cal)[1])) {
  # browser()
  if (any(which(cal$Date[i] == data_SA_90_NeuroNet_pre$Date))) {
    cal$HolidayWeek[i] <- data_SA_90_NeuroNet_pre$FeiertagsWoche[
      which(cal$Date[i] == data_SA_90_NeuroNet_pre$Date)[1]
      ]
  } else {
    cal$HolidayWeek[i] <- NA
  } # Stop if-else
}




cal$Quantity <- 0
Quantity <- as.data.frame( table( sort(data_SA_90_NeuroNet_pre$Date) ) )

Quantity$Var1 <- as.Date(as.character(Quantity$Var1))
for (i in seq(dim(Quantity)[1])) {
  cal$Quantity[ which(  cal$Date == Quantity[[1]][i] ) ] <- Quantity[[2]][i]
}


# Compute and store sum of shipped weights (= Weight)
cal$Weight <- 0
Weight <- aggregate( gewicht ~ Date, data_SA_90_NeuroNet_pre, sum )
for (i in seq(dim(Weight)[1])) {
  cal$Weight[ which(  cal$Date == Weight[[1]][i] ) ] <- Weight[[2]][i]
}

# Compute and store average size of shipping as Weight/Quantity
cal$Size <- cal$Weight / cal$Quantity
cal$Size[which(cal$Size == "NaN")] <- 0
# # Compute and store the average temperature for each day
# Temperature <- aggregate( Temp ~ Date, data_SA_90_NeuroNet_pre, mean )
# cal$Temp <- NA
# for (i in seq(dim(Temperature)[1])) {
#   cal$Temp[ which(  cal$Date == Temperature[[1]][i] ) ] <- Temperature[[2]][i]
# }

holidays <- cal$Date[cal$Quantity < 500 & cal$Weekend == 0];holidays
# Conlusion:
# dunno what's with 2015-09-17??
# - 2016-01-06 Heilige Drei Koenige
# - 2016-03-25 Karfreitag 
# - 2016-03-28 Ostermontag
# - 2016-05-05 Christi Himmelfahrt
# - 2016-05-16 Pfingstmontag
# - 2016-05-26 Fronleichnam
# - 2016-10-03 Tag der Deutschen Einheit
# - 2016-11-01 Allerheiligen
# - 2016-12-26 Weihnachten
cal$Holiday[ cal$Date %in% holidays ] <- 1
cal$Holiday <- as.factor(cal$Holiday)
cal$Holiday[1] <- 0 # 2015-09-17 was not a holiday

cal[which(is.na(cal$HolidayWeek)),]
for(j in 1:length(cal$Holiday)){
  if (cal$Holiday[j] == 1 ){
    cal$HolidayWeek[j] <- 1
  } 
}
cal$HolidayWeek[c(193,466)] <- 1
cal$HolidayWeek[c(242,382,451)] <- 0

cal[c(193,242,382,451,466),]


cal$Month <- as.factor(cal$Month)
cal$Quarter <- as.factor(cal$Quarter)
cal$Weekday_No <- as.factor(cal$Weekday_No)
cal$Weekend <- as.factor(cal$Weekend)
# cal$Holiday <- as.factor(cal$Holiday)
cal$HolidayWeek <- as.factor(cal$HolidayWeek)
levels(cal$Weekday_No)

# save object for later use
setwd("D:/")
saveRDS(cal, file = "cal.rds")
head(cal)
# calnames <- colnames(cal)
# saveRDS(calnames, file = "calnames.rds")
