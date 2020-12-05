from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
import numpy as np
import scipy.sparse as sp

class TfidfVectorizerPlus(TfidfVectorizer):
    def __init__(self, fit_col=None, col_name=None, max_df=1.0, min_df=1):
        TfidfVectorizer.__init__(self)
        self.fit_col = fit_col
        self.col_name = col_name
        # self.max_df = max_df
        # self.min_df = min_df
        # self.ngram_range = ngram_range


    def transform(self, X):
        col = super().transform(X[self.col_name])
        X = X.drop(columns=['title', 'Category_3'])
        U=sp.hstack([col, X])
        # new_df = pd.SparseDataFrame(col)
        # U = pd.concat([new_df, X], axis=1)
        return U

    def fit_transform(self, raw_documents, y=None):
        if self.fit_col is not None:
            X_new = self.fit_col
        else:
            X_new = raw_documents

        super().fit_transform(X_new, y)

        U = self.transform(raw_documents)
        return U
