
create or replace table GOVERNANCE_DB.ACCESS_CONTROL.ROW_ACCESS_MAPPING (
  role_name VARCHAR(100) NOT NULL,
  organization_id VARCHAR(50) NOT NULL,
  allowed VARCHAR,
  effective_date DATE DEFAULT CURRENT_DATE(),
  expiry_date DATE,
  created_by VARCHAR DEFAULT CURRENT_USER(),
  created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
  modified_by VARCHAR,
  modified_at TIMESTAMP_LTZ,
  CONSTRAINT pk_row_access PRIMARY KEY (role_name, organization_id)
)
COMMENT = 'Role to organization access mapping for row-level security';



INSERT INTO GOVERNANCE_DB.ACCESS_CONTROL.ROW_ACCESS_MAPPING 
  (role_name, organization_id, allowed)
VALUES
  -- HC_ADMIN sees all organizations
  
  ('HC_ADMIN', 'ORG_VMG_001', 'Y'),   -- Valley Medical Group
  ('HC_ADMIN', 'ORG_BCH_002', 'Y'),
  ('HC_ADMIN', 'ORG_PMC_003', 'Y'),
  ('HC_ADMIN', 'ORG_SGH_004', 'Y'),   -- (add other orgs as needed)
  ('HC_ADMIN', 'ORG_THC_005', 'Y'),
  
  
  -- HC_ENGINEER sees all organizations
  ('HC_ENGINEER', 'ORG_VMG_001', 'Y'),
  ('HC_ENGINEER', 'ORG_BCH_002', 'Y'),
  ('HC_ENGINEER', 'ORG_PMC_003', 'Y'),
  
  -- HC_ANALYST sees only specific organizations
  ('HC_ANALYST', 'ORG_VMG_001', 'Y');  -- Can see Valley Medical Group
  -- ('HC_ANALYST', 'ORG_CMC_002', 'N'),  -- Cannot see other orgs
  


  
-- select * from GOVERNANCE_DB.ACCESS_CONTROL.ROW_ACCESS_MAPPING



CREATE or replace  ROW ACCESS POLICY GOVERNANCE_DB.ACCESS_CONTROL.organization_access_policy
AS (patient_organization_id VARCHAR) RETURNS BOOLEAN ->
  CASE
    -- Admin roles see everything
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SYSADMIN', 'SECURITYADMIN', 'DATA_GOV_ADMIN') 
      THEN TRUE
    
    -- Check mapping table for other roles
    ELSE EXISTS (
      SELECT 1 
      FROM GOVERNANCE_DB.ACCESS_CONTROL.ROW_ACCESS_MAPPING m
      WHERE m.role_name = CURRENT_ROLE()
        AND m.organization_id = patient_organization_id
        AND m.allowed = 'Y'
    )
  END
COMMENT = 'Restricts patient access based on organization and role mapping';

SHOW ROW ACCESS POLICIES IN SCHEMA GOVERNANCE_DB.ACCESS_CONTROL;

-- ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
--   DROP ROW ACCESS POLICY ORGANIZATION_ACCESS_POLICY;

ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  ADD ROW ACCESS POLICY GOVERNANCE_DB.ACCESS_CONTROL.organization_access_policy 
  ON (organization_id);

-- Name Masking
CREATE OR REPLACE MASKING POLICY mp_tokenize_name
AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_GOV_ADMIN', 'HC_ADMIN') THEN val
    ELSE SUBSTR(
           TO_VARCHAR(HASH(LOWER(TRIM(val)))),
           1,
           8
         )
  END;

-- Email Masking
CREATE OR REPLACE MASKING POLICY mp_tokenize_email
AS (val STRING) 
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_GOV_ADMIN', 'HC_ADMIN') THEN val
    ELSE SUBSTR(
           TO_VARCHAR(HASH(LOWER(TRIM(val)))),
           1,
           8
         )
  END;


--National ID Masking
CREATE OR REPLACE MASKING POLICY mp_tokenize_national_id
AS (val STRING) 
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_GOV_ADMIN', 'HC_ADMIN') THEN val
    ELSE 'XXX-XX-XXXX'
  END;


--Diagnosis Masking (PHI)
CREATE OR REPLACE MASKING POLICY mp_tokenize_diagnosis
AS (val STRING)
RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_GOV_ADMIN', 'HC_ADMIN') THEN val
    ELSE 'DX_' || SUBSTR(TO_VARCHAR(HASH(val)), 1, 8)
  END;


-- Date of Birth (Generalization)
CREATE OR REPLACE MASKING POLICY mp_dob_year_only
AS (val DATE)
RETURNS DATE ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_GOV_ADMIN', 'HC_ADMIN') THEN val
    ELSE DATE_FROM_PARTS(YEAR(val), 1, 1)
  END;









ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN first_name
    SET MASKING POLICY mask_pii_tokenized;

ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN last_name
    SET MASKING POLICY mp_tokenize_name;

ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN email
    SET MASKING POLICY mp_tokenize_email;

ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN national_id
    SET MASKING POLICY mp_tokenize_national_id;

ALTER TABLE HEALTHCARE_DB.HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN primary_diagnosis
    SET MASKING POLICY mp_tokenize_diagnosis;

ALTER TABLE HEALTHCARE_SCH.PATIENTS
  MODIFY COLUMN date_of_birth
    SET MASKING POLICY mp_dob_year_only;



