setwd("C:/Users/SCapel/OneDrive - California Department of Fish and Wildlife/Research/Data/R data/")
library("ggplot2")
library("dplyr")

# Data
data <- read.csv("scaff_align_stats.tsv", header = T, sep = "\t")
data$scaff <- factor(data$scaff, levels = c(unique(data$scaff)))
data$size_bin <- cut(data$size, 
                      breaks = c(0,999999,9000000,49000000,99000000,199000000,244374582),
                      labels = c("< 1Mb", "1-9Mb", "10-49Mb", "50-99Mb", "100-199Mb", "200+Mb"))
data$size_bin <- factor(data$size_bin, levels = c("200+Mb", "100-199Mb","50-99Mb", "10-49Mb", "1-9Mb", "< 1Mb"))
data$meanmapq_bin <- cut(data$meanmapq, breaks = c(0,10,20,30,40,50,60),
                          labels = c("0-10", "11-20", "21-30", "31-40", "41-50", "51-60"))
data$meanmapq_bin <- factor(data$meanmapq_bin, levels = c("51-60", "41-50", "31-40", "21-30", "11-20", "0-10"))
top23 <- data[data$scaff %in% c("SUPER__1", "SUPER__2","SUPER__3","SUPER__4","SUPER__5","SUPER__6", "SUPER__7",
                                  "SUPER__8","SUPER__9","SUPER__10", "SUPER__11", "SUPER__12", "SUPER__13", "SUPER__14",
                                  "SUPER__15", "SUPER__16", "SUPER__17", "SUPER__18", "SUPER__19", "SUPER__20",
                                  "SUPER__21", "SUPER__22", "SUPER__23"),]

data_mean <- data %>% group_by(scaff) %>% summarise(mean_cov = mean(cov), 
                                                    mean_qual = mean(meanmapq), 
                                                    mean_depth = mean(meandepth),
                                                    size_bin = unique(size_bin))
top23_mean <- data_mean[c(1:23),]

pops <- read.csv("Population_Map.txt", header = T, sep = "\t")
names(pops) <- c("indiv", "pop", "site", "cov")
data_pop <- left_join(top23, pops, by = "indiv")
data_pop$pop <- factor(data_pop$pop, levels = c("NY PRE", "NY POST", "PA PRE", "PA POST"))
d <- data_pop %>%
  arrange(factor(pop, levels = c("NY PRE", "NY POST", "PA PRE", "PA POST")))
d$indiv <- factor(d$indiv, levels = c(unique(d$indiv)))
pal <- c("#DDCC77", "#CC872F", "#44AA99", "#117733")

out <- rbind(data[data$scaff == "SUPER__211", ], data[data$scaff == "SUPER__212", ])

lowcov <- read.csv("LowCov_scaff_align_stats.tsv", header = T, sep = "\t")
hicov <- read.csv("HiCov_scaff_align_stats.tsv", header = T, sep = "\t")
hicov$size_bin <- cut(hicov$size, breaks = c(0,999999,9000000,49000000,99000000,199000000,244374582),
             labels = c("< 1Mb", "1-9Mb", "10-49Mb", "50-99Mb", "100-199Mb", "200+Mb"))
hicov$size_bin <- factor(hicov$size_bin, levels = c("200+Mb", "100-199Mb","50-99Mb", "10-49Mb", "1-9Mb", "< 1Mb"))
hicov_mean <- hicov %>% group_by(scaff) %>% summarise(mean_cov = mean(cov), 
                                                    mean_qual = mean(meanmapq), 
                                                    mean_depth = mean(meandepth),
                                                    size_bin = unique(size_bin))

allsamps <- rbind(hicov, lowcov)
allsamps_pop <- left_join(allsamps, pops, by = "indiv")
allsamps_pop_top23 <- allsamps_pop[allsamps_pop$scaff %in% c("SUPER__1", "SUPER__2","SUPER__3","SUPER__4","SUPER__5","SUPER__6", "SUPER__7",
                                "SUPER__8","SUPER__9","SUPER__10", "SUPER__11", "SUPER__12", "SUPER__13", "SUPER__14",
                                "SUPER__15", "SUPER__16", "SUPER__17", "SUPER__18", "SUPER__19", "SUPER__20",
                                "SUPER__21", "SUPER__22", "SUPER__23"),]
allsamps_pop_top23$pop <- factor(allsamps_pop_top23$pop, levels = c("NY PRE", "NY POST", "PA PRE", "PA POST"))
aspt23 <- allsamps_pop_top23 %>%
  arrange(factor(pop, levels = c("NY PRE", "NY POST", "PA PRE", "PA POST")))
