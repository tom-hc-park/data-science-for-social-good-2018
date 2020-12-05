# Summary
.csv files containing raw data and intermediate processing steps.  

## File Structure
```
results  
|----address_parsing  
|----deduplication  
|----raw  
     `----raw_old  
```

## Detailed Description
* results: contains a single csv of raw data for the current month (for the Python script to automatically append to).
* address_parsing: csv containing parsed addresses
* deduplication: csv cleaned using various de-duplication methods
* raw:  Unprocessed csv files but standardized.
..* raw_old: Unprocessed csv files, but columns not standardized. 
