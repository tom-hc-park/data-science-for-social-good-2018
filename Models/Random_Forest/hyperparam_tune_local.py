from sklearn.feature_extraction.text import TfidfVectorizer
import os
import config
import json
import pandas as pd
import numpy as np
import scipy.sparse as sp
from Common.standardize_utils import missingImputationMulti, threeCategory
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_val_score, train_test_split, RandomizedSearchCV, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from Random_Forest.TfidfVectorizerPlus import TfidfVectorizerPlus

f = os.path.join(config.ROOT_DIR, 'results', 'Standardized_Deduped_Datasets', "Imputated_data_sqft_price_rooms.csv")
f2= os.path.join(config.ROOT_DIR, 'results', 'Standardized_Deduped_Datasets',
                 'Imputated_data_Aggregated_Clean_20180815_clipped_no_loc.csv')

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

pipeline = Pipeline([
    ('tfidf', TfidfVectorizerPlus(fit_col=df['title'], col_name='title')),
    ('clf', RandomForestClassifier())
])

# Random Search hyperparam tuning
max_df = [float(x) for x in np.linspace(0.2, 1.0, 10)]
n_est = [int(x) for x in np.linspace(start=10, stop = 2000, num=10)]
max_features=['auto', 'sqrt', 'log2', None]
max_depth = [int(x) for x in np.linspace(5,100, num=5)]
max_depth.append(None)
min_sample_split = [2,5,10]
min_sample_leaf = [1, 2, 4]
bootstrap = [True, False]
random_grid = {
    'tfidf__max_df': max_df,
    'tfidf__min_df': [0.0],
    'tfidf__ngram_range': [(1, 1), (1, 2), (1, 3)],
    'clf__n_estimators': n_est,
    'clf__max_features': max_features,
    'clf__max_depth': max_depth,
    'clf__min_samples_split': min_sample_split,
    'clf__min_samples_leaf': min_sample_leaf,
    'clf__bootstrap': bootstrap
}

random_search = RandomizedSearchCV(estimator=pipeline, param_distributions=random_grid, cv=5, n_iter=100)

random_search.fit(X_train, y_train)
with open ('params_out.txt', 'a') as f:
    f.write("Random search results:")
    f.write(json.dumps(random_search.best_params_)+'\n')
    f.write(str(random_search.best_score_)+'\n')
f.close()




# GridSearch hyperparam tuning
# max_df = [float(x) for x in np.linspace(0.25, 0.8, 20)]
# n_est = [int(x) for x in np.linspace(start=200, stop = 2000, num=100)]
# max_features=['auto', 'sqrt', 'log2', None]
# max_depth = [int(x) for x in np.linspace(50,100, num=10)]
# max_depth.append(None)
# min_sample_split = [5,10]
# min_sample_leaf = [1]
# bootstrap = [False]
# gridsearch = {
#     'tfidf__max_df': max_df,
#     'tfidf__min_df': [0.0],
#     'tfidf__ngram_range': [(1, 1)],
#     'clf__n_estimators': n_est,
#     'clf__max_features': max_features,
#     'clf__max_depth': max_depth,
#     'clf__min_samples_split': min_sample_split,
#     'clf__min_samples_leaf': min_sample_leaf,
#     'clf__bootstrap': bootstrap
# }
# grid_search = GridSearchCV(estimator=pipeline, param_grid=gridsearch, cv=5)
#
# grid_search.fit(X_train, y_train)
# with open ('params_out.txt', 'a') as f:
#     f.write("Random search results:")
#     f.write(json.dumps(grid_search.best_params_)+'\n')
#     f.write(str(grid_search.best_score_)+'\n')
# f.close()

# print(grid_search.best_params_)
# print(grid_search.best_score_)