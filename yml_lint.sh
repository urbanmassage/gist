pip install yamllint==1.8.1

exitCode=0

deployment_folder="./deploy"
deployment_file="deploy.yml"

run(){
    $@
    local ret=$?
    if [ $ret -ne 0 ]; then
        exitCode=1
    fi
}

yamllinter(){
    printf "\nLinting the deploy.yml at ${1}\n"

    #If the deploy.yml file is present then lint it. Otherwise report an error as one must exist
    if [ -e $1/${deployment_file} ]; then   
        run yamllint -c https://raw.githubusercontent.com/urbanmassage/gist/master/lint_conf.yml $1/${deployment_file}
    else
        echo "Error $1/${deployment_file} file is missing"
        exitCode=1
    fi
}

yamllinter ${deployment_folder}

exit $exitCode
