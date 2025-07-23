# Project: Climate Attitudes Analysis
# Author: Marta Bogatyr
# Country analyzed: Czech Republic (CZ)

# --- Load required libraries ---
library(dplyr)
library(ggplot2)
library(foreign)
library(forcats)
library(tidyr)

# --- Load data ---
data <- read.spss("ESS2020_kliima.sav", to.data.frame = TRUE)

# --- Filter data for Czech Republic ---
cz <- data %>% filter(cntry == "Czechia")

# --- Data cleaning ---
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

# --- Age histogram and summary ---
hist(cz$agea, main = "Age Histogram in Czech Republic", xlab = "Age", col = "lightgray", border = "black")
summary(cz$agea)

# --- Education level ---
table(cz$eisced_haridus)
barplot(table(cz$eisced_haridus), main = "Education Level in Czech Republic", xlab = "Education Level", col = "skyblue")

# --- Employment status ---
table(cz$staatus)

# --- Income level ---
table(cz$income_level)

# --- Place of residence ---
table(cz$elukoht)

# --- Climate responsibility ---
table(cz$kliima_kohustus)
hist(cz$kliima_kohustus, main = "Climate Responsibility Histogram in Czech Republic", xlab = "Climate Responsibility", col = "lightgray", border = "black")

# --- Climate concern ---
table(cz$kliima_mure)

# --- Comparison with France and Bulgaria ---
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







# ===========================
# Task 2 - Regression models
# ===========================

# --- Mudel 1: Vanus ja sugu ---
model1 <- lm(kliima_kohustus ~ agea + sugu, data = cz)
summary(model1)

# Visualiseeri mudel 1
ggplot(cz, aes(x = agea, y = kliima_kohustus, color = sugu)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm") +
  labs(title = "Mudel 1: Vanus ja sugu vs kliimakohustus", x = "Vanus", y = "Kliimakohustus") +
  theme_minimal()

# --- Mudel 2: + haridus ja staatus ---
cz <- cz %>%
  mutate(
    eisced_haridus = na_if(eisced_haridus, 77),
    eisced_haridus = na_if(eisced_haridus, 88),
    staatus = na_if(staatus, 77)
  ) %>%
  drop_na(eisced_haridus, staatus)

model2 <- lm(kliima_kohustus ~ agea + sugu + eisced_haridus + staatus, data = cz)
summary(model2)

# --- Mudel 3: + sissetulek ---
cz <- drop_na(cz, sissetulekutase)
model3 <- lm(kliima_kohustus ~ agea + sugu + eisced_haridus + staatus + sissetulekutase, data = cz)
summary(model3)

# --- Mudel 4: + elukoht ---
cz <- cz %>% mutate(elukoht = na_if(elukoht, 77)) %>% drop_na(elukoht)
model4 <- lm(kliima_kohustus ~ agea + sugu + eisced_haridus + staatus + sissetulekutase + elukoht, data = cz)
summary(model4)

# --- Mudel 5: + loodus_oluline ja kliima_mure ---
cz <- cz %>%
  mutate(
    kliima_mure = na_if(kliima_mure, 77),
    loodus_oluline = na_if(loodus_oluline, 77)
  ) %>%
  drop_na(kliima_mure, loodus_oluline)

model5 <- lm(kliima_kohustus ~ agea + sugu + eisced_haridus + staatus + sissetulekutase + elukoht + kliima_mure + loodus_oluline, data = cz)
summary(model5)

# --- Mudel 6: koosmõju sugu * kliima_mure ---
model6 <- lm(kliima_kohustus ~ agea + sugu * kliima_mure + eisced_haridus + staatus + sissetulekutase + elukoht + loodus_oluline, data = cz)
summary(model6)

# Visualiseeri koosmõju
interact_plot(model6, pred = kliima_mure, modx = sugu, plot.points = TRUE)
