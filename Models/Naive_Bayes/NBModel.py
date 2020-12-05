import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB, BernoulliNB, MultinomialNB
from sklearn.metrics import accuracy_score


# Pre-processing the dataset
def label_housing_type(row):
    cat = row['Category']
    if cat >= 0 and cat < 3: return 'A'
    if cat >= 3 and cat < 4: return 'B'
    if cat == 4:
        return 'C'
    else:
        return cat


def clean_na(grid):
    if not grid >= 0:
        return 0
    else:
        return grid


def drop_column(col_array):
    for col in col_array:
        try:
            if col in df.columns:
                df.drop([col], axis=1, inplace=True)
        except FileNotFoundError as e:
            print(e)
            continue


csv_data = pd.read_csv('Imputated_data_m_1_20180822.csv')

df = pd.DataFrame(csv_data)

#df.drop(['X.2', 'X.3'], axis=1, inplace=True)
drop_column(['X.1', 'X.2', 'X.3'])


df['price'] = df['price'].map(clean_na)
df['rooms'] = df['rooms'].map(clean_na)
df['sqft'] = df['sqft'].map(clean_na)
df['Category'] = df['Category'].map(clean_na)

df['label'] = df.apply(lambda row: label_housing_type(row), axis=1)

data = df[['price', 'rooms', 'sqft', 'label']]

# print(df.loc[0:20][['price', 'rooms', 'sqft', 'label']])
# print(data[0:20])

X = data[['price', 'rooms', 'sqft']]
y = data['label']

# Checking the proportion of each label
summary = data.groupby('label')['price'].count().reset_index()
summary['proportion'] = summary['price'] / summary['price'].sum()
summary.rename(columns={'price': 'counts'}, inplace=True)
print(summary)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=None)

model = GaussianNB()
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)

print('Score is : ' + str(accuracy))


#Checking result proportion
y_pred = y_pred.tolist()

unique, counts = np.unique(y_pred, return_counts=True)
prop = dict(zip(unique, counts))

print(prop)


print(type(y_pred))



# print(df.dtypes)
