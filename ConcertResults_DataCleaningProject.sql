/*
===============================================================================
SQL Data Cleaning Portfolio Project: Highest-Grossing Concert Tours
Environment: SQL Server Management Studio (SSMS) /
Database: DataCleaningProject
Raw Table: dbo.HighestGrossingConcertsDataset
===============================================================================

WHAT MAKES THIS DATASET "DIRTY"?
1. Wikipedia Footnote Citations:
   - Columns like [Peak], [All_Time_Peak], [Actual_gross], and [Tour_title] 
     contain bracketed references like "7[2]", "$229,100,000[b]", or "‡[4][a]".
2. Currency Formatting Stored as Text:
   - Gross revenue columns contain "$" and "," characters, preventing math 
     aggregations and sorting as numbers.
3. Special Typographical Symbols in Tour Titles:
   - Symbols like † (dagger), ‡ (double dagger), and * (asterisk) are attached 
     to tour names.
4. Combined Date Ranges with En-Dashes:
   - [Year_s] combines single years ("2023") and ranges ("2023–2024") separated 
     by an Unicode en-dash (NCHAR(8211)) rather than a standard hyphen.
5. Unnecessary Metadata Column:
   - The [Ref] column only holds Wikipedia footnote numbers and isn't needed 
     for analysis.
===============================================================================
*/

USE DataCleaningProject;
GO

-- ============================================================================
-- VIEW THE "BEFORE" DATA
-- ============================================================================
SELECT * FROM dbo.HighestGrossingConcertsDataset;
GO


-- ============================================================================
-- STEP 1: CREATE A STAGING TABLE & STANDARDIZE COLUMN NAMES
-- ============================================================================
-- Best practice so I never overwrite my raw imported table! Work on a copy so 
-- I can always re-run or audit my original data.

DROP TABLE IF EXISTS dbo.Staging_HighestGrossingConcertTours;

SELECT 
    [Rank],
    [Peak],
    [All_Time_Peak],
    [Actual_gross]                      AS Actual_Gross,
    [Adjusted_gross_in_2022_dollars]    AS Adjusted_Gross_2022,
    [Artist],
    [Tour_title]                        AS Tour_Title,
    [Year_s]                            AS Years_Raw,
    [Shows],
    [Average_gross]                     AS Average_Gross,
    [Ref]                               AS Ref_Col
INTO dbo.Staging_HighestGrossingConcertTours
FROM dbo.HighestGrossingConcertsDataset;
GO


-- ============================================================================
-- STEP 2: REMOVE WIKIPEDIA CITATIONS (e.g., "[4]", "[b]", "[21][a]")
-- ============================================================================
-- Technique: CHARINDEX('[', Column) finds the position of the first opening 
-- bracket. LEFT(Column, Position - 1) keeps everything before that bracket!

UPDATE dbo.Staging_HighestGrossingConcertTours
SET 
    Peak = CASE 
        WHEN CHARINDEX('[', Peak) > 0 
        THEN LEFT(Peak, CHARINDEX('[', Peak) - 1)
        ELSE Peak 
    END,
    All_Time_Peak = CASE 
        WHEN CHARINDEX('[', All_Time_Peak) > 0 
        THEN LEFT(All_Time_Peak, CHARINDEX('[', All_Time_Peak) - 1)
        ELSE All_Time_Peak 
    END,
    Actual_Gross = CASE 
        WHEN CHARINDEX('[', Actual_Gross) > 0 
        THEN LEFT(Actual_Gross, CHARINDEX('[', Actual_Gross) - 1)
        ELSE Actual_Gross 
    END,
    Tour_Title = CASE 
        WHEN CHARINDEX('[', Tour_Title) > 0 
        THEN LEFT(Tour_Title, CHARINDEX('[', Tour_Title) - 1)
        ELSE Tour_Title 
    END;
GO


-- ============================================================================
-- STEP 3: CLEAN SPECIAL SYMBOLS (†, ‡, *) & WHITESPACE FROM MY TITLES
-- ============================================================================
-- Technique: Nested REPLACE() strips out dagger symbols and asterisks, and 
-- TRIM() removes any trailing spaces left behind.

