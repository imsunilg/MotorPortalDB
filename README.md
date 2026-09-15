# MotorPortalDB

PostgreSQL database schema, scripts, functions, procedures and seed data for the Motor Portal application.

Database: `SGInsuranceDB` · Schema: `SGInsurance` · Engine: PostgreSQL 15+

## Progress

- [ ] Bootstrap (ground rules, README, .gitignore)
- [ ] 15 core tables + FKs + indexes
- [ ] PL/pgSQL functions & procedures (premium, GST, proposal/policy numbers, validation, payment, lifecycle)
- [ ] Reporting view `vw_policy_issue_report`
- [ ] Seed data (admin user, products, functions, master policies, sample batches)
- [ ] migrate.sh / rollback.sql verified end-to-end
