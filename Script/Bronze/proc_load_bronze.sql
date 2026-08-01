/*
===============================================================================
Stored Procedure: Load Bronze Layer (Raw GA4 Data Ingestion)
===============================================================================
Script Purpose:
    This procedure truncates and loads raw Google Analytics 4 event export CSV 
    data into the 'bronze.google_analytics_data' table using BULK INSERT.
    
    It logs step execution times, handles CSV quoting, and formats data landing.
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.proc_load_bronze AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '==================================================';

        -----------------------------------------------------------------------
        -- 1. Ingest Google Analytics Dataset
        -----------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.google_analytics_data';
        
        TRUNCATE TABLE bronze.google_analytics_data;

        PRINT '>> Inserting Table: bronze.google_analytics_data';

        BULK INSERT bronze.google_analytics_data
        FROM 'E:\KLaggle google anlytics data set\google_analytics_data.csv'
        WITH (
            FIRSTROW = 2,
            FORMAT = 'CSV',                  -- Crucial for handling real CSV structures
            FIELDTERMINATOR = ',',
            FIELDQUOTE = '"',                -- Strips out quotation marks automatically
            ROWTERMINATOR = '0x0a',          -- Maps perfectly to Unix (LF) format
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(ss, @start_time, @end_time) AS VARCHAR) + ' sec';
        PRINT '>> ----------';

        SET @batch_end_time = GETDATE();
        PRINT '==================================================';
        PRINT '>> Bronze Layer Load Completed Successfully.';
        PRINT '>> Total Execution Time: ' + CAST(DATEDIFF(ss, @batch_start_time, @batch_end_time) AS VARCHAR) + ' sec';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        PRINT '==================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT '==================================================';
    END CATCH
END;
GO
