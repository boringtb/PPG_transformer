#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Apr 18 23:06:21 2021

@author: ktang5
"""

import os

INPUT_FOLDER = '/collab2/ktang5/data'
OUTPUT_FOLDER = '/collab2/ktang5/out_test_32' # no need for 35

def print_progress(i, n):
	a = int(20 * i/n)
	print('\r[' + '='*a + '>' + ' '*(20-a) + '] {:.1f}% '.format(100*i/n), end='')

print('Started')
files = os.listdir(INPUT_FOLDER)
files = [i for i in files if i[:2] == '32']
print('{:d} files to move.'.format(len(files)))

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

patients = set(i[:7] for i in files)
n = len(patients)
print('{:d} patients in total'.format(n))

for i, patient in enumerate(patients):
	try:
		os.makedirs(os.path.join(OUTPUT_FOLDER, patient), exist_ok=True)
		command = 'cp {0}/{2}* {1}/{2}/'.format(INPUT_FOLDER, OUTPUT_FOLDER, patient)
		os.popen(command)
	except KeyboardInterrupt:
		print('\nInterrupted by user')
		break
	print_progress(i, n)

print('Finished')
