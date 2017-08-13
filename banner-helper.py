#!/usr/bin/env python

BANNER = """// ===================================================================================================
// Copyright (C) %d Kaltura Inc.
//
// Licensed under the AGPLv3 license, unless a different license for a 
// particular library is specified in the applicable library path.
//
// You may obtain a copy of the License at
// https://www.gnu.org/licenses/agpl-3.0.html
// ===================================================================================================
"""

import os
from sys import exit
from datetime import datetime

FIRST_YEAR = 2017
THIS_YEAR = datetime.now().year

def has_banner(d):
	d = d.lstrip()
	for year in xrange(FIRST_YEAR, THIS_YEAR + 1):
		if d.startswith(BANNER % year):
			return True
	return False

def process(dir):
	global modified_files
	banner = BANNER % THIS_YEAR
	for root, dirs, files in os.walk(dir):
		for name in files:
			fileExt = os.path.splitext(name)[1]
			if fileExt != '.swift':
				continue
		
			fullPath = os.path.join(root, name)
			d = file(fullPath, 'rb').read()
		
			if has_banner(d):
				continue
		
			d = banner + '\n' + d
		
			file(fullPath, 'wb').write(d)
			
			modified_files += 1


modified_files = 0

for dir in ('Addons', 'Classes', 'Plugins', 'Widevine'):
	process(dir)

# exit with 0 (OK) if there was at least one change.
exit(0 if modified_files > 0 else 1)
