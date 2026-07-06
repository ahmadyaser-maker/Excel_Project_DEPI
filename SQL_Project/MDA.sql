SET GLOBAL local_infile = 1;
CREATE DATABASE IF NOT EXISTS Manufacturing_Downtime_Analysis;
USE Manufacturing_Downtime_Analysis;
-- DROP DATABASE IF EXISTS Manufacturing_Downtime_Analysis;
SELECT * FROM ai4i2020_raw;
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1) DATA PROFILING (Find problems before cleaning):
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- 1.1) Missing values summary:
SELECT
  SUM(unique_id IS NULL) AS missing_unique_id,
  SUM(product_id IS NULL OR TRIM(product_id)='') AS missing_product_id,
  SUM(machine_type IS NULL OR TRIM(machine_type)='') AS missing_machine_type,
  SUM(brand IS NULL OR TRIM(brand)='') AS missing_brand,
  SUM(location IS NULL OR TRIM(location)='') AS missing_location,
  SUM(product_type IS NULL OR TRIM(product_type)='') AS missing_product_type,
  SUM(air_temperature_K IS NULL) AS missing_air_temperature_K,
  SUM(process_temperature_K IS NULL) AS missing_process_temperature_K,
  SUM(temperature_C IS NULL) AS missing_temperature_C,
  SUM(rotational_speed_rpm IS NULL) AS missing_rotational_speed_rpm,
  SUM(vibration_mm_s IS NULL) AS missing_vibration_mm_s,
  SUM(pressure_bar IS NULL) AS missing_pressure_bar,
  SUM(voltage_V IS NULL) AS missing_voltage_V,
  SUM(current_A IS NULL) AS missing_current_A,
  SUM(torque_Nm IS NULL) AS missing_torque_Nm,
  SUM(tool_wear_min IS NULL) AS missing_tool_wear_min,
  SUM(machine_failure IS NULL) AS missing_machine_failure,
  SUM(failure_type IS NULL OR TRIM(failure_type)='') AS missing_failure_type,
  SUM(tool_wear_failure IS NULL) AS missing_tool_wear_failure,
  SUM(heat_dissipation_failure IS NULL) AS missing_heat_dissipation_failure,
  SUM(power_failure IS NULL) AS missing_power_failure,
  SUM(overstain_failure IS NULL) AS missing_overstain_failure,
  SUM(random_failures IS NULL) AS missing_random_failures,
  SUM(timestamp IS NULL OR TRIM(timestamp)='') AS missing_timestamp,
  SUM(operating_hours IS NULL) AS missing_operating_hours,
  SUM(downtime_hours IS NULL) AS missing_downtime_hours,
  SUM(maintenance_type IS NULL OR TRIM(maintenance_type)='') AS missing_maintenance_type,
  SUM(maintenance_cost IS NULL) AS missing_maintenance_cost,
  SUM(production_units IS NULL) AS missing_production_units,
  SUM(defect_rate IS NULL) AS missing_defect_rate
FROM ai4i2020_raw;

-- 1.2) Duplicates by national_id:
SELECT product_id, COUNT(*) AS count FROM ai4i2020_raw WHERE product_id IS NOT NULL GROUP BY product_id HAVING COUNT(*) > 1;

-- 1.3) Product_ID that looks invalid (Strict Pattern Matching):
SELECT product_id FROM ai4i2020_raw WHERE TRIM(product_id) NOT REGEXP '^[A-Z][0-9]{5}$';
SELECT timestamp FROM ai4i2020_raw WHERE TRIM(timestamp) NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$';

-- 1.4) Inconsistency view:
SELECT machine_type, COUNT(*) AS count FROM ai4i2020_raw GROUP BY machine_type ORDER BY count DESC;
SELECT brand, COUNT(*) AS count FROM ai4i2020_raw GROUP BY brand ORDER BY count DESC;
SELECT location, COUNT(*) AS count FROM ai4i2020_raw GROUP BY location ORDER BY count DESC;
SELECT product_type, COUNT(*) AS count FROM ai4i2020_raw GROUP BY product_type ORDER BY count DESC;
SELECT failure_type, COUNT(*) AS count FROM ai4i2020_raw GROUP BY failure_type ORDER BY count DESC;
SELECT maintenance_type, COUNT(*) AS count FROM ai4i2020_raw GROUP BY maintenance_type ORDER BY count DESC;

