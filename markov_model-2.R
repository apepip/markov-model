# ==============================================================================
# MY FIRST MARKOV MODEL: cost-effectiveness analysis
# ==============================================================================
# IMPORTANT: every number in this model is MADE UP, for learning the mechanics
# only. They do not represent any real drug and must not be used for decisions.
#
# Model question:
#   Is a new, more expensive treatment worth it compared with the current one?
#
# Health states (a person is in exactly one at a time):
#   1. Stable      2. Progression      3. Death (absorbing state: no way out)
#
# Each "cycle" lasts 1 year. In every cycle the cohort moves between states
# according to transition probabilities, and accumulates costs and QALYs
# (quality-adjusted life years) depending on the state it is in.
# ==============================================================================

# --------------------------- 1. ASSUMPTIONS (inputs) --------------------------
states        <- c("Stable", "Progression", "Death")
n_cycles      <- 20        # time horizon: 20 years
cohort        <- 1000      # people who start in the "Stable" state
discount_rate <- 0.03      # annual discount rate for costs and QALYs (assumption:
                           # check the current methodological guideline of your country)

# Transition probabilities per cycle. Each ROW sums to 1.
# Row = starting state, column = destination state.
p_current <- matrix(c(
  0.70, 0.20, 0.10,   # From Stable:      stays / progresses / dies
  0.00, 0.75, 0.25,   # From Progression: never goes back to stable / stays / dies
  0.00, 0.00, 1.00    # From Death:       absorbing
), nrow = 3, byrow = TRUE, dimnames = list(states, states))

p_new <- matrix(c(
  0.80, 0.15, 0.05,   # the new treatment delays progression and lowers mortality
  0.00, 0.75, 0.25,   # once in progression, both treatments behave the same
  0.00, 0.00, 1.00
), nrow = 3, byrow = TRUE, dimnames = list(states, states))

# Costs per person per cycle, in US dollars (USD)
cost_current <- c(Stable = 650,  Progression = 3200, Death = 0)
cost_new     <- c(Stable = 6000, Progression = 3200, Death = 0)
#   The new treatment costs USD 5,350 more per year while the person is stable
#   (the drug itself).

# Utility (quality of life) per state: 1 = perfect health, 0 = death
utility <- c(Stable = 0.80, Progression = 0.50, Death = 0)

# --------------------------- 2. FUNCTION THAT RUNS THE MODEL ------------------
run_model <- function(p, cost, utility, n_cycles, cohort, discount_rate) {
  # "Trace" matrix: one row per cycle, how many people are in each state
  trace <- matrix(0, nrow = n_cycles + 1, ncol = 3,
                  dimnames = list(0:n_cycles, states))
  trace[1, ] <- c(cohort, 0, 0)                # cycle 0: everyone starts Stable

  for (t in 1:n_cycles) {
    trace[t + 1, ] <- trace[t, ] %*% p         # the cohort moves one cycle
  }

  # Half-cycle correction: transitions are assumed to happen mid-cycle, so the
  # start and end of each cycle are averaged.
  trace_hcc <- (trace[1:n_cycles, ] + trace[2:(n_cycles + 1), ]) / 2

  # Discount factor: what happens later is worth less today
  disc <- 1 / (1 + discount_rate)^(1:n_cycles)

  total_cost <- sum((trace_hcc %*% cost)    * disc) / cohort
  total_qaly <- sum((trace_hcc %*% utility) * disc) / cohort

  list(trace = trace, cost = total_cost, qaly = total_qaly)
}

# --------------------------- 3. RUN BOTH STRATEGIES ---------------------------
res_current <- run_model(p_current, cost_current, utility, n_cycles, cohort, discount_rate)
res_new     <- run_model(p_new,     cost_new,     utility, n_cycles, cohort, discount_rate)

# --------------------------- 4. RESULTS: DIFFERENCES AND ICER -----------------
delta_cost <- res_new$cost - res_current$cost
delta_qaly <- res_new$qaly - res_current$qaly
icer       <- delta_cost / delta_qaly    # extra cost per QALY gained

fmt <- function(x) format(round(x), big.mark = ",", decimal.mark = ".", scientific = FALSE)

cat("\n================ RESULTS PER PERSON (discounted) ================\n")
cat("                    Cost (USD)         QALY\n")
cat(sprintf("Current treatment   %15s   %8.3f\n", fmt(res_current$cost), res_current$qaly))
cat(sprintf("New treatment       %15s   %8.3f\n", fmt(res_new$cost),     res_new$qaly))
cat(sprintf("Difference          %15s   %8.3f\n", fmt(delta_cost),       delta_qaly))
cat("\nICER (extra cost per QALY gained): USD", fmt(icer), "\n")
cat("=================================================================\n")

# The decision is compared against a willingness-to-pay threshold.
# This value is an EXAMPLE: each country/agency sets its own.
threshold <- 20000
cat("\nExample threshold: USD", fmt(threshold), "per QALY\n")
if (delta_qaly > 0 && icer <= threshold) {
  cat("-> With these made-up numbers, the new treatment is BELOW the threshold.\n")
} else if (delta_qaly > 0) {
  cat("-> With these made-up numbers, the new treatment is ABOVE the threshold.\n")
} else {
  cat("-> The new treatment adds no extra QALYs.\n")
}

# --------------------------- 5. PLOT: WHERE THE COHORT IS ---------------------
png("markov_trace.png", width = 1200, height = 500, res = 130)
par(mfrow = c(1, 2), mar = c(4.2, 4.2, 3, 1))
colors <- c("#2a9d8f", "#e9a23b", "#7a7a7a")
for (k in 1:2) {
  tr <- if (k == 1) res_current$trace else res_new$trace
  matplot(0:n_cycles, tr, type = "l", lty = 1, lwd = 2.5, col = colors,
          xlab = "Years", ylab = "People in each state",
          main = if (k == 1) "Current treatment" else "New treatment")
  if (k == 1) legend("right", legend = states, col = colors, lwd = 2.5, bty = "n")
}
dev.off()
cat("\nPlot saved as markov_trace.png\n")

# --------------------------- 6. MAXIMUM PRICE BELOW THE THRESHOLD -------------
# The ICER is a straight line of the drug price, so two points are enough to
# draw that line and solve for the price that gives exactly the threshold.
icer_at_price <- function(price) {
  cost_n <- cost_new
  cost_n["Stable"] <- price              # only the drug price changes
  r_n <- run_model(p_new, cost_n, utility, n_cycles, cohort, discount_rate)
  (r_n$cost - res_current$cost) / (r_n$qaly - res_current$qaly)
}

icer_a <- icer_at_price(0)               # ICER if the drug were free
icer_b <- icer_at_price(1000)            # ICER with a price of USD 1,000
slope  <- icer_b - icer_a                # how much the ICER rises per USD 1,000

max_price <- (threshold - icer_a) / slope * 1000

cat("\n---------------- MAXIMUM PRICE ----------------\n")
cat("Slope: the ICER rises by USD", fmt(slope), "for every USD 1,000 of price\n")
cat("Maximum yearly drug price to stay at the threshold: USD", fmt(max_price), "\n")
cat("Check, ICER at that price: USD", fmt(icer_at_price(max_price)), "\n")
