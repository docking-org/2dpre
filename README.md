# 2dload - repository for zinc22 2D database logic

## description of files and subdirectories:

- *2dload.py, load_app/, psql/*

	- These files encompass the python+postgres interface with individual zinc22 databases. Used to perform critical operations such as uploading, patching, and exporting
	
	- *2dload.py*
		- Main executable, see python3 2dload.py --help

	- *load_app/*
		- Contains python codebase accessed by 2dload.py. Contains two main submodules, one for each of our database sub-systems tin & antimony, with the common folder holding logic common to both

	- *psql/*
		- Postgres code to be accessed by the python interface, contains the sql logic for our operations (python does the orchestration and nitty-gritty of operations, psql is the real workhorse)

- *preprocessing/*

	- Scripts for processing raw smiles data into canonicalized neutralized etc. format

- *install/*

	- Used for configuring new tin/antimony postgres databases. Needs an update.

- *utils-2d/*

	- Bash/python scripts for orchestrating operations on the zinc22 system as a whole. Contains multiple submodules, including one for each zinc22 subsystem

	- for example, 2d_upload_all.bash attempts to perform an upload operation across the system, using slurm to allocate resources and queue jobs

- *utils-2d/common_files*

	- Contains all sorts of (relatively) static data about the system, e.g which database is on which machine, which chemical tranches map to which tin database, etc.

- *utils-2d/zinc22_stats*

	- Scripts used to collect statistics across the system as a whole. Useful for assessing system health and problem areas.
