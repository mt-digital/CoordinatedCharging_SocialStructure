require(ggplot2)
require(latex2exp)
require(dplyr)
require(readr)
require(purrr)
require(reshape2)
require(stringr)

mytheme = theme(axis.line = element_line(), legend.key=element_rect(fill = NA),
                text = element_text(size=22),# family = 'PT Sans'),
                # axis.text.x = element_text(size=12),
                # axis.text.y=  element_text(size=12), 
                panel.background = element_rect(fill = "white"))

supp_asymm_heatmaps <- function(csv_dir = "data/supp_parts", write_dir = "figures/supp") {
  neighborhood_w_vals <- c("1", "2", "Both")
  
  # neighborhood_w_vals <- c("1")
  for (neighborhood_w_innovation in neighborhood_w_vals) {
    
    files <- list.files(csv_dir, 
                        pattern = paste0("neighborhood_w_innovation=", neighborhood_w_innovation),
                        full.names = TRUE)
    
    tbl_part <- files %>%
      map_df(~read_csv(., show_col_types = FALSE))
    
    tbl_part$neighborhood_w_innovation = neighborhood_w_innovation
    
    if (neighborhood_w_innovation == "1") {
      tbl <- tbl_part
    }
    else {
      tbl <- rbind(tbl, tbl_part)
    }
  }
  
  for (neighborhood_w_innovation in neighborhood_w_vals) {
    # nagents sensitivity.
    for (this_nagents in c(50, 100, 200)) {
      
      this_tbl <- tbl[tbl$nagents == this_nagents, ]
      this_write_dir <- file.path(write_dir, "nagents", this_nagents)
      write_path <- file.path(this_write_dir, paste0(neighborhood_w_innovation, ".pdf"))
      
      asymm_heatmap(this_tbl, neighborhood_w_innovation, write_path)
    }
    # minority neighborhood size sensitivity.
    for (this_neighborhood_1_frac in c(0.2, 0.35, 0.5)) {
      
      this_tbl <- tbl[tbl$neighborhood_1_frac == this_neighborhood_1_frac, ]
      this_write_dir <- file.path(write_dir, "m", this_neighborhood_1_frac)
      write_path <- file.path(this_write_dir, paste0(neighborhood_w_innovation, ".pdf"))
      
      asymm_heatmap(this_tbl, neighborhood_w_innovation, write_path)
    }
    # f(a) sensitivity.
    for (this_a_fitness in c(1.05, 1.4, 2.0)) {
      
      this_tbl <- tbl[tbl$a_fitness == this_a_fitness, ]
      this_write_dir <- file.path(write_dir, "a_fitness", this_a_fitness)
      write_path <- file.path(this_write_dir, paste0(neighborhood_w_innovation, ".pdf"))
      
      asymm_heatmap(this_tbl, neighborhood_w_innovation, write_path)
    }
  }

  
  # 
}

main_asymm_heatmaps <- function(csv_dir = "data/main_parts", write_dir = "figures/heatmaps/main", measure = "success_rate")
{
  
  # for (group_w_innovation in c(1, 2, "Both")) {
  neighborhood_w_vals <- c("1", "2", "Both")
  # group_w_vals <- c("1")
  for (neighborhood_w_innovation in neighborhood_w_vals) {
    
    files <- list.files("data/main_parts", 
                        pattern = paste0("neighborhood_w_innovation=", 
                                         neighborhood_w_innovation),
                        full.names = TRUE)
    
    tbl_part <- files %>%
      map_df(~read_csv(., show_col_types = FALSE))
    
    tbl_part$neighborhood_w_innovation = neighborhood_w_innovation
    
    if (neighborhood_w_innovation == "1") {
      tbl <- tbl_part
    }
    else {
      tbl <- rbind(tbl, tbl_part)
    }
  }
  
  print(tbl) 
  
  # return (asymm_heatmap(tbl, neighborhood_w_innovation, file.path(write_dir, paste0(neighborhood_w_innovation, ".pdf"))))
  
  for (neighborhood_w_innovation in neighborhood_w_vals) {
    
    asymm_heatmap(tbl, neighborhood_w_innovation, 
                  file.path(write_dir, paste0(neighborhood_w_innovation, ".pdf")),
                  measure)

  }
}


