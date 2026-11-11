# Data-Cleaning-Project
A collection of projects focusing on cleaning, transforming and preparing raw datasets for analysis. 


# SQL Data Cleaning Project: Highest-Grossing Concert Tours

Project Overview

This project demonstrates an end-to-end SQL Data Cleaning pipeline in SQL Server Management Studio (SSMS) using a raw Kaggle dataset of the highest-grossing concert tours by women.

Raw data scraped from Wikipedia often contains footnote citations ([4], [b]), special typographical symbols (†, ‡, *), currency formatting stored as text ("$780,000,000"), and multi-year date ranges (2023–2024). Using T-SQL string manipulation and type-casting functions, I transformed the raw dataset into an analysis-ready relational table.

## Raw Dataset (Before Cleaning)
[DatasetBeforeCleaning.png]

## Cleaned Dataset
[SSMSCleanedDataset.png]