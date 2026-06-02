# Excel formula/value discrepancies - 1405 payroll workbook

During validation, most extracted salary rows matched the implemented formulas.
Two rows have cached worksheet values that do not match the visible formulas:

- Personnel code 8, مجتبی کاربخش: `لیست حقوق!P13` has formula-based overtime inconsistent with the cached value after the daily wage was manually overridden to `20,000,000`.
- Personnel code 13, هادی جدی شریف 2: `لیست حقوق!H18` and dependent totals are cached/manual values that do not match `totalDays * dailyWage1405`.
- Personnel code 11, جعفر غنیشاهی: insurance base is cached as `0` despite positive earnings.
- Personnel code 14, شعبانعلی مسعودی: insurance base is cached as `0` despite positive earnings.
- Personnel code 16, مهدی صالحی 2: insurance base is cached as `0` despite positive earnings.

The app calculation engine follows the visible formulas. The extracted reference asset still preserves the cached Excel salary records for audit/reference seeding.
