import pandas as pd

# Parses out numeric values in the selected column (e.g. removes sqft from '640 sqft'
def to_num(df, col):
    df[col].replace(regex=True, inplace=True, to_replace=r'[^0-9]', value=r'')
    df[col] = pd.to_numeric(df[col], errors='coerce')
    return df


# Standardizes private room and house values in 'rooms' to be numeric values
def convert_rooms(df):
    df['rooms'].replace('private room', 0.1, regex=False, inplace=True)
    df['rooms'].replace('house', 7.1, regex=False, inplace=True)
    df = to_num(df, 'rooms')
    return df

# Missing value imputation
# Input: Dataframe df, value to replace missing values with, column name
def missingImputation(df, value, colName):
    df[colName].fillna(value, inplace=True)

# Missing value imputation for multiple columns at once
def missingImputationMulti (df, value, colNames):
    for col in colNames:
        missingImputation(df, value, col)

# Create column with 3 categories based on the 10 category classification
# Input: DataFrame with column "Category" containing the 10 category classification
def threeCategory(df):
    df['Category_3'] = df['Category'].dropna().apply(lambda x: "1" if x < 3.0 else ("2" if x < 4.0 else "3"))
    df['Category_text'] = df['Category'].apply(lambda x: str(x))