aspt23$indiv <- factor(aspt23$indiv, levels = c(unique(aspt23$indiv)))


# Individual depth of coverage (LowCov all scaffolds)
ggplot(d, aes(x = indiv, y = meandepth)) +
  geom_boxplot(aes(fill = factor(pop)), outlier.shape = 21, outlier.size = 1) +
  labs(fill = "Populaiton", title = "HiC Alignment: Low Coverage Samples", subtitle = "top 23 scaffolds") +
  xlab("Sample") +
  ylab("Mean depth/scaffold") +
  annotate("text", x = 44, y = 42, label = "Mean depth = 22.42") +  # mean depth across entire genome for all individuals
  scale_fill_manual(values = pal) +
  scale_color_manual(values = pal) + 
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), 
        panel.background = element_blank(), 
        panel.border = element_rect(color = "darkgrey", fill = NA, size = 0.5))

# Individual depth of coverage - ALL individuals, top 23 scaffolds
covlabs <- c(`High` = "High (mean = 46.1)", `Low` = "Low (mean = 22.1)")
ggplot(aspt23, aes(x = indiv, y = meandepth)) +
  geom_boxplot(aes(fill = factor(pop)), outlier.shape = 21, outlier.size = 1, lwd = 0.25) +
  labs(fill = "Populaiton", title = "HiC Alignment: All Samples by Coverage", subtitle = "top 23 scaffolds") +
  xlab("Sample") +
  ylab("Mean depth/scaffold") +
  facet_grid(. ~ cov.y, scales = "free", space = "free", labeller = as_labeller(covlabs)) +
  scale_fill_manual(values = pal) +
  scale_color_manual(values = pal) + 
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), 
        panel.background = element_blank(), 
        panel.border = element_rect(color = "darkgrey", fill = NA, linewidth = 0.5))


# LowCov alignment by scaffold
## Samples plotted individually
ggplot(data, aes(x = meanmapq, y = cov, color = size_bin)) +
  geom_point(alpha = 0.35, shape = 16, size = 1) +
  geom_point(top23, mapping = aes(x = meanmapq, y = cov, color = size_bin), shape = 21, alpha = 0.75, size = 1.5) +
  scale_x_continuous(expand = c(0.005,0), limits = c(0,60)) +
  scale_y_continuous(expand = c(0.005,0.005)) +
  labs(color = "Scaffold Size", title = "Scaffold Alignment Quality - LowCov samples plotted individually", 
       subtitle = "Top 23 scaffolds outlined") +
  xlab("Scaffold Mean Map Quality (Phred Score)") +
  ylab("Scaffold Coverage (%)") +
  theme(panel.background = element_blank(), panel.border = element_rect(linewidth = 0.5, color = "darkgrey", fill = NA))

# Sample mean
ggplot(data_mean, aes(x = mean_qual, y = mean_cov, color = size_bin)) +
  geom_point(shape = 16, size = 1) +
  geom_text(top23_mean, mapping = aes (x = mean_qual, y = mean_cov, color = size_bin, label = scaff), 
            size = 2.5, vjust = c(rep(c(2,-1.5,-1,4),5),1.5,-1,3), 
            hjust = c(rep(0.5,10),rep(1,5), rep(2,5),0.5,0.1,0.1)) +
  scale_x_continuous(expand = c(0.01,0), limits = c(0,60)) +
  scale_y_continuous(expand = c(0,4)) +
  labs(color = "Scaffold Size", title = "Mean Scaffold Alignment Quality - samples lumped") +
  xlab("Mean Scaffold Map Quality (Phred Score)") +
  ylab("Mean Scaffold Coverage (%)") +
  theme(panel.background = element_blank(), panel.border = element_rect(size = 0.5, color = "darkgrey", fill = NA))

# Mean depth boxplots
ggplot(data, aes(x = scaff, y = meandepth)) +
  geom_boxplot(outlier.size = 0.2, lwd = 0.2) +
  geom_hline(yintercept = 0) +
  geom_boxplot(top23, mapping = aes(x = scaff, y = meandepth), color = "darkblue", outlier.size = 0.2, lwd = 0.2) +
  geom_boxplot(out, mapping = aes(x = scaff, y = meandepth), color = "firebrick3", outlier.size = 0.2, lwd = 0.2) +
  ylab("mean depth") +
  xlab("scaffold") +
  theme(panel.background = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), axis.line.y = element_line(color = "black"))
