#!/bin/sh
#Usage: db.sh
#Author:suhasini.medicherla@oracle.com
#Creation Date:Feb-16-2023

HOME_DIR=/scratch
SHIPHOME_DB=/ade_autofs/ud222_db/RDBMS_19.14.0.0.0DBRU_LINUX.X64.rdd/LATEST/install/shiphome/goldimage/db_home.zip
EXIT_STATUS="Success"
Results=${HOME_DIR}/results

cd ${HOME_DIR}

#creating results directory

if [ ! -d "results" ]
then
        echo "Results Directory dosen't exist under workspace.. Creating new"
        mkdir -p results
else
        echo "Directory already available .. cleaning up the contents of dir"
        rm -rf results/*
fi

#Creating DB directory

if [ ! -d "DB" ]
then
        echo "DB Directory dosen't exist under workspace.. Creating new"
        mkdir -p DB
else
        echo "DB Directory already available .. cleaning up the contents of dir"
        rm -rf DB/*
fi

rm -rf database
rm -rf ${HOME_DIR}/database/oraInventory/*
cd DB
echo "Copying the Installer"
cp ${SHIPHOME_DB} .
echo "unzipping"
unzip db_home.zip > unzip.txt

echo "Generate Response file"

function generate_rsp()
{

        FILENAME=${HOME_DIR}/db.rsp
        if [ -f FILENAME ];
        then
                rm db.rsp;
                       else
               touch db.rsp
        fi

        echo 'oracle.install.option=INSTALL_DB_SWONLY' \ >> $FILENAME
        echo 'oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v12.1.0' \ >> $FILENAME
        echo 'ORACLE_HOSTNAME=`mporacle19i -f`' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.type=GENERAL_PURPOSE' \ >> $FILENAME
        echo 'UNIX_GROUP_NAME=dba' \ >> $FILENAME
        echo "INVENTORY_LOCATION=${HOME_DIR}/database/oraInventory" \ >> $FILENAME
        echo 'SELECTED_LANGUAGES=en' \ >> $FILENAME
        echo "ORACLE_HOME=${HOME_DIR}/DB" \ >> $FILENAME
        echo "ORACLE_BASE=${HOME_DIR}/DB/work" \ >> $FILENAME
        echo 'oracle.install.db.InstallEdition=EE' \ >> $FILENAME
        echo 'oracle.install.db.DBA_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.OPER_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.CLUSTER_NODES=' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.globalDBName=testdb.us.oracle.com' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.SID=testdb' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.characterSet=AL32UTF8' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.memoryLimit=810' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.memoryOption=true' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.installExampleSchemas=true' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.password.ALL=welcome1' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.password.SYS=' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.password.SYSTEM=' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.password.DBSNMP=' \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE' \ >> $FILENAME
        echo "oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=${HOME_DIR}/DB/oradata" \ >> $FILENAME
        echo 'oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=' \ >> $FILENAME
        echo 'oracle.install.db.config.asm.diskGroup=' \ >> $FILENAME
        echo 'oracle.install.db.config.asm.ASMSNMPPassword=' \ >> $FILENAME
        echo 'MYORACLESUPPORT_USERNAME=' \ >> $FILENAME
        echo 'MYORACLESUPPORT_PASSWORD=' \ >> $FILENAME
        echo 'SECURITY_UPDATES_VIA_MYORACLESUPPORT=false' \ >> $FILENAME
        echo 'DECLINE_SECURITY_UPDATES=true' \ >> $FILENAME
        echo 'PROXY_HOST=' \ >> $FILENAME
        echo 'PROXY_PORT=' \ >> $FILENAME
        echo 'PROXY_USER=' \ >> $FILENAME
        echo 'PROXY_PWD=' \ >> $FILENAME
        echo 'COLLECTOR_SUPPORTHUB_URL=' \ >> $FILENAME
        echo 'oracle.installer.autoupdates.option=' \ >> $FILENAME
        echo 'oracle.installer.autoupdates.downloadUpdatesLoc=' \ >> $FILENAME
        echo 'AUTOUPDATES_MYORACLESUPPORT_USERNAME=' \ >> $FILENAME
        echo 'AUTOUPDATES_MYORACLESUPPORT_PASSWORD=' \ >> $FILENAME
        echo 'oracle.install.db.BACKUPDBA_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.DGDBA_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.KMDBA_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.OSRACDBA_GROUP=dba' \ >> $FILENAME
        echo 'oracle.install.db.rac.configurationType=' \ >> $FILENAME
        echo 'oracle.install.db.isRACOneInstall=' \ >> $FILENAME
        echo 'oracle.install.db.racOneServiceName=' \ >> $FILENAME
        echo 'oracle.install.db.rac.serverpoolName=' \ >> $FILENAME
        echo 'oracle.install.db.rac.serverpoolCardinality=' \ >> $FILENAME
        echo 'PROXY_REALM=' \ >> $FILENAME
}
generate_rsp

echo "Running the Installer"
./runInstaller -ignorePrereqFailure  -force -silent -waitforcompletion -responseFile ${HOME_DIR}/db.rsp
if [ $? -eq 0 ]
then
        echo "The installation of DB is successful."
else
        echo "Install failed" >&2
        EXIT_STATUS="FAIL"
fi
#Checking installation log

#echo "----------------------------------------------------"
#echo "     Check for errors in install logs               "
#echo "----------------------------------------------------"
echo "Checking installation logs"
grep -r -i -q ${HOME_DIR}/database/oraInventory/logs -e "SEVERE"
if [ $? -eq 0  ]
then
        echo "There are errors in install logs..exiting"
        EXIT_STATUS="FAIL"
else
        echo "There are no errors in install logs."
fi

if [ ${EXIT_STATUS} != "FAIL" ]
then
        touch ${HOME_DIR}/results/DB_install.suc
else
        touch ${HOME_DIR}/results/DB_install.dif
fi
echo "----------------------------------------------------"

netca_exit_status="success"
${HOME_DIR}/DB/bin/netca /orahome ${HOME_DIR}/DB  /orahnam DB /instype typical /inscomp client,oraclenet,javavm,server,ano /insprtcl tcp /cfg local /authadp NO_VALUE /responseFile ${HOME_DIR}/DB/network/install/netca_typ.rsp /silent > netca.log 2>&1
#echo "----------------------------------------------------"
#echo "     Check for errors in netca logs               "
#echo "----------------------------------------------------"
echo "Checking netca logs"
grep -r -i -q netca.log -e "SEVERE"
if [ $? -eq 0  ]
then
        echo "There are errors in netca logs..exiting"

        netca_exit_status="FAIL"
else

       echo "There are no errors in netca logs."
fi
if [ ${netca_exit_status} != "FAIL" ]
then
        touch ${HOME_DIR}/results/netca.suc
else
        touch ${HOME_DIR}/results/netca.dif
fi

/usr/local/packages/aime/install/run_as_root ${HOME_DIR}/DB/root.sh

echo "----------------------------------------------------"
echo "              Configuring DBCA                      "
echo "----------------------------------------------------"

dbca_exit_status="success"

${HOME_DIR}/DB/bin/dbca -createDatabase -templateName General_Purpose.dbc -gdbName testdb.us.oracle.com -sid testdb -sysPassword welcome1 -systemPassword welcome1 -emConfiguration LOCAL -dbsnmpPassword welcome1 -datafileJarLocation ${HOME_DIR}/DB/assistants/dbca/templates -storageType FS -datafileDestination ${HOME_DIR}/DB/oradata -responseFile NO_VALUE -characterset AL32UTF8 -obfuscatedPasswords false -oratabLocation ORATAB -recoveryAreaDestination NO_VALUE -initParams _resource_includes_unlimited_tablespace=TRUE -silent -createAsContainerDatabase true -numberOfPDBs 1 -pdbName pdb_1 -pdbAdminPassword welcome1       > dbca.log 2>&1

if ! (grep "Database creation complete" dbca.log);
then
        echo "dbca failed ..exiting.."
        dbca_exit_status="FAIL"
else

        echo "dbca is successful."
fi

if [ ${dbca_exit_status} != "FAIL" ]
then
        touch ${HOME_DIR}/results/dbca.suc
else
        touch ${HOME_DIR}/results/dbca.dif
fi

#echo "----------------------------------------------------"
#echo "              Populate Export File                  "
#echo "----------------------------------------------------"
function populate_exportfile()
{
        FILENAME=${HOME_DIR}/export.txt
        echo "HOSTNAME=`mporacle19i -f`" \ >> $FILENAME
        echo "PDB=pdb_1" \ >> $FILENAME
        echo "PORT=$port" \ >> $FILENAME
        echo "SHIPHOME_DB=${SHIPHOME_DB}" \ >> $FILENAME
        sed -i '/^$/d;s/[[:blank:]]//g' $FILENAME

}
populate_exportfile