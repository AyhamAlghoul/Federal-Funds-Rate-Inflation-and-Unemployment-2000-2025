#install.packages("quantmod")
library(quantmod)
library(tidyverse)

#Data retreival from FRED 
getSymbols(
  c("FEDFUNDS", "CPIAUCSL", "UNRATE"),
  src = "FRED",
  from = "1999-01-01",
  to = "2026-01-01")

#Creating dataset
data <- data.frame(
  date = as.Date(index(FEDFUNDS)),
  fed_rate = as.numeric(FEDFUNDS),
  cpi = as.numeric(CPIAUCSL),
  unemployment = as.numeric(UNRATE))

data <- data %>%
  arrange(date) %>%
  mutate(
    inflation = 100 * (cpi / lag(cpi, 12) - 1)) %>%
  filter(
    date >= as.Date("2000-01-01"),
    date < as.Date("2026-01-01")) %>%
  drop_na()

write.csv(data,"../Data/fred_data.csv", row.names = FALSE)

#Graph of the federal funds rate over time
p1 <- ggplot(data, aes(x = date, y = fed_rate)) +
  geom_line(color = "steelblue") +
  labs(
    title = "Federal Funds Rate (2000–2025)",
    x = "Year",y = "Interest Rate (%)", 
    caption="Source: Federal Reserve Bank of St. Louis") +theme_minimal()

p1
ggsave("../figures/fed_rate.png", p1,width=10,height=6,dpi=300)

#Graph featuring both the federal funds rate and inflation rate
p2 <- ggplot(data, aes(x = date)) +
  geom_line(aes(y = fed_rate, color = "Federal Funds Rate"),
            linewidth = 1) +
  geom_line(aes(y = inflation, color = "Inflation Rate"),
            linewidth = 1) +
  scale_color_manual(
    values = c(
      "Federal Funds Rate" = "steelblue",
      "Inflation Rate" = "firebrick")) +
  labs(
    title = "Federal Funds Rate vs. Inflation (2000–2025)",
    x = "Year",y = "Rate (%)",color = "Variable",
    caption = "Source: Federal Reserve Bank of St. Louis") +
  theme_minimal() + theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold"),
    plot.caption = element_text(size = 9))
p2
ggsave("../Figures/FFrates_inflation.png", plot = p2, width = 10,
       height = 6,dpi = 300)

#Regression 
model <- lm(unemployment ~ fed_rate, data = data)
summary(model)

#Regression Stats
beta <- coef(model)["fed_rate"]
p_value <- summary(model)$coefficients["fed_rate", "Pr(>|t|)"]
r_squared <- summary(model)$r.squared

stats <- paste0(
  "Coefficient = ", round(beta, 3),
  "\np-value = ", format.pval(p_value, digits = 3),
  "\nR² = ", round(r_squared, 3))

#Graph of relationship between unemployment and federal funds rate
p3 <- ggplot(data, aes(x = fed_rate, y = unemployment)) +
  geom_point(
    aes(color = "Monthly Observations"),alpha = 0.5 ) +
  geom_smooth(
    aes(color = "OLS Regression"),method = "lm",se = TRUE) +
  scale_color_manual(values = c( "Monthly Observations" = "steelblue",
      "OLS Regression" = "firebrick")) +
  annotate("label",x = Inf,y = Inf,label = stats,hjust = 1.05
           ,vjust = 1.2, size = 3.5) +
  labs(title = "Federal Funds Rate vs. Unemployment (2000–2025)",
    x = "Effective Federal Funds Rate (%)",
    y = "Unemployment Rate (%)",color = "Variable",
    caption = "Source: Federal Reserve Bank of St. Louis") +
  theme_minimal() +
  theme(legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold"),
    plot.caption = element_text(size = 9))

p3

ggsave("../Figures/rates_unemployment.png", plot = p3,width = 10,
  height = 6,dpi = 300)

#Additional model controlling for inflation
model2 <- lm(unemployment ~ fed_rate + inflation, data = data)
summary(model2)
