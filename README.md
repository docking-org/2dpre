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
	
## Installation

Admittedly, this system has been under development in the highly-specific environment of our lab cluster, thus links to local cluster files, programs, as well as assumptions about what software is pre-installed on machines may be contained in the code of this repository. To the best of our ability we have tried to keep the logic mostly self-contained in this repository. Here we will attempt to describe a procedure for installing this software to your own cluster. Masochism not required, but recommended.

### Setting up databases

1. Install tin01 code repository & python environment- this is necessary for chemical pre-processing of source data. Without this step molecules won't be canonicalized, thus duplicate molecules may enter the system. Elide this at your own risk.

2. Install postgres on all designated database machines, and create tin instances using install/create-tin-instances.sh. The allocation of tin instances to machines and subsequently chemical tranches to those instances is not a simple task, and depends on the distribution & size of data you wish to upload. The distribution of data also affects the optimal level of partitioning for database instances. If you'd rather not think too hard about this, you can set all instances to use ~128 partitions.
If you'd like to be thorough and set partitioning on an instance-by-instance basis, you should shoot for ~1GB of raw chemical data per partition. Thus if an instance will own ~512GB of raw data, e.g H23P200 molecules, it should be allocated 512 partitions.
You can view our chemical space configuration in common_files/partitions.txt. This "partitions" file maps chemical partitions to instances, not physical database ones. You can view our physical partition configuration in common_files/physical_partitions.txt.

3. Create antimony instances using install/create-antimony-instances.sh. Antimony instances play nicer than tin ones (as they are evenly distributed via hash function rather than chemical properties), and have a static configuration of 128 partitions per instance, which can be adjusted up or down if preferred. 128 partitions per instance w/64 instances is suitably fast for the volume of data zinc22 has. You also need fewer antimony instances than you do tin instances, about half.
Similar to TIN, there are physical partitions of the database within an instance, as well as logical partitioning between instances. Each antimony instance is given ownership of a portion of codes based on the last digits of the sha256 hash of the code. This mapping is defined in load_app/antimony/hash_partition_map.txt, and the mapping of machine addresses to hash partitions is defined in load_app/antimony/machine_partition_map.txt.

4. Create the common database, which is used by numerous programs inside and outside the repository to access common database configuration. The contents & schema of this database are described in the supplemental methods of the zinc22 paper, and shares much of its contents with files found in common_files.

### Uploading data

Once database instances, partitions, and common configuration have been created, it is now possible to upload data to the system.

We use slurm scripts to orchestrate our database operations, thus slurm is expected to be installed across the database cluster.

1. Split the data into HAC/LogP tranches via preprocessing/rdkit_hlogp_batch_mp_2.py. This uses the same environment as tin01.

2. Pre-process the data via preprocessing/pre_process_all.bash. You'll also need to modify pre_process.bash to point to your installation of tin01. This script should be run in a screen or background process, as it will need to stay alive until all jobs have been submitted (which may take some time due to maximum queue size).

3. Since this is a distributed upload, things can go wrong. We have systems in place to ensure that the system is relatively synchronized, or at least if something goes wrong it can be isolated. 
	- The first of these systems is the patch system- patches are applied across the whole system, and uploads can only proceed if an instance is up-to-date on patches. There have been many patches through our database's history, but starting from a fresh install there shouldn't be any required patches. 
		- Creating a patch requires writing & modifiying code. First, .pgsql files need to be created that define 
			1. the code for patch functions "code.pgsql"
			2. the code for applying the patch "apply.pgsql" and 
			3. the code for testing the patch "test.pgsql". 
		- All of this code must execute successfully on a database for the patch to be considered "complete"
		- A patch does not have to have all these files defined, for example just "code.pgsql" could be defined for a patch. 
		- A corresponding python class must be created for this patch, you can see examples of this in load_app/tin/patches
		- The patch load order is defined in 2dload.py in the "checktinpatches" and "checksbpatches" functions. Starting from a fresh install, all of these should be removed prior to loading (our patches will contain hard-coded references etc and don't make sense on a fresh system)
	- The second system is our upload history system. This system only applies to TIN, as it is more sensitive than its sister system, antimony.
		- Side note: if antimony did break or the data inside became malformed somehow, it would be much simpler to synchronize than TIN, as we can simply blank the antimony databases and upload again
	- The upload history system simply requires all upload operations to be entered into a log (common_files/tin_upload_history.txt), and requires that uploads to individual databases are performed in the order specified in the log. This makes upload/rollback operations across the system as a whole coherent.
	
4. Upload data via utils-2d/tin/2d_upload_all.bash. You must specify source files, an upload name (must also be defined in tin_upload_history.txt) as well as a directory destination for the upload diff (usable for a hypothetical rollback).

5. Once upload has completed, it is possible to export the data to disk. This can be accomplished via utils-2d/tin/2d_export_all.bash. You must specify a destination directory, as well as an export type. Export types are described in the supplemental methods of the zinc22 paper. ZINC IDs are generated from the uploaded data- you may wish to modify these ZINC IDs such that they are distinct from our ZINC IDs (modifying the 3rd/4th digit after ZINC is safe to do without corrupting the information encoded in the ID)

### Searching the database

utils-2d/tin/search_zinc22.py is a simple but effective script for searching across the database. It is documented in the wiki @ https://wiki.docking.org/index.php/Search_zinc22.py. Once you've completed all the previous steps it should be possible to use this script to search for molecules.

You can also install your own version of cartblanche for this purpose, but search_zinc22.py is simpler. Psycopg2 & postgres libraries are required for the search_zinc22.py script.
