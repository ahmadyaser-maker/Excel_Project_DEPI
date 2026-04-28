
#  Manufacturing Downtime Analysis

> **A full-cycle data analytics project** — from raw industrial machine data to a professional Excel dashboard and executive presentation.  
> Built by Team 1 · Supervised by **Dr. Amal Mahmoud**

---

##  Project Overview

This project analyzes **10,000 real-world manufacturing operation records** across 20 machines, 4 machine types, and 4 brands to uncover failure patterns, measure operational efficiency, and deliver actionable maintenance intelligence.

The end deliverable is a management-ready Excel dashboard and a polished presentation covering the full data analytics pipeline — from raw data to business insight.

---

##  Objectives

- Measure machine efficiency using **OEE** (Overall Equipment Effectiveness)
- Identify root causes of **downtime and failure events**
- Calculate key manufacturing KPIs: **MTBF, MTTR, Availability, Performance, Quality**
- Build a **management-level dashboard** for decision support
- Enable a shift from **corrective → preventive → predictive** maintenance

---

##  Repository Structure

```
manufacturing-downtime-analysis/
│
├── data/
│   ├── cleaned_data.xlsx          # Cleaned operational dataset (10,000 records)
│   └── D.xlsx                     # Raw source data
│
├── dashboard/
│   └── Manufacturing_Dashboard.xlsx   # 5-sheet Excel dashboard
│
├── presentation/
│   └── manufacturing_downtime.pptx    # 15-slide team presentation
│
├── analysis/
│   └── insights_summary.md        # Key findings and recommendations
│
└── README.md
```

---

##  Dataset

| Field | Detail |
|---|---|
| **Records** | 10,000 hourly machine observations |
| **Period** | January – December 2025 |
| **Machines** | 20 unique machines (M001–M020) |
| **Machine Types** | CNC · Lathe · Press · Conveyor |
| **Brands** | ABB · Bosch · GE · Siemens |
| **Features** | 31 columns including RPM, Torque, Tool Wear, Failure Flags, Maintenance Type/Cost, Downtime, Production Units, Defect Rate |

---

##  Key Findings

| Metric | Value |
|---|---|
| Overall Failure Rate | **3.4%** (339 events) |
| Average OEE | **~49%** (world class = 85%) |
| Average Availability | **93.2%** |
| Average Performance | **53.4%** ← #1 loss driver |
| Average Quality | **98.4%** |
| MTBF | **43.8 hours** |
| MTTR | **2.98 hours** |
| Corrective Maintenance Cost | **$633 avg** (vs $175 preventive) |
| Peak Failure Month | **July — 11.4% failure rate** |
| Highest Risk Machine | **M017 & M007 (Bosch Lathe/Press) — 24 failures each** |

---

##  Dashboard Sheets

The Excel dashboard contains **5 fully formatted, color-coded sheets**:

| Sheet | Description |
|---|---|
| 📊 Dashboard | Main command center — KPI cards, 6 charts, insights panel |
| 📈 OEE Analysis | Monthly OEE breakdown vs world-class benchmarks |
| 🔧 Machine Analysis | All 20 machines ranked by risk level |
| 🛠 Maintenance & Failure | Cost comparison, failure types, early warning flags |
| 📋 Data Sample | First 500 rows of cleaned data with failure highlighting |

---

## 🧠 Methodology

```
Raw Data → Data Cleaning → Data Modeling → KPI Calculation → Dashboard → Insights
```

1. **Data Cleaning** — Validated nulls, enforced logical constraints (downtime ≥ 0, production ≥ 0), preserved edge cases
2. **Data Modeling** — Designed a star schema with Fact + 5 Dimension tables (Machine, Product, Time, Failure, Maintenance)
3. **KPI Framework** — Calculated OEE components, MTBF, MTTR, Cost Per Failure using domain-standard formulas
4. **Dashboard** — Built in Excel with embedded charts, conditional formatting, and executive-ready layout
5. **Presentation** — 15-slide deck covering the full analysis pipeline

---

## ⚡ Key Insights

- **Performance is the #1 OEE gap** — machines run at only 53% of maximum RPM, not because of breakdowns but operational settings. Fixing speed alone could raise OEE by ~20 percentage points.
- **June–July seasonal spike** — failure rates jump from 3.4% average to 9% (June) and 11.4% (July), almost certainly heat-related. Pre-summer inspections are strongly recommended.
- **Corrective maintenance costs 3.6× more** than preventive ($633 vs $175 per event). Shifting to flag-based intervention pays for itself immediately.
- **Tool wear threshold** — failure rate climbs from 2.2% below 150 min to 15.5% past 200 min. Replace tools before 180 minutes.
- **Early warning flags work** — when any single failure flag fires (HDF, OSF, PWF, TWF), the machine fails 94.4% of the time. A rules-based alert system on these 5 flags would intercept most failures before breakdown.

---

## 👥 Team

| Name | Contact |
|---|---|
| Ahmed Yasser | [linkedin.com/in/ahmedyassermousa](https://linkedin.com/in/ahmedyassermousa) · 01555804012 |
| Mohamed El-Nady | [linkedin.com/in/mohamed--el-nady](https://linkedin.com/in/mohamed--el-nady) · 01152455483 |
| Mohamed Adel | — |
| Abdulrahman Mohamed | [linkedin.com/in/abdulrahman-salahuddin](https://linkedin.com/in/abdulrahman-salahuddin) · 01551474804 |

**Supervisor:** Dr. Amal Mahmoud

---

## 🛠 Tools Used

![Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=flat&logo=microsoft-excel&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=flat&logo=pandas&logoColor=white)
![PowerPoint](https://img.shields.io/badge/PowerPoint-B7472A?style=flat&logo=microsoft-powerpoint&logoColor=white)

- **Python / Pandas / NumPy** — data cleaning, EDA, KPI calculation
- **openpyxl** — programmatic Excel dashboard generation
- **Microsoft Excel** — final dashboard and formatting
- **PowerPoint** — executive presentation (15 slides)

---

## 📄 License

This project was created for academic purposes as a final project submission.  
© 2025 Team 1 — All rights reserved.
