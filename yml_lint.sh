exitCode=0

deployment_folder="./deploy"

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
    if [ -e $1/deploy.yml ]; then
        run yamllint -c test/circle/lintconf.yml $1/Chart.yaml
    else
        echo "Error $1/deploy.yml file is missing"
        exitCode=1
    fi
}

yamllinter ${deployment_folder}
