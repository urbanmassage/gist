exitCode=0

deployment_folder="./deploy"
deployment_file="deploy.yml"
lint_file="lint_conf.yml"

run(){
    $@
    local ret=$?
    if [ $ret -ne 0 ]; then
        exitCode=1
    fi
}

yamllinter(){
    printf "\nLinting the deploy.yml at ${1}\n"
    
    echo "Downloading linter profile"
    wget -O $1/$lint_file https://raw.githubusercontent.com/urbanmassage/gist/master/$lint_file

    if [ -e $1/$deployment_file ]; then      
        run yamllint -c $1/$lint_file $1/$deployment_file
    else
        echo "Error $1/$deployment_file file is missing"
        exitCode=1
    fi
}

yamllinter ${deployment_folder}

exit $exitCode
