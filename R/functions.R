
library(tidyverse)
library(data.table)

mycolors <-c(
    "#386CB0", "#F0027F", "#BF5B17", "#1B9E77", "#D95F02", "#7570B3", 
    "#66A61E", "#E6AB02", "#A6761D", "#C2DF23FF", "#38598CFF", "#482173FF", 
    "#85D54AFF", "#1E9B8AFF",  "#023047", "#ffb703", "#fb8500","#51C56AFF", "#606c38","#283618","#fefae0",
    "#dda15e","#bc6c25", "#FDE725FF", "#2D708EFF", 
    "#433E85FF", "#25858EFF", "#440154FF", "#7FC97F", "#BEAED4", 
    "#FDC086","#8ecae6", "#219ebc", "#023047", "#ffb703", "#fb8500")

plot_bar <- function(data, x, y, fill, title, xlab, ylab){
    
    ggplot(data, aes(x = {{x}}, y = {{y}}, fill = {{fill}})) +
    geom_col(width = .5) +
    #coord_flip() +
    scale_fill_manual(values =mycolors) +
    labs(title = title, x = xlab, y = ylab) +
    theme_minimal()
}

# number_curr_df = public_debt[, .(number_curr =.N), 
#                              by = .(president, curr)]
# 
# 
# plot_bar(number_curr_df, president, number_curr, curr, "Number of loans by president", "President", "Number of loans")

