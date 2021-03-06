################################################
# This program was written by Camilo Marchesini.
################################################

# This R script reproduces the three descriptive plots on the U.S. economy that appear in my master thesis. It also shows the potential of 
# package -fredr to produce powerful data visualisations for time series generously provided by the Federal Reserve Bank of St.Louis.
# The use of package -neverhpfilter is also illustrated.

#     Copyright (C) 2019  Camilo Marchesini
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

######################
# Library 
library(tidyverse) # many packages bundled into one
library(readxl) # read xl table
library(zoo) # zoo contains the function as.yearqtr
library(purrr) # for map_dfr
library(lemon) # Better legend in ggplot2
library(gridExtra) # Arrange multiple ggplot graphs
# install.packages("fredr")
library(fredr) # Retrive data from FRED
# install.packages("extrafont")
library(extrafont)
# More information on www.fontsquirrel.com/fonts/latin-modern-roman
library(xts) # treats time series objects
#devtools::install_github("JustinMShea/neverhpfilter")
library(neverhpfilter)  # implements hamilton filter
######################

# For documentation on how to use library(fredr), visit http://sboysel.github.io/fredr/articles/fredr.html and follow
# To request the API from the Federal Reserve Bank, visit https://research.stlouisfed.org/docs/api/api_key.html

# fredr_set_key() - Set the required FRED API key for the session.
# fredr() or fredr_series_observations() - Fetch a FRED series.
# fredr_series_search_text() - Search for a FRED series by text.
# fredr_request() - Send a general request to the FRED API.

####################################################  IMPORTANT !!!!!!!!!!!!!!!!!!!!! #####################################################
# Always run at the beginning of each session: this is the API key provided by the FRED
fredr_set_key("yourAPIkey")
############################################################################################################################################

# EXAMPLE DOWNLOAD:
# Leverage the native features of the FRED API by passing additional parameters:
fredr_series_observations(
  series_id = "UNRATE",
  observation_start = as.Date("1990-01-01"),
  frequency = "q",
  units = "chg"
)

# It is relatively straightforward to convert tibbles returned by fredr into other time series objects.
# For example,

# use library(xts)
gnpca <- fredr(series_id = "GNPCA", units = "log") %>%
  mutate(value = value - lag(value)) %>%
  filter(!is.na(value))

# View FRED API documentation and browse
fredr_docs(endpoint = "series/observations")
# To go to the parameter section 
fredr_docs(endpoint = "category/related_tags", params = TRUE)

######################################################### START PLOTS ################################################################
# Set working directory
setwd("~/Desktop/yourdirectory")
# Or go to your preferred wd and type
# wd <- getwd()
# setwd(wd)
# Clear workspace
rm(list=ls())
# Clear screen
cat("\014")  
####################################################################################################
# Figure 1: Cyclical Properties of Real Aggregate Asset Prices and Credit to Non-Financial Sector
####################################################################################################
###########   IMPORTANT !!!!!!!!!!!!!!!!!!!!!
# Always run at the beginning of each session: this is the API key provided by the FRED
fredr_set_key("yourAPIkey")

# Real Output
gdp <- fredr_series_observations( 
  series_id = "GDPC1",
  observation_start = as.Date("1985-01-01"),
  observation_end = as.Date("2018-09-01"),
  frequency = "q",
  units = "lin"
)  
# Make quarterly data as YYYYQ
gdp  <- transform(gdp, date = as.yearqtr(date))

# Nominal Output
ngdp <- fredr_series_observations(  
  series_id = "GDP",
  observation_start = as.Date("1985-01-01"),
  observation_end = as.Date("2018-09-01"),
  frequency = "q",
  units = "lin"
)  
# Make quarterly data as YYYYQ
ngdp  <- transform(ngdp, date = as.yearqtr(date))

# Real potential output
potgdp <- fredr_series_observations(   
  series_id = "GDPPOT",
  observation_start = as.Date("1985-01-01"),
  observation_end = as.Date("2018-09-01"),
  frequency = "q",
  units = "lin"
)
# Make quarterly data as YYYYQ
potgdp  <- transform(potgdp, date = as.yearqtr(date))

