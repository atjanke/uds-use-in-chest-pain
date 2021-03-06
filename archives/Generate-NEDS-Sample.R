#### Libraries             ####
library(data.table)
library(tidytable)
library(tidyverse)
library(splitstackshape)


#### Load NEDS data        ####
setwd("/Users/alexanderjanke/Data/neds/2019_NEDS")

neds19 <- fread("NEDS_2019_ED.csv"
                #,nrow=5000000
                )
colnames(neds19) <- c("hosp_ed","KEY_ED","CPT1","CPT2","CPT3","CPT4","CPT5","CPT6","CPT7",
                      "CPT8","CPT9","CPT10","CPT11","CPT12","CPT13","CPT14","CPT15",
                      "cpt16","cpt17","cpt18","cpt19","cpt20","cpt21","cpt22","cpt23","cpt24","cpt25","cpt26",
                      "cpt27","cpt28","cpt29","cpt30","cpt31","cpt32","cpt33","cpt34","cpt35",
                      "PRCCSED1","PRCCSED2","PRCCSED3","PRCCSED4","PRCCSED5","PRCCSED6","PRCCSED7","PRCCSED8",
                      "PRCCSED9","PRCCSED10","PRCCSED11","PRCCSED12","PRCCSED13","PRCCSED14","PRCCSED15","cptccs16",
                      "cptccs17","cptccs18","cptccs19","cptccs20","cptccs21","cptccs22","cptccs23","cptccs24",
                      "cptccs25","cptccs26","cptccs27","cptccs28","cptccs29","cptccs30","cptccs31","cptccs32",
                      "cptccs33","cptccs34","cptccs35","nCPT")

neds19 <- neds19 %>% select.(KEY_ED,CPT1:CPT15,PRCCSED1:PRCCSED9)

core <- fread("NEDS_2019_Core.csv"
              #,nrow=5000000
              )

colnames(core) <- c("AGE","amonth","aweekend","died_visit","DISCWT","DISP_ED","dqtr",
                    "edevent","FEMALE","hcupfile","HOSP_ED","DX1","DX2","DX3","DX4","DX5","DX6",
                    "DX7","DX8","DX9","DX10","DX11","DX12","DX13","DX14","DX15","i10_dx16","i10_dx17",
                    "i10_dx18","i10_dx19","i10_dx20","i10_dx21","i10_dx22","i10_dx23","i10_dx24",
                    "i10_dx25","i10_dx26","i10_dx27","i10_dx28","i10_dx29","i10_dx30",
                    "i10_dx31","i10_dx32","i10_dx33","i10_dx34","i10_dx35",
                    "i10_injury","i10_injury_cut","I10_injury_drown","i10_injury_fall","i10_injury_fire",
                    "i10_injury_firearm","i10_injury_machinery","i10_injury_mvt","i10_injury_nature",
                    "i10_injury_overexertion","i10_injury_poison","i10_injury_struck","i10_injury_suffocation",
                    "i10_intent_assault","i10_intent_self_harm",
                    "i10_intent_unintentional","i10_multinjury","i10_ndx","KEY_ED","NEDS_STR",
                    "PAY1","pay2","pl_nchs","RACE","TOTCHG_ED","year","ZIPINC_QRTL")

core <- core %>% select.(HOSP_ED,KEY_ED,DISCWT,NEDS_STR,RACE,AGE,FEMALE,PAY1,DISP_ED,DX1:DX15)

neds19 <- neds19 %>%
  left_join.(core,by="KEY_ED") %>%
  select.(HOSP_ED,KEY_ED,DISCWT,NEDS_STR,RACE,AGE,FEMALE,PAY1,DISP_ED,DX1:DX15,CPT1:CPT15,PRCCSED1:PRCCSED9)

# Recode RACE
neds19 <- neds19 %>%
  mutate(RACE = case_when(
   RACE==1~"White",
   RACE==2~"Black",
   RACE==3~"Hispanic",
   RACE==4~"Asian or Pacific Islander",
   RACE==5~"Native American",
   RACE==6~"Other",
   RACE==T~"Missing"))

#### Save NEDS data files  ####
setwd("/Users/alexanderjanke/Documents/GitHub/trauma-disparities")

saveRDS(neds19,"data-cleaned/neds19.rds")

subsample <- stratified(neds19,c("HOSP_ED"),0.05)
saveRDS(subsample,"data-cleaned/neds19-subsample.rds")




#### EDA for USD           ####
df <- neds19

# Identifies visits with a UDS
list_of_uds_visits <- df %>%
  mutate(row_name = row_number()) %>%
  select(row_name, CPT1:CPT15) %>%
  pivot_longer(CPT1:CPT15) %>%
  filter(value=="80305" | value=="80306" | value=="80307") %>%
  select(row_name) %>%
  unique() %>%
  mutate(UDS=1)

df <- df %>%
  mutate(row_name = row_number()) %>%
  left_join(list_of_uds_visits,by="row_name") %>%
  select(-row_name)

df$UDS[is.na(df$UDS)] <- 0

# Limit to ED visits not resulting in admission
df <- df %>% filter(DISP_ED != 9)

# UDS Rate by Race/Sex
df %>%
  group_by(RACE,FEMALE) %>%
  summarize(
    DISCWT = mean(DISCWT),
    Count = sum(UDS),
    UDS_Rate = sum(UDS)/n()) %>%
  filter(Count>10) %>%
  View()