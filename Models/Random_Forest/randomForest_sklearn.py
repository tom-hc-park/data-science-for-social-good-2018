from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import sklearn.metrics as metrics
import pandas as pd
import numpy as np
import scipy.sparse as sp
import matplotlib.pyplot as plt
import os
import config
from Common.standardize_utils import missingImputationMulti, threeCategory

# -------------------------- Helper Functions ------------------------------

# Fit the model and get predictions
def getPredictions(clf, test, train_x, train_y, test_x):
    clf.fit(train_x, train_y)
    predict2 = clf.predict(test_x)
    test['predict'] = predict2
    return clf

def getAccuracy (clf, test_x, test_y):
    accuracy = clf.score(test_x, test_y)
    return accuracy, clf.oob_score_

def printAccuracy (model_name, accuracy, oob):
    print(model_name)
    print("Prediction accuracy: %0.2f" % accuracy)
    print("OOB score: %0.2f" % oob)

# Gets the probability of the classification categories
def getClassificationProbability(clf, test, test_x):
    proba = pd.DataFrame(clf.predict_proba(test_x))
    proba = proba.add_prefix('proba_')
    test2 = test.reset_index()
    out_df = pd.concat([test2, proba], axis=1)
    return out_df

def getRFClassifier(n_jobs=2, n_estimators=250, max_depth=50, random_state=1234, oob_score=True):
    return RandomForestClassifier(n_jobs=n_jobs, n_estimators=n_estimators, random_state=random_state,
                                  oob_score=oob_score, max_depth=max_depth)

# Plots the prediction accuracy and OOB scores for the range of estimators from 1 to n_estimators
def plotVaryingEstimators (n_estimators, test, train_x, train_y, test_x, test_y):
    arr = []
    arr2 = []
    for i in range(1, n_estimators):
        clf = getRFClassifier(n_estimators=i)
        clf = getPredictions(clf, test, train_x, train_y, test_x)
        pred, oob = getAccuracy(clf, test_x, test_y)
        arr.append(pred)
        arr2.append(1.0-oob)
    x_coordinate = [i for i in range(len(arr))]
    plt.plot(x_coordinate, arr)
    plt.plot(x_coordinate, arr2)
    plt.show()

# Code for printing influential features
def printInfluentialFeatures(clf):
    importances = clf.feature_importances_
    std = np.std([tree.feature_importances_ for tree in clf.estimators_],
                 axis=0)
    indices = np.argsort(importances)[::-1]
    print(importances.shape)
    print("Feature ranking:")

    for f in range(features.shape[1]):
        print("%d. feature %d (%f)" % (f + 1, indices[f], importances[indices[f]]))

# Get tfidfVectorizer and do transformations
def getTfidfVec(train, test, max_df=0.55):
    vec = TfidfVectorizer(max_df= max_df)
    train_x = vec.fit_transform(train)
    test_x = vec.transform(test)

    # feature_array = np.array(vec.get_feature_names())
    # tfidf_sorting = np.argsort(test_x.toarray()).flatten()[::-1]
    # n = 5
    # top_n = feature_array[tfidf_sorting][:n]
    # print(top_n)
    return train_x, test_x

# TODO: bugfix required for the for loop to correctly vectorize then fit the models. Try with Pipeline?
# Code for plotting OOB and % accuracy with varying max_df
# max_df is the number of points to plot (integer value)
# def plotVaryingMaxdf(max_df, clf, test, train_tfidf, test_tfidf, train_y, test_y):
#     arr = []
#     arr2 = []
#     for i in range(1, max_df):
#         train_x, test_x = getTfidfVec(train_tfidf, test_tfidf)
#         clf = getPredictions(clf, test, test_x, train_x, train_y)
#         acc, oob = getAccuracy(clf, test_x, test_y)
#         arr.append(acc)
#         arr2.append(1.0-oob)
#     x_coordinate = [i/max_df for i in range(1, max_df)]
#     plt.plot(x_coordinate, arr, label="% Prediction accuracy")
#     plt.plot(x_coordinate, arr2, label= "% OOB error")
#     plt.title("Prediction accuracy and OOB error with varying max_df values")
#     plt.xlabel("max_df")
#     plt.show()


# -------------------------- Script to run the classifiers and print the results ------------------------------

# define input file path here:
# f = "../results/Standardized_Deduped_Datasets/1000samples_20180815_withoutstar_labelledJA.csv"
# f = "../results/Standardized_Deduped_Datasets/1000samples_20180815_labelledJA.csv"
f = os.path.join(config.ROOT_DIR, 'results', 'Standardized_Deduped_Datasets', "2000samples_labeled_20181021.csv")
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

# create a stratified train-test split
train, test = train_test_split(df, test_size=0.2, stratify=df['Category_3'])

# tfidf vectorizer for title
train_title, test_title = getTfidfVec(train['title'], test['title'])

# join the tf-idf matrix with other features
df2 = train[['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
             'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price']]
features = sp.hstack([train_title, df2.values])
test_features = sp.hstack([test_title, test[['rms_0.0', 'rms_0.1', 'rms_1.0', 'rms_2.0', 'rms_3.0', 'rms_4.0',
             'rms_5.0', 'rms_6.0', 'rms_7.0', 'rms_7.1', 'price']].values])

# #Logistic regression with TFIDF on titles, 10 classes
# model = LogisticRegression()
# model.fit(train_x, train["Category_text"])
# test['predict'] = model.predict(test_x)
# scores = metrics.accuracy_score(test['Category_text'],test['predict'])
# c_val_score = cross_val_score(model, train_x, train['Category_text'], cv=10)
# print("Logistic Regression")
# print("Accuracy: %0.2f (+/- %0.2f)" % (c_val_score.mean(), c_val_score.std() * 2))
# print("Prediction: %0.2f" % scores)

# Random_Forest Classifier from sklearn, with default settings
clf = getRFClassifier()

# #Random forest, TFIDF titles, 10 classes
# clf = getPredictions(clf, test, train_x, train['Category_text'], test_x)
# acc, oob = getAccuracy(clf, test_x, test['Category_text'])
# printAccuracy("rf-titles-10categories", acc, oob)
#
# #Random forest, TFIDF titles, 3 classes
# clf = getPredictions(clf, test,  train_x, train['Category_3'], test_x)
# acc, oob = getAccuracy(clf, test_x, test['Category_3'])
# printAccuracy("rf-titles-3categories", acc, oob)
#
# #Random forest, TFIDF titles + rooms, price, 10 classes
clf = getPredictions(clf, test, features, train['Category_text'], test_features)
acc, oob = getAccuracy(clf, test_features, test['Category_text'])
printAccuracy("rf-titles-rms-price-10categories", acc, oob)
print(metrics.confusion_matrix(test['Category_3'], test['predict']))

#Random forest, TFIDF titles + rooms, price, 3 classes
clf = getPredictions(clf, test, features, train['Category_3'], test_features)
acc, oob = getAccuracy(clf, test_features, test['Category_3'])
printAccuracy("rf-titles-rms-price-3categories", acc, oob)
print(metrics.confusion_matrix(test['Category_3'], test['predict']))
#plotVaryingEstimators(50, test, features, train['Category_3'], test_features, test['Category_3'])