# Total Credit to Private Non-Financial Sector, Adjusted for Breaks, for United States
private <- fredr_series_observations(   
  series_id = "CRDQUSAPABIS",
  observation_start = as.Date("1985-01-01"),
  observation_end = as.Date("2018-09-01"),
  frequency = "q",
  units = "lin"
)
# Make quarterly data as YYYYQ
private  <- transform(private, date = as.yearqtr(date))

# Compute real output gap
gap <- (gdp[,3]-potgdp[,3]) %>% as.data.frame()
gap$series_id <- rep("GDP_GAP", nrow(gap))
colnames(gap) <- c("value","series_id")
# Add date column
gap$date <- gdp[,1]
gap$value <- gap$value*0.01

# Applying Hamilton filter to compute credit gap
creditratio <- private[,3]/ngdp[,3] %>% as.data.frame() %>% 
  ts(start = c(1985, 1), frequency = 4)
dates <- seq(as.Date("1985-01-01"), length=135, by="quarters")
creditratio <- xts(x=creditratio, order.by=dates)
# Quarterly data (h)orizon=8, lags (p) = 4, Hamilton (2018)
credit_filter <- yth_filter(creditratio, h = 8, p = 4)
# Extract trend
credit_trend <- credit_filter[,2]
creditgap <- (creditratio - credit_trend)
colnames(creditgap) <- c("gap")
creditgap <- as.data.frame(creditgap)
creditgap$series_id <- rep("CRED_GAP", nrow(creditgap))
colnames(creditgap) <- c("value","series_id") 
creditgap$date <- gdp[,1]
creditgap$value <- creditgap$value*100
# The credit gap ready to be plotted

# Download the series on real house prices from OECD
# Real House Prices  https://data.oecd.org/price/housing-prices.htm
hprices <-read.csv("Houseprices.csv", header = T)
# Remove - from variable time and replace it with space
hprices$TIME <- sub('-'," ", hprices$TIME)
hprices  <- transform(hprices, date = as.yearqtr(TIME))
hprices <- select(hprices, c(date,INDICATOR,Value))
colnames(hprices) <- c("date","series_id","value")
hprices$series_id <- as.character(hprices$series_id)
hprices$value <- as.numeric(hprices$value)

# Applying Hamilton filter to compute real house price gap
house <- hprices$value %>% as.data.frame() %>% 
  ts(start = c(1985, 1), frequency = 4)
dates <- seq(as.Date("1985-01-01"), length=135, by="quarters")
house <- xts(x=house, order.by=dates)
house_filter <- yth_filter(house, h = 8, p = 4)
# Extract trend
house_trend <- house_filter[,2]
housegap <- (house - house_trend)
colnames(housegap) <- c("gap")
housegap <- as.data.frame(housegap)
housegap$series_id <- rep("HOUSE_GAP", nrow(housegap))
colnames(housegap) <- c("value","series_id") 
housegap$date <- gdp[,1]
housegap$value <- housegap$value
# The house price gap ready to be plotted

datafed <- rbind(creditgap,housegap,gap)
mycolors <- c("GDP_GAP"="orchid2","CRED_GAP"="deepskyblue2","HOUSE_GAP"="darkred")

figure_1 <- ggplot(data=datafed, mapping = aes(x = date, y = value, color = series_id, na.rm = T)) + 
  # Shade recession period: 1990Q3 - 1991Q1, Source:NBER
  geom_rect(xmin =  datafed$date[23], ymin = -Inf,   
            xmax =  datafed$date[25], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) + 
  # Shade recession period: 2001Q1 - 2001Q4, Source:NBER
  geom_rect(xmin =  datafed$date[65], ymin = -Inf,   
            xmax =  datafed$date[68], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) +  #fill regulates the filling, colour regulates the borders
  # Shade recession period: 2007Q4 - 2009Q2, Source:NBER
  geom_rect(xmin =  datafed$date[92], ymin = -Inf,   
            xmax =  datafed$date[98], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) + # Invisible boarders with colour = "white"
  geom_bar(data=filter(datafed, series_id == "GDP_GAP"), stat="identity", colour = "orchid2") +
  geom_path(size=1.2) +  # Make lines just a bit thicker, but make lines more transparent
  geom_hline(yintercept=0, 
             color = "black", size=0.4) +
  scale_y_continuous(name="Gap",breaks=c(seq(-18,12,3))) +
  scale_color_manual(name=NULL,values = mycolors, 
                     labels=c("Credit-to-GDP Gap",
                              "Real Output Gap",
                              "Real House Price Gap")) +
  scale_x_yearqtr(format = "%Y Q%q", breaks = seq(from = min(datafed$date), to = max(datafed$date), by = 1.25)) + 
  labs(x="", # No x-title
       color="") +
  theme_bw() +
  theme(text=element_text(family = "LM Roman Demi 10", face = "bold",size = 18),
        axis.text.x = element_text(angle=45, vjust = 0.5),
        panel.grid.major.y = element_line(linetype=3),
        panel.grid.minor.y = element_line(linetype=3),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.background = element_rect(fill ="transparent"), # get rid of legend bg
        legend.key = element_rect(fill = "transparent", colour = NA), # get rid of key legend fill, and of the surrounding
        legend.title=element_text(color="black"),
        plot.caption = element_text(hjust = 0) # Left-align caption/notes
  ) 
