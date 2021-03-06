source("Libraries.R")
source("Functions.R")

df <- readRDS("data-cleaned/df.rds")

#### Figure for # of Urine drug screens ####
a <- df %>%
  filter(Chest_Pain==1) %>%
  filter(AGE>12) %>%
  filter(RACE=="Black/African American" | RACE=="White") %>%
  group_by(RACE,SEX) %>%
  summarise(TOXSCREN_TOT  = sum(TOXSCREN),
            TOTAL_ENC = n(),
            TOXSCREN_PRO  = sum(TOXSCREN)/n()) %>%
  mutate(
    UPPER_BOUND = Upper_Bound(TOXSCREN_TOT,TOTAL_ENC),
    LOWER_BOUND = Lower_Bound(TOXSCREN_TOT,TOTAL_ENC)) %>%
  ggplot(aes(x=RACE,y=TOXSCREN_PRO, fill=SEX))+
  geom_bar(stat="identity", position = position_dodge(width=0.9))+
  geom_errorbar(aes(x=RACE,ymin=LOWER_BOUND,ymax=UPPER_BOUND),width=0.2, position = position_dodge(width=0.9))+
  scale_y_continuous(labels=scales::percent_format())+
  scale_fill_manual(values=wes_palette(n=2, name="GrandBudapest2"))+
  xlab("")+ylab("")+
  theme(axis.text.x = element_text(angle = 0))+
  ggtitle("Visits with a Urine Drug Screen\nChest Pain and Age > 13")+
  guides(fill=guide_legend(title=""))+
  theme_bw()
b <- df %>%
  filter(INJURY=="Injury-related") %>%
  filter(AGE>12) %>%
  filter(RACE=="Black/African American" | RACE=="White") %>%
  group_by(RACE,SEX) %>%
  summarise(
    TOXSCREN_TOT  = sum(TOXSCREN),
    TOTAL_ENC = n(),
    TOXSCREN_PRO  = sum(TOXSCREN)/n()) %>%
  mutate(
    UPPER_BOUND = Upper_Bound(TOXSCREN_TOT,TOTAL_ENC),
    LOWER_BOUND = Lower_Bound(TOXSCREN_TOT,TOTAL_ENC)) %>%
  ggplot(aes(x=RACE,y=TOXSCREN_PRO, fill=SEX))+
  geom_bar(stat="identity", position = position_dodge(width=0.9))+
  geom_errorbar(aes(x=RACE,ymin=LOWER_BOUND,ymax=UPPER_BOUND),width=0.2, position = position_dodge(width=0.9))+
  scale_y_continuous(labels=scales::percent_format())+
  scale_fill_manual(values=wes_palette(n=2, name="GrandBudapest2"))+
  xlab("")+ylab("")+
  theme(axis.text.x = element_text(angle = 0))+
  ggtitle("Visits with a Urine Drug Screen\nInjury and Age > 13")+
  guides(fill=guide_legend(title=""))+
  theme_bw()

grid.arrange(a,b)
plot<-arrangeGrob(a,b)
ggsave("Figures/Combined-Drug-Screen-Figure.jpeg",plot,width=4,height=6,dpi=600)

#### Figure for pain meds by race       ####

pain_scale <- df %>%
  filter(PAINSCALE > 6) %>%
  mutate(Meds_Given  = ifelse(
    rowSums(across(Acetaminophen:Hydrocodone_Acetaminophen))>0,1,0)) %>%
  mutate(RACE = as.character(RAC    E)) %>%
  mutate(RACE = case_when(
    RACE=="White" ~ RACE,
    RACE=="Black/African American" ~ RACE,
    T ~ "Other")) %>%
  mutate(AGECATEGORY = cut(AGE, c(0,10,20,30,40,50,60,70,80,90,100))) %>%
  group_by(AGECATEGORY,RACE) %>%
  summarise(
    Count = n(),
    Meds_Given = 
              sum(ifelse(Meds_Given==1,1,0))/n()) %>%
  mutate(
    Lower = Lower_Bound(Meds_Given*Count,Count),
    Upper = Upper_Bound(Meds_Given*Count,Count))

ggplot(
  filter(
  pain_scale
  ,RACE!="Other" & AGECATEGORY!="(90,100]" & is.na(AGECATEGORY)==FALSE)
  ,aes(x=AGECATEGORY,y=Meds_Given,color=RACE))+
  geom_point(size=4)+
  geom_errorbar(aes(ymin=Lower, ymax=Upper),width=0.1)+
  scale_y_continuous(labels=scales::percent,limits=c(0,0.5))+
  ylab("Proportion of Patients Receiving Pain Medication")+
  xlab("Age")+
  theme_bw()+
  ggtitle("Pain Scale 7+, All ED Visits, Yes/No Pain Medication Given in ED")
ggsave("Figures/Fig-Pain-Scale-7.jpg",width=7,height=5,dpi=600)

df %>%
  mutate(Meds_Given  = ifelse(
    rowSums(across(Acetaminophen:Hydrocodone_Acetaminophen))>0,1,0)) %>%
  mutate(RACE = as.character(RACE)) %>%
  mutate(RACE = case_when(
    RACE=="White" ~ RACE,
    RACE=="Black/African American" ~ RACE,
    T ~ "Other")) %>%
  group_by(PAINSCALE,RACE) %>%
  summarise(Meds_Given=sum(Meds_Given)/n()) %>%
  ggplot(aes(x=PAINSCALE,y=Meds_Given,group=RACE,color=RACE))+
  geom_line()+geom_point()+
  xlab("Pain Scale")+ylab("Proportion of Patients Receiving Any Pain Medication")+
  scale_y_continuous(labels=scales::percent_format(accuracy=1))+
  theme_bw()
ggsave("Figures/Fig-Meds-By-Pain-Scale.jpg",width=7,height=5,dpi=600)

#### Figure for CT utilization by age   ####

age_ct <-
  df %>%
  filter(AGE>4 & AGE<30) %>%
  filter(INJURY_ENC=="Initial encounter") %>%
  group_by(AGE) %>%
  summarise(
    CT_Rate = sum(ifelse(CATSCAN=="CT imaging performed",1,0))/n(),
    Visit_Count = n())

age_ct %>%
  mutate(Discontinuity = as.factor(ifelse(AGE<16,1,0))) %>%
  ggplot(aes(x=AGE,y=Visit_Count,color=Discontinuity)) +
  geom_point()+
  geom_smooth(method="loess")+
  geom_vline(xintercept=15.5,linetype="dashed")+
  theme_bw()+
  scale_x_continuous(limits=c(0,35))+
  scale_y_continuous()+xlab("Age")+ylab("Proportion of Visits, Any CT Done")