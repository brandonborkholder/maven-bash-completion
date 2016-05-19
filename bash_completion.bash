function_exists()
{
	declare -F $1 > /dev/null
	return $?
}

function_exists _get_comp_words_by_ref ||
_get_comp_words_by_ref ()
{
    local exclude cur_ words_ cword_;
    if [ "$1" = "-n" ]; then
        exclude=$2;
        shift 2;
    fi;
    __git_reassemble_comp_words_by_ref "$exclude";
    cur_=${words_[cword_]};
    while [ $# -gt 0 ]; do
        case "$1" in
            cur)
                cur=$cur_
            ;;
            prev)
                prev=${words_[$cword_-1]}
            ;;
            words)
                words=("${words_[@]}")
            ;;
            cword)
                cword=$cword_
            ;;
        esac;
        shift;
    done
}

function_exists __ltrim_colon_completions ||
__ltrim_colon_completions()
{
	if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
		# Remove colon-word prefix from COMPREPLY items
		local colon_word=${1%${1##*:}}
		local i=${#COMPREPLY[*]}
		while [[ $((--i)) -ge 0 ]]; do
			COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
		done
	fi
}

function_exists __find_mvn_projects ||
__find_mvn_projects()
{
    find . -name 'pom.xml' -not -path '*/target/*' -prune | while read LINE ; do
        local withoutPom=${LINE%/pom.xml}
        local module=${withoutPom#./}
        if [[ -z ${module} ]]; then
            echo "."
        else
            echo ${module}
        fi
    done
}

function_exists _realpath ||
_realpath () 
{
    if [[ -f "$1" ]]
    then
        # file *must* exist
        if cd "$(echo "${1%/*}")" &>/dev/null
        then
	    # file *may* not be local
	    # exception is ./file.ext
	    # try 'cd .; cd -;' *works!*
 	    local tmppwd="$PWD"
	    cd - &>/dev/null
        else
	    # file *must* be local
	    local tmppwd="$PWD"
        fi
    else
        # file *cannot* exist
        return 1 # failure    
    fi

    # reassemble realpath
    echo "$tmppwd"/"${1##*/}"
    return 1 #success
}

function_exists __pom_hierarchy ||
__pom_hierarchy()
{
    local pom=`_realpath "pom.xml"`
    POM_HIERARCHY+=("$pom")
    while [ -n "$pom" ] && grep -q "<parent>" "$pom"; do
	    ## look for a new relativePath for parent pom.xml
        local parent_pom_relative=`grep -e "<relativePath>.*</relativePath>" "$pom" | sed 's/.*<relativePath>//' | sed 's/<\/relativePath>.*//g'`

    	## <parent> is present but not defined, assume ../pom.xml
    	if [ -z "$parent_pom_relative" ]; then
    	    parent_pom_relative="../pom.xml"
    	fi 

    	## if pom exists continue else break
    	parent_pom=`_realpath "${pom%/*}/$parent_pom_relative"`
        if [ -n "$parent_pom" ]; then 
            pom=$parent_pom
    	else 
    	    break
        fi
    	POM_HIERARCHY+=("$pom")
    done
}

_mvn()
{
    local cur prev
    COMPREPLY=()
    POM_HIERARCHY=()
    __pom_hierarchy
    _get_comp_words_by_ref -n : cur prev words

    local opts="-am|-amd|-B|-C|-c|-cpu|-D|-e|-emp|-ep|-f|-fae|-ff|-fn|-gs|-h|-l|-N|-npr|-npu|-nsu|-o|-P|-pl|-q|-rf|-s|-T|-t|-U|-up|-V|-v|-X"
    local long_opts="--also-make|--also-make-dependents|--batch-mode|--strict-checksums|--lax-checksums|--check-plugin-updates|--define|--errors|--encrypt-master-password|--encrypt-password|--file|--fail-at-end|--fail-fast|--fail-never|--global-settings|--help|--log-file|--non-recursive|--no-plugin-registry|--no-plugin-updates|--no-snapshot-updates|--offline|--activate-profiles|--projects|--quiet|--resume-from|--settings|--threads|--toolchains|--update-snapshots|--update-plugins|--show-version|--version|--debug"

    local common_clean_lifecycle="pre-clean|clean|post-clean"
    local common_default_lifecycle="validate|initialize|generate-sources|process-sources|generate-resources|process-resources|compile|process-classes|generate-test-sources|process-test-sources|generate-test-resources|process-test-resources|test-compile|process-test-classes|test|prepare-package|package|pre-integration-test|integration-test|post-integration-test|verify|install|deploy"
    local common_site_lifecycle="pre-site|site|post-site|site-deploy"
    local common_lifecycle_phases="${common_clean_lifecycle}|${common_default_lifecycle}|${common_site_lifecycle}"

    local plugin_goals_appengine="appengine:backends_configure|appengine:backends_delete|appengine:backends_rollback|appengine:backends_start|appengine:backends_stop|appengine:backends_update|appengine:debug|appengine:devserver|appengine:devserver_start|appengine:devserver_stop|appengine:endpoints_get_client_lib|appengine:endpoints_get_discovery_doc|appengine:enhance|appengine:rollback|appengine:set_default_version|appengine:start_module_version|appengine:stop_module_version|appengine:update|appengine:update_cron|appengine:update_dos|appengine:update_indexes|appengine:update_queues|appengine:vacuum_indexes"
    local plugin_goals_android="android:apk|android:apklib|android:clean|android:deploy|android:deploy-dependencies|android:dex|android:emulator-start|android:emulator-stop|android:emulator-stop-all|android:generate-sources|android:help|android:instrument|android:manifest-update|android:pull|android:push|android:redeploy|android:run|android:undeploy|android:unpack|android:version-update|android:zipalign|android:devices"
    local plugin_goals_ant="ant:ant|ant:clean"
    local plugin_goals_antrun="antrun:run"
    local plugin_goals_archetype="archetype:generate|archetype:create-from-project|archetype:crawl"
    local plugin_goals_assembly="assembly:single|assembly:assembly"
    local plugin_goals_build_helper="build-helper:add-resource|build-helper:add-source|build-helper:add-test-resource|build-helper:add-test-source|build-helper:attach-artifact|build-helper:bsh-property|build-helper:cpu-count|build-helper:help|build-helper:local-ip|build-helper:maven-version|build-helper:parse-version|build-helper:regex-properties|build-helper:regex-property|build-helper:released-version|build-helper:remove-project-artifact|build-helper:reserve-network-port|build-helper:timestamp-property"
    local plugin_goals_buildnumber="buildnumber:create|buildnumber:create-timestamp|buildnumber:help|buildnumber:hgchangeset"
    local plugin_goals_cargo="cargo:start|cargo:run|cargo:stop|cargo:deploy|cargo:undeploy|cargo:help"
    local plugin_goals_checkstyle="checkstyle:checkstyle|checkstyle:check"
    local plugin_goals_cobertura="cobertura:cobertura"
    local plugin_goals_findbugs="findbugs:findbugs|findbugs:gui|findbugs:help"
    local plugin_goals_dependency="dependency:analyze|dependency:analyze-dep-mgt|dependency:analyze-duplicate|dependency:analyze-only|dependency:analyze-report|dependency:build-classpath|dependency:copy|dependency:copy-dependencies|dependency:get|dependency:go-offline|dependency:help|dependency:list|dependency:list-repositories|dependency:properties|dependency:purge-local-repository|dependency:resolve|dependency:resolve-plugins|dependency:sources|dependency:tree|dependency:unpack|dependency:unpack-dependencies"
    local plugin_goals_deploy="deploy:deploy-file"
    local plugin_goals_ear="ear:ear|ear:generate-application-xml"
    local plugin_goals_eclipse="eclipse:clean|eclipse:eclipse"
    local plugin_goals_ejb="ejb:ejb"
    local plugin_goals_enforcer="enforcer:enforce|enforcer:display-info"
    local plugin_goals_exec="exec:exec|exec:java"
    local plugin_goals_failsafe="failsafe:integration-test|failsafe:verify"
    local plugin_goals_flyway="flyway:clean|flyway:history|flyway:init|flyway:migrate|flyway:status|flyway:validate"
    local plugin_goals_gpg="gpg:sign|gpg:sign-and-deploy-file"
    local plugin_goals_grails="grails:clean|grails:config-directories|grails:console|grails:create-controller|grails:create-domain-class|grails:create-integration-test|grails:create-pom|grails:create-script|grails:create-service|grails:create-tag-lib|grails:create-unit-test|grails:exec|grails:generate-all|grails:generate-controller|grails:generate-views|grails:help|grails:init|grails:init-plugin|grails:install-templates|grails:list-plugins|grails:maven-clean|grails:maven-compile|grails:maven-functional-test|grails:maven-grails-app-war|grails:maven-test|grails:maven-war|grails:package|grails:package-plugin|grails:run-app|grails:run-app-https|grails:run-war|grails:set-version|grails:test-app|grails:upgrade|grails:validate|grails:validate-plugin|grails:war"
    local plugin_goals_gwt="gwt:browser|gwt:clean|gwt:compile|gwt:compile-report|gwt:css|gwt:debug|gwt:eclipse|gwt:eclipseTest|gwt:generateAsync|gwt:help|gwt:i18n|gwt:mergewebxml|gwt:resources|gwt:run|gwt:run-codeserver|gwt:sdkInstall|gwt:source-jar|gwt:soyc|gwt:test"
    local plugin_goals_help="help:active-profiles|help:all-profiles|help:describe|help:effective-pom|help:effective-settings|help:evaluate|help:expressions|help:help|help:system"
    local plugin_goals_hibernate3="hibernate3:hbm2ddl|hibernate3:help"
    local plugin_goals_idea="idea:clean|idea:idea"
    local plugin_goals_install="install:install-file"
    local plugin_goals_jacoco="jacoco:check|jacoco:dump|jacoco:help|jacoco:instrument|jacoco:merge|jacoco:prepare-agent|jacoco:prepare-agent-integration|jacoco:report|jacoco:report-integration|jacoco:restore-instrumented-classes"
    local plugin_goals_javadoc="javadoc:javadoc|javadoc:jar|javadoc:aggregate"
    local plugin_goals_jboss="jboss:start|jboss:stop|jboss:deploy|jboss:undeploy|jboss:redeploy"
    local plugin_goals_jboss_as="jboss-as:add-resource|jboss-as:deploy|jboss-as:deploy-only|jboss-as:deploy-artifact|jboss-as:redeploy|jboss-as:redeploy-only|jboss-as:undeploy|jboss-as:undeploy-artifact|jboss-as:run|jboss-as:start|jboss-as:shutdown|jboss-as:execute-commands"
    local plugin_goals_jetty="jetty:run|jetty:run-exploded"
    local plugin_goals_jxr="jxr:jxr"
    local plugin_goals_license="license:format|license:check"
    local plugin_goals_liquibase="liquibase:changelogSync|liquibase:changelogSyncSQL|liquibase:clearCheckSums|liquibase:dbDoc|liquibase:diff|liquibase:dropAll|liquibase:help|liquibase:migrate|liquibase:listLocks|liquibase:migrateSQL|liquibase:releaseLocks|liquibase:rollback|liquibase:rollbackSQL|liquibase:status|liquibase:tag|liquibase:update|liquibase:updateSQL|liquibase:updateTestingRollback"
    local plugin_goals_nexus_staging="nexus-staging:close|nexus-staging:deploy|nexus-staging:deploy-staged|nexus-staging:deploy-staged-repository|nexus-staging:drop|nexus-staging:help|nexus-staging:promote|nexus-staging:rc-close|nexus-staging:rc-drop|nexus-staging:rc-list|nexus-staging:rc-list-profiles|nexus-staging:rc-promote|nexus-staging:rc-release|nexus-staging:release"
    local plugin_goals_pmd="pmd:pmd|pmd:cpd|pmd:check|pmd:cpd-check"
    local plugin_goals_release="release:clean|release:prepare|release:rollback|release:perform|release:stage|release:branch|release:update-versions"
    local plugin_goals_repository="repository:bundle-create|repository:bundle-pack|repository:help"
    local plugin_goals_scm="scm:add|scm:checkin|scm:checkout|scm:update|scm:status"
    local plugin_goals_site="site:site|site:deploy|site:run|site:stage|site:stage-deploy"
    local plugin_goals_sonar="sonar:sonar|sonar:help"
    local plugin_goals_source="source:aggregate|source:jar|source:jar-no-fork"
    local plugin_goals_surefire="surefire:test"
    local plugin_goals_tomcat6="tomcat6:help|tomcat6:run|tomcat6:run-war|tomcat6:run-war-only|tomcat6:stop|tomcat6:deploy|tomcat6:undeploy"
    local plugin_goals_tomcat7="tomcat7:help|tomcat7:run|tomcat7:run-war|tomcat7:run-war-only|tomcat7:deploy"
    local plugin_goals_tomcat="tomcat:help|tomcat:start|tomcat:stop|tomcat:deploy|tomcat:undeploy"
    local plugin_goals_liberty="liberty:create-server|liberty:start-server|liberty:stop-server|liberty:run-server|liberty:deploy|liberty:undeploy|liberty:java-dump-server|liberty:dump-server|liberty:package-server"
    local plugin_goals_versions="versions:display-dependency-updates|versions:display-plugin-updates|versions:display-property-updates|versions:update-parent|versions:update-properties|versions:update-child-modules|versions:lock-snapshots|versions:unlock-snapshots|versions:resolve-ranges|versions:set|versions:use-releases|versions:use-next-releases|versions:use-latest-releases|versions:use-next-snapshots|versions:use-latest-snapshots|versions:use-next-versions|versions:use-latest-versions|versions:commit|versions:revert"
    local plugin_goals_vertx="vertx:init|vertx:runMod|vertx:pullInDeps|vertx:fatJar"
    local plugin_goals_war="war:war|war:exploded|war:inplace|war:manifest"
    local plugin_goals_spring_boot="spring-boot:run|spring-boot:repackage"
    local plugin_goals_jgitflow="jgitflow:feature-start|jgitflow:feature-finish|jgitflow:release-start|jgitflow:release-finish|jgitflow:hotfix-start|jgitflow:hotfix-finish|jgitflow:build-number"
    local plugin_goals_wildfly="wildfly:add-resource|wildfly:deploy|wildfly:deploy-only|wildfly:deploy-artifact|wildfly:redeploy|wildfly:redeploy-only|wildfly:undeploy|wildfly:undeploy-artifact|wildfly:run|wildfly:start|wildfly:shutdown|wildfly:execute-commands"

    local plugin_args_ant_ant="-Doverwrite="
    local plugin_args_ant_clean="-DdeleteCustomFiles="
    local plugin_args_antrun_run="-DsourceRoot=|-Dtasks=|-DtestSourceRoot="
    local plugin_args_archetype_crawl="-Dcatalog=|-Drepository="
    local plugin_args_archetype_create_from_project="-Darchetype.filteredExtentions=|-Darchetype.languages=|-Darchetype.postPhase=|-Darchetype.encoding=|-Dinteractive=|-Darchetype.keepParent=|-DpackageName=|-Darchetype.partialArchetype=|-Darchetype.preserveCData=|-Darchetype.properties=|-DtestMode="
    local plugin_args_archetype_generate="-DarchetypeArtifactId=|-DarchetypeCatalog=|-DarchetypeGroupId=|-DarchetypeRepository=|-DarchetypeVersion=|-Dfilter=|-Dgoals=|-DinteractiveMode="
    local plugin_args_assembly_assembly="-DappendAssemblyId=|-Dattach=|-Dclassifier=|-Ddescriptor=|-DdescriptorId=|-Dassembly.dryRun=|-DexecutedProject=|-DignoreMissingDescriptor=|-DincludeSite=|-DrunOnlyAtExecutionRoot=|-DskipAssembly=|-DtarLongFileMode="
    local plugin_args_assembly_single="-DappendAssemblyId=|-Dattach=|-Dclassifier=|-Ddescriptor=|-DdescriptorId=|-Dassembly.dryRun=|-DignoreMissingDescriptor=|-DincludeSite=|-DrunOnlyAtExecutionRoot=|-DskipAssembly=|-DtarLongFileMode="
    local plugin_args_build_helper_attach_artifact="-Dbuildhelper.runOnlyAtExecutionRoot=|-Dbuildhelper.skipAttach="
    local plugin_args_build_helper_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_build_helper_remove_project_artifact="-Dbuildhelper.failOnError=|-Dbuildhelper.removeAll="
    local plugin_args_buildnumber_create="-Dmaven.buildNumber.buildNumberPropertyName=|-Dmaven.buildNumber.doCheck=|-Dmaven.buildNumber.doUpdate=|-Dmaven.buildNumber.format=|-Dmaven.buildNumber.getRevisionOnlyOnce=|-Dmaven.buildNumber.locale=|-Dpassword=|-Dmaven.buildNumber.revisionOnScmFailure=|-Dmaven.buildNumber.scmBranchPropertyName=|-Dmaven.buildNumber.scmDirectory=|-Dmaven.buildNumber.shortRevisionLength=|-Dmaven.buildNumber.skip=|-Dmaven.buildNumber.timestampFormat=|-Dmaven.buildNumber.timestampPropertyName=|-Dmaven.buildNumber.useLastCommittedRevision=|-Dusername="
    local plugin_args_buildnumber_create_timestamp="-Dmaven.buildNumber.skip=|-Dmaven.buildNumber.timestampFormat=|-Dmaven.buildNumber.timestampPropertyName=|-Dmaven.buildNumber.timestampTimeZone="
    local plugin_args_buildnumber_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_buildnumber_hgchangeset="-Dmaven.changeSet.scmDirectory=|-Dmaven.buildNumber.skip="
    local plugin_args_checkstyle_check="-Dcheckstyle.config.location=|-Dcheckstyle.consoleOutput=|-Dencoding=|-Dcheckstyle.excludes=|-Dcheckstyle.failOnViolation=|-Dcheckstyle.header.file=|-Dcheckstyle.includeResources=|-Dcheckstyle.includes=|-Dcheckstyle.includeTestResources=|-Dcheckstyle.console=|-Dcheckstyle.maxAllowedViolations=|-Dcheckstyle.output.file=|-Dcheckstyle.output.format=|-Dcheckstyle.properties.location=|-Dcheckstyle.resourceExcludes=|-Dcheckstyle.resourceIncludes=|-Dcheckstyle.output.rules.file=|-Dcheckstyle.skip=|-Dcheckstyle.skipExec=|-Dcheckstyle.suppression.expression=|-Dcheckstyle.suppressions.location=|-Dcheckstyle.violation.ignore=|-Dcheckstyle.violationSeverity="
    local plugin_args_checkstyle_checkstyle="-Dcheckstyle.config.location=|-Dcheckstyle.consoleOutput=|-Dcheckstyle.enable.files.summary=|-Dcheckstyle.enable.rss=|-Dcheckstyle.enable.rules.summary=|-Dcheckstyle.enable.severity.summary=|-Dencoding=|-Dcheckstyle.excludes=|-Dcheckstyle.header.file=|-Dcheckstyle.includeResources=|-Dcheckstyle.includes=|-Dcheckstyle.includeTestResources=|-DlinkXRef=|-Dcheckstyle.output.file=|-Dcheckstyle.output.format=|-Dcheckstyle.properties.location=|-Dcheckstyle.resourceExcludes=|-Dcheckstyle.resourceIncludes=|-Dcheckstyle.skip=|-Dcheckstyle.suppression.expression=|-Dcheckstyle.suppressions.location="
    local plugin_args_cobertura_cobertura="-Dcobertura.aggregate=|-Dproject.build.sourceEncoding=|-Dcobertura.report.format=|-Dcobertura.maxmem=|-Dcobertura.omitGplFiles=|-Dquiet="
    local plugin_args_dependency_analyze="-Danalyzer=|-DfailOnWarning=|-DignoreNonCompile=|-DoutputXML=|-DscriptableFlag=|-DscriptableOutput=|-Dmdep.analyze.skip=|-Dverbose="
    local plugin_args_dependency_analyze_dep_mgt="-Dmdep.analyze.failBuild=|-Dmdep.analyze.ignore.direct=|-Dmdep.analyze.skip="
    local plugin_args_dependency_analyze_duplicate="-Dmdep.analyze.skip="
    local plugin_args_dependency_analyze_only="-Danalyzer=|-DfailOnWarning=|-DignoreNonCompile=|-DoutputXML=|-DscriptableFlag=|-DscriptableOutput=|-Dmdep.analyze.skip=|-Dverbose="
    local plugin_args_dependency_analyze_report="-DignoreNonCompile=|-Dmdep.analyze.skip="
    local plugin_args_dependency_build_classpath="-Dclassifier=|-Dmdep.cpFile=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-Dmdep.fileSeparator=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeScope=|-DincludeTypes=|-Dmdep.localRepoProperty=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-Dmdep.outputFile=|-Dmdep.outputFilterFile=|-Dmdep.outputProperty=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.pathSeparator=|-Dmdep.prefix=|-Dmdep.prependGroupId=|-Dmdep.regenerateFile=|-Dsilent=|-Dmdep.skip=|-Dmdep.stripClassifier=|-Dmdep.stripVersion=|-Dtype=|-Dmdep.useBaseVersion="
    local plugin_args_dependency_copy="-Dartifact=|-DoutputAbsoluteArtifactFilename=|-DoutputDirectory=|-Dmdep.overIfNewer=|-Dmdep.overWriteReleases=|-Dmdep.overWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dmdep.stripClassifier=|-Dmdep.stripVersion=|-Dmdep.useBaseVersion="
    local plugin_args_dependency_copy_dependencies="-Dclassifier=|-Dmdep.copyPom=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-Dmdep.failOnMissingClassifierArtifact=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputDirectory=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dmdep.stripClassifier=|-Dmdep.stripVersion=|-Dtype=|-Dmdep.useBaseVersion=|-Dmdep.useRepositoryLayout=|-Dmdep.useSubDirectoryPerArtifact=|-Dmdep.useSubDirectoryPerScope=|-Dmdep.useSubDirectoryPerType="
    local plugin_args_dependency_get="-Dartifact=|-DartifactId=|-Dclassifier=|-Ddest=|-DgroupId=|-Dpackaging=|-DremoteRepositories=|-DrepoId=|-DrepoUrl=|-Dmdep.skip=|-Dtransitive=|-Dversion="
    local plugin_args_dependency_go_offline="-DappendOutput=|-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeReactor=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputFile=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dtype="
    local plugin_args_dependency_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_dependency_list="-DappendOutput=|-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeReactor=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeParents=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputFile=|-Dmdep.outputScope=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dsort=|-Dtype="
    local plugin_args_dependency_list_repositories="-Ddependency.ignorePermissions=|-DoutputAbsoluteArtifactFilename=|-Dsilent=|-Dmdep.skip=|-Ddependency.useJvmChmod="
    local plugin_args_dependency_properties="-Dmdep.skip="
    local plugin_args_dependency_purge_local_repository="-DactTransitively=|-Dexclude=|-Dinclude=|-DmanualInclude=|-DreResolve=|-DresolutionFuzziness=|-Dskip=|-DsnapshotsOnly=|-Dverbose="
    local plugin_args_dependency_resolve="-DappendOutput=|-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeReactor=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeParents=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputFile=|-Dmdep.outputScope=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dsort=|-Dtype="
    local plugin_args_dependency_resolve_plugins="-DappendOutput=|-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeReactor=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputFile=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dtype="
    local plugin_args_dependency_sources="-DappendOutput=|-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-DexcludeReactor=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-DincludeParents=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputFile=|-Dmdep.outputScope=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dsort=|-Dtype="
    local plugin_args_dependency_tree="-DappendOutput=|-Dexcludes=|-Dincludes=|-Doutput=|-DoutputFile=|-DoutputType=|-Dscope=|-Dskip=|-Dtokens=|-Dverbose="
    local plugin_args_dependency_unpack="-Dartifact=|-Dmdep.unpack.excludes=|-Ddependency.ignorePermissions=|-Dmdep.unpack.includes=|-DoutputAbsoluteArtifactFilename=|-DoutputDirectory=|-Dmdep.overIfNewer=|-Dmdep.overWriteReleases=|-Dmdep.overWriteSnapshots=|-Dsilent=|-Dmdep.skip=|-Ddependency.useJvmChmod="
    local plugin_args_dependency_unpack_dependencies="-Dclassifier=|-DexcludeArtifactIds=|-DexcludeClassifiers=|-DexcludeGroupIds=|-Dmdep.unpack.excludes=|-DexcludeScope=|-DexcludeTransitive=|-DexcludeTypes=|-Dmdep.failOnMissingClassifierArtifact=|-Ddependency.ignorePermissions=|-DincludeArtifactIds=|-DincludeClassifiers=|-DincludeGroupIds=|-Dmdep.unpack.includes=|-DincludeScope=|-DincludeTypes=|-DmarkersDirectory=|-DoutputAbsoluteArtifactFilename=|-DoutputDirectory=|-DoverWriteIfNewer=|-DoverWriteReleases=|-DoverWriteSnapshots=|-Dmdep.prependGroupId=|-Dsilent=|-Dmdep.skip=|-Dmdep.stripClassifier=|-Dmdep.stripVersion=|-Dtype=|-Ddependency.useJvmChmod=|-Dmdep.useRepositoryLayout=|-Dmdep.useSubDirectoryPerArtifact=|-Dmdep.useSubDirectoryPerScope=|-Dmdep.useSubDirectoryPerType="
    local plugin_args_deploy_deploy_file="-DartifactId=|-Dclassifier=|-Dclassifiers=|-DgeneratePom.description=|-Dfile=|-Dfiles=|-DgeneratePom=|-DgroupId=|-Djavadoc=|-Dpackaging=|-DpomFile=|-DrepositoryId=|-DrepositoryLayout=|-DretryFailedDeploymentCount=|-Dsources=|-Dtypes=|-DuniqueVersion=|-DupdateReleaseInfo=|-Durl=|-Dversion="
    local plugin_args_ear_ear="-Dmaven.ear.duplicateArtifactsBreakTheBuild=|-Dmaven.ear.escapedBackslashesInFilePath=|-Dmaven.ear.escapeString=|-Dmaven.ear.skinnyWars=|-Dmaven.ear.useJvmChmod="
    local plugin_args_eclipse_clean="-Dbasedir=|-Dproject.packaging=|-Declipse.skip="
    local plugin_args_eclipse_eclipse="-Declipse.addGroupIdToProjectName=|-Declipse.addVersionToProjectName=|-Declipse.ajdtVersion=|-DoutputDirectory=|-Declipse.classpathContainersLast=|-DdownloadJavadocs=|-DdownloadSources=|-Declipse.downloadSources=|-Declipse.projectDir=|-DforceRecheck=|-Declipse.jeeversion=|-Declipse.limitProjectReferencesToWorkspace=|-Declipse.manifest=|-Dproject.packaging=|-Declipse.preferStandardClasspathContainer=|-Declipse.projectNameTemplate=|-Declipse.skip=|-Declipse.testSourcesLast=|-Declipse.useProjectReferences=|-Declipse.workspace=|-Declipse.wtpapplicationxml=|-DwtpContextName=|-Declipse.wtpdefaultserver=|-Declipse.wtpmanifest=|-Dwtpversion="
    local plugin_args_ejb_ejb="-Dejb.classifier=|-Dejb.ejbJar=|-Dejb.ejbVersion=|-Dejb.escapeBackslashesInFilePath=|-Dejb.escapeString=|-Dejb.filterDeploymentDescriptor=|-Dejb.generateClient=|-DjarName="
    local plugin_args_enforcer_enforce="-Denforcer.fail=|-Denforcer.failFast=|-Denforcer.ignoreCache=|-Denforcer.skip="
    local plugin_args_exec_exec="-Dexec.async=|-Dexec.asyncDestroyOnShutdown=|-Dexec.classpathScope=|-Dexec.args=|-Dexec.executable=|-Dexec.longClasspath=|-Dexec.outputFile=|-Dexec.skip=|-DsourceRoot=|-DtestSourceRoot=|-Dexec.toolchain=|-Dexec.workingdir="
    local plugin_args_exec_java="-Dexec.arguments=|-Dexec.classpathScope=|-Dexec.cleanupDaemonThreads=|-Dexec.args=|-Dexec.daemonThreadJoinTimeout=|-Dexec.includePluginsDependencies=|-Dexec.includeProjectDependencies=|-Dexec.keepAlive=|-Dexec.killAfter=|-Dexec.mainClass=|-Dexec.skip=|-DsourceRoot=|-Dexec.stopUnresponsiveDaemonThreads=|-DtestSourceRoot="
    local plugin_args_failsafe_integration_test="-Dmaven.test.additionalClasspath=|-DargLine=|-DchildDelegation=|-Dmaven.test.dependency.excludes=|-Dmaven.failsafe.debug=|-DdependenciesToScan=|-DdisableXmlReport=|-DenableAssertions=|-Dencoding=|-DexcludedGroups=|-Dfailsafe.excludesFile=|-Dit.failIfNoSpecifiedTests=|-DfailIfNoTests=|-DforkCount=|-Dfailsafe.timeout=|-DforkMode=|-Dgroups=|-Dfailsafe.includesFile=|-DjunitArtifactName=|-Djvm=|-DobjectFactory=|-Dparallel=|-DparallelOptimized=|-Dfailsafe.parallel.forcedTimeout=|-Dfailsafe.parallel.timeout=|-DperCoreThreadCount=|-Dfailsafe.printSummary=|-Dmaven.test.redirectTestOutputToFile=|-Dfailsafe.reportFormat=|-Dsurefire.reportNameSuffix=|-Dfailsafe.rerunFailingTestsCount=|-DreuseForks=|-Dfailsafe.runOrder=|-Dfailsafe.shutdown=|-Dmaven.test.skip=|-Dfailsafe.skipAfterFailureCount=|-Dmaven.test.skip.exec=|-DskipITs=|-DskipTests=|-Dfailsafe.suiteXmlFiles=|-Dit.test=|-DtestNGArtifactName=|-DthreadCount=|-DthreadCountClasses=|-DthreadCountMethods=|-DthreadCountSuites=|-DtrimStackTrace=|-Dfailsafe.useFile=|-Dfailsafe.useManifestOnlyJar=|-Dfailsafe.useSystemClassLoader=|-DuseUnlimitedThreads=|-Dbasedir="
    local plugin_args_failsafe_verify="-Dencoding=|-DfailIfNoTests=|-Dmaven.test.skip=|-Dmaven.test.skip.exec=|-DskipITs=|-DskipTests=|-Dmaven.test.failure.ignore="
    local plugin_args_findbugs_findbugs="-Dfindbugs.debug=|-Dfindbugs.effort=|-Dfindbugs.excludeBugsFile=|-Dfindbugs.excludeFilterFile=|-Dfindbugs.failOnError=|-Dfindbugs.fork=|-Dfindbugs.includeFilterFile=|-Dfindbugs.includeTests=|-Dfindbugs.jvmArgs=|-Dfindbugs.maxHeap=|-Dfindbugs.maxRank=|-Dfindbugs.nested=|-Dfindbugs.omitVisitors=|-Dfindbugs.onlyAnalyze=|-DoutputEncoding=|-Dfindbugs.pluginList=|-Dfindbugs.relaxed=|-Dfindbugs.skip=|-Dfindbugs.skipEmptyReport=|-Dencoding=|-Dfindbugs.threshold=|-Dfindbugs.timeout=|-Dfindbugs.trace=|-Dfindbugs.userPrefs=|-Dfindbugs.visitors=|-Dfindbugs.xmlOutput="
    local plugin_args_findbugs_gui="-Dfindbugs.debug=|-Dfindbugs.effort=|-Dencoding=|-Dfindbugs.maxHeap=|-Dfindbugs.pluginList="
    local plugin_args_findbugs_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_gpg_sign="-Dgpg.defaultKeyring=|-Dgpg.executable=|-Dgpg.homedir=|-Dgpg.keyname=|-Dgpg.lockMode=|-Dgpg.passphrase=|-Dgpg.passphraseServerId=|-Dgpg.publicKeyring=|-Dgpg.secretKeyring=|-Dgpg.skip=|-Dgpg.useagent="
    local plugin_args_gpg_sign_and_deploy_file="-DartifactId=|-Dgpg.ascDirectory=|-Dclassifier=|-Dclassifiers=|-Dgpg.defaultKeyring=|-DgeneratePom.description=|-Dgpg.executable=|-Dfile=|-Dfiles=|-DgeneratePom=|-DgroupId=|-Dgpg.homedir=|-Djavadoc=|-Dgpg.keyname=|-Dgpg.lockMode=|-Dpackaging=|-Dgpg.passphrase=|-Dgpg.passphraseServerId=|-DpomFile=|-Dgpg.publicKeyring=|-DrepositoryId=|-DrepositoryLayout=|-DretryFailedDeploymentCount=|-Dgpg.secretKeyring=|-Dsources=|-Dtypes=|-DuniqueVersion=|-DupdateReleaseInfo=|-Durl=|-Dgpg.useagent=|-Dversion="
    local plugin_args_gwt_clean="-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.war="
    local plugin_args_gwt_compile="-Dgwt.compiler.enableClosureCompiler=|-Dgwt.compiler.clusterFunctions=|-Dgwt.compiler.compileReport=|-Dgwt.compiler.compilerMetrics=|-Dgwt.compiler.soycDetailed=|-Dgwt.disableCastChecking=|-Dgwt.disableClassMetadata=|-Dgwt.disableRunAsync=|-Dgwt.draftCompile=|-Dgwt.compiler.enforceStrictResources=|-Dgwt.extraJvmArgs=|-Dgwt.extraParam=|-Dgwt.compiler.strict=|-Dgwt.compiler.force=|-Dgwt.compiler.fragmentCount=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.compiler.incremental=|-Dgwt.compiler.inlineLiteralParameters=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.compiler.localWorkers=|-Dgwt.logLevel=|-Dgwt.compiler.methodNameDisplayMode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.compiler.optimizationLevel=|-Dgwt.compiler.optimizeDataflow=|-Dgwt.compiler.ordinalizeEnums=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.compiler.removeDuplicateFunctions=|-Dgwt.saveSource=|-Dgwt.compiler.skip=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.validateOnly=|-Dgwt.war="
    local plugin_args_gwt_compile_report="-Dgwt.compilerReport.skip="
    local plugin_args_gwt_css="-Dproject.build.sourceEncoding=|-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.style=|-Dgwt.war="
    local plugin_args_gwt_debug="-Dgwt.appEngineArtifactId=|-Dgwt.appEngineGroupId=|-Dgwt.appEngineHome=|-Dgwt.appEngineVersion=|-DattachDebugger=|-Dgwt.bindAddress=|-Dgwt.cacheGeneratorResults=|-Dgwt.codeServerPort=|-Dgwt.copyWebapp=|-Dgwt.debugPort=|-Dgwt.debugSuspend=|-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.compiler.incremental=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.compiler.methodNameDisplayMode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.noserver=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.port=|-DrunTarget=|-Dgwt.server=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.superDevMode=|-Dgwt.war="
    local plugin_args_gwt_eclipse="-Dgwt.bindAddress=|-Dgwt.blacklist=|-Dgwt.extraJvmArgs=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.noserver=|-Dgwt.port=|-Duse.google.eclipse.plugin=|-Dgwt.war=|-Dgwt.whitelist="
    local plugin_args_gwt_eclipseTest="-Dgwt.test.batch=|-Dgwt.compiler.clusterFunctions=|-Dgwt.disableCastChecking=|-Dgwt.disableClassMetadata=|-Dgwt.disableRunAsync=|-Dgwt.draftCompiler=|-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.test.htmlunit=|-Dgwt.compiler.incremental=|-Dgwt.compiler.inlineLiteralParameters=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.test.mode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.compiler.optimizationLevel=|-Dgwt.compiler.optimizeDataflow=|-Dgwt.compiler.ordinalizeEnums=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.test.precompile=|-Dgwt.test.prod=|-Dgwt.compiler.removeDuplicateFunctions=|-Dgwt.test.selenium=|-Dgwt.test.showUi=|-Dmaven.test.skip=|-Dmaven.test.skip.exec=|-DskipTests=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.testBeginTimeout=|-Dmaven.test.failure.ignore=|-Dgwt.testMethodTimeout=|-Dgwt.test.tries=|-Dgwt.test.userAgents=|-Dgwt.war=|-Dgwt.test.web="
    local plugin_args_gwt_generateAsync="-Dproject.build.sourceEncoding=|-Dmaven.gwt.failOnError=|-DgenerateAsync.force=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.modulePathPrefix=|-Dgwt.rpcPattern=|-Dgwt.war="
    local plugin_args_gwt_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_gwt_i18n="-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.style=|-Dgwt.war="
    local plugin_args_gwt_mergewebxml="-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.style=|-Dgwt.war="
    local plugin_args_gwt_resources="-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.war="
    local plugin_args_gwt_run="-Dgwt.appEngineArtifactId=|-Dgwt.appEngineGroupId=|-Dgwt.appEngineHome=|-Dgwt.appEngineVersion=|-Dgwt.bindAddress=|-Dgwt.cacheGeneratorResults=|-Dgwt.codeServerPort=|-Dgwt.copyWebapp=|-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.compiler.incremental=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.compiler.methodNameDisplayMode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.noserver=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.port=|-DrunTarget=|-Dgwt.server=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.superDevMode=|-Dgwt.war="
    local plugin_args_gwt_run_codeserver="-Dgwt.bindAddress=|-Dgwt.codeServerPort=|-Dgwt.compiler.enforceStrictResources=|-Dgwt.extraJvmArgs=|-Dgwt.compiler.strict=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.compiler.incremental=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.codeServer.launcherDir=|-Dgwt.logLevel=|-Dgwt.compiler.methodNameDisplayMode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.codeServer.precompile=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.war="
    local plugin_args_gwt_source_jar="-Djar.finalName=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.inplace=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.war="
    local plugin_args_gwt_test="-Dgwt.test.batch=|-Dgwt.compiler.clusterFunctions=|-Dgwt.disableCastChecking=|-Dgwt.disableClassMetadata=|-Dgwt.disableRunAsync=|-Dgwt.draftCompiler=|-Dgwt.extraJvmArgs=|-Dgwt.gen=|-Dgwt.genParam=|-Dgwt.gwtSdkFirstInClasspath=|-Dgwt.test.htmlunit=|-Dgwt.compiler.incremental=|-Dgwt.compiler.inlineLiteralParameters=|-Dgwt.inplace=|-Dgwt.jvm=|-Dgwt.logLevel=|-Dgwt.test.mode=|-Dgwt.module=|-Dgwt.modulePathPrefix=|-Dgwt.compiler.optimizationLevel=|-Dgwt.compiler.optimizeDataflow=|-Dgwt.compiler.ordinalizeEnums=|-Dgwt.persistentunitcache=|-Dgwt.persistentunitcachedir=|-Dgwt.test.precompile=|-Dgwt.test.prod=|-Dgwt.compiler.removeDuplicateFunctions=|-Dgwt.test.selenium=|-Dgwt.test.showUi=|-Dmaven.test.skip=|-Dmaven.test.skip.exec=|-DskipTests=|-Dmaven.compiler.source=|-Dgwt.style=|-Dgwt.testBeginTimeout=|-Dmaven.test.failure.ignore=|-Dgwt.testMethodTimeout=|-Dgwt.test.tries=|-Dgwt.test.userAgents=|-Dgwt.war=|-Dgwt.test.web="
    local plugin_args_help_active_profiles="-Doutput="
    local plugin_args_help_all_profiles="-Doutput="
    local plugin_args_help_describe="-DartifactId=|-Dcmd=|-Ddetail=|-Dgoal=|-DgroupId=|-Dmedium=|-Dminimal=|-Doutput=|-Dplugin=|-Dversion="
    local plugin_args_help_effective_pom="-Doutput="
    local plugin_args_help_effective_settings="-Doutput=|-DshowPasswords="
    local plugin_args_help_evaluate="-Dartifact=|-Dexpression="
    local plugin_args_help_expressions="-Doutput="
    local plugin_args_help_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_help_system="-Doutput="
    local plugin_args_hibernate3_hbm2ddl="-Dplugin.classRealm=|-Dhibernatetool="
    local plugin_args_hibernate3_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_idea_idea="-DdeploymentDescriptorFile=|-DdownloadJavadocs=|-DdownloadSources=|-DideaVersion=|-DjavadocClassifier=|-DjdkLevel=|-DjdkName=|-DlinkModules=|-Doverwrite=|-DsourceClassifier=|-DuseFullNames=|-DwildcardResourcePatterns="
    local plugin_args_install_install_file="-DartifactId=|-Dclassifier=|-DcreateChecksum=|-Dfile=|-DgeneratePom=|-DgroupId=|-Djavadoc=|-DlocalRepositoryPath=|-Dpackaging=|-DpomFile=|-DrepositoryLayout=|-Dsources=|-DupdateReleaseInfo=|-Dversion="
    local plugin_args_javadoc_aggregate="-DadditionalJOption=|-Dadditionalparam=|-Daggregate=|-Dmaven.javadoc.applyJavadocSecurityFix=|-Dauthor=|-Dbootclasspath=|-DbootclasspathArtifacts=|-Dbottom=|-Dbreakiterator=|-Dcharset=|-Ddebug=|-Ddescription=|-DdestDir=|-DdetectJavaApiLink=|-DdetectLinks=|-DdetectOfflineLinks=|-Ddocencoding=|-Ddocfilessubdirs=|-Ddoclet=|-DdocletArtifact=|-DdocletArtifacts=|-DdocletPath=|-Ddoctitle=|-Dencoding=|-Dexcludedocfilessubdir=|-DexcludePackageNames=|-Dextdirs=|-Dmaven.javadoc.failOnError=|-Dfooter=|-Dgroups=|-Dheader=|-Dhelpfile=|-DjavaApiLinks=|-DjavadocExecutable=|-DjavadocVersion=|-Dkeywords=|-Dlinks=|-Dlinksource=|-Dlocale=|-DlocalRepository=|-Dmaxmemory=|-Dminmemory=|-Dname=|-Dnocomment=|-Dnodeprecated=|-Dnodeprecatedlist=|-Dnohelp=|-Dnoindex=|-Dnonavbar=|-Dnooverview=|-Dnoqualifier=|-Dnosince=|-Dnotimestamp=|-Dnotree=|-DofflineLinks=|-Dold=|-DdestDir=|-Doverview=|-Dpackagesheader=|-DproxyHost=|-DproxyPort=|-Dquiet=|-Dproject.remoteArtifactRepositories=|-DreportOutputDirectory=|-DresourcesArtifacts=|-Dserialwarn=|-Dshow=|-Dmaven.javadoc.skip=|-Dsource=|-Dsourcepath=|-Dsourcetab=|-Dsplitindex=|-Dstylesheet=|-Dstylesheetfile=|-Dsubpackages=|-Dtaglet=|-DtagletArtifact=|-DtagletArtifacts=|-Dtagletpath=|-Dtaglets=|-Dtags=|-Dtop=|-Duse=|-DuseStandardDocletOptions=|-DvalidateLinks=|-Dverbose=|-Dversion=|-Dwindowtitle="
    local plugin_args_javadoc_jar="-DadditionalJOption=|-Dadditionalparam=|-Daggregate=|-Dmaven.javadoc.applyJavadocSecurityFix=|-Dattach=|-Dauthor=|-Dbootclasspath=|-DbootclasspathArtifacts=|-Dbottom=|-Dbreakiterator=|-Dcharset=|-Dmaven.javadoc.classifier=|-Ddebug=|-DdestDir=|-DdetectJavaApiLink=|-DdetectLinks=|-DdetectOfflineLinks=|-Ddocencoding=|-Ddocfilessubdirs=|-Ddoclet=|-DdocletArtifact=|-DdocletArtifacts=|-DdocletPath=|-Ddoctitle=|-Dencoding=|-Dexcludedocfilessubdir=|-DexcludePackageNames=|-Dextdirs=|-Dmaven.javadoc.failOnError=|-Dproject.build.finalName=|-Dfooter=|-Dgroups=|-Dheader=|-Dhelpfile=|-Dproject.build.directory=|-DjavaApiLinks=|-DjavadocExecutable=|-DjavadocVersion=|-Dkeywords=|-Dlinks=|-Dlinksource=|-Dlocale=|-DlocalRepository=|-Dmaxmemory=|-Dminmemory=|-Dnocomment=|-Dnodeprecated=|-Dnodeprecatedlist=|-Dnohelp=|-Dnoindex=|-Dnonavbar=|-Dnooverview=|-Dnoqualifier=|-Dnosince=|-Dnotimestamp=|-Dnotree=|-DofflineLinks=|-Dold=|-DdestDir=|-Doverview=|-Dpackagesheader=|-DproxyHost=|-DproxyPort=|-Dquiet=|-Dproject.remoteArtifactRepositories=|-DresourcesArtifacts=|-Dserialwarn=|-Dshow=|-Dmaven.javadoc.skip=|-Dsource=|-Dsourcepath=|-Dsourcetab=|-Dsplitindex=|-Dstylesheet=|-Dstylesheetfile=|-Dsubpackages=|-Dtaglet=|-DtagletArtifact=|-DtagletArtifacts=|-Dtagletpath=|-Dtaglets=|-Dtags=|-Dtop=|-Duse=|-DuseStandardDocletOptions=|-DvalidateLinks=|-Dverbose=|-Dversion=|-Dwindowtitle="
    local plugin_args_javadoc_javadoc="-DadditionalJOption=|-Dadditionalparam=|-Daggregate=|-Dmaven.javadoc.applyJavadocSecurityFix=|-Dauthor=|-Dbootclasspath=|-DbootclasspathArtifacts=|-Dbottom=|-Dbreakiterator=|-Dcharset=|-Ddebug=|-Ddescription=|-DdestDir=|-DdetectJavaApiLink=|-DdetectLinks=|-DdetectOfflineLinks=|-Ddocencoding=|-Ddocfilessubdirs=|-Ddoclet=|-DdocletArtifact=|-DdocletArtifacts=|-DdocletPath=|-Ddoctitle=|-Dencoding=|-Dexcludedocfilessubdir=|-DexcludePackageNames=|-Dextdirs=|-Dmaven.javadoc.failOnError=|-Dfooter=|-Dgroups=|-Dheader=|-Dhelpfile=|-DjavaApiLinks=|-DjavadocExecutable=|-DjavadocVersion=|-Dkeywords=|-Dlinks=|-Dlinksource=|-Dlocale=|-DlocalRepository=|-Dmaxmemory=|-Dminmemory=|-Dname=|-Dnocomment=|-Dnodeprecated=|-Dnodeprecatedlist=|-Dnohelp=|-Dnoindex=|-Dnonavbar=|-Dnooverview=|-Dnoqualifier=|-Dnosince=|-Dnotimestamp=|-Dnotree=|-DofflineLinks=|-Dold=|-DdestDir=|-Doverview=|-Dpackagesheader=|-DproxyHost=|-DproxyPort=|-Dquiet=|-Dproject.remoteArtifactRepositories=|-DreportOutputDirectory=|-DresourcesArtifacts=|-Dserialwarn=|-Dshow=|-Dmaven.javadoc.skip=|-Dsource=|-Dsourcepath=|-Dsourcetab=|-Dsplitindex=|-Dstylesheet=|-Dstylesheetfile=|-Dsubpackages=|-Dtaglet=|-DtagletArtifact=|-DtagletArtifacts=|-Dtagletpath=|-Dtaglets=|-Dtags=|-Dtop=|-Duse=|-DuseStandardDocletOptions=|-DvalidateLinks=|-Dverbose=|-Dversion=|-Dwindowtitle="
    local plugin_args_jboss_deploy="-Djboss.fileNameEncoding=|-Djboss.hostName=|-Djboss.port=|-Djboss.serverId=|-Djboss.skip="
    local plugin_args_jboss_redeploy="-Djboss.hostName=|-Djboss.port=|-Djboss.serverId=|-Djboss.skip="
    local plugin_args_jboss_start="-Denv.JBOSS_HOME=|-Djboss.options=|-Djboss.serverId=|-Djboss.serverName=|-Djboss.startOptions="
    local plugin_args_jboss_stop="-Denv.JBOSS_HOME=|-Djboss.options=|-Djboss.serverId=|-Djboss.serverName=|-Djboss.stopOptions=|-Djboss.stopWait="
    local plugin_args_jboss_undeploy="-Djboss.hostName=|-Djboss.port=|-Djboss.serverId=|-Djboss.skip="
    local plugin_args_jxr_jxr="-Dbottom=|-Dencoding=|-DoutputEncoding=|-Dmaven.jxr.skip="
    local plugin_args_pmd_check="-Daggregate=|-Dpmd.excludeFromFailureFile=|-Dpmd.failOnViolation=|-Dpmd.failurePriority=|-Dpmd.printFailingErrors=|-Dpmd.skip=|-Dproject.build.directory=|-Dpmd.verbose="
    local plugin_args_pmd_cpd="-Daggregate=|-Dformat=|-Dcpd.ignoreIdentifiers=|-Dcpd.ignoreLiterals=|-DlinkXRef=|-DminimumTokens=|-Dproject.reporting.outputDirectory=|-DoutputEncoding=|-Dcpd.skip=|-Dencoding=|-Dproject.build.directory="
    local plugin_args_pmd_cpd_check="-Daggregate=|-Dpmd.excludeFromFailureFile=|-Dcpd.failOnViolation=|-Dpmd.printFailingErrors=|-Dcpd.skip=|-Dproject.build.directory=|-Dpmd.verbose="
    local plugin_args_pmd_pmd="-Daggregate=|-Dpmd.benchmark=|-Dpmd.benchmarkOutputFilename=|-Dformat=|-DlinkXRef=|-DminimumPriority=|-Dproject.reporting.outputDirectory=|-DoutputEncoding=|-Dpmd.skip=|-Dpmd.skipPmdError=|-Dencoding=|-Dpmd.suppressMarker=|-Dproject.build.directory=|-DtargetJdk=|-Dpmd.typeResolution="
    local plugin_args_release_branch="-DaddSchema=|-Darguments=|-DautoVersionSubmodules=|-DbranchBase=|-DbranchName=|-DcheckModificationExcludeList=|-DdevelopmentVersion=|-DdryRun=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DreleaseVersion=|-DremoteTagging=|-DscmCommentPrefix=|-DsuppressCommitBeforeBranch=|-Dtag=|-DtagBase=|-DtagNameFormat=|-DupdateBranchVersions=|-DupdateDependencies=|-DupdateVersionsToSnapshot=|-DupdateWorkingCopyVersions=|-DuseEditMode=|-Dusername="
    local plugin_args_release_clean="-Darguments=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DscmCommentPrefix=|-Dtag=|-DtagBase=|-DtagNameFormat=|-Dusername="
    local plugin_args_release_perform="-Darguments=|-DconnectionUrl=|-DdryRun=|-Dgoals=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DreleaseProfiles=|-DscmCommentPrefix=|-Dtag=|-DtagBase=|-DtagNameFormat=|-DuseReleaseProfile=|-Dusername=|-DworkingDirectory="
    local plugin_args_release_prepare="-DaddSchema=|-DignoreSnapshots=|-Darguments=|-DautoVersionSubmodules=|-DcheckModificationExcludeList=|-DcommitByProject=|-DcompletionGoals=|-DdevelopmentVersion=|-DdryRun=|-DgenerateReleasePoms=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpreparationGoals=|-DpushChanges=|-DreleaseVersion=|-DremoteTagging=|-Dresume=|-DscmCommentPrefix=|-DsuppressCommitBeforeTag=|-Dtag=|-DtagBase=|-DtagNameFormat=|-DupdateDependencies=|-DupdateWorkingCopyVersions=|-DuseEditMode=|-Dusername=|-DwaitBeforeTagging="
    local plugin_args_release_rollback="-Darguments=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DscmCommentPrefix=|-Dtag=|-DtagBase=|-DtagNameFormat=|-Dusername="
    local plugin_args_release_stage="-Darguments=|-DconnectionUrl=|-Dgoals=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DreleaseProfiles=|-DscmCommentPrefix=|-DstagingRepository=|-Dtag=|-DtagBase=|-DtagNameFormat=|-DuseReleaseProfile=|-Dusername=|-DworkingDirectory="
    local plugin_args_release_update_versions="-DaddSchema=|-Darguments=|-DautoVersionSubmodules=|-DdevelopmentVersion=|-DlocalCheckout=|-DmavenExecutorId=|-Dpassword=|-DpomFileName=|-DpushChanges=|-DscmCommentPrefix=|-Dtag=|-DtagBase=|-DtagNameFormat=|-Dusername="
    local plugin_args_repository_bundle_create="-Dbundle.disableMaterialization="
    local plugin_args_repository_bundle_pack="-DartifactId=|-Dbundle.disableMaterialization=|-DgroupId=|-DscmConnection=|-DscmUrl=|-Dversion="
    local plugin_args_repository_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_scm_add="-Dbasedir=|-DconnectionType=|-DconnectionUrl=|-DdeveloperConnectionUrl=|-Dexcludes=|-Dincludes=|-Dpassphrase=|-Dpassword=|-DprivateKey=|-DpushChanges=|-DtagBase=|-Dusername=|-DworkingDirectory="
    local plugin_args_scm_checkin="-Dbasedir=|-DconnectionType=|-DconnectionUrl=|-DdeveloperConnectionUrl=|-Dexcludes=|-Dincludes=|-Dmessage=|-Dpassphrase=|-Dpassword=|-DprivateKey=|-DpushChanges=|-DscmVersion=|-DscmVersionType=|-DtagBase=|-Dusername=|-DworkingDirectory="
    local plugin_args_scm_checkout="-Dbasedir=|-DcheckoutDirectory=|-DconnectionType=|-DconnectionUrl=|-DdeveloperConnectionUrl=|-Dexcludes=|-Dincludes=|-Dpassphrase=|-Dpassword=|-DprivateKey=|-DpushChanges=|-DscmVersion=|-DscmVersionType=|-DskipCheckoutIfExists=|-DtagBase=|-DuseExport=|-Dusername=|-DworkingDirectory="
    local plugin_args_scm_status="-Dbasedir=|-DconnectionType=|-DconnectionUrl=|-DdeveloperConnectionUrl=|-Dexcludes=|-Dincludes=|-Dpassphrase=|-Dpassword=|-DprivateKey=|-DpushChanges=|-DtagBase=|-Dusername=|-DworkingDirectory="
    local plugin_args_scm_update="-Dbasedir=|-DconnectionType=|-DconnectionUrl=|-DdeveloperConnectionUrl=|-Dexcludes=|-Dincludes=|-Dpassphrase=|-Dpassword=|-DprivateKey=|-DpushChanges=|-DrevisionKey=|-DrunChangelog=|-DscmVersion=|-DscmVersionType=|-DtagBase=|-Dusername=|-DworkingDirectory="
    local plugin_args_site_deploy="-Dmaven.site.chmod=|-Dmaven.site.chmod.mode=|-Dmaven.site.chmod.options=|-Dencoding=|-Dlocales=|-DoutputEncoding=|-Dmaven.site.deploy.skip="
    local plugin_args_site_run="-DgenerateProjectInfo=|-Dencoding=|-Dlocales=|-DoutputEncoding=|-Dport=|-DrelativizeDecorationLinks=|-Dtemplate=|-DtemplateDirectory=|-DtemplateFile="
    local plugin_args_site_site="-DgenerateProjectInfo=|-DgenerateReports=|-DgenerateSitemap=|-Dencoding=|-Dlocales=|-DsiteOutputDirectory=|-DoutputEncoding=|-DrelativizeDecorationLinks=|-Dmaven.site.skip=|-Dtemplate=|-DtemplateDirectory=|-DtemplateFile=|-Dvalidate="
    local plugin_args_site_stage="-Dmaven.site.chmod=|-Dmaven.site.chmod.mode=|-Dmaven.site.chmod.options=|-Dencoding=|-Dlocales=|-DoutputEncoding=|-Dmaven.site.skip=|-Dmaven.site.deploy.skip=|-DstagingDirectory=|-DtopSiteURL="
    local plugin_args_site_stage_deploy="-Dmaven.site.chmod=|-Dmaven.site.chmod.mode=|-Dmaven.site.chmod.options=|-Dencoding=|-Dlocales=|-DoutputEncoding=|-Dmaven.site.deploy.skip=|-DstagingRepositoryId=|-DstagingSiteURL=|-DtopSiteURL="
    local plugin_args_sonar_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_sonar_sonar="-Dsonar.skip="
    local plugin_args_source_aggregate="-Dmaven.source.attach=|-Dmaven.source.classifier=|-Dmaven.source.excludeResources=|-Dmaven.source.forceCreation=|-Dmaven.source.includePom=|-Dmaven.source.skip=|-Dmaven.source.useDefaultExcludes=|-Dmaven.source.useDefaultManifestFile="
    local plugin_args_source_jar="-Dmaven.source.attach=|-Dmaven.source.classifier=|-Dmaven.source.excludeResources=|-Dmaven.source.forceCreation=|-Dmaven.source.includePom=|-Dmaven.source.skip=|-Dmaven.source.useDefaultExcludes=|-Dmaven.source.useDefaultManifestFile="
    local plugin_args_source_jar_no_fork="-Dmaven.source.attach=|-Dmaven.source.classifier=|-Dmaven.source.excludeResources=|-Dmaven.source.forceCreation=|-Dmaven.source.includePom=|-Dmaven.source.skip=|-Dmaven.source.useDefaultExcludes=|-Dmaven.source.useDefaultManifestFile="
    local plugin_args_surefire_test="-Dmaven.test.additionalClasspath=|-DargLine=|-DchildDelegation=|-Dmaven.test.dependency.excludes=|-Dmaven.surefire.debug=|-DdependenciesToScan=|-DdisableXmlReport=|-DenableAssertions=|-DexcludedGroups=|-Dsurefire.excludesFile=|-Dsurefire.failIfNoSpecifiedTests=|-DfailIfNoTests=|-DforkCount=|-Dsurefire.timeout=|-DforkMode=|-Dgroups=|-Dsurefire.includesFile=|-DjunitArtifactName=|-Djvm=|-DobjectFactory=|-Dparallel=|-DparallelOptimized=|-Dsurefire.parallel.forcedTimeout=|-Dsurefire.parallel.timeout=|-DperCoreThreadCount=|-Dsurefire.printSummary=|-Dmaven.test.redirectTestOutputToFile=|-Dsurefire.reportFormat=|-Dsurefire.reportNameSuffix=|-Dsurefire.rerunFailingTestsCount=|-DreuseForks=|-Dsurefire.runOrder=|-Dsurefire.shutdown=|-Dmaven.test.skip=|-Dsurefire.skipAfterFailureCount=|-Dmaven.test.skip.exec=|-DskipTests=|-Dsurefire.suiteXmlFiles=|-Dtest=|-Dmaven.test.failure.ignore=|-DtestNGArtifactName=|-DthreadCount=|-DthreadCountClasses=|-DthreadCountMethods=|-DthreadCountSuites=|-DtrimStackTrace=|-Dsurefire.useFile=|-Dsurefire.useManifestOnlyJar=|-Dsurefire.useSystemClassLoader=|-DuseUnlimitedThreads=|-Dbasedir="
    local plugin_args_tomcat_deploy="-Dmaven.tomcat.charset=|-Dtomcat.ignorePackaging=|-Dmaven.tomcat.mode=|-Dtomcat.password=|-Dmaven.tomcat.path=|-Dmaven.tomcat.server=|-Dmaven.tomcat.tag=|-Dmaven.tomcat.update=|-Dmaven.tomcat.url=|-Dtomcat.username="
    local plugin_args_tomcat_help="-Ddetail=|-Dgoal=|-DindentSize=|-DlineLength="
    local plugin_args_tomcat_start="-Dmaven.tomcat.charset=|-Dtomcat.ignorePackaging=|-Dtomcat.password=|-Dmaven.tomcat.path=|-Dmaven.tomcat.server=|-Dmaven.tomcat.url=|-Dtomcat.username="
    local plugin_args_tomcat_stop="-Dmaven.tomcat.charset=|-Dtomcat.ignorePackaging=|-Dtomcat.password=|-Dmaven.tomcat.path=|-Dmaven.tomcat.server=|-Dmaven.tomcat.url=|-Dtomcat.username="
    local plugin_args_tomcat_undeploy="-Dmaven.tomcat.charset=|-Dmaven.tomcat.failOnError=|-Dtomcat.ignorePackaging=|-Dtomcat.password=|-Dmaven.tomcat.path=|-Dmaven.tomcat.server=|-Dmaven.tomcat.url=|-Dtomcat.username="
    local plugin_args_versions_display_dependency_updates="-DallowSnapshots=|-DgenerateBackupPoms=|-Dversions.logOutput=|-DoutputEncoding=|-Dversions.outputFile=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId=|-Dverbose="
    local plugin_args_versions_display_plugin_updates="-DallowSnapshots=|-DgenerateBackupPoms=|-Dversions.logOutput=|-DoutputEncoding=|-Dversions.outputFile=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_display_property_updates="-DallowSnapshots=|-DautoLinkItems=|-DexcludeProperties=|-DgenerateBackupPoms=|-DincludeProperties=|-Dversions.logOutput=|-DoutputEncoding=|-Dversions.outputFile=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_lock_snapshots="-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_resolve_ranges="-DallowSnapshots=|-DexcludeProperties=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-DincludeProperties=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-DprocessProperties=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_set="-DallowSnapshots=|-DartifactId=|-DgenerateBackupPoms=|-DgroupId=|-DnewVersion=|-DoldVersion=|-DprocessDependencies=|-DprocessParent=|-DprocessPlugins=|-DprocessProject=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId=|-DupdateMatchingVersions="
    local plugin_args_versions_unlock_snapshots="-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_update_child_modules="-DallowSnapshots=|-DgenerateBackupPoms=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_update_parent="-DallowSnapshots=|-DgenerateBackupPoms=|-DparentVersion=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_update_properties="-DallowSnapshots=|-DautoLinkItems=|-DexcludeProperties=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-DincludeProperties=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_latest_releases="-DallowIncrementalUpdates=|-DallowMajorUpdates=|-DallowMinorUpdates=|-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_latest_snapshots="-DallowIncrementalUpdates=|-DallowMajorUpdates=|-DallowMinorUpdates=|-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_latest_versions="-DallowIncrementalUpdates=|-DallowMajorUpdates=|-DallowMinorUpdates=|-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_next_releases="-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_next_snapshots="-DallowIncrementalUpdates=|-DallowMajorUpdates=|-DallowMinorUpdates=|-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_next_versions="-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_versions_use_releases="-DallowSnapshots=|-DexcludeReactor=|-Dexcludes=|-DgenerateBackupPoms=|-Dincludes=|-DprocessDependencies=|-DprocessDependencyManagement=|-Dmaven.version.rules=|-Dmaven.version.rules.serverId="
    local plugin_args_war_exploded="-DarchiveClasses=|-Dmaven.war.containerConfigXML=|-Dmaven.war.escapedBackslashesInFilePath=|-Dmaven.war.escapeString=|-Dmaven.war.filteringDeploymentDescriptors=|-DresourceEncoding=|-Dmaven.war.supportMultiLineFiltering=|-DuseCache=|-Dmaven.war.useJvmChmod=|-Dmaven.war.webxml="
    local plugin_args_war_inplace="-DarchiveClasses=|-Dmaven.war.containerConfigXML=|-Dmaven.war.escapedBackslashesInFilePath=|-Dmaven.war.escapeString=|-Dmaven.war.filteringDeploymentDescriptors=|-DresourceEncoding=|-Dmaven.war.supportMultiLineFiltering=|-DuseCache=|-Dmaven.war.useJvmChmod=|-Dmaven.war.webxml="
    local plugin_args_war_manifest="-DarchiveClasses=|-Dmaven.war.containerConfigXML=|-Dmaven.war.escapedBackslashesInFilePath=|-Dmaven.war.escapeString=|-Dmaven.war.filteringDeploymentDescriptors=|-DresourceEncoding=|-Dmaven.war.supportMultiLineFiltering=|-DuseCache=|-Dmaven.war.useJvmChmod=|-Dmaven.war.webxml="
    local plugin_args_war_war="-DarchiveClasses=|-Dmaven.war.containerConfigXML=|-Dmaven.war.escapedBackslashesInFilePath=|-Dmaven.war.escapeString=|-DfailOnMissingWebXml=|-Dmaven.war.filteringDeploymentDescriptors=|-DprimaryArtifact=|-DresourceEncoding=|-Dmaven.war.supportMultiLineFiltering=|-DuseCache=|-Dmaven.war.useJvmChmod=|-Dwar.warName=|-Dmaven.war.webxml="

    ## some plugin (like jboss-as) has '-' which is not allowed in shell var name, to use '_' then replace
    local common_plugins=`compgen -v | grep "^plugin_goals_.*" | sed 's/plugin_goals_//g' | tr '_' '-' | tr '\n' '|'`

    local options="-Dmaven.test.skip=true|-DskipTests|-DskipITs|-Dtest|-Dit.test|-DfailIfNoTests|-Dmaven.surefire.debug|-DenableCiProfile|-Dpmd.skip=true|-Dcheckstyle.skip=true|-Dtycho.mode=maven|-Dmaven.javadoc.skip=true|-Dgwt.compiler.skip|-Dcobertura.skip=true|-Dfindbugs.skip=true||-DperformRelease=true|-Dgpg.skip=true|-DforkCount"

    local profile_settings=`[ -e ~/.m2/settings.xml ] && grep -e "<profile>" -A 1 ~/.m2/settings.xml | grep -e "<id>.*</id>" | sed 's/.*<id>//' | sed 's/<\/id>.*//g' | tr '\n' '|' `
    
    local profiles="${profile_settings}|"
    for item in ${POM_HIERARCHY[*]}
    do
        local profile_pom=`[ -e $item ] && grep -e "<profile>" -A 1 $item | grep -e "<id>.*</id>" | sed 's/.*<id>//' | sed 's/<\/id>.*//g' | tr '\n' '|' `
        local profiles="${profiles}|${profile_pom}"
    done

    # find goal options
    local goal_options=""
    for item in ${words[@]}
    do
        if [[ ${item} == *:* ]]; then
            local var_name="plugin_args_${item//[-:]/_}"
            goal_options="|${!var_name}"
        fi
    done

    local IFS=$'|\n'

    if [[ ${cur} == -D* ]] ; then
      COMPREPLY=( $(compgen -S ' ' -W "${options}${goal_options}" -- ${cur}) )

    elif [[ ${prev} == -P ]] ; then
      if [[ ${cur} == *,* ]] ; then
        COMPREPLY=( $(compgen -S ',' -W "${profiles}" -P "${cur%,*}," -- ${cur##*,}) )
      else
        COMPREPLY=( $(compgen -S ',' -W "${profiles}" -- ${cur}) )
      fi

    elif [[ ${cur} == --* ]] ; then
      COMPREPLY=( $(compgen -W "${long_opts}" -S ' ' -- ${cur}) )

    elif [[ ${cur} == -* ]] ; then
        COMPREPLY=( $(compgen -W "${opts}" -S ' ' -- ${cur}) )

    elif [[ ${prev} == -pl ]] ; then
        if [[ ${cur} == *,* ]] ; then
            COMPREPLY=( $(compgen -W "$(__find_mvn_projects)" -S ',' -P "${cur%,*}," -- ${cur##*,}) )
        else
            COMPREPLY=( $(compgen -W "$(__find_mvn_projects)" -S ',' -- ${cur}) )
        fi

    elif [[ ${prev} == -rf || ${prev} == --resume-from ]] ; then
        COMPREPLY=( $(compgen -d -S ' ' -- ${cur}) )

    elif [[ ${cur} == *:* ]] ; then
        local plugin
        for plugin in $common_plugins; do
          if [[ ${cur} == ${plugin}:* ]]; then
            ## note that here is an 'unreplace', see the comment at common_plugins
            var_name="plugin_goals_${plugin//-/_}"
            COMPREPLY=( $(compgen -W "${!var_name}" -S ' ' -- ${cur}) )
          fi
        done

    else
        if echo "${common_lifecycle_phases}" | tr '|' '\n' | grep -q -e "^${cur}" ; then
          COMPREPLY=( $(compgen -S ' ' -W "${common_lifecycle_phases}" -- ${cur}) )
        elif echo "${common_plugins}" | tr '|' '\n' | grep -q -e "^${cur}"; then
          COMPREPLY=( $(compgen -S ':' -W "${common_plugins}" -- ${cur}) )
        fi
    fi

    __ltrim_colon_completions "$cur"
}

complete -o default -F _mvn -o nospace mvn
complete -o default -F _mvn -o nospace mvnDebug
