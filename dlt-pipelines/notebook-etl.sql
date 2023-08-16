-- Databricks notebook source
-- COMMAND ----------

-- DBTITLE 1,Turbine metadata
CREATE INCREMENTAL LIVE TABLE turbine (
  CONSTRAINT correct_schema EXPECT (_rescued_data IS NULL)
)
COMMENT "Turbine details, with location, wind turbine model type etc"
AS SELECT * FROM cloud_files("/demos/manufacturing/iot_turbine/turbine", "json", map("cloudFiles.inferColumnTypes" , "true"))

-- COMMAND ----------

-- DBTITLE 1,Wind Turbine sensor 
CREATE INCREMENTAL LIVE TABLE sensor_bronze (
  CONSTRAINT correct_schema EXPECT (_rescued_data IS NULL),
  CONSTRAINT correct_energy EXPECT (energy IS NOT NULL and energy > 0) ON VIOLATION DROP ROW
)
COMMENT "Raw sensor data coming from json files ingested in incremental with Auto Loader: vibration, energy produced etc. 1 point every X sec per sensor."
AS SELECT * FROM cloud_files("/demos/manufacturing/iot_turbine/incoming_data", "json", map("cloudFiles.inferColumnTypes" , "true"))

-- COMMAND ----------

-- DBTITLE 1,Historical status
CREATE INCREMENTAL LIVE TABLE historical_turbine_status (
  CONSTRAINT correct_schema EXPECT (_rescued_data IS NULL)
)
COMMENT "Turbine status to be used as label in our predictive maintenance model (to know which turbine is potentially faulty)"
AS SELECT * FROM cloud_files("/demos/manufacturing/iot_turbine/historical_turbine_status", "json", map("cloudFiles.inferColumnTypes" , "true"))

-- COMMAND ----------

-- DBTITLE 1, Compute aggregations: merge sensor data at an hourly level
CREATE LIVE TABLE sensor_hourly (
  CONSTRAINT turbine_id_valid EXPECT (turbine_id IS not NULL)  ON VIOLATION DROP ROW,
  CONSTRAINT timestamp_valid EXPECT (hourly_timestamp IS not NULL)  ON VIOLATION DROP ROW
)
COMMENT "Hourly sensor stats, used to describe signal and detect anomalies"
AS
SELECT turbine_id,
      date_trunc('hour', from_unixtime(timestamp)) AS hourly_timestamp, 
      avg(energy)          as avg_energy,
      stddev_pop(sensor_A) as std_A,
      stddev_pop(sensor_B) as std_B,
      stddev_pop(sensor_C) as std_C,
      stddev_pop(sensor_D) as std_D,
      stddev_pop(sensor_E) as std_E,
      stddev_pop(sensor_F) as std_F,
      percentile_approx(sensor_A, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_A,
      percentile_approx(sensor_B, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_B,
      percentile_approx(sensor_C, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_C,
      percentile_approx(sensor_D, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_D,
      percentile_approx(sensor_E, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_E,
      percentile_approx(sensor_F, array(0.1, 0.3, 0.6, 0.8, 0.95)) as percentiles_F
  FROM LIVE.sensor_bronze GROUP BY hourly_timestamp, turbine_id

-- COMMAND ----------

-- Build our table used by ML Engineers: join sensor aggregates with wind turbine metadata and historical status
CREATE LIVE TABLE turbine_training_dataset 
COMMENT "Hourly sensor stats, used to describe signal and detect anomalies"
AS
SELECT * except(t._rescued_data, s._rescued_data, m.turbine_id) FROM LIVE.sensor_hourly m
    INNER JOIN LIVE.turbine t USING (turbine_id)
    INNER JOIN LIVE.historical_turbine_status s ON m.turbine_id = s.turbine_id AND from_unixtime(s.start_time) < m.hourly_timestamp AND from_unixtime(s.end_time) > m.hourly_timestamp