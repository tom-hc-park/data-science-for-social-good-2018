import nltk
import re

nltk.download('stopwords')
stopwords = nltk.corpus.stopwords.words('english')

# Remove punctuation and stopwords from pandas df row
def remove_punct_and_stopwords(row, colname):
    lowercase = str(row[colname]).lower()
    series = re.sub('[^a-z\s\d]', '', lowercase)
    series = [w for w in series.split() if w not in set(stopwords)]
    return series

# input_col - column name to apply on
# output_col - name of column to store output
# df - pandas data frame
def remove_stopwords(df, input_col, output_col):
    df[output_col] = df.apply(remove_punct_and_stopwords, axis=1, args=(input_col,))
    return df