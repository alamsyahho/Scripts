#!/bin/bash

TYPE=$1
export DIR=`pwd`
export FILE=${DIR}/file.properties
export V_LOG=install.log

PLATFORM=`grep '^PLATFORM=' ${FILE} | cut -f2 -d=`
JAVA_HOME=`grep '^JAVA_HOME=' ${FILE} | cut -f2 -d=`
ANT_HOME=`grep '^ANT_HOME=' ${FILE} | cut -f2 -d=`
EBAO_HOME=`grep '^EBAO_HOME=' ${FILE} | cut -f2 -d=`
EBAO_TMP_HOME=`grep '^EBAO_TMP_HOME=' ${FILE} | cut -f2 -d=`
EBAO_ARCH_HOME=`grep '^EBAO_ARCH_HOME=' ${FILE} | cut -f2 -d=`

HOST_NAME=`hostname`

if [ -d ${JAVA_HOME} ]; then
        if [ ! -x ${JAVA_HOME}/bin/java ]; then
                echo "${JAVA_HOME}/bin/java doesn't exist or permission denied! Installation Fail!"
                exit 1;
        fi
else
        echo "JAVA_HOME doesn't exist! Installation Fail!";
        exit 1;
fi

FLAG=`echo ${EBAO_HOME} | awk '{if("'${EBAO_HOME}'" !~ /^\//) print 0;else print 1}'`
if [ ${FLAG} -eq 0 ]; then
        echo "EBAO_HOME should use the absolute path! Installation Fail!";
        exit 1;
fi

FLAG=`echo ${EBAO_TMP_HOME} | awk '{if("'${EBAO_TMP_HOME}'" !~ /^\//) print 0;else print 1}'`
if [ ${FLAG} -eq 0 ]; then
        echo "EBAO_TMP_HOME should use the absolute path! Installation Fail!";
        exit 1;
fi

FLAG=`echo ${EBAO_ARCH_HOME} | awk '{if("'${EBAO_ARCH_HOME}'" !~ /^\//) print 0;else print 1}'`
if [ ${FLAG} -eq 0 ]; then
        echo "EBAO_ARCH_HOME should use the absolute path! Installation Fail!";
        exit 1;
fi

if [ ${PLATFORM} == weblogic ]; then
	WL_HOME=`grep '^WL_HOME=' ${FILE} | cut -f2 -d=`
	DOMAIN_HOME=`grep '^DOMAIN_HOME=' ${FILE} | cut -f2 -d=`
	if [ -d ${WL_HOME} ] && [ -d ${DOMAIN_HOME} ]; then
		if [ ! -f ${WL_HOME}/server/lib/weblogic.jar ]; then
                echo "${WL_HOME}/server/lib/weblogic.jar doesn't exist! Installation Fail!"
                exit 1;
        	fi
	else 
		echo "WL_HOME, DOMAIN_HOME doesn't exist! Installation Fail!";
		exit 1;
	fi

	if [ -d ${ANT_HOME} ]; then
        	if [ ! -x ${ANT_HOME}/bin/ant ]; then
               	echo "${ANT_HOME}/bin/ant doesn't exist or permission denied! Installation Fail!"
                exit 1;
        	fi
	else
        	echo "ANT_HOME doesn't exist! Installation Fail!";
        	exit 1;
	fi
