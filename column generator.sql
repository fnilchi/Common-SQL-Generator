PL/SQL Developer Test script 3.0
194
DECLARE
  L                NUMBER;
  LV_SQL           VARCHAR2(1000);
  LV_SCHEMA        VARCHAR2(1000);
  LV_OUTPUT_SCHEMA VARCHAR2(1000);
  LV_TABLE_NAME    VARCHAR2(1000);
  LV_TABLE_ALIAS   VARCHAR2(1000);

  LV_NOT_NULL_FIELDS_CONDITION VARCHAR2(1000);

  LV_NOT_NULL_FIELDS           NUMBER := 0;
  LV_NULL_FIELDS               NUMBER := 0;
  LV_OLD_NEW_4_TRIGGER         NUMBER := 0;
  LV_OUTPUT_4_FORM_ASSIGNMENT  NUMBER := 0;
  LV_OUTPUT_4_PLSQL_ASSIGNMENT NUMBER := 0;
  LV_OUTPUT_4_SELECT           NUMBER := 0;
  LV_ADDITIVE                  VARCHAR2(100) := ' ';
BEGIN
  LV_SCHEMA                    := UPPER(TRIM(:SCHEMA_));
  LV_OUTPUT_SCHEMA             := UPPER(TRIM(:OUTPUT_SCHEMA));
  LV_TABLE_NAME                := UPPER(TRIM(:TABLE_NAME));
  LV_TABLE_ALIAS               := UPPER(TRIM(:TABLE_ALIAS));
  LV_NULL_FIELDS               := TO_NUMBER(:NULL_FIELDS);
  LV_NOT_NULL_FIELDS           := TO_NUMBER(:NOT_NULL_FIELDS);
  LV_OLD_NEW_4_TRIGGER         := TO_NUMBER(:OLD_NEW_4_TRIGGER);
  LV_OUTPUT_4_FORM_ASSIGNMENT  := TO_NUMBER(:OUTPUT_4_FORM_ASSIGNMENT);
  LV_OUTPUT_4_PLSQL_ASSIGNMENT := TO_NUMBER(:OUTPUT_4_PLSQL_ASSIGNMENT);
  LV_OUTPUT_4_SELECT           := TO_NUMBER(:OUTPUT_4_SELECT);

  LV_NOT_NULL_FIELDS_CONDITION := TRIM(:NOT_NULL_FIELDS_CONDITION);

  LV_NULL_FIELDS               := NVL(LV_NULL_FIELDS, 0);
  LV_NOT_NULL_FIELDS           := NVL(LV_NOT_NULL_FIELDS, 0);
  LV_OLD_NEW_4_TRIGGER         := NVL(LV_OLD_NEW_4_TRIGGER, 0);
  LV_OUTPUT_4_FORM_ASSIGNMENT  := NVL(LV_OUTPUT_4_FORM_ASSIGNMENT, 0);
  LV_OUTPUT_4_PLSQL_ASSIGNMENT := NVL(LV_OUTPUT_4_PLSQL_ASSIGNMENT, 0);
  LV_OUTPUT_4_SELECT           := NVL(LV_OUTPUT_4_SELECT, 0);

  IF (LV_OUTPUT_4_FORM_ASSIGNMENT = 1)
  THEN
    DBMS_OUTPUT.PUT_LINE('BEGIN');
  ELSIF (LV_OLD_NEW_4_TRIGGER = 1 OR LV_OUTPUT_4_PLSQL_ASSIGNMENT = 1 OR
        LV_OUTPUT_4_SELECT = 1)
  THEN
    DBMS_OUTPUT.PUT_LINE('SELECT ');
  END IF;
  FOR C IN ( --
            SELECT V.*
              FROM ALL_TAB_COLUMNS V
             WHERE V.TABLE_NAME LIKE UPPER(LV_TABLE_NAME)
                   AND V.COLUMN_NAME NOT IN (
                                             --
                                             'CREATE_DATE'
                                            ,'CREATE_BY_DB_USER'
                                            ,'CREATE_BY_APP_USER'
                                            ,'LAST_UPDATE_DATE'
                                            ,'LAST_UPDATE_BY_DB_USER'
                                            ,'LAST_UPDATE_BY_APP_USER'
                                            ,'LAST_CHANGE_TS'
                                            ,'MODULE_NAME'
                                            ,'OS_USERNAME'
                                            ,'ATTACH_ID'
                                             --
                                             )
            --
            )
  LOOP
  
    IF (NVL(LV_NOT_NULL_FIELDS, 0) = 0)
    THEN
      IF (NVL(LV_NULL_FIELDS, 0) = 0)
      THEN
        LV_SQL := 'SELECT 1 AS FLG FROM DUAL';
      ELSE
        LV_SQL := 'SELECT 1 AS FLG FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM ' ||
                  LV_SCHEMA || '.' || C.TABLE_NAME || ' T WHERE T.' ||
                  C.COLUMN_NAME || ' IS NOT NULL ';
        LV_SQL := LV_SQL || ' )';
      END IF;
    ELSE
      LV_SQL := 'SELECT 1 AS FLG FROM DUAL WHERE EXISTS (SELECT 1 FROM ' ||
                LV_SCHEMA || '.' || C.TABLE_NAME || ' T WHERE T.' ||
                C.COLUMN_NAME || ' IS NOT NULL ';
      IF (LV_NOT_NULL_FIELDS_CONDITION IS NOT NULL)
      THEN
        LV_SQL := LV_SQL || ' AND T.' || LV_NOT_NULL_FIELDS_CONDITION;
      END IF;
      LV_SQL := LV_SQL || ' )';
    
    END IF;
  
    BEGIN
      EXECUTE IMMEDIATE LV_SQL
        INTO L;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        L := 0;
    END;
    L := NVL(L, 0);
    --DBMS_OUTPUT.PUT_LINE('CASE WHEN ' || C.COLUMN_NAME ||' IS NULL THEN 1 END AS ' || C.COLUMN_NAME || ', ');
    -- DBMS_OUTPUT.PUT_LINE('LENGTH('||C.COLUMN_NAME||') AS '||C.COLUMN_NAME||', ')  ;
    --DBMS_OUTPUT.PUT_LINE(C.COLUMN_NAME || ', ');
    IF (L > 0)
    THEN
      --DBMS_OUTPUT.PUT_LINE(LV_TABLE_ALIAS || '.' || C.COLUMN_NAME || ', ');
      IF (LV_OUTPUT_4_FORM_ASSIGNMENT = 1)
      THEN
        DBMS_OUTPUT.PUT_LINE(':' || LV_TABLE_ALIAS || '.' || C.COLUMN_NAME ||
                             ' := :' || LV_TABLE_NAME || '.' ||
                             C.COLUMN_NAME || ';');
      ELSIF (LV_OLD_NEW_4_TRIGGER = 1)
      THEN
        DBMS_OUTPUT.PUT_LINE(LV_ADDITIVE || ':OLD.' || C.COLUMN_NAME ||
                             ' = :NEW.' || C.COLUMN_NAME);
        LV_ADDITIVE := ' AND ';
      ELSIF (LV_OUTPUT_4_PLSQL_ASSIGNMENT = 1)
      THEN
        DBMS_OUTPUT.PUT_LINE(LV_ADDITIVE || LV_TABLE_ALIAS || '.' ||
                             C.COLUMN_NAME || ' = ' || LV_TABLE_NAME || '.' ||
                             C.COLUMN_NAME);
        LV_ADDITIVE := ',';
      ELSIF (LV_OUTPUT_4_SELECT = 1)
      THEN
        DBMS_OUTPUT.PUT_LINE(LV_ADDITIVE || LV_TABLE_ALIAS || '.' ||
                             C.COLUMN_NAME);
        LV_ADDITIVE := ',';
      END IF;
    END IF;
  END LOOP;
  IF (LV_OUTPUT_4_FORM_ASSIGNMENT = 1)
  THEN
    DBMS_OUTPUT.PUT_LINE('END;');
  ELSIF (LV_OLD_NEW_4_TRIGGER = 1 OR LV_OUTPUT_4_PLSQL_ASSIGNMENT = 1 OR
        LV_OUTPUT_4_SELECT = 1)
  THEN
    IF (LV_OUTPUT_SCHEMA IS NULL)
    THEN
      DBMS_OUTPUT.PUT_LINE('FROM ' || LV_TABLE_NAME || ' ' ||
                           LV_TABLE_ALIAS);
    ELSE
      DBMS_OUTPUT.PUT_LINE('FROM ' || LV_SCHEMA || '.' || LV_TABLE_NAME || ' ' ||
                           LV_TABLE_ALIAS);
    END IF;
  END IF;
  DBMS_OUTPUT.PUT_LINE('--TO_DATE(A, ''YYYY/MM/DD'', ''NLS_CALENDAR=PERSIAN'') AS A');
  DBMS_OUTPUT.PUT_LINE('--TO_CHAR(A, ''YYYY/MM/DD'', ''NLS_CALENDAR=PERSIAN'') AS A');
END;
11
NULL_FIELDS
1
﻿0
5
NOT_NULL_FIELDS
1
﻿1
5
OLD_NEW_4_TRIGGER
1
﻿0
5
OUTPUT_4_FORM_ASSIGNMENT
1
﻿0
5
OUTPUT_4_PLSQL_ASSIGNMENT
1
﻿0
5
OUTPUT_4_SELECT
1
﻿1
5
SCHEMA_
1
﻿mam
5
OUTPUT_SCHEMA
0
5
TABLE_NAME
1
﻿mam_material_transactions
5
TABLE_ALIAS
1
﻿x
5
NOT_NULL_FIELDS_CONDITION
2
﻿ MTYP_TRANSACTION_TYPE_ID = 3
       AND CREATE_BY_DB_USER = 'SUP_BACKEND'
5
1
LV_SQL
0
0
