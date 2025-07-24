# Project: Climate Attitudes Analysis
# Author: Marta Bogatyr
# Country analyzed: Czech Republic (CZ)

# Load libraries 
library(dplyr)
library(ggplot2)
library(foreign)
library(forcats)
library(tidyr)

# Load data 
data <- read.spss("ESS2020_kliima.sav", to.data.frame = TRUE)

# Filter data for Czech Republic 
cz <- data %>% filter(cntry == "Czechia")

# Data cleaning
cz <- cz %>%
  mutate(
    agea = as.numeric(as.character(agea)),
    kliima_kohustus = as.numeric(as.character(kliima_kohustus)),
    gender = factor(sugu, levels = c(1, 2), labels = c("Male", "Female")),
    income_level = fct_collapse(as.character(sissetulekutase),
                                "Refusal" = c("77"), "Don't know" = c("88"), "Missing" = c("99")),
    income_level = na_if(income_level, "Refusal"),
    income_level = na_if(income_level, "Don't know"),
    income_level = na_if(income_level, "Missing")
  ) %>%
  drop_na(kliima_kohustus, agea, gender)

# Age histogram and summary 
hist(cz$agea, main = "Age Histogram in Czech Republic", xlab = "Age", col = "lightgray", border = "black")
summary(cz$agea)

# Education level 
table(cz$eisced_haridus)
barplot(table(cz$eisced_haridus), main = "Education Level in Czech Republic", xlab = "Education Level", col = "skyblue")

# Employment status
table(cz$staatus)

# Income level
table(cz$income_level)

# Place of residence
table(cz$elukoht)

# Climate responsibility 
table(cz$kliima_kohustus)
hist(cz$kliima_kohustus, main = "Climate Responsibility Histogram in Czech Republic", xlab = "Climate Responsibility", col = "lightgray", border = "black")

# Climate concern 
table(cz$kliima_mure)

# Comparison with France and Bulgaria
fr <- data %>% filter(cntry == "France")
bg <- data %>% filter(cntry == "Bulgaria")

fr$kliima_kohustus <- as.numeric(as.character(fr$kliima_kohustus))
bg$kliima_kohustus <- as.numeric(as.character(bg$kliima_kohustus))

# Frequency values based on observation (manual input)
comparison_data <- data.frame(
  Group = 1:9,
  Czechia = c(124, 174, 244, 187, 386, 233, 257, 194, 86),
  France = c(8, 15, 34, 41, 205, 193, 353, 476, 191),
  Bulgaria = c(98, 178, 234, 164, 486, 263, 355, 256, 81)
)

# Reshape to long format for plotting
long_data <- pivot_longer(comparison_data, cols = c("Czechia", "France", "Bulgaria"),
                          names_to = "Country", values_to = "Frequency")

# Plot grouped bar chart
ggplot(long_data, aes(x = factor(Group), y = Frequency, fill = Country)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Comparison of Climate Responsibility Opinions by Country",
    x = "Response Group (1 = strongly disagree, 9 = strongly agree)",
    y = "Frequency"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("orange", "darkorange3", "deeppink3"))




# Task 2 - Regression models


# Model 1: Age and gender

model1 <- lm(kliima_kohustus ~ agea + gender, data = cz)
summary(model1)

ggplot(cz, aes(x = agea, y = kliima_kohustus)) +
  geom_point(aes(color = gender), alpha = 0.4) +
  geom_smooth(method = "lm", color = "blue", se = FALSE) +
  labs(title = "Model 1: Age and Gender vs Climate Responsibility",
       x = "Age", y = "Climate Responsibility") +
  theme_minimal()


# Model 2: Education and employment status

model2 <- lm(kliima_kohustus ~ agea + gender + education + status, data = cz)
summary(model2)

# Optional visualization for one added variable:
ggplot(cz, aes(x = status, y = kliima_kohustus)) +
  geom_boxplot(aes(fill = gender)) +
  labs(title = "Model 2: Climate Responsibility by Employment Status",
       x = "Employment Status", y = "Climate Responsibility") +
  theme_minimal()

# Model 3: Income level and responsibility

cz3 <- cz %>% drop_na(income) # remove NA for this model
model3 <- lm(kliima_kohustus ~ agea + gender + education + status + income, data = cz3)
summary(model3)

# Prepare factor
cz3$income <- fct_relevel(cz3$income,
                          "Living comfortably",
                          "Coping on present income",
                          "Difficult on present income",
                          "Very difficult on present income",
                          "Refusal",
                          "Don't know")

# Convert income to numeric index for regression plotting
cz3$income_code <- as.numeric(cz3$income)

# Plot regression with ggplot2
ggplot(cz3, aes(x = income_code, y = kliima_kohustus, color = gender)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = FALSE, size = 1.2) +
  scale_x_continuous(
    breaks = 1:6,
    labels = levels(cz3$income)
  ) +
  labs(
    title = "Regression of Climate Responsibility by Gender and Income Level",
    x = "Income Level (ordered)",
    y = "Climate Responsibility"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Model 4: Residence and responsibility

cz4 <- cz3 %>% drop_na(residence)
model4 <- lm(kliima_kohustus ~ agea + gender + education + status + income + residence, data = cz4)
summary(model4)

# Plot regression with ggplot2
ggplot(cz4, aes(x = residence, y = kliima_kohustus, color = gender)) +
  geom_point(position = position_jitter(width = 0.2), alpha = 0.4) +  
  geom_smooth(method = "lm", se = TRUE) +  
  labs(
    title = "Regression of Climate Responsibility by Gender and Residence",
    x = "Residence Type",
    y = "Climate Responsibility"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.title = element_blank()
  )

# Model 5: Gender and climate concern

model6 <- lm(kliima_kohustus ~ agea + gender * climate_concern + education + status +
               income + residence, data = cz5)
summary(model6)

ggplot(cz5, aes(x = climate_concern, y = kliima_kohustus, color = gender)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Gender and Climate Concern",
    x = "Climate Concern",
    y = "Climate Responsibility"
  ) +
  theme_minimal()