ggplot(data, aes(x = scaff, y = meandepth)) +
  geom_boxplot(outlier.size = 0.2, lwd = 0.2) +
  geom_hline(yintercept = 0) +
  geom_boxplot(top23, mapping = aes(x = scaff, y = meandepth), color = "darkblue", outlier.size = 0.2, lwd = 0.2) +
  geom_boxplot(out, mapping = aes(x = scaff, y = meandepth), color = "firebrick3", outlier.size = 0.2, lwd = 0.2) +
  ylab("mean depth (log scale)") +
  xlab("scaffold") +
  scale_y_log10() +
  theme(panel.background = element_blank(), axis.text.x = element_blank(), 
        axis.ticks.x = element_blank(), axis.line.y = element_line(color = "black"))

allsamps_out <- allsamps[allsamps$scaff %in% c("SUPER__211", "SUPER__212"),]
mt <- read.csv("ALL_mtDNA_align_stats.tsv", header = T, sep = "\t")
mt_scaffs <- rbind(allsamps_out, mt)
mt_scaffs$scaff <- factor(mt_scaffs$scaff, levels = c("SUPER__211", "SUPER__212", "SUPER__211:255-17730"))

ggplot(mt_scaffs, aes(x = scaff, y = meandepth)) +
  geom_boxplot(outlier.size = 0.2, lwd = 0.2) +
  geom_hline(yintercept = 0) +
  scale_y_continuous(expand = c(0.01,0)) +
  ylab("mean depth") +
  theme(panel.background = element_blank(), axis.ticks.x = element_blank(), 
        axis.title.x = element_blank(), axis.line.y = element_line(color = "black"))

# write.csv(data_mean, row.names = F, col.names = T, file = "LowCov_scaffold_mean_align_stats.csv")
# write.csv(hicov_mean, row.names = F, col.names = T, file = "HiCov_scaffold_mean_align_stats.csv")


# Mean coverage of individuals by 50kb windows across scaffolds
mc_low <- read.csv("LowCov_50kbwin_meandepth.tsv", header = T, sep = "\t")
mc_hi <- read.csv("HiCov_50kbwin_meandepth.tsv", header = T, sep = "\t")
axis_set <- mc_low %>% group_by(scaff) %>% summarise(center = mean(center_cum), end = max(end_cum))
axis_set$scaff <- gsub("SUPER__","",axis_set$scaff)

ggplot(mc_hi, aes(x = center_cum, y = mean_depth, color = as.factor(scaff))) +
  geom_point(alpha = 0.2, size = 0.5, shape = 16) +
  #geom_vline(xintercept = axis_set$end, linetype = "dashed", linewidth = 0.1) +
  geom_hline(yintercept = 46.1, linetype = "dashed") +
  scale_x_continuous(label = axis_set$scaff, breaks = axis_set$center, expand = c(0.005,0.005)) +
  scale_y_log10(expand = c(0.01,0.01)) +
  scale_color_manual(values = rep(c("#69BACF", "#4B8A9A"), unique(length(axis_set$scaff)))) +
  xlab("Scaffold") +
  ylab("Mean depth") +
  labs(title = "Mean depth of coverage by 50kb windows", 
       subtitle = "HiCov samples; overall mean = 46.1 (dashed line)") +
  theme(legend.position = "none", panel.background = element_blank(), 
        axis.ticks.x = element_blank(), axis.text.x = element_text(size = 8),
        axis.line.y = element_line(color = "#545454", size = 0.5))

ggplot(mc_low, aes(x = center_cum, y = mean_depth, color = as.factor(scaff))) +
  geom_point(alpha = 0.1, size = 0.5, shape = 16) +
  #geom_vline(xintercept = axis_set$end, linetype = "dashed", linewidth = 0.1) +
  geom_hline(yintercept = 22.1, linetype = "dashed") +
  scale_x_continuous(label = axis_set$scaff, breaks = axis_set$center, expand = c(0.005,0.005)) +
  scale_y_log10(expand = c(0.01,0.01)) +
  scale_color_manual(values = rep(c("#69BACF", "#4B8A9A"), unique(length(axis_set$scaff)))) +
  xlab("Scaffold") +
  ylab("Mean depth") +
  labs(title = "Mean depth of coverage by 50kb windows", 
       subtitle = "LowCov samples; overall mean = 22.1 (dashed line)") +
  theme(legend.position = "none", panel.background = element_blank(), 
        axis.ticks.x = element_blank(), axis.text.x = element_text(size = 8),
        axis.line.y = element_line(color = "#545454", size = 0.5)))

