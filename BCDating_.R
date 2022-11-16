library(readr)
library(zoo)
install.packages("FactoMineR")
library("FactoMineR")
install.packages("factoextra")
library("factoextra")
library(readr)
library(ggplot2)
install.packages("gridExtra") 
library("gridExtra") 
library(rpart)
library(rpart.plot)
install.packages("rpart.plot")
library(rpart.plot)
library("MASS")
library("corrplot")
install.packages("openxlsx")
library("openxlsx")
# BCDating 

install.packages("BCDating")
install.packages("zoo") 
library(MASS)
library(BCDating)
library(zoo)
# Import datafile : !! importer la table à la main et sélectionner pour la colonne dateok le type Data : d%/m%/Y% !!
Meteo_sync3 <- read.csv("C:\Users\ceecy\PythonScripts\Memoire\Scripts\BC DATING\Meteo_sync3.csv", sep=";")
meteo_sync3
typeof(Meteo_sync3$TEMP)

# Sup IIIII, var1
Meteo_sync3 <- Meteo_sync3[,-1]
Meteo_sync3 <- Meteo_sync3[,-5]

#Convert to numeric, doesn't work
Meteo_sync3$TEMP <- as.numeric(levels(Meteo_sync3$TEMP))[Meteo_sync3$TEMP] #pas besoin
typeof(Meteo_sync3$TEMP)

#Convert to timeseries
?as.ts
?read.zoo #pas besoin
#meteo_ts <- read.zoo(Meteo_sync3, header = TRUE, format = "numeric",index.name=Meteo_sync3$var1)
meteo_tstest <- as.ts(Meteo_sync3,freq=frequency(1/12), names= c('TEMP','PRCP','WDSP','seventy','fifty','fourty','thirty','twenty','fifteen','ten'))
meteo_tstestT <- ts(data=Meteo_sync3$TEMP, start=1973, end=2020, frequency=12,names= c('TIME','TEMP'))
meteo_tsteT <-as.ts(meteo_tstestT)
class(meteo_tsteT)
meteo_tsteT
# Import datafile 
Meteo_ts<- read.csv("C:\Users\ceecy\PythonScripts\Memoire\Scripts\BC DATING\Meteo_ts.csv", sep=";") #pas besoin
Meteo_ts

#Check column type for ts 
typeof(meteo_tste[, 'PRCP'])

#Convert to numeric for ts, doesn't work #pas besoin
meteo_ts[, 'PRCP'] <- as.numeric(meteo_ts[, 'PRCP'])
attributes(meteo_ts[, 'PRCP']) <- attributes(meteo_ts[, 'PRCP'])

meteo_ts <- matrix(as.numeric(meteo_ts),    # Convert to numeric matrix
                  ncol = ncol(meteo_ts))

#BC DATING applying
?BBQ
?BCDating

Meteo_sync4 <- Meteo_sync3[-37:-575,-3:-11]
meteo_tstest <- ts(data=Meteo_sync4, frequency=12, names= c('TIME','TEMP'))
meteo_test <- ts(data=Meteo_sync4, frequency=12,names= c('TIME','TEMP'))
meteo_test
#BBQ(meteo_ts, mincycle = 5, minphase = 2, name ="Dating Meteorologic cycles of QBO and Singapore")
Meteo_extract <- BBQ(meteo_test,name="")
Meteo_extracte <- BBQ(meteo_tsteT,name="")
plot(Meteo_extracte)
summary(Meteo_extracte)
library(BCDating)
data("Iran.non.Oil.GDP.Cycle")
Iran.non.Oil.GDP.Cycle
data("Iran.non.Oil.GDP.Cycle")
dat <- BBQ(Iran.non.Oil.GDP.Cycle, name="Dating Business Cycles of Iran")
show(dat)
summary(dat)
plot(dat)

write.xlsx(Exp_Rec, "C:\\Users\\ceecy\\PythonScripts\\Memoire\\Scripts\\BC DATING\\Exp_Rec.xlsx")