asymm_heatmap <- function(asymm_tbl, this_neighborhood_w_innovation, write_path, measure = "success_rate") {
  
  asymm_agg <- asymm_tbl %>%
    filter(home_is_work_prob_1 != 0.99) %>% 
    filter(home_is_work_prob_2 != 0.99) %>%
    group_by(home_is_work_prob_1, home_is_work_prob_2, neighborhood_w_innovation) %>%
    summarize(success_rate = mean(frac_a_curr_trait),
              step = mean(step))
  # return (asymm_agg)
    # asymm_tbl %>% 
    #   subset(group_w_innovation == this_group_w_innovation)
  asymm_lim_agg <- asymm_agg[asymm_agg$neighborhood_w_innovation == this_neighborhood_w_innovation, ]
  
  print(unique(asymm_lim_agg$neighborhood_w_innovation))
  print(head(asymm_lim_agg))
  
  # asymm_lim_aggregated <- asymm_lim_aggregated %>%
  
  if (measure == "success_rate") {
  
    asymm_max_line <-
      asymm_lim_agg %>% 
        group_by(home_is_work_prob_1) %>% 
        filter(success_rate == max(success_rate))
    
    print(asymm_max_line)
    max_success_rate <- 
      asymm_max_line[asymm_max_line$success_rate == 
                       max(asymm_max_line$success_rate), ]
  } else if (measure == "step") {
    asymm_max_line <-
      asymm_lim_agg %>% 
      group_by(home_is_work_prob_1) %>% 
      filter(step == max(step))
    
    print(asymm_max_line)
    max_success_rate <- 
      asymm_max_line[asymm_max_line$step == 
                       max(asymm_max_line$step), ]
  } else {
    stop ("measure not recognized")
  }
  
  h1max <- max_success_rate$home_is_work_prob_1
  h2max <- max_success_rate$home_is_work_prob_2
  
  # print(paste("Maximum success_rate ", max_success_rate$success_rate[1], ", at h1 = ", h1max, " h2 = ", h2max))
  
  if (measure == "success_rate") {
    ggplotstart <- ggplot(asymm_lim_agg, aes(x = home_is_work_prob_1, y = home_is_work_prob_2, fill = success_rate))
    measure_label <- "Success\nrate"
  } else if (measure == "step") {
    ggplotstart <- ggplot(asymm_lim_agg, aes(x = home_is_work_prob_1, y = home_is_work_prob_2, fill = step))
    measure_label <- "Mean steps"
  } else {
    stop("Measure not recognized.")
  }
  
   ggplotstart + 
    geom_tile() +
    scale_fill_gradient2(low = "#000000", mid = "#010101", high = "#FFFFFF") +
    geom_point(data = asymm_max_line, aes(x = home_is_work_prob_1, y = home_is_work_prob_2)) +
    geom_smooth(data = asymm_max_line, aes(x = home_is_work_prob_1, y = home_is_work_prob_2), se=FALSE) +

    geom_point(data = max_success_rate, aes(x=home_is_work_prob_1, y=home_is_work_prob_2), 
               shape='diamond', size=5, color='red') +

    labs(x = TeX("Minority neighborhood home-work corr., $w_{min}"), 
         y = TeX("Majority neighborhood home-work corr., $w_{maj}")) +

    coord_fixed() + labs(fill = measure_label) +
    mytheme
    
  # save_path <- file.path(write_dir, str_replace(basename(csv_loc), ".csv", ".pdf"))
  
  ggsave(write_path, width = 6.75, height = 5)
}


plot_neighborhood_freq_series <- function(csv_loc, write_dir = "figures/neighborhood_prevalence") {

    df <- read.csv(csv_loc)
    names(df) <- c("step", "frac_a", "Minority", "Majority", "Trial")
    df <- df[c("step", "Majority", "Minority", "Trial")]
    enslim <- 10
    df <- filter(df, Trial <= enslim)
    df$Trial = factor(df$Trial, levels = 1:enslim)
  
  df <- melt(df, id=c("step", "Trial"), value.name = "Frequency", variable.name = "Neighborhood")

  ggplot(df, aes(x=step, y=Frequency)) + 
    geom_line(aes(color=Trial, linetype=Neighborhood), lwd=0.8) +
    # geom_line(aes(x=step, y=frac_a_max, color=Trial, linetype="Majority"), linetype=1, lwd=1.05) +
    xlab("Step") + ylab(TeX(r"(Coord. charging prevalence)")) +
    # scale_linetype_manual(name = "Group", values=c("Majority", "Minority"), labels = c("Majority", "Minority")) +
    mytheme #+ guides(color=guide_legend(override.aes=list(fill=NA))) 
  
  save_path <- file.path(write_dir, str_replace(basename(csv_loc), ".csv", ".pdf"))
  
  ggsave(save_path, width = 7.5, height = 4.65)
}
