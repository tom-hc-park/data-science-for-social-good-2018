import re
import pandas as pd
import numpy as np
import spacy
from pathlib import Path
from sklearn.feature_extraction.text import TfidfVectorizer
import config
from sklearn.base import TransformerMixin
from sklearn.feature_extraction.stop_words import ENGLISH_STOP_WORDS
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from Random_Forest.TfidfVectorizerPlus import TfidfVectorizerPlus
from Common.standardize_utils import missingImputationMulti, threeCategory
import scipy.sparse as sp


class DescriptionTransformer(TransformerMixin):
    def transform(self, X, **transform_params):
        return [cleanDesc(text) for text in X]

    def fit(self, X, y=None, **fit_params):
        return self

    def get_params(self, deep=True):
        return()

def cleanDesc(text):
    text = text.strip().replace("\n", " ").replace("\r", " ")
    text = text.lower()
    text = re.sub(' +', ' ', text)
    return text

def tokenize(text):
    tokens = nlp(text)
    lemmas = []
    for t in tokens:
        if not t.is_punct and not t.is_bracket:
            lemmas.append(t.lemma_.lower().strip() if t.lemma_ != '-PRON-' else t.lower_)

    tokens = lemmas
    tokens = [t for t in tokens if t not in ENGLISH_STOP_WORDS]

    return tokens

def printNMostInformative(vectorizer, clf, N, model_features):
    feature_names = vectorizer.get_feature_names()+model_features
    coefs_with_names = sorted(zip(clf.feature_importances_, feature_names))
    least_impt = coefs_with_names[:N]
    most_impt = coefs_with_names[:-(N + 1):-1]
    print("Lowest feature importances")
    for feat in least_impt:
        print(feat)
    print("Highest feature importances ")
    for feat in most_impt:
        print(feat)

df = pd.read_csv(Path(config.ROOT_DIR)/'results'/'Standardized_Deduped_Datasets'/'2000samples_labeled_20181021.csv')

nlp = spacy.load('en')
text = df.iloc[0]['description']


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
df = df.loc[:, df.columns.isin(['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
             'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price', 'description', 'title','Category_3'])]

X_train, X_test, y_train, y_test = train_test_split(df, df['Category_3'], test_size=0.2, stratify=df['Category_3'])


vec = TfidfVectorizer(tokenizer=tokenize)
# vec = TfidfVectorizer()
clf = RandomForestClassifier(n_jobs=2, n_estimators=250, max_depth=50, random_state=1234, oob_score=True)

train_desc = vec.fit_transform(X_train['description'])
test_desc = vec.transform(X_test['description'])
df_train_desc = pd.DataFrame(train_desc.toarray(), columns=vec.get_feature_names())
df_test_desc = pd.DataFrame(test_desc.toarray(), columns=vec.get_feature_names())

train_title = vec.fit_transform(X_train['title'])
test_title = vec.transform(X_test['title'])
df_train_title = pd.DataFrame(train_title.toarray(), columns=vec.get_feature_names()).add_prefix("title_")
df_test_title = pd.DataFrame(test_title.toarray(), columns=vec.get_feature_names()).add_prefix("title_")

additional_features = ['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
             'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price']

X_train_features = X_train[additional_features]
X_train_features.reset_index(inplace=True)
X_test_features = X_test[additional_features]
X_test_features.reset_index(inplace=True)

df_train = pd.concat([df_train_desc, df_train_title, X_train_features.drop('index', axis=1)], axis=1)
df_test = pd.concat([df_test_desc, df_test_title, X_test_features.drop('index', axis=1)], axis=1)

clf.fit(df_train, y_train)
predict = clf.predict(df_test)
print("Prediction accuracy: %0.2f" % clf.score(df_test, y_test))
print("OOB score: %0.2f" % clf.oob_score_)
feature_importances = pd.DataFrame(clf.feature_importances_,
                                   index = df_train.columns,
                                   columns=['importance']).sort_values('importance', ascending=False)
print(feature_importances.head(10))

df_train = pd.concat([df_train_desc, X_train_features.drop('index', axis=1)], axis=1)
df_test = pd.concat([df_test_desc, X_test_features.drop('index', axis=1)], axis=1)
clf.fit(df_train, y_train)
predict = clf.predict(df_test)
print("Prediction accuracy: %0.2f" % clf.score(df_test, y_test))
print("OOB score: %0.2f" % clf.oob_score_)
feature_importances = pd.DataFrame(clf.feature_importances_,
                                   index = df_train.columns,
                                   columns=['importance']).sort_values('importance', ascending=False)
print(feature_importances.head(10))

df_train = pd.concat([df_train_title, X_train_features.drop('index', axis=1)], axis=1)
df_test = pd.concat([df_test_title, X_test_features.drop('index', axis=1)], axis=1)
clf.fit(df_train, y_train)
predict = clf.predict(df_test)
print("Prediction accuracy: %0.2f" % clf.score(df_test, y_test))
print("OOB score: %0.2f" % clf.oob_score_)
feature_importances = pd.DataFrame(clf.feature_importances_,
                                   index = df_train.columns,
                                   columns=['importance']).sort_values('importance', ascending=False)
print(feature_importances.head(10))
# df2 = X_train[additional_features]
# features = sp.hstack([train_desc, df2.values])
# test_features = sp.hstack([test_desc, X_test[['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
#              'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price']].values])
# clf.fit(features, y_train)
# predict2 = clf.predict(test_features)
# X_test['predict'] = predict2
#
# print("Prediction accuracy: %0.2f" % clf.score(test_features, y_test))
# print("OOB score: %0.2f" % clf.oob_score_)
# printNMostInformative(vec, clf, 10, additional_features)


# pipe = Pipeline([('clean', DescriptionTransformer()),
#                  # ('tfidf', TfidfVectorizerPlus(fit_col=df['title'], col_name='title')),
#                  ('tfidf_desc', vec),
#                  ('clf', clf)
#                  ])
#
# pipe.fit(X_train, y_train)
# pipe.predict(X_test)
# print(pipe.score_)