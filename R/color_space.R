library(colorspace)

# Function to calculate color distances and filter similar colors
filter_similar_colors <- function(colors = mycolors, threshold = 10) {
    # Convert hex colors to LAB color space
    lab_colors <- hex2RGB(colors) %>% as("LAB")
    
    # Calculate pairwise distances between colors
    color_distances <- as.matrix(dist(lab_colors@coords))
    
    # Create a logical vector to keep track of which colors to keep
    keep <- rep(TRUE, length(colors))
    
    # Loop through each color and compare with others
    for (i in seq_along(colors)) {
        if (keep[i]) {
            for (j in seq_along(colors)) {
                if (i != j && color_distances[i, j] < threshold) {
                    keep[j] <- FALSE
                }
            }
        }
    }
    
    # Return filtered colors
    return(colors[keep])
}


mycolors <- c("#386CB0", "#F0027F", "#BF5B17", "#1B9E77", "#D95F02", "#7570B3", 
              "#66A61E", "#E6AB02", "#A6761D", "#2BB07FFF", "#C2DF23FF", "#38598CFF", 
              "#482173FF", "#85D54AFF", "#1E9B8AFF", "#51C56AFF", "#FDE725FF", 
              "#2D708EFF", "#433E85FF", "#25858EFF", "#440154FF", "#7FC97F", 
              "#E7298A", "#BEAED4", "#FDC086")

filtered_colors <- filter_similar_colors(mycolors)

# Print the filtered colors
scales::show_col(filtered_colors)
