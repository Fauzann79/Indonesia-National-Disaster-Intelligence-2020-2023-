/* CLEANING AND STANDARDIZING DATE DATA */

-- Remove trailing '0' characters from date strings
UPDATE data_bencana
SET date = SUBSTR(date, 1, LENGTH(date)-1)
WHERE date LIKE '%0';

-- Add a new column with DATE data type
ALTER TABLE data_bencana ADD COLUMN formatted_date DATE;

-- Convert cleaned strings into standard SQL date format
UPDATE data_bencana
SET formatted_date = STR_TO_DATE(
    CASE 
        WHEN LENGTH(date) = 9 THEN CONCAT('0', date) 
        ELSE date 
    END, 
    '%d/%m/%Y'
);

-- Verify conversion results and identify failures
SELECT date, formatted_date 
FROM data_bencana 
WHERE formatted_date IS NULL;


/* TOTAL VICTIM METRICS */

-- Overall victim count (Total human impact)
SELECT SUM(death + missing_person + injured_person) AS total_victims
FROM data_bencana;

-- Specific victim breakdowns
SELECT SUM(death) AS total_deaths FROM data_bencana;
SELECT SUM(missing_person) AS total_missing FROM data_bencana;
SELECT SUM(injured_person) AS total_injured FROM data_bencana;

-- Victim distribution by geographical location
SELECT province, SUM(death + missing_person + injured_person) AS total_victims
FROM data_bencana
GROUP BY province
ORDER BY total_victims DESC;

-- Victim distribution by disaster category
SELECT disaster_type, SUM(death + missing_person + injured_person) AS total_victims
FROM data_bencana
GROUP BY disaster_type
ORDER BY total_victims DESC;






/* INFRASTRUCTURE DAMAGE & EVENT SEVERITY */

-- Total infrastructure impact (Houses and public facilities)
SELECT SUM(damaged_house + flooded_house + damaged_facility) AS total_damaged_units
FROM data_bencana;

-- Breakdown by damage category
SELECT SUM(damaged_house) AS total_damaged_houses FROM data_bencana;
SELECT SUM(flooded_house) AS total_flooded_houses FROM data_bencana;
SELECT SUM(damaged_facility) AS total_damaged_facilities FROM data_bencana;

-- Infrastructure damage distribution by province
SELECT province,
    SUM(damaged_house + flooded_house + damaged_facility) AS total_damaged
FROM data_bencana
GROUP BY province
ORDER BY total_damaged DESC;

-- Infrastructure damage distribution by disaster category
SELECT disaster_type, 
    SUM(damaged_house + flooded_house + damaged_facility) AS total_damaged
FROM data_bencana
GROUP BY disaster_type
ORDER BY total_damaged DESC;

-- Event Severity Index (Average victims per incident)
SELECT disaster_type, 
    COUNT(*) AS total_events, 
    SUM(death + missing_person + injured_person) AS total_victims,
    ROUND(SUM(death + missing_person + injured_person) / COUNT(*), 2) AS avg_victims_per_event
FROM data_bencana
GROUP BY disaster_type
ORDER BY avg_victims_per_event DESC;



/* TEMPORAL TREND ANALYSIS */

-- Annual disaster frequency
SELECT EXTRACT(YEAR FROM formatted_date) AS year,
    COUNT(*) AS total_disasters
FROM data_bencana
GROUP BY year
ORDER BY year ASC;

-- Monthly seasonality (Identifying peak disaster months)
SELECT EXTRACT(MONTH FROM formatted_date) AS month,
    COUNT(*) AS total_disasters
FROM data_bencana
GROUP BY month
ORDER BY month ASC;

-- Annual summary: Frequency vs Human Impact vs Infrastructure Damage
SELECT EXTRACT(YEAR FROM formatted_date) AS year,
    COUNT(*) AS total_disasters,
    SUM(death + missing_person + injured_person) AS total_victims,
    SUM(damaged_house + flooded_house + damaged_facility) AS total_damaged
FROM data_bencana
GROUP BY year
ORDER BY total_disasters DESC;



/* GEOGRAPHICAL HOTSPOTS & DISASTER TYPE ANALYSIS */

-- Top 10 most disaster-prone provinces
SELECT province, COUNT(*) AS total_disasters
FROM data_bencana
GROUP BY province
ORDER BY total_disasters DESC
LIMIT 10;

-- Top 10 high-risk cities
SELECT city, province, COUNT(*) AS total_events
FROM data_bencana
GROUP BY city, province
ORDER BY total_events DESC
LIMIT 10;

-- Provincial impact: Frequency vs Mortality vs Infrastructure Damage
SELECT province, 
    COUNT(*) AS total_events,
    SUM(death) AS total_deaths, 
    SUM(damaged_house + flooded_house) AS total_damage
FROM data_bencana
GROUP BY province
ORDER BY total_damage DESC;

-- Top 10 flood-prone cities
SELECT city, COUNT(*) AS flood_frequency
FROM data_bencana
WHERE disaster_type = 'BANJIR'
GROUP BY city
ORDER BY flood_frequency DESC
LIMIT 10;

-- Comparison: Lethality vs Destructiveness by disaster type
SELECT disaster_type,
    COUNT(*) AS total_events,
    SUM(death) AS total_deaths,
    SUM(damaged_house + flooded_house) AS total_damage,
    ROUND(SUM(death) / COUNT(*), 2) AS avg_deaths_per_event,
    ROUND(SUM(damaged_house + flooded_house) / COUNT(*), 2) AS avg_damage_per_event
FROM data_bencana
GROUP BY disaster_type
ORDER BY total_deaths DESC;

-- Primary causes frequency (Cleaned text)
SELECT TRIM(cause) AS clean_cause, 
    COUNT(*) AS report_count
FROM data_bencana
WHERE cause IS NOT NULL 
    AND TRIM(cause) NOT IN ('', 'Tidak diketahui', '-') 
GROUP BY clean_cause
ORDER BY report_count DESC
LIMIT 10;

-- Detailed casualty and facility breakdown
SELECT 
    disaster_type,
    SUM(death) AS total_deaths,
    SUM(injured_person) AS total_injured,
    SUM(damaged_house) AS houses_damaged,
    SUM(damaged_facility) AS public_facilities_damaged
FROM data_bencana
GROUP BY disaster_type
ORDER BY total_deaths DESC;

-- Mortality contribution percentage by disaster type
SELECT disaster_type,
    SUM(death) AS total_deaths,
    ROUND(SUM(death) * 100.0 / (SELECT SUM(death) FROM data_bencana), 2) AS death_contribution_pct
FROM data_bencana
GROUP BY disaster_type
ORDER BY death_contribution_pct DESC;

-- Ratio of public facility damage vs residential damage
SELECT disaster_type,
    SUM(damaged_house) AS total_houses,
    SUM(damaged_facility) AS total_facilities,
    ROUND(SUM(damaged_facility) / NULLIF(SUM(damaged_house), 0), 2) AS facility_to_house_ratio
FROM data_bencana
GROUP BY disaster_type;