CREATE OR REPLACE PROCEDURE sp_populate_dim_date (
    p_start_date DATE,
    p_end_date DATE
) AS
    v_current_date DATE := p_start_date;
BEGIN
    WHILE v_current_date <= p_end_date LOOP
        INSERT INTO dim_date (
            date_id,
            full_date,
            day_of_month,
            day_name,
            day_of_week,
            month_number,
            month_name,
            quarter,
            year_number,
            is_weekend
        )
        VALUES (
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYYMMDD')),
            v_current_date,
            TO_NUMBER(TO_CHAR(v_current_date, 'DD')),
            TO_CHAR(v_current_date, 'Day'),
            TO_NUMBER(TO_CHAR(v_current_date, 'D')),
            TO_NUMBER(TO_CHAR(v_current_date, 'MM')),
            TO_CHAR(v_current_date, 'Month'),
            TO_NUMBER(TO_CHAR(v_current_date, 'Q')),
            TO_NUMBER(TO_CHAR(v_current_date, 'YYYY')),
            CASE WHEN TO_CHAR(v_current_date, 'DY') IN ('SAT', 'SUN') THEN 1 ELSE 0 END
        );
        v_current_date := v_current_date + 1;
    END LOOP;
    COMMIT;
END;
/

-- Populate Date Dimension (Example: 2020 to 2030)
EXEC sp_populate_dim_date(TO_DATE('2020-01-01', 'YYYY-MM-DD'), TO_DATE('2030-12-31', 'YYYY-MM-DD'));

PROMPT 'Date Dimension Populated Successfully!';
