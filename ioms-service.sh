#!/bin/bash
set -x

HOST_NAME=`hostname`
SCRIPT_DIR=`dirname $0`

echo ${JAVA_HOME}

# log file
SCRIPT_LOG=/tmp/oms-start.log.$$

function LOG_MSG {
   echo $*
   echo $* >> ${SCRIPT_LOG}
}

LOG_MSG "Started script at  `date '+%Y-%m-%d %T %Z'` : $*"

function STOP {
    ps -auxww --no-heading | grep "${JAVA_CMD_TO_STOP}"  | awk ' { print $2 } ' | grep -v $$ | awk  ' { print "Killing " $1 "..." ; killcmd="kill " $1;  if (system(killcmd) == 0 ) { print "Killed " $1 " Done."; }  }'
}

function START {
   # below >&- 2>&- & are added to fork the process as child process and close the stdout and stderr so the calling process thinks it is terminated. It is used for ssh command from CI otherwise the command will never come out.
    ${JAVA_CMD} >&- 2>&- &
    LOG_MSG "Started java process with PID:"  $?
    LOG_MSG "Started java process at `date '+%Y-%m-%d %T %Z'` : ${JAVA_CMD} "
#    disown
}

function PRINT_USAGE {
    LOG_MSG "Error: invalid number of argumets.. Command used : \"$0 $*\""
    LOG_MSG "Usage: $0 (RESTART|STOP|MANUAL) service-name project-name [FIXNAME] [FIXDATE]"
    LOG_MSG "Example to start order-execution-service: $0 RESTART order-execution-service autoexec"
    LOG_MSG "Example to stop order-execution-service: $0 STOP order-execution-service autoexec"
    LOG_MSG "Example to manually run a fix on order-execution-service: $0 MANUAL order-execution-service autoexec GRP16"
    LOG_MSG "Example to manually run a fix on order-execution-service: $0 MANUAL order-execution-service autoexec GRP16 MAR022016"
    LOG_MSG "Example to start order-execution-service with property file: $0 RESTART order-execution-service autoexec autoexec-qa2.properties"
    exit 1
}

function VALIDATE_ENV {
    # arguments checking
    if [ "$#" -eq 3 ] && ! [ "$1" == "RESTART" -o "$1" == "STOP" ]
    then
        PRINT_USAGE
    fi
    if [ "$#" -eq 5 -a "$1" != "MANUAL" ]
    then
        PRINT_USAGE
    fi
    if [ "$#" -eq 4 ]  && ! [ "$1" == "RESTART" -o "$1" == "STOP"  -o "$1" == "MANUAL" ]
    then
        PRINT_USAGE
    fi
}

function DETERMINE_ARGS {
    MODE=$1
    SERVICE_NAME=$2
    echo ${SERVICE_NAME}
    PROJECT_NAME=$3
    echo ${PROJECT_NAME}

    FIXNAME=""
    FIXDATE=""
    if [ "$#" -eq 4 ] && [ ${MODE} == "RESTART" -o ${MODE} == "STOP" ]
    then
        SET_PROPERTY_FILE $4
    elif [ ${MODE} == "MANUAL" ]
    then
        FIXNAME=" $4"
        FIXDATE=" $5"
    fi
}

function SET_PROPERTY_FILE {
    export OMS_ENV_RUNTIME_PROPS=file:${OMS_RUNTIME_CFG}/${1}
}

VALIDATE_ENV $*
DETERMINE_ARGS $*

# set the environment variables
. ${SCRIPT_DIR}/ioms-loadEnv.sh ${PROJECT_NAME}

JARFILE_NAME="${OMS_RUNTIME_JCLASS}/${SERVICE_NAME}.jar"
echo ${JARFILE_NAME}

JAVA_EXEC="${JAVA_HOME}/bin/java"
JAVA_ARGS="-Dlog4j.configurationFile=${OMS_RUNTIME_CFG}/${PROJECT_NAME}-log4j2.xml -Xms128m -Xmx512m
-Dorg.omg.CORBA.ORBClass=com.ibm.CORBA.iiop.ORB -verbose:gc  -XX:+PrintGCDetails  -XX:+PrintGCTimeStamps -Xloggc:${OMS_LOGS}/gc.log -XX:+HeapDumpOnOutOfMemoryError  `cat abc.txt 2> /dev/null`"
JAR_ARGS="-jar ${JARFILE_NAME}${FIXNAME}${FIXDATE}"

echo ${JAVA_HOME}
JAVA_CMD="${JAVA_EXEC} ${JAVA_ARGS} ${JAR_ARGS}"
JAVA_CMD_TO_STOP="${JAVA_EXEC} .* ${JAR_ARGS}"
echo ${JAVA_CMD}

STOP
if [ ${MODE} == "RESTART" -o ${MODE} == "MANUAL" ]
then
    START
fi

LOG_MSG "Ended script at at `date '+%Y-%m-%d %T %Z'` : $*"

exit 0
