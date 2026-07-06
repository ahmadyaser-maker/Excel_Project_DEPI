"""
Manufacturing Downtime Analysis (MDA) Dashboard
================================================
An interactive Streamlit dashboard built on top of the exploratory data
analysis performed in `MDA.ipynb`. It loads the AI4I2020 manufacturing
dataset, reproduces the key aggregations/visualizations from the notebook,
and adds interactive filters + KPIs so users can explore the data live.

Run with:
    streamlit run app.py
"""

import io
import os
import base64

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st

# --------------------------------------------------------------------------
# Page configuration
# --------------------------------------------------------------------------
st.set_page_config(
    page_title="Manufacturing Downtime Analysis",
    page_icon="🏭",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Path where the notebook expects the raw data file. We look for it locally
# first and fall back to an uploader so the app never crashes if it's missing.
DEFAULT_DATA_PATH = "AI4I2020.csv"

# Exact category orders used throughout MDA.ipynb so charts match the
# original analysis instead of falling back to alphabetical ordering.
FAILURE_ORDER = ["None", "Overheat", "Overstrain", "Power", "Unknown", "Wear"]
PRODUCT_TYPE_ORDER = ["High", "Low", "Medium"]
MACHINE_ORDER = ["CNC", "Conveyor", "Lathe", "Press"]
MANUFACTURER_ORDER = ["ABB", "Bosch", "GE", "Conveyor"]
MAINTENANCE_ORDER = ["Corrective", "Preventive"]


# --------------------------------------------------------------------------
# Page Background Image
# --------------------------------------------------------------------------
def set_background(image_file):
    with open(image_file, "rb") as file:
        encoded_image = base64.b64encode(file.read()).decode()

    st.markdown(
        f"""
        <style>

        /* ==============================
           Background Image
           ============================== */

        .stApp {{
            background-image:
                linear-gradient(
                    rgba(0, 0, 0, 0.25),
                    rgba(0, 0, 0, 0.25)
                ),
                url("data:image/jpg;base64,{encoded_image}");

            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            background-attachment: fixed;
        }}

        [data-testid="stMain"] {{
            background: transparent;
        }}

        [data-testid="stMainBlockContainer"] {{
            background: transparent;
        }}


        /* =========================================
           Make Main Page Text White
           ========================================= */

        .stApp p,
        .stApp span,
        .stApp label,
        .stApp h1,
        .stApp h2,
        .stApp h3,
        .stApp h4,
        .stApp h5,
        .stApp h6 {{
            color: white !important;
        }}

        [data-testid="stMetricLabel"] p {{
            color: white !important;
        }}

        [data-testid="stMetricValue"] div {{
            color: white !important;
        }}

        button[data-baseweb="tab"] p {{
            color: white !important;
        }}


        /* =========================================
           ضع كود الـ Sidebar هنا بالضبط
           ========================================= */

        /* Filters title */
        [data-testid="stSidebar"] h1,
        [data-testid="stSidebar"] h2,
        [data-testid="stSidebar"] h3 {{
            color: black !important;
        }}

        /* Product Type, Machine Type, etc. */
        [data-testid="stSidebar"] label p {{
            color: black !important;
        }}

        /* Checkbox text */
        [data-testid="stSidebar"] [data-testid="stCheckbox"] p {{
            color: black !important;
        }}

        /* Month Range numbers */
        [data-testid="stSidebar"] [data-testid="stSlider"] p {{
            color: black !important;
        }}

        /* Total records caption */
        [data-testid="stSidebar"] [data-testid="stCaptionContainer"],
        [data-testid="stSidebar"] [data-testid="stCaptionContainer"] p {{
            color: black !important;
        }}

        /* الاختيارات الحمراء تظل الكتابة داخلها بيضاء */
        [data-testid="stSidebar"] [data-baseweb="tag"],
        [data-testid="stSidebar"] [data-baseweb="tag"] span {{
            color: white !important;
        }}


        /* النهاية — الكود السابق يكون فوق هذا السطر مباشرة */
        </style>
        """,
        unsafe_allow_html=True
    )


set_background("E:\Python\Presentation1_page-0001.jpg")


# --------------------------------------------------------------------------
# Helper: format large numbers like the notebook does (K / M suffixes)
# --------------------------------------------------------------------------
def format_value(value: float) -> str:
    """Format a numeric value using K/M suffixes, mirroring MDA.ipynb."""
    if pd.isna(value):
        return "N/A"
    if abs(value) >= 1_000_000:
        return f"{value / 1_000_000:.1f} M"
    if abs(value) >= 1_000:
        return f"{value / 1_000:.1f} K"
    return f"{value:,.1f}"


# --------------------------------------------------------------------------
# Data loading & preprocessing (mirrors sections 2-4 of MDA.ipynb)
# --------------------------------------------------------------------------
@st.cache_data(show_spinner="Loading and preparing data...")
def load_data(file_or_path) -> pd.DataFrame:
    """Load the AI4I2020 dataset and apply the same cleaning steps used
    in the MDA.ipynb notebook (feature selection, type fixes, timestamp
    parsing, brand normalization)."""
    df = pd.read_csv(file_or_path)

    # --- 4.2 Feature Selection: drop columns not needed for analysis ----
    drop_columns = [c for c in ["unique_id", "product_id", "temperature_C"] if c in df.columns]
    df = df.drop(columns=drop_columns)

    # --- Timestamp handling -------------------------------------------
    if "timestamp" in df.columns:
        df["timestamp"] = pd.to_datetime(df["timestamp"], errors="coerce")
        df["month_number"] = df["timestamp"].dt.month
        df["Month"] = df["timestamp"].dt.month_name()

    # --- Data cleaning: failure_type is mostly missing because a
    # "no failure" event isn't labeled in the raw data. Fill it with
    # "None" so it behaves as its own category, matching the "None"
    # bucket used throughout the notebook's pivot-style analyses. ------
    if "failure_type" in df.columns:
        df["failure_type"] = df["failure_type"].fillna("None")

    # --- Normalize brand: the notebook folds "Siemens" into "Conveyor" -
    if "brand" in df.columns:
        df["brand"] = df["brand"].replace("Siemens", "Conveyor")

    return df


def ordered_categorical(series: pd.Series, order: list) -> pd.Categorical:
    """Apply a fixed category order, falling back gracefully if some
    categories in `order` aren't present in the data."""
    present_order = [c for c in order if c in series.unique()]
    extra = [c for c in series.unique() if c not in present_order]
    final_order = present_order + sorted(extra)
    return pd.Categorical(series, categories=final_order, ordered=True)


# --------------------------------------------------------------------------
# Load data (with graceful error handling if MDA.ipynb's source CSV is missing)
# --------------------------------------------------------------------------
st.title("🏭 Manufacturing Downtime Analysis Dashboard")
st.caption("Interactive dashboard built on top of the analysis in `MDA.ipynb`.")

data_source = None
if os.path.exists(DEFAULT_DATA_PATH):
    data_source = DEFAULT_DATA_PATH
else:
    st.warning(
        f"Couldn't find `{DEFAULT_DATA_PATH}` next to `app.py`. "
        "Please upload the dataset to continue."
    )
    uploaded_file = st.file_uploader("Upload AI4I2020.csv", type=["csv"])
    if uploaded_file is not None:
        data_source = io.BytesIO(uploaded_file.getvalue())

if data_source is None:
    st.info("Waiting for a data file to be provided (AI4I2020.csv).")
    st.stop()

try:
    df = load_data(data_source)
except Exception as e:
    st.error(f"Failed to load or process the dataset: {e}")
    st.stop()

if df.empty:
    st.error("The loaded dataset is empty. Please check the source file.")
    st.stop()

# --------------------------------------------------------------------------
# Sidebar filters
# --------------------------------------------------------------------------
st.sidebar.header("🔎 Filters")

# Product type filter
product_types = sorted(df["product_type"].dropna().unique()) if "product_type" in df.columns else []
selected_product_types = st.sidebar.multiselect(
    "Product Type", options=product_types, default=product_types
)

# Machine type filter
machine_types = sorted(df["machine_type"].dropna().unique()) if "machine_type" in df.columns else []
selected_machine_types = st.sidebar.multiselect(
    "Machine Type", options=machine_types, default=machine_types
)

# Brand / manufacturer filter
brands = sorted(df["brand"].dropna().unique()) if "brand" in df.columns else []
selected_brands = st.sidebar.multiselect("Manufacturer (Brand)", options=brands, default=brands)

# Maintenance type filter
maintenance_types = sorted(df["maintenance_type"].dropna().unique()) if "maintenance_type" in df.columns else []
selected_maintenance_types = st.sidebar.multiselect(
    "Maintenance Type", options=maintenance_types, default=maintenance_types
)

# Month range slider (based on month_number, if available)
if "month_number" in df.columns and df["month_number"].notna().any():
    min_month, max_month = int(df["month_number"].min()), int(df["month_number"].max())
    if min_month == max_month:
        selected_month_range = (min_month, max_month)
    else:
        selected_month_range = st.sidebar.slider(
            "Month Range", min_value=min_month, max_value=max_month, value=(min_month, max_month)
        )
else:
    selected_month_range = None

# Failure-only checkbox
only_failures = st.sidebar.checkbox("Show only records with a machine failure", value=False)

st.sidebar.markdown("---")
st.sidebar.caption(f"Total records in dataset: **{len(df):,}**")

# --------------------------------------------------------------------------
# Apply filters
# --------------------------------------------------------------------------
filtered_df = df.copy()

if selected_product_types:
    filtered_df = filtered_df[filtered_df["product_type"].isin(selected_product_types)]
if selected_machine_types:
    filtered_df = filtered_df[filtered_df["machine_type"].isin(selected_machine_types)]
if selected_brands:
    filtered_df = filtered_df[filtered_df["brand"].isin(selected_brands)]
if selected_maintenance_types:
    filtered_df = filtered_df[filtered_df["maintenance_type"].isin(selected_maintenance_types)]
if selected_month_range is not None:
    filtered_df = filtered_df[
        filtered_df["month_number"].between(selected_month_range[0], selected_month_range[1])
    ]
if only_failures and "machine_failure" in filtered_df.columns:
    filtered_df = filtered_df[filtered_df["machine_failure"] == 1]

if filtered_df.empty:
    st.warning("No records match the selected filters. Try widening your selection.")
    st.stop()

# --------------------------------------------------------------------------
# KPI Section
# --------------------------------------------------------------------------
st.subheader("📊 Key Performance Indicators")

total_production = filtered_df["production_units"].sum() if "production_units" in filtered_df else np.nan
total_downtime = filtered_df["downtime_hours"].sum() if "downtime_hours" in filtered_df else np.nan
total_maintenance_cost = filtered_df["maintenance_cost"].sum() if "maintenance_cost" in filtered_df else np.nan
failure_rate = (
    filtered_df["machine_failure"].mean() * 100 if "machine_failure" in filtered_df else np.nan
)
avg_defect_rate = filtered_df["defect_rate"].mean() if "defect_rate" in filtered_df else np.nan

kpi_cols = st.columns(5)
kpi_cols[0].metric("Total Production Units", format_value(total_production))
kpi_cols[1].metric("Total Downtime (hrs)", format_value(total_downtime))
kpi_cols[2].metric("Total Maintenance Cost", f"${format_value(total_maintenance_cost)}")
kpi_cols[3].metric("Machine Failure Rate", f"{failure_rate:.2f}%" if not pd.isna(failure_rate) else "N/A")
kpi_cols[4].metric("Avg. Defect Rate", f"{avg_defect_rate:.2f}%" if not pd.isna(avg_defect_rate) else "N/A")

st.markdown("---")

# --------------------------------------------------------------------------
# Visualization tabs (mirrors Section 6 of MDA.ipynb, rebuilt with Plotly
# for interactivity: hover tooltips, zoom, and responsive resizing)
# --------------------------------------------------------------------------
tab_names = [
    "📈 Production Trend",
    "🛠️ Maintenance Cost",
    "⚠️ Failures",
    "⏱️ Downtime",
    "🏗️ Production by Machine/Brand",
    "📈 Correlation",
    "🗂️ Raw Data"
]
tabs = st.tabs(tab_names)

# ---- Tab 1: Monthly production trend --------------------------------
with tabs[0]:
    st.markdown("#### Total Production Units by Month")
    if {"month_number", "Month", "production_units"}.issubset(filtered_df.columns):
        monthly_production = (
            filtered_df.groupby(["month_number", "Month"], as_index=False)["production_units"]
            .sum()
            .sort_values("month_number")
        )
        monthly_production["Production_K"] = monthly_production["production_units"] / 1000

        fig = px.line(
            monthly_production,
            x="Month",
            y="Production_K",
            markers=True,
            labels={"Production_K": "Production (K units)", "Month": ""},
            title="Month and Sum of Production",
        )
        fig.update_traces(line=dict(width=3), marker=dict(size=8))
        fig.update_layout(yaxis_visible=False, template="plotly_white")
        st.plotly_chart(fig, use_container_width=True)

        with st.expander("View underlying data"):
            st.dataframe(
                monthly_production.rename(
                    columns={"production_units": "Total Production Units"}
                )[["Month", "Total Production Units"]],
                use_container_width=True,
            )
    else:
        st.info("Required columns for this chart are not present in the dataset.")

# ---- Tab 2: Maintenance cost analyses --------------------------------
with tabs[1]:
    col1, col2 = st.columns(2)

    # Pie: maintenance cost by maintenance type
    with col1:
        st.markdown("#### Total Maintenance Cost by Maintenance Type")
        if {"maintenance_type", "maintenance_cost"}.issubset(filtered_df.columns):
            maint_cost = (
                filtered_df.groupby("maintenance_type", as_index=False)["maintenance_cost"].sum()
            )
            fig = px.pie(
                maint_cost,
                names="maintenance_type",
                values="maintenance_cost",
                hole=0.35,
            )
            fig.update_traces(textinfo="label+percent")
            st.plotly_chart(fig, use_container_width=True)

    # Bar: maintenance cost by maintenance type (Corrective vs Preventive order)
    with col2:
        st.markdown("#### Maintenance Cost: Corrective vs Preventive")
        if {"maintenance_type", "maintenance_cost"}.issubset(filtered_df.columns):
            maint_cost_ordered = maint_cost.copy()
            maint_cost_ordered["maintenance_type"] = ordered_categorical(
                maint_cost_ordered["maintenance_type"], MAINTENANCE_ORDER
            )
            maint_cost_ordered = maint_cost_ordered.sort_values("maintenance_type")
            fig = px.bar(
                maint_cost_ordered,
                x="maintenance_type",
                y="maintenance_cost",
                text=maint_cost_ordered["maintenance_cost"].apply(format_value),
                labels={"maintenance_type": "", "maintenance_cost": "Maintenance Cost"},
            )
            fig.update_traces(textposition="outside")
            fig.update_layout(yaxis_visible=False, template="plotly_white")
            st.plotly_chart(fig, use_container_width=True)

    st.markdown("#### Maintenance Cost by Brand / Machine Type")
    col3, col4 = st.columns(2)
    with col3:
        if {"brand", "maintenance_cost"}.issubset(filtered_df.columns):
            manuf_cost = filtered_df.groupby("brand", as_index=False)["maintenance_cost"].sum()
            fig = px.bar(
                manuf_cost, x="brand", y="maintenance_cost",
                text=manuf_cost["maintenance_cost"].apply(format_value),
                labels={"brand": "Brand", "maintenance_cost": "Total Maintenance Cost"},
                title="By Brand",
            )
            fig.update_traces(textposition="outside")
            fig.update_layout(template="plotly_white")
            st.plotly_chart(fig, use_container_width=True)
    with col4:
        if {"machine_type", "maintenance_cost"}.issubset(filtered_df.columns):
            machine_cost = filtered_df.groupby("machine_type", as_index=False)["maintenance_cost"].sum()
            fig = px.bar(
                machine_cost, x="machine_type", y="maintenance_cost",
                text=machine_cost["maintenance_cost"].apply(format_value),
                labels={"machine_type": "Machine Type", "maintenance_cost": "Total Maintenance Cost"},
                title="By Machine Type",
            )
            fig.update_traces(textposition="outside")
            fig.update_layout(template="plotly_white")
            st.plotly_chart(fig, use_container_width=True)

# ---- Tab 3: Failure analysis -----------------------------------------
with tabs[2]:
    st.markdown("#### Maintenance Cost by Failure Type")
    if {"failure_type", "maintenance_cost"}.issubset(filtered_df.columns):
        failure_cost = filtered_df.groupby("failure_type", as_index=False)["maintenance_cost"].sum()
        failure_cost["failure_type"] = ordered_categorical(failure_cost["failure_type"], FAILURE_ORDER)
        failure_cost = failure_cost.sort_values("failure_type")
        fig = px.bar(
            failure_cost,
            x="failure_type",
            y="maintenance_cost",
            text=failure_cost["maintenance_cost"].apply(format_value),
            labels={"failure_type": "Failure Type", "maintenance_cost": "Maintenance Cost"},
            title="Failure Type and Sum of Maintenance Cost",
        )
        fig.update_traces(textposition="outside")
        fig.update_layout(yaxis_visible=False, template="plotly_white")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("Required columns for this chart are not present in the dataset.")

    show_failures_only_table = st.checkbox("Show only failed-machine rows in the table below")
    table_df = filtered_df if not show_failures_only_table else filtered_df[filtered_df.get("machine_failure", 0) == 1]
    st.dataframe(table_df.head(200), use_container_width=True)

# ---- Tab 4: Downtime analysis ------------------------------------------
with tabs[3]:
    st.markdown("#### Sum of Downtime Hours by Product Type")
    if {"product_type", "downtime_hours"}.issubset(filtered_df.columns):
        downtime_analysis = filtered_df.groupby("product_type", as_index=False)["downtime_hours"].sum()
        downtime_analysis["product_type"] = ordered_categorical(
            downtime_analysis["product_type"], PRODUCT_TYPE_ORDER
        )
        downtime_analysis = downtime_analysis.sort_values("product_type")
        fig = px.bar(
            downtime_analysis,
            x="product_type",
            y="downtime_hours",
            text=downtime_analysis["downtime_hours"].apply(lambda v: f"{v:,.0f}"),
            labels={"product_type": "Type", "downtime_hours": "Sum of Downtime Hours"},
            title="Type and Sum of Downtime",
        )
        fig.update_traces(textposition="outside")
        fig.update_layout(yaxis_visible=False, template="plotly_white")
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("Required columns for this chart are not present in the dataset.")

    st.markdown("#### Product Count by Type")
    if "product_type" in filtered_df.columns:
        product_count = filtered_df.groupby("product_type", as_index=False).size()
        product_count["product_type"] = ordered_categorical(product_count["product_type"], PRODUCT_TYPE_ORDER)
        product_count = product_count.sort_values("product_type")
        fig = px.bar(
            product_count,
            x="product_type",
            y="size",
            text=product_count["size"].apply(lambda v: format_value(v)),
            labels={"product_type": "Type", "size": "Count of Products"},
        )
        fig.update_traces(textposition="outside")
        fig.update_layout(template="plotly_white")
        st.plotly_chart(fig, use_container_width=True)

# ---- Tab 5: Production by machine type / manufacturer -----------------
with tabs[4]:
    col1, col2 = st.columns(2)
    with col1:
        st.markdown("#### Production Units by Machine Type")
        if {"machine_type", "production_units"}.issubset(filtered_df.columns):
            machine_prod = filtered_df.groupby("machine_type", as_index=False)["production_units"].sum()
            machine_prod["machine_type"] = ordered_categorical(machine_prod["machine_type"], MACHINE_ORDER)
            machine_prod = machine_prod.sort_values("machine_type")
            fig = px.bar(
                machine_prod,
                x="production_units",
                y="machine_type",
                orientation="h",
                text=machine_prod["production_units"].apply(format_value),
                labels={"machine_type": "", "production_units": "Total Production Units"},
            )
            fig.update_traces(textposition="outside")
            fig.update_layout(template="plotly_white", yaxis=dict(autorange="reversed"))
            st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.markdown("#### Production Units by Manufacturer")
        if {"brand", "production_units"}.issubset(filtered_df.columns):
            manuf_prod = filtered_df.groupby("brand", as_index=False)["production_units"].sum()
            manuf_prod["brand"] = ordered_categorical(manuf_prod["brand"], MANUFACTURER_ORDER)
            manuf_prod = manuf_prod.sort_values("brand")
            fig = px.bar(
                manuf_prod,
                x="production_units",
                y="brand",
                orientation="h",
                text=manuf_prod["production_units"].apply(format_value),
                labels={"brand": "", "production_units": "Total Production Units"},
            )
            fig.update_traces(textposition="outside")
            fig.update_layout(template="plotly_white", yaxis=dict(autorange="reversed"))
            st.plotly_chart(fig, use_container_width=True)
# --- Tab 6: Correlation ---------------------------------------------------
with tabs[5]:
    numeric_cols_default = [
        "air_temperature_K",
        "process_temperature_K",
        "rotational_speed_rpm",
        "vibration_mm_s",
        "pressure_bar",
        "voltage_V",
        "current_A",
        "torque_Nm",
        "tool_wear_min",
        "operating_hours",
        "maintenance_cost",
        "production_units",
        "defect_rate",
    ]
    available_numeric = [c for c in numeric_cols_default if c in filtered_df.columns]

    if len(available_numeric) < 2:
        # Fall back to any numeric columns present in the dataset
        available_numeric = filtered_df.select_dtypes(include="number").columns.tolist()

    if len(available_numeric) >= 2:
        selected_numeric = st.multiselect(
            "Select variables to include in the correlation matrix",
            options=available_numeric,
            default=available_numeric,
        )
        if len(selected_numeric) >= 2:
            corr_matrix = filtered_df[selected_numeric].corr()
            fig = px.imshow(
                corr_matrix,
                text_auto=".2f",
                color_continuous_scale="RdBu_r",
                zmin=-1,
                zmax=1,
                title="Correlation Matrix",
                aspect="auto",
            )
            fig.update_layout(height=700)
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("Select at least two variables to compute a correlation matrix.")
    else:
        st.info("Not enough numeric columns available to compute a correlation matrix.")

st.markdown("---")
# ---- Tab 7: Raw / filtered data browser --------------------------------
with tabs[6]:
    st.markdown("#### Filtered Dataset")
    st.write(f"Showing **{len(filtered_df):,}** of **{len(df):,}** total records.")
    st.dataframe(filtered_df, use_container_width=True)

    csv_bytes = filtered_df.to_csv(index=False).encode("utf-8")
    st.download_button(
        "⬇️ Download filtered data as CSV",
        data=csv_bytes,
        file_name="filtered_manufacturing_data.csv",
        mime="text/csv",
    )

st.markdown("---")
st.caption("Dashboard generated from the analysis in MDA.ipynb • Built with Streamlit & Plotly")