-- 1.5) Checking Invalid Numbers:
SELECT * FROM ai4i2020_raw 
WHERE 
    (air_temperature_K IS NOT NULL AND (air_temperature_K < 0 OR air_temperature_K > 400))
    OR (process_temperature_K IS NOT NULL AND (process_temperature_K < 0 OR process_temperature_K > 400))
    OR (temperature_C IS NOT NULL AND (temperature_C < -100 OR temperature_C > 200)) 
    OR (rotational_speed_rpm IS NOT NULL AND (rotational_speed_rpm < 0 OR rotational_speed_rpm > 5000))
    OR (vibration_mm_s IS NOT NULL AND (vibration_mm_s < 0 OR vibration_mm_s > 100))
    OR (pressure_bar IS NOT NULL AND (pressure_bar < 0 OR pressure_bar > 100))
    OR (voltage_V IS NOT NULL AND (voltage_V < 0 OR voltage_V > 600))
    OR (current_A IS NOT NULL AND (current_A < 0 OR current_A > 200))
    OR (torque_Nm IS NOT NULL AND (torque_Nm < 0 OR torque_Nm > 500))
    OR (tool_wear_min IS NOT NULL AND (tool_wear_min < 0 OR tool_wear_min > 1000))
    OR (operating_hours IS NOT NULL AND (operating_hours < 0 OR operating_hours > 100000))
    OR (maintenance_cost IS NOT NULL AND (maintenance_cost < 0 OR maintenance_cost > 100000))
    OR (production_units IS NOT NULL AND (production_units < 0 OR production_units > 100000))
    OR (defect_rate IS NOT NULL AND (defect_rate < 0 OR defect_rate > 100));
/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2) CLEANING and FIXING INVALID NUMBERS:
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- 2.1)Fix Invalid Numbers and Outliers:
-- Air Temperature (Kelvin)
UPDATE ai4i2020_raw SET air_temperature_K = NULL WHERE air_temperature_K IS NOT NULL AND (air_temperature_K < 0 OR air_temperature_K > 400);

-- Process Temperature (Kelvin)
UPDATE ai4i2020_raw SET process_temperature_K = NULL WHERE process_temperature_K IS NOT NULL AND (process_temperature_K < 0 OR process_temperature_K > 400);

-- Temperature (Celsius)
UPDATE ai4i2020_raw SET temperature_C = NULL WHERE temperature_C IS NOT NULL AND (temperature_C < -100 OR temperature_C > 200);

-- Rotational Speed
UPDATE ai4i2020_raw SET rotational_speed_rpm = NULL WHERE rotational_speed_rpm IS NOT NULL AND (rotational_speed_rpm < 0 OR rotational_speed_rpm > 5000);

-- Vibration
UPDATE ai4i2020_raw SET vibration_mm_s = NULL WHERE vibration_mm_s IS NOT NULL AND (vibration_mm_s < 0 OR vibration_mm_s > 100);

-- Pressure
UPDATE ai4i2020_raw SET pressure_bar = NULL WHERE pressure_bar IS NOT NULL AND (pressure_bar < 0 OR pressure_bar > 100);

-- Torque
UPDATE ai4i2020_raw SET torque_Nm = NULL WHERE torque_Nm IS NOT NULL AND (torque_Nm < 0 OR torque_Nm > 500);

-- Voltage
UPDATE ai4i2020_raw SET voltage_V = NULL WHERE voltage_V IS NOT NULL AND (voltage_V < 0 OR voltage_V > 600);

-- Current
UPDATE ai4i2020_raw SET current_A = NULL WHERE current_A IS NOT NULL AND (current_A < 0 OR current_A > 200);

-- Tool Wear
UPDATE ai4i2020_raw SET tool_wear_min = NULL WHERE tool_wear_min IS NOT NULL AND (tool_wear_min < 0 OR tool_wear_min > 1000);

-- Operating Hours
UPDATE ai4i2020_raw SET operating_hours = NULL WHERE operating_hours IS NOT NULL AND (operating_hours < 0 OR operating_hours > 100000);

-- Maintenance Cost
UPDATE ai4i2020_raw SET maintenance_cost = NULL WHERE maintenance_cost IS NOT NULL AND (maintenance_cost < 0 OR maintenance_cost > 100000);

-- Production Units
UPDATE ai4i2020_raw SET production_units = NULL WHERE production_units IS NOT NULL AND (production_units < 0 OR production_units > 100000);

-- Defect Rate 
UPDATE ai4i2020_raw SET defect_rate = NULL WHERE defect_rate IS NOT NULL AND (defect_rate < 0 OR defect_rate > 100);


-- 2.2) Impute Missing Numbers (simple: average):
-- Air Temperature (Kelvin)
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(air_temperature_K) AS avg_air_temperature_K FROM ai4i2020_raw WHERE air_temperature_K IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.air_temperature_K = b.avg_air_temperature_K WHERE a.air_temperature_K IS NULL AND a.brand IS NOT NULL;