UPDATE dbo.Staging_HighestGrossingConcertTours
SET Tour_Title = TRIM(
    REPLACE(
        REPLACE(
            REPLACE(Tour_Title, N'†', ''),
        N'‡', ''),
    '*', '')
);
GO


-- ============================================================================
-- STEP 4: CLEAN CURRENCY STRINGS ("$" and ",")
-- ============================================================================
-- Technique: Strip out dollar signs and commas so SQL Server can convert the 
-- text strings into numeric BIGINT values.

UPDATE dbo.Staging_HighestGrossingConcertTours
SET 
    Actual_Gross        = TRIM(REPLACE(REPLACE(Actual_Gross, '$', ''), ',', '')),
    Adjusted_Gross_2022 = TRIM(REPLACE(REPLACE(Adjusted_Gross_2022, '$', ''), ',', '')),
    Average_Gross       = TRIM(REPLACE(REPLACE(Average_Gross, '$', ''), ',', ''));
GO


-- ============================================================================
-- STEP 5: SPLIT [Years_Raw] INTO [Start_Year] AND [End_Year]
-- ============================================================================
-- Technique: The raw column uses an Unicode en-dash '–' (NCHAR(8211)), e.g., 
-- "2023–2024". First I standardize '–' to a normal hyphen '-', then extract 
-- the 4-digit start and end years using LEFT() and RIGHT().

ALTER TABLE dbo.Staging_HighestGrossingConcertTours
ADD Start_Year INT,
    End_Year   INT;
GO

UPDATE dbo.Staging_HighestGrossingConcertTours
SET Years_Raw = REPLACE(Years_Raw, N'–', '-');

UPDATE dbo.Staging_HighestGrossingConcertTours
SET 
    Start_Year = CAST(LEFT(Years_Raw, 4) AS INT),
    End_Year   = CAST(RIGHT(TRIM(Years_Raw), 4) AS INT);
GO


-- ============================================================================
-- STEP 6: HANDLE EMPTY STRINGS (CONVERT BLANK "" TO NULL)
-- ============================================================================
-- Technique: NULLIF(TRIM(Column), '') turns any stray empty strings into NULLs 
-- so casting to INT won't fail.

UPDATE dbo.Staging_HighestGrossingConcertTours
SET 
    Peak          = NULLIF(TRIM(Peak), ''),
    All_Time_Peak = NULLIF(TRIM(All_Time_Peak), '');
GO


-- ============================================================================
-- STEP 7: BUILD FINAL CLEANED TABLE WITH PROPER SQL DATA TYPES
-- ============================================================================
-- I cast each column to its true data type (INT, BIGINT, NVARCHAR) and drop 
-- the unneeded [Years_Raw] and [Ref_Col] columns.

DROP TABLE IF EXISTS dbo.Cleaned_ConcertTours;

SELECT 
    CAST([Rank] AS INT)                     AS [Rank],
    CAST(Peak AS INT)                       AS Peak,
    CAST(All_Time_Peak AS INT)              AS All_Time_Peak,
    CAST(Actual_Gross AS BIGINT)            AS Actual_Gross,
    CAST(Adjusted_Gross_2022 AS BIGINT)     AS Adjusted_Gross_2022,
    CAST(TRIM(Artist) AS NVARCHAR(100))     AS Artist,
    CAST(Tour_Title AS NVARCHAR(150))       AS Tour_Title,
    Start_Year,
    End_Year,
    CAST(Shows AS INT)                      AS Shows,
    CAST(Average_Gross AS BIGINT)           AS Average_Gross
INTO dbo.Cleaned_ConcertTours
FROM dbo.Staging_HighestGrossingConcertTours
ORDER BY [Rank];
GO


SELECT * FROM dbo.Cleaned_ConcertTours
ORDER BY [Rank];

-- Optional Quality Check: Verify my cleaned numeric columns can now do math!
SELECT TOP 3
    Artist,
    COUNT(*)                                    AS Number_Of_Top_Tours,
    FORMAT(SUM(Actual_Gross), 'C0', 'en-US')    AS Total_Actual_Gross,
    FORMAT(AVG(Average_Gross), 'C0', 'en-US')   AS Avg_Gross_Per_Show
FROM dbo.Cleaned_ConcertTours
GROUP BY Artist
ORDER BY SUM(Actual_Gross) DESC;
GO