elif [ ${PLATFORM} == websphere ]; then
	USER_INSTALL_ROOT=`grep '^USER_INSTALL_ROOT=' $FILE | cut -f2 -d=`
	SERVER_NAME=`grep '^SERVER_NAME=' $FILE | cut -f2 -d=`
	ADMIN_USERNAME=`grep '^ADMIN_USERNAME=' $FILE | cut -f2 -d=`
	ADMIN_PASSWD=`grep '^ADMIN_PASSWD=' $FILE | cut -f2 -d=`
	JVM_initHeapSize=`grep '^JVM_initHeapSize=' $FILE | cut -f2 -d=`
	JVM_maxHeapSize=`grep '^JVM_maxHeapSize=' $FILE | cut -f2 -d=`
	JDBC_URL=`grep '^JDBC_URL=' $FILE | cut -f2 -d=`
	DS_USERNAME=`grep '^DS_USERNAME=' $FILE | cut -f2 -d=`
	DS_PASSWORD=`grep '^DS_PASSWORD=' $FILE | cut -f2 -d=`
	EXT_LIB_HOME=`grep '^EXT_LIB_HOME=' $FILE | cut -f2 -d=`
	JNDI_NAME=`grep '^JNDI_NAME=' $FILE | cut -f2 -d=`

	FLAG=`echo $USER_INSTALL_ROOT | awk '{if($USER_INSTALL_ROOT !~ /^\//) print 0;else print 1}'`
	if [ $FLAG -eq 0 ]; then
        	echo "USER_INSTALL_ROOT should use the absolute path! Installation Fail!";
        	exit 1;
	else
  		if [ ! -d $USER_INSTALL_ROOT ] && [ ! -x $USER_INSTALL_ROOT/bin/wsadmin.sh ] && [ ! -x $USER_INSTALL_ROOT/bin/startServer.sh ] &&[ ! -x $USER_INSTALL_ROOT/bin/stopServer.sh ]; then
        	echo "$USER_INSTALL_ROOT doesn't exist or permission denied! Installation Fail!"
        	exit 1;
  		fi
	fi

	if [ -d ${ANT_HOME} ]; then
                if [ ! -x ${ANT_HOME}/bin/ws_ant.sh ]; then
                echo "${ANT_HOME}/bin/ws_ant doesn't exist or permission denied! Installation Fail!"
                exit 1;
                fi
        else
                echo "ANT_HOME doesn't exist! Installation Fail!";
                exit 1;
        fi
else
	echo "Please correct PLATFORM to weblogic or websphere!"
	exit 1;
fi

get_cellName() {
  script=${DIR}/util/websphere7/getCell.jacl
  "${USER_INSTALL_ROOT}/bin/wsadmin.sh"  -f "${script}"  -user ${ADMIN_USERNAME} -password ${ADMIN_PASSWD} >${DIR}/${V_LOG}
}

get_INSURANCE_WAR_ROOT() {
  if [ -f ${DIR}/getWarRoot.properties ]
  then
  rm -fr ${DIR}/getWarRoot.properties
  get_cellName
  if [  $?  -ne  0 ]; then
  echo "get CellName failed!" >> ${DIR}/${V_LOG}
  exit 1;
  else
  echo "Get CellName successed!" >> ${DIR}/${V_LOG}
  fi
  FILE=${DIR}/getWarRoot.properties
  CELL=`grep '^CELL=' ${FILE} | cut -f2 -d=`
  LS_LIB=${USER_INSTALL_ROOT}/installedApps/${CELL}/insurance.ear/web.war/WEB-INF
  echo LS_LIB=${LS_LIB} >> ${DIR}/getWarRoot.properties
  else
  get_cellName
  if [  $?  -ne  0 ]; then
  echo "get CellName failed!" >> ${DIR}/${V_LOG}
  exit 1;
  else
  echo "Get CellName successed!" >> ${DIR}/${V_LOG}
  fi
  FILE=${DIR}/getWarRoot.properties
  CELL=`grep '^CELL=' ${FILE} | cut -f2 -d=`
  LS_LIB=${USER_INSTALL_ROOT}/installedApps/${CELL}/insurance.ear/web.war/WEB-INF/
  echo LS_LIB=${LS_LIB} >> ${DIR}/getWarRoot.properties
  fi
}

