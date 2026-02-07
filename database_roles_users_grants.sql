-------------------------------------------------------------STEP 1-------------------------------------------------------------------------------------------------------
-------------------------------------------------CREATION OF ROLE,USER AND GRANTS TO ROLES --------------------------------------------------------------------------------
--create users and roles
USE ROLE SECURITYADMIN

create user "james@isel"
    default_warehouse=demo_wh default_role= DATA_GOV_ADMIN   password='anypassword' must_change_password = false;
create user "john@isel"
    default_warehouse=demo_wh default_role=HC_ADMIN       password='anypassword' must_change_password = false;
create user "bella@isel"
    default_warehouse=demo_wh default_role=HC_ENGINEER        password='anypassword' must_change_password = false;
create user "jasmine@isel"
    default_warehouse=demo_wh default_role=HC_ANALYST        password='anypassword' must_change_password = false;

CREATE ROLE IF NOT EXISTS DATA_GOV_ADMIN;
CREATE ROLE IF NOT EXISTS HC_ADMIN;
CREATE ROLE IF NOT EXISTS HC_ENGINEER;
CREATE ROLE IF NOT EXISTS HC_ANALYST;




-- create role hierachy 
--securityadmin : datagovadmin
--sysadmin: HC_ADMIN
--HC_ADMIN: HC_ENGINEER,HC_ANALYST


GRANT ROLE DATA_GOV_ADMIN TO ROLE SECURITYADMIN;

USE ROLE SYSADMIN;

GRANT ROLE HC_ADMIN TO ROLE SYSADMIN;
GRANT ROLE HC_ENGINEER TO ROLE HC_ADMIN;
GRANT ROLE HC_ANALYST TO ROLE HC_ADMIN;






--grant roles 
use role useradmin;
grant role DATA_GOV_ADMIN to user "james@isel";
grant role HC_ADMIN to user "john@isel";
grant role HC_ENGINEER to user "bella@isel";
grant role HC_ANALYST to user "jasmine@isel";

----------------------------------------------------------------------------------------STEP 2--------------------------------------------------------------------------------------------
-- we want to create a database
-- we need to use sysadmin because thats its job for object creation
use role sysadmin

CREATE DATABASE IF NOT EXISTS HEALTHCARE_DB;

grant ownership on database HEALTHCARE_DB to role HC_ADMIN;

------------------------------------------------------------------------------------SCHEMA AND TABLE CREATION-----------------------------------------------------------------------------
-- create the database using HC_admin, you can also do this by login into the 
--HC_admin user 'john@isel'
use role HC_ADMIN

CREATE SCHEMA IF NOT EXISTS HEALTHCARE_SCH ;

CREATE OR REPLACE TABLE HEALTHCARE_SCH.PATIENTS (
    patient_id VARCHAR(50) PRIMARY KEY,
    organization_id VARCHAR(50) NOT NULL,
    organization_name VARCHAR(200) NOT NULL,
    region VARCHAR(10) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(200),
    national_id VARCHAR(50),
    date_of_birth DATE NOT NULL,
    primary_diagnosis VARCHAR(200),
    diagnosis_code VARCHAR(20),
    patient_status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    created_by VARCHAR(100) DEFAULT CURRENT_USER()
)
COMMENT = 'Patient master table with multi-tenant isolation';

INSERT INTO HEALTHCARE_SCH.PATIENTS 
(patient_id, organization_id, organization_name, region, first_name, last_name, email, national_id, date_of_birth, primary_diagnosis, diagnosis_code, patient_status) 
VALUES
-- Valley Medical Group (US)
('PT_20240815_001', 'ORG_VMG_001', 'Valley Medical Group', 'US', 'John', 'Carter', 'john.carter@email.com', '123-45-6789', '1985-04-12', 'Type 2 Diabetes Mellitus', 'E11.9', 'active'),
('PT_20240823_002', 'ORG_VMG_001', 'Valley Medical Group', 'US', 'Maria', 'Lopez', 'maria.lopez@email.com', '987-65-4321', '1990-09-01', 'Essential Hypertension', 'I10', 'active'),
('PT_20240905_003', 'ORG_VMG_001', 'Valley Medical Group', 'US', 'Emily', 'Johnson', 'emily.j@email.com', '321-54-9876', '1992-06-18', 'Chronic Migraine', 'G43.709', 'active'),

