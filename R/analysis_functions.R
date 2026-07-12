# Reusable analysis helpers for the June 2025 KSh register ---------------------

kes_billions <- function(x) {
    paste0("KES ", scales::comma(x / 1e9, accuracy = 0.1), " bn")
}

kes_trillions <- function(x) {
    paste0("KES ", scales::number(x / 1e12, accuracy = 0.001), " tn")
}

add_presidential_period <- function(data) {
    periods <- data.table::data.table(
        president = c(
            "Jomo Kenyatta", "Daniel arap Moi", "Mwai Kibaki",
            "Uhuru Kenyatta", "William Ruto"
        ),
        start_date = as.Date(c(
            "1963-12-12", "1978-08-22", "2002-12-30",
            "2013-04-09", "2022-09-13"
        )),
        end_date = as.Date(c(
            "1978-08-22", "2002-12-30", "2013-04-09",
            "2022-09-13", "9999-12-31"
        ))
    )

    data[, president := NA_character_]
    for (i in seq_len(nrow(periods))) {
        data[
            agreement_date >= periods$start_date[i] &
                agreement_date < periods$end_date[i],
            president := periods$president[i]
        ]
    }
    data
}

add_maturity_bucket <- function(data, reporting_date) {
  years_to_maturity <- as.numeric(
    data$maturity_date - reporting_date
  ) / 365.25
  data[, maturity_bucket := cut(
        years_to_maturity,
        breaks = c(-Inf, 0, 1, 3, 5, 10, Inf),
        labels = c("Matured", "Within 1 year", "1-3 years", "3-5 years",
                   "5-10 years", "More than 10 years"),
        right = TRUE
    )]
    data
}

external_debt_theme <- function() {
    ggplot2::theme_minimal(base_size = 11) +
        ggplot2::theme(
            plot.title.position = "plot",
            plot.title = ggplot2::element_text(face = "bold", size = 13),
            plot.subtitle = ggplot2::element_text(colour = "#4b5563"),
            panel.grid.minor = ggplot2::element_blank(),
            legend.position = "bottom"
        )
}

plot_kes_bar <- function(data, x, y, title, subtitle = NULL,
                         fill = "#386CB0", horizontal = TRUE) {
    plot <- ggplot2::ggplot(data, ggplot2::aes(x = {{ x }}, y = {{ y }})) +
        ggplot2::geom_col(fill = fill, width = 0.7) +
        ggplot2::scale_y_continuous(
            labels = function(value) scales::label_number(
                scale = 1e-9, suffix = " bn", accuracy = 1
            )(value),
            expand = ggplot2::expansion(mult = c(0, 0.08))
        ) +
        ggplot2::labs(
            title = title, subtitle = subtitle,
            x = NULL, y = "Outstanding debt (KES billions)"
        ) +
        external_debt_theme()

    if (horizontal) plot <- plot + ggplot2::coord_flip()
    plot
}
