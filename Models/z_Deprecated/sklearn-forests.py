from sklearn import preprocessing
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import train_test_split
import Common.nlp_utils as nutils
import pandas as pd
import numpy as np
import re

sum =0
def bag_words (row, colname):
    if len(row[colname]) > 0 and row[colname][0] != "nan" :
        try:
           return vec.fit_transform(row[colname])
        except:
            global sum
            sum+=1

# define input file path here:
# f = "../results/Standardized_Deduped_Datasets/1000samples_20180815_withoutstar_labelledJA.csv"
f = "../results/Standardized_Deduped_Datasets/1000samples_20180815_labelledJA.csv"

df = pd.read_csv(f)
vec = CountVectorizer(stop_words=None)

# Missing values
#df['sqft'] = df['sqft'].dropna().apply(lambda x: float(re.sub("\D", "", x)))

df['lat'].fillna(-1, inplace=True)
df['long'].fillna(-1, inplace=True)
df['price'].fillna(-1, inplace=True)
df['sqft'].fillna(-1, inplace=True)
df['rooms'].fillna(-1, inplace=True)
df['description'].fillna("", inplace=True)
df['title'].fillna("", inplace=True)

# df['Category_text'] = df['Category'].apply(lambda x: "whole" if x < 3 else "partial")
df['Category_text'] = df['Category'].apply(lambda x: str(x))

rooms = pd.get_dummies(df['rooms'])
df = pd.concat([df, rooms], axis=1)


# # Bag of words
# desc_corpus = vec.fit_transform(train['description'])
#
# title_corpus = vec.fit_transform(train['title'])
# title_corpus = title_corpus.toarray()

# features = ['price', 'sqft', 'rooms']
features = ['price', 'sqft', 0.0, 0.1, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]

# train = df.iloc[:99]
# test = df.iloc[99:]

train, test = train_test_split(df, test_size=0.2)

clf = RandomForestClassifier(n_jobs=2, random_state=1234)
# clf.fit(train[features], train['Label_0.entire_1.part'])
# prediction = clf.predict(test[features])
# test['predicted'] = prediction
#
# scores = cross_val_score(clf, train[features], train['Label_0.entire_1.part'], cv=10)
# print("Accuracy: %0.2f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))

clf.fit(train[features], train['Category_text'])
predict2 = clf.predict(test[features])
test['predict2'] = predict2
scores2 = cross_val_score(clf, train[features], train['Category_text'], cv=10)
print("Accuracy: %0.2f (+/- %0.2f)" % (scores2.mean(), scores2.std() * 2))

