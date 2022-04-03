#!/usr/bin/env bash

BASE_PATH="#PUT_YOUR_BASE_PATH_HERE" #etc: https://gitlab.ecmacompany.com
#how to get private access token: https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token
GITLAB_PRIVATE_TOKEN=#PUT_YOUR_GITLAB_PRIVATE_TOKEN_HERE 
GROUP_ID="#PUT_YOUR_GROUP_ID_HERE"

SUB_GROUPS_IDS=`curl -s $BASE_PATH/api/v4/groups/$GROUP_ID/subgroups \ | grep -o "\"id\":[^ ,]\+" | awk -F':' '{print $2}'`
SUB_GROUPS_IDS+=" $GROUP_ID"
SCRIPT_PATH=$(pwd)

for SUB_GROUP_ID in $SUB_GROUPS_IDS; do
    cd $SCRIPT_PATH

    GROUP_SSH_URLS=`curl -s $BASE_PATH/api/v4/groups/$SUB_GROUP_ID/projects?private_token=$GITLAB_PRIVATE_TOKEN\&per_page=999 \ | grep -o "\"ssh_url_to_repo\":[^ ,]\+" | awk -F'"' '{print $4}'`
    GROUP_FULL_PATHS=`curl -s $BASE_PATH/api/v4/groups/$SUB_GROUP_ID?private_token=$GITLAB_PRIVATE_TOKEN\&per_page=999 \ | grep -o "\"full_path\":[^ ,]\+" | awk -F'"' '{print $4}'`
    GROUP_FULL_PATH=$(echo $GROUP_FULL_PATHS | awk -F" " '{print $1}')
    
    mkdir -p $GROUP_FULL_PATH
    cd $GROUP_FULL_PATH

    for REPO_SSH_URL in $(echo $GROUP_SSH_URLS ); do
        REPO_PATH=$(echo "$REPO_SSH_URL" | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')

        if [ ! -d "$REPO_PATH" ]; then
            echo "Cloning $REPO_PATH ( $REPO_SSH_URL )"
            git clone "$REPO_SSH_URL"
        else
            echo "Pulling $REPO_PATH"
            (cd "$REPO_PATH" && git pull)
        fi
    done
done
