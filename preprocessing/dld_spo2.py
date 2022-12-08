#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 11 08:01:28 2021

@author: ktang5
"""

import pandas as pd
import numpy as np
import time
import os
from sklearn.model_selection import train_test_split
from tqdm import tqdm
import wget
root_dir = '/collab2/ktang5/cleaned_39_new/'
os.chdir(root_dir)

l = os.listdir()

root_url = 'https://physionet.org/files/mimic3wdb/1.0/'

for i in tqdm(l):
    url = root_url + str(i[:2]) + '/' + str(i) + '/'
    tp_dir = root_dir + i
    os.chdir(tp_dir)
    
    d_url = url + i + '.hea?download'
    f = i + '.hea'
    wget.download(d_url, f)

    d_url = url + i + 'n.hea?download'
    f = i + 'n.hea'
    wget.download(d_url, f)
    
    d_url = url + i + 'n.dat?download'
    f = i + 'n.dat'
    wget.download(d_url, f)