reposition_legend(figure_1, 'top left')
dev.copy(png,"Figure1.png", width=1180, height=600)
# Take picture off the console screen
dev.off()

###########################################################################################################################
# Figure 2:  Chicago Fed National Financial Conditions Subindexes and Charge-off rate on Loans Secured by real Estate
###########################################################################################################################
###########   IMPORTANT !!!!!!!!!!!!!!!!!!!!!
# Always run at the beginning of each session: this is the API key provided by the FRED
fredr_set_key("yourAPIkey")
###########
rm(list=ls())
# Risk subindex
risk <- fredr_series_observations(   
  series_id = "NFCIRISK",
  observation_start = as.Date("1995-01-01"),
  frequency = "q",
  units = "lin"
)  
# Make quarterly data as YYYYQ
risk  <- transform(risk, date = as.yearqtr(date))

# Credit subindex
credit <- fredr_series_observations(   
  series_id = "NFCICREDIT",
  observation_start = as.Date("1995-01-01"),
  frequency = "q",
  units = "lin"
)
# Make quarterly data as YYYYQ
credit  <- transform(credit, date = as.yearqtr(date))

# Leverage subindex
leverage <- fredr_series_observations(
  series_id = "NFCILEVERAGE",
  observation_start = as.Date("1995-01-01"),
  frequency = "q",
  units = "lin"
)  
# Make quarterly data as YYYYQ
leverage  <- transform(leverage, date = as.yearqtr(date))

# Charge-off rate
choff <- fredr_series_observations(    
  series_id = "CORSREACBS",
  observation_start = as.Date("1995-01-01"),
  frequency = "q",
  units = "lin"
) 
# Make quarterly data as YYYYQ
choff  <- transform(choff, date = as.yearqtr(date))

# Merge
datafed <- rbind(risk,credit,leverage,choff)
mycolors <- c("NFCILEVERAGE"="goldenrod3","NFCICREDIT"="deeppink2","NFCIRISK"="forestgreen","CORSREACBS"="blue")

