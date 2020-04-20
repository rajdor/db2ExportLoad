# Db2 export and load

This project is intended to be an example of Db2 Warehouse to Db2 Warehouse export and load


## Download Db2 Server Client
   * https://epwt-www.mybluemix.net/software/support/trial/cst/programwebsite.wss?siteId=850&h=null&p=null
   * Download IBM Data Server Client (Linux 32-bit AMD and Intel x86) Version  11.5
   
## Db2 Server Client installation
```bash
cd ~/Downloads
tar xvzf ibm_data_server_client_linuxx64_v11.5.tar.gz
cd client
sudo apt-get install libpam0g:i386 libaio1
sudo ln -s /lib/i386-linux-gnu/libpam.so.0 /lib/libpam.so.0
sudo apt-get install libx32stdc++6
./db2setup
```
   * Start a new terminal session, (the $HOME/sqllib/db2profile should have been added to your bash .profile)
   * Catalog your database(s)
```bash
db2 catalog tcpip node db2wh remote 192.168.72.129 server 50000
db2 catalog database bludb as bludb at node db2wh
db2 terminate
```
   * Test database connection 
```bash
 db2 connect to bludb user bluadmin using bluadmin

   Database Connection Information

 Database server        = DB2/LINUXX8664 11.1.9.0
 SQL authorization ID   = BLUADMIN
 Local database alias   = BLUDB
```

## Create config file

   * The shell script uses jq to read a config file and create environment variables for source and target connection, database and table details
   * Example below
```json
{
   "SOURCE_DATABASE":"bludb"	
  ,"SOURCE_USER":"bluadmin"
  ,"SOURCE_PASSWORD":"bluadmin"
  ,"SOURCE_SCHEMA":"TESTDATA"
  ,"SOURCE_TABLE":"CLAIM"

  ,"TARGET_DATABASE":"bludb"	
  ,"TARGET_USER":"bluadmin"
  ,"TARGET_PASSWORD":"bluadmin"
  ,"TARGET_SCHEMA":"TESTDATA"
  ,"TARGET_TABLE":"CLAIM2"
  
  ,"OPTION":"REPLACE"
}
```

## Run script
```bash
./db22db2.sh
```

```text
found jq
Reading Config
################################################################
SOURCE_DATABASE : bludb
SOURCE_USER     : bluadmin
SOURCE_PASSWORD : bluadmin
SOURCE_SCHEMA   : TESTDATA
SOURCE_TABLE    : CLAIM
################################################################
TARGET_DATABASE : bludb
TARGET_USER     : bluadmin
TARGET_PASSWORD : bluadmin
TARGET_SCHEMA   : TESTDATA
TARGET_TABLE    : CLAIM2
################################################################
OPTION          : REPLACE
################################################################
################################################################
WORKSPACE       : /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF
EXPORTFILE      : /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ixf
EXPORTMSGS      : /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM_export.txt
IMPORTFILE      : /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ixf
IMPORTMSGS      : /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM2_import.txt
################################################################
# CHECKING THE BASICS BEFORE WE GET STARTED ###################

   Database Connection Information

 Database server        = DB2/LINUXX8664 11.1.9.0
 SQL authorization ID   = BLUADMIN
 Local database alias   = BLUDB

OK : testing connection to bludb

   Database Connection Information

 Database server        = DB2/LINUXX8664 11.1.9.0
 SQL authorization ID   = BLUADMIN
 Local database alias   = BLUDB

OK : testing connection to bludb
OK : Found source table TESTDATA.CLAIM
OK : Target schema TESTDATA
OK : Found target table CLAIM2
################################################################
################################################################
INFO : About to connect to source

   Database Connection Information

 Database server        = DB2/LINUXX8664 11.1.9.0
 SQL authorization ID   = BLUADMIN
 Local database alias   = BLUDB

INFO : About to run export

Number of rows exported: 250000

SQL3104N  The Export utility is beginning to export data to file 
"/tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ixf".

SQL27984W  The export command completed successfully. However, some 
information that would be required to recreate one or more tables has not been 
saved to the output file. The file will not be able to be used by the IMPORT 
command to create or replace tables. Reason code: "16".

SQL3105N  The Export utility has finished exporting "250000" rows.

################################################################
INFO : About to connect to target

   Database Connection Information

 Database server        = DB2/LINUXX8664 11.1.9.0
 SQL authorization ID   = BLUADMIN
 Local database alias   = BLUDB

INFO : About to run load
load client from /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ixf of IXF messages /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM2_import.txt REPLACE into TESTDATA.CLAIM2 STATISTICS NO NONRECOVERABLE

Number of rows read         = 250000
Number of rows skipped      = 0
Number of rows loaded       = 250000
Number of rows rejected     = 0
Number of rows deleted      = 0
Number of rows committed    = 250000

SQL3109N  The utility is beginning to load data from file 
"/tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ixf".

SQL3500W  The utility is beginning the "ANALYZE" phase at time "04/20/2020 
10:32:21.211020".

SQL3150N  The H record in the PC/IXF file has product "DB2    02.00", date 
"20200420", and time "203158".

SQL3153N  The T record in the PC/IXF file has name 
"/tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ix", qualifier "", and 
source "            ".

SQL3519W  Begin Load Consistency Point. Input record count = "0".

SQL3520W  Load Consistency Point was successful.

SQL3515W  The utility has finished the "ANALYZE" phase at time "04/20/2020 
10:32:32.587518".

SQL3500W  The utility is beginning the "LOAD" phase at time "04/20/2020 
10:32:32.587777".

SQL3150N  The H record in the PC/IXF file has product "DB2    02.00", date 
"20200420", and time "203158".

SQL3153N  The T record in the PC/IXF file has name 
"/tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF/TESTDATA_CLAIM.ix", qualifier "", and 
source "            ".

SQL3110N  The utility has completed processing.  "250000" rows were read from 
the input file.

SQL3519W  Begin Load Consistency Point. Input record count = "250000".

SQL3520W  Load Consistency Point was successful.

SQL3515W  The utility has finished the "LOAD" phase at time "04/20/2020 
10:32:34.235156".

SQL3500W  The utility is beginning the "BUILD" phase at time "04/20/2020 
10:32:34.241610".

SQL3213I  The indexing mode is "REBUILD".

SQL3515W  The utility has finished the "BUILD" phase at time "04/20/2020 
10:32:34.578812".


Number of rows read         = 250000
Number of rows skipped      = 0
Number of rows loaded       = 250000
Number of rows rejected     = 0
Number of rows deleted      = 0
Number of rows committed    = 250000

################################################################
#  DON'T FORGET TO CLEAN UP WORKSPACE /tmp/ie-2020-04-20-20-31-52-EVp1aXhMYF
################################################################
```