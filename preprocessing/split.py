#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 27 15:37:18 2021

@author: ktang5
"""

import pandas as pd
import numpy as np
import time
import os
from sklearn.model_selection import train_test_split

df = pd.read_csv('o2_33_new_data.csv')

fl = os.listdir()
for f in fl[1:]:
    print(f)
    tempdf = pd.read_csv(f)
    df = pd.concat([df, tempdf])

X = X.reset_index(drop = True)
y = X[['2503', '2504']]
y.columns = ['SBP', 'DBP']
y['ID'] = y.index
y = y[['ID', 'SBP', 'DBP']]
z = pd.DataFrame(X.index, columns = ['ID'])
q = pd.concat([z, X], axis = 1)
q = q.drop(['2503', '2504'], axis = 1)
X_train, X_test, y_train, y_test = train_test_split(q, y, test_size=0.2, random_state=42)


import pickle
pickle.dump(df, open('./data','wb'),protocol = 4)