case "${TYPE}" in
	install)
		if [ ${PLATFORM} == weblogic ]; then
                #################### Install eBao LifeSystem on Weblogic ##################
			shift
			. ${DOMAIN_HOME}/bin/setDomainEnv.sh
                	echo  "Install eBao LifeSystem..."
                	cd ${DIR}
			${ANT_HOME}/bin/ant -Dsrc=${DIR}/../ -Dconf_file=${DIR}/file.properties install -f ${DIR}/util/weblogic103/install.xml >> ${DIR}/${V_LOG}
			if [  $?  -ne  0 ]; then
				echo ""
                		echo "Installation failed" |tee -a ${DIR}/${V_LOG}
		     		exit 1;
			else
				echo "Installation successfully" |tee -a ${DIR}/${V_LOG}
			fi
			echo ""
		else
		#################### Install eBao LifeSystem on Websphere ##################
			export USER_INSTALL_ROOT ADMIN_USERNAME ADMIN_PASSWD SERVER_NAME EXT_LIB_HOME DS_USERNAME DS_PASSWORD JNDI_NAME JDBC_URL JVM_initHeapSize JVM_maxHeapSize EBAO_HOME
			cd ${DIR}
			#********** 1.Get INSURANCE WAR ROOT
                	echo -n "1. Get War Root to getWarRoot.properties..."
			get_INSURANCE_WAR_ROOT
                	if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Get War Root failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                 	else
                     		echo ""
				echo "Get War Root successed!" |tee -a ${DIR}/${V_LOG}
                	fi
                	echo ""
			#********** 2.Configure eBao LifeSystem
                	echo -n "2. Configure eBao LifeSystem..."
                	${ANT_HOME}/bin/ws_ant.sh -Dsrc=${DIR}/../ -Dconf_file1=${DIR}/file.properties -Dconf_file2=${DIR}/getWarRoot.properties install -f ${DIR}/util/websphere7/install.xml >> ${DIR}/${V_LOG}
                	if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Configure eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                	else
				echo ""
                     		echo "Configure eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                	fi
                	echo ""
                	#********** 3.Deploy eBao LifeSystem 
                	echo -n "3. Deploy eBao LifeSystem..."
                	sh ${USER_INSTALL_ROOT}/bin/wsadmin.sh -f util/websphere7/ebao_app_install.jacl -user ${ADMIN_USERNAME} -password ${ADMIN_PASSWD} ${SERVER_NAME} ${EXT_LIB_HOME} ${DS_USERNAME} ${DS_PASSWORD} ${JNDI_NAME} ${JDBC_URL} ${JVM_initHeapSize} ${JVM_maxHeapSize} ${EBAO_HOME}/app_config/app/ ${EBAO_HOME}/EAR_FILE/insurance.ear insurance ${EBAO_HOME}/share_lib ls >> ${DIR}/${V_LOG}
			if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Deploy eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                	else
				echo ""
                     		echo "Deploy eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                	fi
                	echo ""
                	#********** 4.Stop Application Server
                	echo -n "4. Stop Application Server...  "
			${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} stop_server -f ${DIR}/util/websphere7/maintain.xml >> ${DIR}/${V_LOG}
                	if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Stop Server failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                	else
				echo ""
                     		echo "Stop Server successed!" |tee -a ${DIR}/${V_LOG}
                	fi
                	echo ""
                	#********** 5.Start Application Server
                	echo -n "5. Start Application Server...  "
			${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} start_server -f ${DIR}/util/websphere7/maintain.xml >> ${DIR}/${V_LOG}
                	if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Start Server failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                	else
				echo ""
                     		echo "Start Server successed!" |tee -a ${DIR}/${V_LOG}
                  	fi
                	echo ""
                	#********** 6.Start Batch Server ##################
                	echo -n "6. Start Batch Server...  "
                	sh ${EBAO_HOME}/applications/batch/bin/batch_manage.sh restart >> ${DIR}/${V_LOG} 2>/dev/null
                	if [  $?  -ne  0 ]; then
                     		echo ""
                     		echo "Start Batch failed!" |tee -a ${DIR}/${V_LOG}
                     		exit 1;
                	else
				echo ""
                     		echo "Start Batch successed!" |tee -a ${DIR}/${V_LOG}
                  	fi
                	echo ""
                	echo "Installation successfully"
                    	exit 0;
		fi
		;;
	upgrade)
		if [ ${PLATFORM} == weblogic ]; then
                #################### Upgrade eBao LifeSystem on Weblogic ##################
                        #********** 1.Upgrade eBao LifeSystem
			shift
			. ${DOMAIN_HOME}/bin/setDomainEnv.sh
                	echo  "1. Upgrade eBao LifeSystem..."
                	export JAVA_HOME
                	cd ${DIR}
                	${ANT_HOME}/bin/ant -Dsrc=${DIR}/../ -Dconf_file=${DIR}/file.properties upgrade -f ${DIR}/util/weblogic103/install.xml > ${DIR}/${V_LOG}
                	echo ""
                	echo "Upgrade eBao LifeSystem successed!" 
                        echo ""
                        #********** 2.Stop Application Server
                        echo -n "2. Stop Application Server...  "
                        ${ANT_HOME}/bin/ant -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties stop_server -f ${DIR}/util/weblogic103/maintain.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Stop Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Stop Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
			#********** 3.Start Application Server
                        echo -n "3. Start Application Server...  "
                        ${ANT_HOME}/bin/ant -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties start_server -f ${DIR}/util/weblogic103/maintain.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Start Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Start Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 4.Rereart Batch Server ##################
                        echo -n "4. Restart Batch Server...  "
                        sh ${EBAO_HOME}/applications/batch/bin/batch_manage.sh restart >> ${DIR}/${V_LOG} 2>/dev/null
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Start Batch failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Start Batch successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "Upgrade successfully"
                        exit 0;
		else
                #################### Upgrade eBao LifeSystem on Websphere ##################
			export USER_INSTALL_ROOT ADMIN_USERNAME ADMIN_PASSWD SERVER_NAME EXT_LIB_HOME DS_USERNAME DS_PASSWORD JNDI_NAME JDBC_URL JVM_initHeapSize JVM_maxHeapSize EBAO_HOME HOST_NAME
                        cd ${DIR}
                        #********** 1.Stop Application Server
                        echo -n "1. Stop Application Server...  "
                        ${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} stop_server -f ${DIR}/util/websphere7/maintain.xml > ${DIR}/${V_LOG}
			if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Stop Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Stop Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 2.Start Application Server
                        echo -n "2. Start Application Server...  "
                        ${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} start_server -f ${DIR}/util/websphere7/maintain.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Start Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Start Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 3.Get INSURANCE WAR ROOT
                        echo -n "3. Get War Root to getWarRoot.properties..."
			get_INSURANCE_WAR_ROOT
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Get War Root failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Get War Root successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 4.Configure eBao LifeSystem
                        echo -n "4. Configure eBao LifeSystem..."
                        ${ANT_HOME}/bin/ws_ant.sh -Dsrc=${DIR}/../ -Dconf_file1=${DIR}/file.properties -Dconf_file2=${DIR}/getWarRoot.properties upgrade -f ${DIR}/util/websphere7/install.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Configure eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Configure eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
			#********** 5.Deploy eBao LifeSystem 
                        echo -n "5. Deploy eBao LifeSystem..."
			sh ${USER_INSTALL_ROOT}/bin/wsadmin.sh -f util/websphere7/eBaoDeploy.jacl -user ${ADMIN_USERNAME} -password ${ADMIN_PASSWD} insurance ${EBAO_HOME}/EAR_FILE/insurance.ear >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Deploy eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Deploy eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 6.Stop Application Server
                        echo -n "6. Stop Application Server...  "
			${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} stop_server -f ${DIR}/util/websphere7/maintain.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Stop Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Stop Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
			#********** 7.Start Application Server
                        echo -n "7. Start Application Server...  "
                        ${ANT_HOME}/bin/ws_ant.sh -Dext.lib.dir=${DIR}/lib -Dconf_file1=${DIR}/file.properties -Dconf_file2=${USER_INSTALL_ROOT}/properties/portdef.props -DHOST_NAME=${HOST_NAME} start_server -f ${DIR}/util/websphere7/maintain.xml >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Start Server failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Start Server successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        #********** 8.Start Batch Server ##################
                        echo -n "8. Start Batch Server...  "
                        sh ${EBAO_HOME}/applications/batch/bin/batch_manage.sh restart >> ${DIR}/${V_LOG} 2>/dev/null
                        if [  $?  -ne  0 ]; then
                                echo ""
                                echo "Start Batch failed!" |tee -a ${DIR}/${V_LOG}
                                exit 1;
                        else
                                echo ""
                                echo "Start Batch successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "Upgrade successfully"
                        exit 0;
                fi
	 	;;
        uninstall)
                if [ ${PLATFORM} == weblogic ]; then
                #################### Uninstall eBao LifeSystem on Weblogic ##################
                        echo "1. Stop Batch System..."
                        if [ -d ${EBAO_HOME}/batch ]; then
                               sh ${EBAO_HOME}/applications/batch/bin/batch_manage.sh stop > ${DIR}/${V_LOG}
                        else
                        echo "Batch Home doesn't exist or permission denied!" |tee -a ${DIR}/${V_LOG}
                        exit 1;
                        fi
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Stop Batch System failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Stop Batch System successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "2. Undeploy eBao LifeSystem..."
                        . ${DOMAIN_HOME}/bin/setDomainEnv.sh
                        echo  "Undeploy eBao LifeSystem..."
                        cd ${DIR}
                        ${ANT_HOME}/bin/ant -Dsrc=${DIR}/../ -Dconf_file=${DIR}/file.properties uninstall -f ${DIR}/util/weblogic103/uninstall.xml > ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Undeploy eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Undeploy eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "3. Remove eBao LifeSystem..."
                        if [ -d ${EBAO_HOME} ] && [ -d ${EBAO_TMP_HOME} ]; then
                                rm -fr ${EBAO_HOME}
                                rm -fr ${EBAO_TMP_HOME}
                        else 
                                echo "EBAO_HOME, EBAO_TMP_HOME doesn't exist!" |tee -a ${DIR}/${V_LOG}
                        exit 1;
                        fi
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Remove eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Remove eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "Uninstall eBao LifeSystem successfully"
                        exit 0;
                else
                #################### Uninstall eBao LifeSystem on Websphere ##################
                        echo "1. Stop Batch System..."
                        if [ -d ${EBAO_HOME}/batch ]; then
                               sh ${EBAO_HOME}/applications/batch/bin/batch_manage.sh stop > ${DIR}/${V_LOG}
                        else
                        echo "Batch Home doesn't exist or permission denied!" |tee -a ${DIR}/${V_LOG}
                        exit 1;
                        fi
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Stop Batch System failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Stop Batch System successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "2. Undeploy eBao LifeSystem..."
                        sh ${USER_INSTALL_ROOT}/bin/wsadmin.sh -f util/websphere7/ebao_app_uninstall.jacl ${JNDI_NAME} insurance ls >> ${DIR}/${V_LOG}
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Undeploy eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Undeploy eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "3. Remove eBao LifeSystem..."
                        if [ -d ${EBAO_HOME} ] && [ -d ${EBAO_TMP_HOME} ]; then
                                rm -fr ${EBAO_HOME}
                                rm -fr ${EBAO_TMP_HOME}
                        else 
                                echo "EBAO_HOME, EBAO_TMP_HOME doesn't exist!" |tee -a ${DIR}/${V_LOG}
                        exit 1;
                        fi
                        if [  $?  -ne  0 ]; then
                               echo ""
                               echo "Remove eBao LifeSystem failed!" |tee -a ${DIR}/${V_LOG}
                               exit 1;
                        else
                               echo ""
                               echo "Remove eBao LifeSystem successed!" |tee -a ${DIR}/${V_LOG}
                        fi
                        echo ""
                        echo "Uninstall eBao LifeSystem successfully"
                        exit 0;
                fi
                ;;     
	*)
                echo $"Usage: `basename $0` {install|upgrade|uninstall}"
		exit 1;
		;;
esac
