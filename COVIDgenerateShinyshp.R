#Generates shapefile for use in COVIDmapper Shiny app

rm(list=ls())

library(tidyverse)
library(paletteer)
library(curl)
library(readxl)
library(sf)
library(gtools)

#Read in 2018 mid-year population estimates at LSOA level by sex and single year of age
temp <- tempfile()
temp2 <- tempfile()
source <- "https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2flowersuperoutputareamidyearpopulationestimates%2fmid2018sape21dt1a/sape21dt1amid2018on2019lalsoasyoaestimatesformatted.zip"
temp <- curl_download(url=source, destfile=temp, quiet=FALSE, mode="wb")
unzip(zipfile=temp, exdir=temp2)
data_m <- read_excel(file.path(temp2, "SAPE21DT1a-mid-2018-on-2019-LA-lsoa-syoa-estimates-formatted.xlsx"), 
                     sheet="Mid-2018 Males", range="A5:CQ35097", col_names=TRUE)
data_f <- read_excel(file.path(temp2, "SAPE21DT1a-mid-2018-on-2019-LA-lsoa-syoa-estimates-formatted.xlsx"), 
                     sheet="Mid-2018 Females", range="A5:CQ35097", col_names=TRUE)

#Merge sex-specific data
data_m$sex <- "Male"
data_f$sex <- "Female"
data <- rbind(data_m, data_f)

#Collapse into age bands matching CFR data
data$`0-9` <- rowSums(data[,c(5:14)])
data$`10-19` <- rowSums(data[,c(15:24)])
data$`20-29` <- rowSums(data[,c(25:34)])
data$`30-39` <- rowSums(data[,c(35:44)])
data$`40-49` <- rowSums(data[,c(45:54)])
data$`50-59` <- rowSums(data[,c(55:64)])
data$`60-69` <- rowSums(data[,c(65:74)])
data$`70-79` <- rowSums(data[,c(75:84)])
data$`80+` <- rowSums(data[,c(85:95)])

data <- data[,c(1:3, 96:105)]

data_long <- gather(data, age, pop, c(5:13))

# CFR Italian 26 March
# https://www.epicentro.iss.it/coronavirus/bollettino/Bollettino-sorveglianza-integrata-COVID-19_26-marzo%202020.pdf
# IFR from Imperial report https://www.imperial.ac.uk/media/imperial-college/medicine/sph/ide/gida-fellowships/Imperial-College-COVID19-NPI-modelling-16-03-2020.pdf

cfr <-  tibble::tribble(
  ~age, ~b, ~m, ~f, ~ifr,
  "0-9",      0.1,      0.000001, 0.3,      0.002,
  "10-19",    0.000001, 0.000001, 0.000001, 0.006,
  "20-29",    0.1,      0.2,      0.1,      0.03,
  "30-39",    0.4,      0.6,      0.2,      0.08,
  "40-49",    0.8,      1.4,      0.4,      0.15,
  "50-59",    2.3,      3.5,      1.0,      0.6,
  "60-69",    8.4,     10.3,      5.1,      2.2,
  "70-79",   22.7,     26.9,     15.6,      5.1,
  "80+",     30.6,     38.4,     22.6,       9.3
) 

#Calculate age-specific sex:population cfr ratios in Italian data
cfr$mtobratio <- cfr$m/cfr$b
cfr$ftobratio <- cfr$f/cfr$b

#Apply these to population estimates of ifr from Imperial figures
cfr$mifr <- cfr$ifr*cfr$mtobratio
cfr$fifr <- cfr$ifr*cfr$ftobratio

#Merge into population data
data_long <- merge(data_long,cfr, all.x=TRUE)

#Calculate expected deaths with 100% inflection by age group
data_long$ex_deaths <- case_when(
  data_long$sex=="Male" ~ data_long$pop*data_long$mifr/100,
  data_long$sex=="Female" ~ data_long$pop*data_long$fifr/100
)