-- Process Temperature (Kelvin)
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(process_temperature_K) AS avg_process_temperature_K FROM ai4i2020_raw WHERE process_temperature_K IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.process_temperature_K = b.avg_process_temperature_K  WHERE a.process_temperature_K IS NULL AND a.brand IS NOT NULL;

-- Temperature (Celsius)
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(temperature_C) AS avg_temperature_C FROM ai4i2020_raw WHERE temperature_C IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.temperature_C = b.avg_temperature_C WHERE a.temperature_C IS NULL AND a.brand IS NOT NULL;

-- Rotational Speed
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(rotational_speed_rpm) AS avg_rotational_speed_rpm FROM ai4i2020_raw WHERE rotational_speed_rpm IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.rotational_speed_rpm = b.avg_rotational_speed_rpm WHERE a.rotational_speed_rpm IS NULL AND a.brand IS NOT NULL;

-- Vibration
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(vibration_mm_s) AS avg_vibration_mm_s FROM ai4i2020_raw WHERE vibration_mm_s IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.vibration_mm_s = b.avg_vibration_mm_s WHERE a.vibration_mm_s IS NULL AND a.brand IS NOT NULL;

-- Pressure
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(pressure_bar) AS avg_pressure_bar FROM ai4i2020_raw WHERE pressure_bar IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.pressure_bar = b.avg_pressure_bar WHERE a.pressure_bar IS NULL AND a.brand IS NOT NULL;

-- Torque (Included for completeness)
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(torque_Nm) AS avg_torque_Nm FROM ai4i2020_raw WHERE torque_Nm IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.torque_Nm = b.avg_torque_Nm WHERE a.torque_Nm IS NULL AND a.brand IS NOT NULL;

-- Voltage
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(voltage_V) AS avg_voltage_V FROM ai4i2020_raw WHERE voltage_V IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.voltage_V = b.avg_voltage_V WHERE a.voltage_V IS NULL AND a.brand IS NOT NULL;

-- Current
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(current_A) AS avg_current_A FROM ai4i2020_raw WHERE current_A IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.current_A = b.avg_current_A WHERE a.current_A IS NULL AND a.brand IS NOT NULL;

-- Tool Wear
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(tool_wear_min) AS avg_tool_wear_min FROM ai4i2020_raw WHERE tool_wear_min IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.tool_wear_min = b.avg_tool_wear_min WHERE a.tool_wear_min IS NULL AND a.brand IS NOT NULL;

-- Operating Hours
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(operating_hours) AS avg_operating_hours FROM ai4i2020_raw WHERE operating_hours IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.operating_hours = b.avg_operating_hours WHERE a.operating_hours IS NULL AND a.brand IS NOT NULL;

-- Maintenance Cost
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(maintenance_cost) AS avg_maintenance_cost FROM ai4i2020_raw WHERE maintenance_cost IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.maintenance_cost = b.avg_maintenance_cost WHERE a.maintenance_cost IS NULL AND a.brand IS NOT NULL;

-- Production Units
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(production_units) AS avg_production_units FROM ai4i2020_raw WHERE production_units IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.production_units = b.avg_production_units WHERE a.production_units IS NULL AND a.brand IS NOT NULL;

-- Defect Rate
UPDATE ai4i2020_raw a JOIN (SELECT brand, AVG(defect_rate) AS avg_defect_rate FROM ai4i2020_raw WHERE defect_rate IS NOT NULL AND brand IS NOT NULL GROUP BY brand) b ON a.brand = b.brand SET a.defect_rate = b.avg_defect_rate WHERE a.defect_rate IS NULL AND a.brand IS NOT NULL;
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3) CREATE A CLEAN TABLE FOR ANALYTICS (Best Practice):
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
CREATE TABLE ai4i2020_clean AS SELECT * FROM ai4i2020_raw;
-- DROP TABLE IF EXISTS employees_clean;
SELECT * FROM ai4i2020_clean;
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
4) Summary Statistics:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS total_records,
    MIN(timestamp) AS earliest_record_date,
    MAX(timestamp) AS latest_record_date,
    ROUND(AVG(air_temperature_K), 1) AS average_air_temp_K,
    ROUND(AVG(process_temperature_K), 1) AS average_process_temp_K,
    ROUND(AVG(temperature_C), 1) AS average_temp_C,
    ROUND(AVG(rotational_speed_rpm), 0) AS average_rpm,
    ROUND(AVG(vibration_mm_s), 2) AS average_vibration_mm_s,
    ROUND(AVG(pressure_bar), 2) AS average_pressure_bar,
    ROUND(AVG(torque_Nm), 1) AS average_torque_Nm,
    ROUND(AVG(tool_wear_min), 0) AS average_tool_wear_min,
    ROUND(AVG(operating_hours), 0) AS average_operating_hours,
    ROUND(AVG(maintenance_cost), 0) AS average_maintenance_cost,
    ROUND(AVG(production_units), 0) AS average_production_units,
    ROUND(AVG(defect_rate), 2) AS average_defect_rate
