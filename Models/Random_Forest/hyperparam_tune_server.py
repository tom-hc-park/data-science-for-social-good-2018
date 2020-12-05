from sklearn.feature_extraction.text import TfidfVectorizer
import os
import config
import json
import pandas as pd
import numpy as np
import scipy.sparse as sp
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_val_score, train_test_split, RandomizedSearchCV, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from TfidfVectorizerPlus import TfidfVectorizerPlus 

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

f = "Imputated_data_sqft_price_rooms.csv"

df = pd.read_csv(f)
colNames = ['lat', 'long', 'price', 'sqft', 'rooms' ]
colNamesString = ['title', 'description']
df = df[pd.notnull(df['Category'])]
# Missing value imputation + collapse categories into 3
missingImputationMulti(df, -1, colNames)
missingImputationMulti(df, "", colNamesString)
threeCategory(df)

# One hot encoding for Rooms variable
rooms = pd.get_dummies(df['rooms'])
rooms = rooms.add_prefix('rms_')
df = pd.concat([df, rooms], axis=1)

# -------------------------- Hyperparameter Tuning ------------------------------------------------------------
# This Pipeline works for the model with titles only.
# pipeline = Pipeline([
#     ('tfidf', TfidfVectorizer()),
#     ('clf', RandomForestClassifier())
# ])



df = df.loc[:, df.columns.isin(['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
             'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price', 'title', 'Category_3'])]

X_train, X_test, y_train, y_test = train_test_split(df, df['Category_3'], test_size=0.2, stratify=df['Category_3'])

# Overload TfidfVectorizer with additional params to vectorize titles only
pipeline = Pipeline([
    ('tfidf', TfidfVectorizerPlus(fit_col=df['title'], col_name='title')),
    ('clf', RandomForestClassifier())
])


max_df = [float(x) for x in np.linspace(0.25, 0.7, 10)]
n_est = [int(x) for x in np.linspace(start=200, stop = 1400, num=50)]
max_features=['auto', 'sqrt']
max_depth = [int(x) for x in np.linspace(50,100, num=5)]
min_sample_split = [5,10]
min_sample_leaf = [1]
bootstrap = [False]
gridsearch = {
'tfidf__max_df': max_df,
    'tfidf__min_df': [0.0],
    
    'clf__n_estimators': n_est,
    'clf__max_features': max_features,
    'clf__max_depth': max_depth,
    'clf__min_samples_split': min_sample_split,
    'clf__min_samples_leaf': min_sample_leaf,
    'clf__bootstrap': bootstrap
}


grid_search = GridSearchCV(estimator=pipeline, param_grid=gridsearch, cv=3, n_jobs=-1, verbose=1)

grid_search.fit(X_train, y_train)
with open ('params_out.txt', 'a') as f:
    f.write("Grid search results:")
    f.write(json.dumps(grid_search.best_params_)+'\n')
    f.write(str(grid_search.best_score_)+'\n')
f.close()

#print(grid_search.best_params_)
#print(grid_search.best_score_)