figure_2 <- ggplot(data=datafed, mapping = aes(x = date, y = value, color = series_id, na.rm = T)) +  # silently remove NA for plotting
  # Shade recession period: 2001Q1 - 2001Q4, Source:NBER
  geom_rect(xmin = datafed$date[25], ymin = -Inf,   
            xmax = datafed$date[28], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) +  #fill regulates the filling, colour regulates the borders
  # Shade recession period: 2007Q4 - 2009Q2, Source:NBER
  geom_rect(xmin = datafed$date[52], ymin = -Inf,   
            xmax = datafed$date[58], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) +  # Invisible boarders with colour = "white"
  geom_path(size=1.2) +  # Make lines just a bit thicker, but make lines more transparent
  geom_area(data=filter(datafed, series_id != "CORSREACBS"),aes(group=series_id), position = "identity", fill = "lightskyblue", alpha = 0.2) +
  geom_hline(datafed, yintercept=0, 
             color = "black", size=0.4) +
  scale_y_continuous(name="Index",breaks=c(seq(-3,4,0.50)), sec.axis = sec_axis(~ 1*., name="Charge-off Rate, Percent", breaks=c(seq(0,3.5,0.50)))) +
  scale_color_manual(name="Chicago Fed National Financial Conditions Subindexes",values = mycolors,
                     breaks=c("NFCICREDIT", "NFCILEVERAGE", "NFCIRISK"),
                     labels=c("Credit Subindex (NFCICREDIT)",
                              "Leverage Subindex (NFCILEVERAGE)",
                              "Risk Subindex (NFCIRISK)")) +
  scale_x_yearqtr(format = "%Y Q%q", breaks = seq(from = min(datafed$date), to = max(datafed$date), by = 1.25)) +  # Make breaks every 5 quarters
  labs(x="", # No x-title
       color="") +
  annotate("text", x = datafed$date[76] , y = 2.3, label = "Charge-off Rate on Loans Secured by Real Estate",
           colour = "blue", family = "LM Roman Demi 10", size = 4.5) +
  annotate("text", x = datafed$date[17] , y = 1.7, label = "Dot-com bubble",
           colour = "black",family = "LM Roman Demi 10", size = 4.5) +
  annotate("segment", x =  datafed$date[17], xend = datafed$date[20], y = 1.6, yend = 1.2,
           colour = "pink", size=1.5, alpha=0.6, arrow=arrow(length=unit(0.025,"npc"))) +
  theme_bw() +
  theme(text=element_text(family = "LM Roman Demi 10", face = "bold",size = 18),
        axis.text.x = element_text(angle=45, vjust = 0.5),
        panel.grid.major.y = element_line(linetype=3),
        panel.grid.minor.y = element_line(linetype=3),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        axis.title.y.right = element_text(color = mycolors["CORSREACBS"]), # Color axis
        axis.text.y.right = element_text(color = mycolors["CORSREACBS"]),
        legend.background = element_rect(fill ="transparent"), # get rid of legend bg
        legend.key = element_rect(fill = "transparent", colour = NA), # get rid of key legend fill, and of the surrounding
        legend.title=element_text(color="black"),
        plot.caption = element_text(hjust = 0) # Left-align caption/notes
  ) 
reposition_legend(figure_2, 'top left')
dev.copy(png,"Figure2.png", width=1180, height=600)
dev.off()

#################################################################
# Figure 3: Monetary Policy Uncertainty and Financial Distress
################################################################

# Build a function to create nice date formats
make_monthly <- function(start,end,rows,columns,dataset,vardate){
  months.list <- c("01","02","03","04","05","06","07","08","09","10","11","12")
  years.list <- c(start:end)
  #The next line of code generates all the month-year combinations.
  df<-expand.grid(year=years.list,month=months.list)
  #Then, paste together the year and month with a day so as to get dates like "2007-03-01".  
  # Pass that to as.Date, and pass the result to as.yearqtr.
  df$Date=as.yearmon(as.Date(paste0(df$year,"-",df$month,"-01")))
  df <- df[order(df$Date),]
  df <- df[rows,columns]
  date <- df
  dataset$date <- date
  # Correct Formatting
  dataset$date <- as.yearmon(dataset$date)
  dataset$series_id <- as.character(dataset$series_id)
  dataset$value <- as.numeric(as.character(dataset$value))
  return(dataset)
}

# Download Monetary Policy Uncertainty series from http://www.policyuncertainty.com/monetary.html
# Husted, Lucas, John H. Rogers, and Bo Sun, "Monetary Policy Uncertainty," working paper, Board of Governors of the Federal Reserve Board, 2017
HRS_MPU_monthly <- read_excel("HRS_MPU_monthly.xlsx") %>% as.data.frame()
# Make compatible with the other datasets
# Generate column with series name 
HRS_MPU_monthly$series_id <- rep("HRS_MPU", nrow(HRS_MPU_monthly))
# Reorder columns
HRS_MPU_monthly <- cbind(HRS_MPU_monthly[,1],HRS_MPU_monthly[,3],HRS_MPU_monthly[,2]) %>% as.data.frame()
# rename columns
colnames(HRS_MPU_monthly) <- c("date","series_id","value")
# Eliminate last two lines, which do not contain data
HRS_MPU_monthly <-HRS_MPU_monthly[1:391,] 
# Ready and compatible!