FROM ai4i2020_clean;
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
5) FULL DATA ANALYSIS (KPIs students use in real HR work):
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- 5.1) KPIs:
WITH BaseMetrics AS (
    SELECT 
        SUM(operating_hours) AS total_operating,
        SUM(downtime_hours) AS total_downtime,
        SUM(machine_failure) AS total_failures,
        SUM(maintenance_cost) AS total_maintenance_cost,
        AVG(rotational_speed_rpm) AS avg_speed,
        MAX(rotational_speed_rpm) AS max_speed,
        SUM(production_units) AS total_units,
        SUM(production_units * (1 - defect_rate)) AS total_good_units
    FROM ai4i2020_clean
)
SELECT 
    -- 1. Mean Time Between Failures (MTBF)
    total_operating / NULLIF(total_failures, 0) AS 'MTBF_Hours',
    
    -- 2. Mean Time To Repair (MTTR)
    total_downtime / NULLIF(total_failures, 0) AS 'MTTR_Hours',
    
    -- 3. Cost per Failure
    total_maintenance_cost / NULLIF(total_failures, 0) AS 'Cost_Per_Failure',
    
    -- 4. Availability
    (total_operating - total_downtime) / NULLIF(total_operating, 0) AS 'Availability_Rate',
    
    -- 5. Performance
    avg_speed / NULLIF(max_speed, 0) AS 'Performance_Rate',
    
    -- 6. Total Good Units
    total_good_units AS 'Good_Units',
    
    -- 7. Quality Rate
    total_good_units / NULLIF(total_units, 0) AS 'Quality_Rate',
    
    -- 8. OEE (Availability * Performance * Quality)
    ((total_operating - total_downtime) / NULLIF(total_operating, 0)) * 
    (avg_speed / NULLIF(max_speed, 0)) * 
    (total_good_units / NULLIF(total_units, 0)) AS 'OEE_Rate'
FROM BaseMetrics;

-- 5.2) Month and Sum of Product:
SELECT MONTHNAME(timestamp) AS 'Row Labels', SUM(production_units) AS 'Sum of production_units' FROM ai4i2020_clean GROUP BY MONTH(timestamp), MONTHNAME(timestamp) ORDER BY MONTH(timestamp) ASC;

-- 5.3) Maintenanc and Maintenance Cost:
SELECT maintenance_type AS 'Row Labels', SUM(maintenance_cost) AS 'Sum of maintenance_cost' FROM ai4i2020_clean GROUP BY maintenance_type;

-- 5.4) Brand and Sum of Maintenance Cost:
SELECT brand AS 'Row Labels', SUM(maintenance_cost) AS 'Sum of maintenance_cost' FROM ai4i2020_clean GROUP BY brand;

-- 5.5) Machine Type and Sum of Maintenance Cost:
SELECT machine_type AS 'Row Labels', SUM(maintenance_cost) AS 'Sum of maintenance_cost' FROM ai4i2020_clean GROUP BY machine_type;

-- 5.6) Type and Sum Of Maintenance Cost:
SELECT product_type AS 'Row Labels', SUM(maintenance_cost) AS 'Sum of maintenance_cost' FROM ai4i2020_clean GROUP BY product_type;

-- 5.7) Failure Type and Sum of Maintenance:
SELECT failure_type AS 'Row Labels', SUM(maintenance_cost) AS 'Sum of maintenance_cost' FROM ai4i2020_clean GROUP BY failure_type;

-- 5.8) Defect Rate vs. Maintenance Cost (The Direct Equivalent):
SELECT
  CASE
    WHEN defect_rate >= 15 THEN '15%+ Critical Defects'
    WHEN defect_rate >= 10 THEN '10-14% High Defects'
    WHEN defect_rate >= 5 THEN '5-9% Moderate Defects'
    ELSE '0-4% Acceptable'
  END AS defect_band, COUNT(*) AS count, ROUND(AVG(maintenance_cost), 2) AS average_maintenance_cost FROM ai4i2020_clean GROUP BY defect_band ORDER BY average_maintenance_cost DESC;

