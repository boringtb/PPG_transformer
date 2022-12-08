#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Apr 24 14:25:43 2021

@author: ktang5
"""


import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

os.chdir('/collab2/ktang5/summary')
dirs = os.listdir()
rootdir = os.getcwd()

import pickle
f = open('/collab2/ktang5/dict_r_p.pkl', 'rb')
dict_r_p = pickle.load(f)
#x = pd.read_csv('3302465_0010m.mat_matrixRawCyclesGood.csv', header = None)
#%% slice cnt
cnts = pd.DataFrame(columns = ['record_id', 'slice_cnt'], dtype = 'float64')

for i in range(10):
    id = str(i + 30)
    df = pd.read_csv('{0}_cnts.csv'.format(id))
    df = df.iloc[:, 1:]
    cnts = pd.concat([cnts, df])
cnts['slice_cnt'].sum()
out = pd.cut(cnts['slice_cnt'], bins=[0, 200, 400, 600, 800, 1000, 2000, 4000, 8000], include_lowest=True)
out_norm = out.value_counts(sort=False)
ax = out_norm.plot.bar(rot=0, color="b", figsize=(6,4))
#ax.set_xticklabels([c[1:-1].replace(","," to") for c in out.cat.categories])
plt.setp(ax.get_xticklabels(), rotation=90)
plt.ylabel("record count")
plt.xlabel("slices count range")
plt.title("slices frequency in each record")
plt.show()

#%% convert
cnts = cnts.reset_index(drop = True)
inval_cnts = 0
val = []
for i in range(len(cnts)):
    r = cnts['record_id'][i]
    try:
        x = dict_r_p[r]
        val.append(x)
    except:
        inval_cnts += 1
        pass

len(set(val))        


#%% SBP 
BPs = pd.DataFrame(columns = ['0', '1'], dtype = 'float64')

for i in range(10):
    id = str(i + 30)
    df = pd.read_csv('{0}_BPs.csv'.format(id))
    df = df.iloc[:, 1:]
    BPs = pd.concat([BPs, df])
    
out = pd.cut(BPs['0'], bins=list(range(0, 200)), include_lowest=True)
out_norm = out.value_counts(sort=False)

from matplotlib.ticker import MultipleLocator, FormatStrFormatter
ax = out_norm.plot.bar(rot=0, color="b", figsize=(6,4))

majorLocator   = MultipleLocator(25)
majorFormatter = FormatStrFormatter('%d')
minorLocator   = MultipleLocator(1)

ax.xaxis.set_major_locator(majorLocator)
ax.xaxis.set_major_formatter(majorFormatter)
ax.xaxis.set_minor_locator(minorLocator)

plt.ylabel("slice count")
plt.xlabel("SBP value")
plt.title("SBP distribution")
plt.show()

#%% DBP 
BPs['1'].min()
    
out = pd.cut(BPs['1'], bins=list(range(0, 150)), include_lowest=True)
out_norm = out.value_counts(sort=False)

from matplotlib.ticker import MultipleLocator, FormatStrFormatter
ax = out_norm.plot.bar(rot=0, color="b", figsize=(6,4))

majorLocator   = MultipleLocator(25)
majorFormatter = FormatStrFormatter('%d')
minorLocator   = MultipleLocator(1)

ax.xaxis.set_major_locator(majorLocator)
ax.xaxis.set_major_formatter(majorFormatter)
ax.xaxis.set_minor_locator(minorLocator)


plt.ylabel("slice count")
plt.xlabel("DBP value")
plt.title("DBP distribution")
plt.show()