# Use from January 1995
HRS_MPU_monthly <- HRS_MPU_monthly[121:nrow(HRS_MPU_monthly),]
MPU <- make_monthly(1995,2017,1:271,3,HRS_MPU_monthly,date) 
# Simply rescaling
MPU$value <- MPU$value -100
###########   IMPORTANT !!!!!!!!!!!!!!!!!!!!!
# Always run at the beginning of each session: this is the API key provided by the FRED
fredr_set_key("yourAPIkey")
###########

# Indicator of financial distress 
finstress <- fredr_series_observations(   # financial stress 
  series_id = "STLFSI",
  observation_start = as.Date("1995-01-01"),
  observation_end = as.Date("2017-07-01"),
  frequency = "m",
  units = "lin"
)  
# Make monthly
finstress <- make_monthly(1995,2017,1:271,3,finstress,date)
# Simply rescaling
finstress$value <- finstress$value*100
# Merge
datafed <- rbind(MPU, finstress)
mycolors <- c("HRS_MPU"="purple4", "STLFSI"="orangered2")

figure_3 <- ggplot(data = datafed , mapping = aes(x = date, y = value, color = series_id, na.rm = T)) + # silently remove NA for plotting
  # Shaded recession period: Mar 2001- Nov 2001, Source:NBER
  geom_rect(xmin = datafed$date[74] , ymin = -Inf,   
            xmax = datafed$date[81], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) +  #fill regulates the filling, colour regulates the borders
  # Shaded recession period: Dec 2007 - Jun 2009, Source:NBER
  geom_rect(xmin = datafed$date[155], ymin = -Inf,   
            xmax = datafed$date[177], ymax = Inf,
            fill = "gray93", colour = "white", alpha = 0.2) + 
  geom_hline(yintercept=0, linetype="dashed",  # Add horizontal line at 0
             color = "grey", size=0.4) +
  # Annote interesting spike in both indexes
  annotate('rect', xmin = datafed$date[150] , xmax = datafed$date[157], 
           ymin = -75, ymax = 85, fill = "turquoise2", alpha = 0.4) +
  geom_path(size=1.2) +  # Make lines just a bit thicker, but make lines more transparent
  scale_y_continuous(name="Monetray Policy Uncertainty, Index", breaks=c(seq(-100,320,50)), sec.axis = sec_axis(~ .01*., name="Financial Stress, Index", breaks=c(seq(-3,9.5,.5)))) +
  scale_color_manual(name="series_id", values = mycolors, 
                     labels=c("Monetary Policy Uncertainty (HRS_MPU)","St. Louis Fed Financial Stress Index (STLFSI)")) +
  annotate("segment", x =  datafed$date[144], xend = datafed$date[150], y = 142 , yend = 97,
           colour = "pink", size=1.5, alpha=0.7, arrow=arrow(length=unit(0.025,"npc"))) +
  annotate("segment", x =  datafed$date[144], xend = datafed$date[150], y = -117 , yend = -82,
           colour = "pink", size=1.5, alpha=0.7, arrow=arrow(length=unit(0.025,"npc"))) +
  scale_x_yearmon(format = "%b %Y", breaks = seq(from = min(datafed$date), to = max(datafed$date), by = 1.25)) +  
  labs(x="",color="") + # No x-title
  theme_bw() +
  theme(text=element_text(family = "LM Roman Demi 10", face = "bold", size = 18),
        axis.text.x = element_text(angle=45, vjust = 0.5),    #      
        axis.title.y = element_text(color = mycolors["HRS_MPU"]),
        axis.text.y = element_text(color = mycolors["HRS_MPU"]),
        axis.title.y.right = element_text(color = mycolors["STLFSI"]),
        axis.text.y.right = element_text(color = mycolors["STLFSI"]),
        panel.grid.major.y = element_line(linetype=3),
        panel.grid.minor.y = element_line(linetype=3),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.background = element_rect(fill = "transparent"), # get rid of legend bg
        legend.key = element_rect(fill = "transparent", colour = NA), # get rid of key legend fill, and of the surrounding
        legend.title=element_blank(),
        plot.caption = element_text(hjust = 0) # Left-align caption/notes
  )
reposition_legend(figure_3, 'top left')
dev.copy(png,"Figure3.png", width = 1180, height = 600)
dev.off()

# END