-- 5.9) Tool Wear vs. Defect Rate (Predictive Maintenance Focus):
SELECT
  CASE
    WHEN tool_wear_min >= 200 THEN '200+ mins (Severe Wear)'
    WHEN tool_wear_min >= 150 THEN '150-199 mins (High Wear)'
    WHEN tool_wear_min >= 100 THEN '100-149 mins (Moderate Wear)'
    ELSE '0-99 mins (Low/New)'
  END AS wear_band, COUNT(*) AS count, ROUND(AVG(defect_rate), 2) AS average_defect_rate FROM ai4i2020_clean GROUP BY wear_band ORDER BY average_defect_rate DESC;

-- 5.10) Operating Strain vs. Temperature (Physics Focus):
SELECT
  CASE
    WHEN rotational_speed_rpm >= 2500 THEN '2500+ Extreme RPM'
    WHEN rotational_speed_rpm >= 2000 THEN '2000-2499 High RPM'
    WHEN rotational_speed_rpm >= 1500 THEN '1500-1999 Normal RPM'
    ELSE 'Under 1500 Low RPM'
  END AS speed_band, COUNT(*) AS count, ROUND(AVG(temperature_C), 1) AS average_temperature_C FROM ai4i2020_clean GROUP BY speed_band ORDER BY average_temperature_C DESC;

SELECT product_type AS 'Row Labels', COUNT(product_id) AS 'Count of product_id' FROM ai4i2020_clean GROUP BY product_type;
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
6) Database Schema Design:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- 6.1) Operations Fact Table:
CREATE TABLE IF NOT EXISTS Fact_Operations (process_temperature_K DOUBLE, rotational_speed_rpm INT, timestamp DATETIME, operating_hours INT, maintenance_cost INT, downtime_hours INT, production_units INT, defect_rate DOUBLE, maintenance_id INT, date_id INT, failure_id INT, machine_id INT, product_id VARCHAR(100),
FOREIGN KEY (maintenance_id) REFERENCES Dim_Maintenance(maintenance_id) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (failure_id) REFERENCES Dim_Failure(failure_id) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (product_id) REFERENCES Dim_Product(product_id) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (machine_id) REFERENCES Dim_Machine(machine_id) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (date_id) REFERENCES Dim_Date(date_id) ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO Fact_Operations (process_temperature_K, rotational_speed_rpm, timestamp, operating_hours, maintenance_cost, downtime_hours, production_units, defect_rate, product_id) SELECT process_temperature_K, rotational_speed_rpm, timestamp, operating_hours, maintenance_cost, downtime_hours, production_units, defect_rate, product_id FROM ai4i2020_clean;

-- 6.2) Maintenance Dimension Table:
CREATE TABLE IF NOT EXISTS Dim_Maintenance (maintenance_id INT PRIMARY KEY AUTO_INCREMENT, maintenance_type VARCHAR(100));
INSERT INTO Dim_Maintenance (maintenance_type) SELECT maintenance_type FROM ai4i2020_clean;

-- 6.3) Failure Dimension Table:
CREATE TABLE IF NOT EXISTS Dim_Failure (failure_id INT PRIMARY KEY AUTO_INCREMENT, failure_type VARCHAR(100));
INSERT INTO Dim_Failure (failure_type) SELECT failure_type FROM ai4i2020_clean;

-- 6.4) Product Dimension Table:
CREATE TABLE IF NOT EXISTS Dim_Product (product_id VARCHAR(100) PRIMARY KEY, product_type VARCHAR(100));
INSERT INTO Dim_Product (product_id, product_type) SELECT product_id, product_type FROM ai4i2020_clean;

-- 6.5) Machine Dimension Table:
CREATE TABLE IF NOT EXISTS Dim_Machine (machine_id INT PRIMARY KEY AUTO_INCREMENT, machine_type VARCHAR(100), brand VARCHAR(100), product_type VARCHAR(100));
INSERT INTO Dim_Machine (machine_type, brand, product_type) SELECT machine_type, brand, product_type FROM ai4i2020_clean;

-- 6.6) Date Dimension Table:
CREATE TABLE Dim_Date (date_id INT AUTO_INCREMENT PRIMARY KEY, full_date DATETIME, year INT, month_name VARCHAR(20), day_name VARCHAR(20), day_type VARCHAR(10));
INSERT INTO Dim_Date (full_date, year, month_name, day_name, day_type) SELECT timestamp, YEAR(timestamp), MONTHNAME(timestamp), DAYNAME(timestamp), CASE WHEN DAYOFWEEK(timestamp) IN (1, 6) THEN 'Weekday' ELSE 'Weekend' END FROM ai4i2020_clean;