#!/bin/bash

readonly ARCHIVE_DIR='/archives'

usage ()
{
    echo
    echo "Usage: $(basename ${0}) [-dra] [-h] USER [USER]..."
    echo "Disable user's accounts"
    echo '   -d   Deletes accounts instead of disabling them.'
    echo '   -r   Removes the home directory associated with the account(s)'
    echo '   -a   Creates an archive of the home directory associated with the accounts(s) 
      and stores the archive in the /archives directory.'
    echo '   -h   Display this message.'
}

print_result ()
{
    if [[ ${?} -eq 0 ]]
    then
        echo "  - ${1} '${2}' --> OK"
    else
        echo "  - ${1} '${2}' --> FAIL" >&2
    fi
}

# --
# Root only
if [[ ${UID} -ne 0 ]]
then
    echo "You need superuser privileges to perform this command" >&2
    exit 1
fi

# --
while getopts drah OPTION
do
    case ${OPTION} in
        d) DELETE='true'       ;;
        r) REMOVE_HOME='-r'    ;;
        a) ARCHIVE_HOME='true' ;;
        h)
            usage
            exit 0
        ;;
        ?)
            usage >&2
            exit 1
        ;;
    esac
done

# Get usernames and check if at least one has been given
shift "$(( ${OPTIND} - 1 ))"

if [[ ${#} -eq 0 ]]
then
    echo "You need to give at least one username" >&2
    usage >&2
    exit 1
fi

# --
for USER in ${@}
do

    # Check user
    USER_ID=$(id -u ${USER} 2> /dev/null)
    if [[ ${?} -ne 0 ]]
    then
        echo "The user '${USER}' doesn't exist." >&2

    elif [[ ${USER_ID} -lt 1000 ]]
    then
        echo "You can't modify the user '${USER}' (id < 1000)." >&2

    else
        # Archive --
        if [[ ${ARCHIVE_HOME} = 'true' ]]
        then
            [[ ! -d "${ARCHIVE_DIR}" ]] && mkdir -p "${ARCHIVE_DIR}"
            tar -czf "${ARCHIVE_DIR}/${USER}-$(date +%Y%m%d)".tar.gz /home/${USER} &> /dev/null
            print_result 'Archive' ${USER}
        fi

        # Disable --
        if [[ "${DELETE}" = 'false' ]]
        then
            chage -E 0 ${USER} &> /dev/null
            print_result 'Deactivate' ${USER}

        # Delete --
        else
            userdel ${REMOVE_HOME} ${USER} &> /dev/null
            print_result 'Delete' ${USER}
        fi
    fi
done

exit 0