#Summarise by LSOA
data_LSOA <- data_long %>% 
  group_by(`Area Codes`) %>% 
  summarise(name=unique(LSOA), pop=sum(pop), ex_deaths=sum(ex_deaths))

data_LSOA$mortrate <- data_LSOA$ex_deaths*100000/data_LSOA$pop

#Remove LAs from LSOA-level data
data_LSOA <- subset(data_LSOA, !is.na(name))

#Bring in 2019 IMD data (England only)
temp <- tempfile()
source <- "https://opendatacommunities.org/downloads/cube-table?uri=http%3A%2F%2Fopendatacommunities.org%2Fdata%2Fsocietal-wellbeing%2Fimd2019%2Findices"
temp <- curl_download(url=source, destfile=temp, quiet=FALSE, mode="wb")
IMD <- read.csv(temp)
#IMD <- subset(IMD, (Measurement=="Decile " | Measurement=="Rank") & Indices.of.Deprivation=="a. Index of Multiple Deprivation (IMD)")
IMD <- subset(IMD, (Measurement=="Decile " | Measurement=="Rank") & Indices.of.Deprivation=="e. Health Deprivation and Disability Domain")
IMD_wide <- spread(IMD, Measurement, Value)
data_LSOA <- merge(data_LSOA, IMD_wide[,c(1,5,6)], by.x="Area Codes", by.y="FeatureCode", all.x=TRUE )
colnames(data_LSOA) <- c("code", "name", "pop", "ex_deaths", "mortrate", "decile", "rank")

#Read in *simplified* shapefile
#Original file is from https://opendata.arcgis.com/datasets/e886f1cd40654e6b94d970ecf437b7b5_0.zip?outSR=%7B%22latestWkid%22%3A3857%2C%22wkid%22%3A102100%7D
#Uploaded and then simplified using mapshaper.org

shapefile <- st_read("C:/data projects/colin_misc/Shapefiles/Lower_Layer_Super_Output_Areas_December_2011_Boundaries_EW_BSC.shp")
names(shapefile)[names(shapefile) == "LSOA11CD"] <- "code"

map.data <- full_join(shapefile, data_LSOA, by="code")

#Bring in Local Authorities (LADs)
temp <- tempfile()
source <- "https://opendata.arcgis.com/datasets/fe6c55f0924b4734adf1cf7104a0173e_0.csv"
temp <- curl_download(url=source, destfile=temp, quiet=FALSE, mode="wb")
LSOAtoLAD <- read.csv(temp)[,c(4,10,11)]
colnames(LSOAtoLAD) <- c("code", "LAcode", "LAname")

map.data <- full_join(map.data, LSOAtoLAD, by="code")

map.data <- subset(map.data, substr(code, 1,1)=="E")

#tertile the IMD and mortrate variables
#generate tertiles
map.data$IMDtert <- quantcut(-map.data$rank, q=3, labels=FALSE)
map.data$morttert <- quantcut(map.data$mortrate, q=3, labels=FALSE)

#Generate key
keydata <- data.frame(IMDtert=c(1,1,1,2,2,2,3,3,3), morttert=c(1,2,3,1,2,3,1,2,3),
                      RGB=c("#e8e8e8","#ace4e4","#5ac8c8","#dfb0d6","#a5add3",
                            "#5698b9","#be64ac","#8c62aa","#3b4994"))

#Bring colours into main data for plotting
map.data <- left_join(map.data, keydata, by=c("IMDtert", "morttert"))

#strip out a few unnecessary columns for tidiness
map.data <- map.data[,-c(1,3:6)]

#Save sf object (need to delete original - doesn't like overwriting existing files)
st_write(map.data, "C:/data projects/colin_misc/COVIDmapper/data/COVID19LSOA.shp")

#Pull out list of LAs
LAlist <- as.data.frame(unique(map.data$LAname))
colnames(LAlist) <- "LAname"
#Sort alphabetically
LAlist <- arrange(LAlist, LAname)
write.csv(LAlist, "C:/data projects/colin_misc/COVIDmapper/data/LAlist.csv", )
