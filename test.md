---
title: "Test Document: docdesigner-template v1.0"
subtitle: "Compilation Test Suite"
author:
  - name: "Test Author"
    department: "Department of Sociology"
    institution: "Test University"
    address: "123 Main Street"
    city: "Anytown"
    zip: "12345"
    country: "USA"
    email: "author@test.edu"
    orcid: "0000-0000-0000-0000"
institution: "Household Finance Working Group"
series: "Snapshot"
number: 1
surname: "Author"
runningtitle: "docdesigner-template Test"
date: "March 2026"
abstract: |
  This document tests all major features of docdesigner-template. It exercises
  font presets, anonymize mode, line numbers, bibliography, code blocks,
  and the running header. Compile under both pdfLaTeX and XeLaTeX to verify
  each configuration.
keywords: [LaTeX, template, Pandoc, sociology]
# fontset: humanities       # uncomment to test each preset
# fontset: demography
# fontset: methods
# fontpath: ~/Templates/docdesigner/fonts/   # set if using managed template
anonymize: false             # also test with: true
linenumbers: true
doublespace: false
numbersections: true
# maincolumns: 2            # uncomment to test two-column + references fix
bibliography: test.bib
csl: default.csl
---

# Section 1: Body Text

This paragraph tests basic body text rendering. The quick brown fox jumps over
the lazy dog. Pellentesque habitant morbi tristique senectus et netus et
malesuada fames ac turpis egestas. Aenean commodo ligula eget dolor.

## Subsection: Emphasis and Math

Standard emphasis: *italic text*, **bold text**, and `inline code`.

Display math:
$$
\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i
$$

Inline math: $\beta = (X^\top X)^{-1} X^\top y$.

## Subsection: Citation

The quick citation test [@Author2020; @Smith2019].

# Section 2: Code Block

The methods fontset uses Source Serif Pro with Fira Code for monospace.
This block tests monospace rendering:

```r
fit <- lm(y ~ x1 + x2, data = mydata)
summary(fit)
coef(fit)["x1"]
```

```python
import pandas as pd
df = pd.DataFrame({"x": [1, 2, 3], "y": [4, 5, 6]})
print(df.describe())
```

# Section 3: Table

| Variable | Mean   | SD     | N    |
|----------|-------:|-------:|-----:|
| Income   | 52,400 | 18,200 | 1024 |
| Age      | 41.3   | 12.7   | 1024 |
| Educ     | 14.1   | 2.8    | 1024 |

: Descriptive Statistics {#tbl-desc}

# Section 4: Long Paragraph

This section tests line spacing and line numbering interaction. Lorem ipsum
dolor sit amet, consectetur adipiscing elit. Maecenas tempus, tellus eget
condimentum rhoncus, sem quam semper libero, sit amet adipiscing sem neque
sed ipsum. Nam quam nunc, blandit vel, luctus pulvinar, hendrerit id, lorem.
Maecenas nec odio et ante tincidunt tempus. Donec vitae sapien ut libero
venenatis faucibus. Nullam quis ante. Etiam sit amet orci eget eros faucibus
tincidunt. Duis leo. Sed fringilla mauris sit amet nibh. Donec sodales sagittis
magna. Sed consequat, leo eget bibendum sodales, augue velit cursus nunc.

---

*Compilation checklist:*

- [ ] Default fontset, pdfLaTeX
- [ ] Default fontset, XeLaTeX
- [ ] fontset: humanities, XeLaTeX (EB Garamond)
- [ ] fontset: demography, pdfLaTeX (tgtermes)
- [ ] fontset: demography, XeLaTeX (XITS)
- [ ] fontset: methods, XeLaTeX (Source Serif + Fira Code)
- [ ] anonymize: true
- [ ] maincolumns: 2 (verify references revert to one column)
- [ ] linenumbers: true with doublespace: true (verify warning in log)