-- Berlin Care Hospital (EU)
('PT_20240712_004', 'ORG_BCH_002', 'Berlin Care Hospital', 'EU', 'Hans', 'Müller', 'h.mueller@email.de', 'DE-778899', '1978-01-20', 'Bronchial Asthma', 'J45.9', 'active'),
('PT_20240805_005', 'ORG_BCH_002', 'Berlin Care Hospital', 'EU', 'Marco', 'Bianchi', 'm.bianchi@email.it', 'IT-998877', '1975-11-30', 'Type 1 Diabetes Mellitus', 'E10.9', 'active'),

-- Paris Medical Center (EU)
('PT_20240918_006', 'ORG_PMC_003', 'Paris Medical Center', 'EU', 'Sophie', 'Dubois', 's.dubois@email.fr', 'FR-445566', '1987-02-09', 'Rheumatoid Arthritis', 'M06.9', 'active'),

-- Singapore General Hospital (APAC)
('PT_20240625_007', 'ORG_SGH_004', 'Singapore General Hospital', 'APAC', 'Yuki', 'Tanaka', 'yuki.tanaka@email.jp', 'JP-334455', '1989-08-22', 'Essential Hypertension', 'I10', 'active'),
('PT_20240710_008', 'ORG_SGH_004', 'Singapore General Hospital', 'APAC', 'Wei', 'Zhang', 'wei.zhang@email.sg', 'CN-667788', '1969-03-14', 'Coronary Artery Disease', 'I25.10', 'active'),

-- Tokyo Health Clinic (APAC)
('PT_20240830_009', 'ORG_THC_005', 'Tokyo Health Clinic', 'APAC', 'Aarav', 'Patel', 'aarav.patel@email.in', 'IN-556677', '1982-07-15', 'Ischemic Heart Disease', 'I25.9', 'active');


---------------------------------------------------------STEP 3 ---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------GRANT TO OBJECT --------------------------------------------------------------------------------------------------------------------

use role hc_admin;
grant usage on database HEALTHCARE_DB to role HC_ADMIN;
grant usage on database HEALTHCARE_DB to role HC_ENGINEER;
grant usage on database HEALTHCARE_DB to role HC_ANALYST;

grant usage on schema HEALTHCARE_SCH to role HC_ADMIN;
grant usage on schema HEALTHCARE_SCH to role HC_ENGINEER;
grant usage on schema HEALTHCARE_SCH to role HC_ANALYST;


grant select on table HEALTHCARE_SCH.PATIENTS  to role HC_ANALYST;
grant select on table HEALTHCARE_SCH.PATIENTS  to role HC_ENGINEER







-------------------------------------------------------------------------------------STEP 4 ------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------GOVERNANCE---------------------------------------------------------------------------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS GOVERNANCE_DB
  COMMENT = 'Secure database for governance and access control metadata';

CREATE SCHEMA GOVERNANCE_DB.ACCESS_CONTROL
  COMMENT = 'Schema for row-level security policies and mappings';

-- we implemented this transfer of ownership 
--it’s best practice for enterprises because it separates operational duties (SYSADMIN) from governance duties (DATA_GOV_ADMIN).
USE ROLE SECURITYADMIN;

GRANT OWNERSHIP ON DATABASE GOVERNANCE_DB 
  TO ROLE DATA_GOV_ADMIN COPY CURRENT GRANTS;

GRANT OWNERSHIP ON SCHEMA GOVERNANCE_DB.ACCESS_CONTROL 
  TO ROLE DATA_GOV_ADMIN COPY CURRENT GRANTS;


-- SHOW GRANTS OF ROLE DATA_GOV_ADMIN;
-- SHOW GRANTS ON DATABASE GOVERNANCE_DB;





-- Use SECURITYADMIN to grant everything
USE ROLE SECURITYADMIN;

GRANT USAGE ON DATABASE HEALTHCARE_DB TO ROLE DATA_GOV_ADMIN;
GRANT USAGE ON SCHEMA HEALTHCARE_DB.HEALTHCARE_SCH TO ROLE DATA_GOV_ADMIN;
GRANT REFERENCES ON TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS TO ROLE DATA_GOV_ADMIN;
GRANT APPLY ROW ACCESS POLICY ON ACCOUNT TO ROLE DATA_GOV_ADMIN;

GRANT APPLY masking POLICY ON ACCOUNT TO ROLE DATA_GOV_ADMIN;






















