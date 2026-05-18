
import pandas as pd

import numpy as np

from dateutil.parser import parse
 
def clean_data_pipeline(csv_file):

    """

    This pipeline is intended to use for cleaning the data from csv

    by doing the folliwng tasks step by step.

    1. Loading Data

    2. Trimming Text

    3. Remove $ in Purchase Column

    4. Binning into Category

    5. Outlier Detection

    6. Data Validation

    """

    #1. Loading Data

    df = pd.read_csv(csv_file)
 
    # 2. Triming Text and conveting to Title Style

    df = df.applymap(lambda x: x.strip().title() if type(x) == str else x)
 
    # 3. Remove $ in Purchase Column

    def clean_purchase_amount(x):

        if isinstance(x, str):

            x = x.replace('$', '').strip()

        try:

            return float(x)

        except Exception:

            return np.nan
 
    df['Purchase_Amount'] = df['Purchase_Amount'].apply(clean_purchase_amount)

    
    # 4. Binning into Category

    my_bins = [0,200,400, float('inf')]

    my_labels = ['Low', 'Medium', 'High']
 
    df['Spending_Category'] = pd.cut(df['Purchase_Amount'], bins = my_bins, labels = my_labels, right=False)

    
    # 5. Outlier Detection

    Q1 = df['Purchase_Amount'].quantile(0.25)

    Q3 = df['Purchase_Amount'].quantile(0.75)

    IQR = Q3 - Q1

    outlier_condition = (df['Purchase_Amount'] < (Q1 - 1.5 * IQR)) | (df['Purchase_Amount'] > (Q3 + 1.5 * IQR))

    outliers = df.loc[outlier_condition, ['RecordID', 'Purchase_Amount']]

    mean_purchase = df['Purchase_Amount'].mean()

    df.loc[outlier_condition, ['Purchase_Amount']] = mean_purchase

    
    # 6. Data Validation

    df['Purchase_Amount'] = df['Purchase_Amount'].fillna(df['Purchase_Amount'].mean())

    df['Join_Date'] = df['Join_Date'].apply(lambda x: parse(x, dayfirst=True))
 
    return df
 