# Markov cost-effectiveness model in R

*[Versión en español](README.es.md)*

My first health economic evaluation model: it compares a new, more expensive treatment against the current one and calculates the cost per QALY gained (ICER).

> **Disclaimer:** every number in this model is **made up** and used only to learn the mechanics. They do not represent any real drug and must not be used for decisions.

## What the model does

- **Three health states:** Stable, Progression and Death (absorbing state).
- **Yearly cycles** over 20 years, with a cohort of 1,000 people starting in Stable.
- **Half-cycle correction** and **discounting** of costs and QALYs (3% in the base case).
- **Outputs:** cost and QALYs per person for each treatment, differences, ICER, comparison against a willingness-to-pay threshold (USD 20,000 per QALY, an example value) and the maximum drug price that keeps the ICER under that threshold.

All costs are in US dollars (USD).

## Base case

| | Cost per person | QALYs |
|---|---|---|
| Current treatment | USD 8,648 | 3.149 |
| New treatment | USD 30,706 | 4.263 |
| Difference | USD 22,058 | 1.114 |

**ICER: USD 19,805 per QALY gained**, just below the example threshold.

![Cohort trace for both treatments](markov_trace.png)

## Sensitivity analysis

I changed one assumption at a time and compared with the base case.

| Change | ICER (USD per QALY) | Below USD 20,000? |
|---|---|---|
| Base case (3% discount, new drug price USD 6,000/year) | 19,805 | Yes, barely |
| Discount rate 0% | 18,095 | Yes |
| Discount rate 5% | 20,971 | **No** |
| New drug price USD 4,000/year | 12,823 | Yes |
| New drug price USD 2,000/year | 5,841 | Yes |
| New drug price USD 1,500/year | 4,096 | Yes |
| New treatment with the same mortality as the current one, price USD 2,000 | Undefined | No extra QALYs (dominated) |

## What I learned

- **Discounting** changes how much the future weighs. The new treatment spends early and gains life years late, so a higher discount rate raises the ICER. Here, moving from 3% to 5% is enough to flip the conclusion.
- **The ICER is a straight line of the price, not a proportion.** Each USD 1,000 less in price lowers the ICER by about USD 3,500, but a price of zero does not give an ICER of zero (it is about -USD 1,100), because the new treatment still reduces progression costs.
- **Maximum price:** in the base case the drug can cost up to about USD 6,056 per year and still stay at the threshold (about USD 5,740 with a 5% discount rate and USD 6,607 with 0%).
- **No benefit, no ICER:** if the new treatment does not improve survival there are no extra QALYs and the indicator is meaningless.

## How to run it

1. Install R.
2. Open `markov_model.R` and run the whole script.
3. It prints results to the console and saves the plot as `markov_trace.png`.

No external packages are required.

## Next steps

- Re-implement it with the `heemod` package.
- Probabilistic sensitivity analysis.
- Replicate a published model and compare results.
