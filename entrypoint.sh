#!/bin/bash
set -e

source ${GITLAB_MIRROR_ASSETS}/functions

add_user
fix_home_permissions

case ${1} in
	mirrors|add|delete|ls|update|config|run)
		check_environment
		configure_gitlab_mirror

		case ${1} in
			mirrors)
				exec_as_user "${GITLAB_MIRROR_INSTALL_DIR}/git-mirrors.sh" ${@:2}
				;;
			add)
				exec_as_user "${GITLAB_MIRROR_INSTALL_DIR}/add_mirror.sh" ${@:2}
				;;
			delete)
				exec_as_user "${GITLAB_MIRROR_INSTALL_DIR}/delete_mirror.sh" ${@:2}
				;;
			ls)
				exec_as_user "${GITLAB_MIRROR_INSTALL_DIR}/ls-mirrors.sh" ${@:2}
				;;
			update)
				exec_as_user "${GITLAB_MIRROR_INSTALL_DIR}/update_mirror.sh" ${@:2}
				;;
			config)
				echo "Populated /config volume, please add ssh keys and configuration"
				;;
			run)
				exec "${@:2}"
				;;
		esac
		;;
	help)
		echo "Available options:"
		echo " git-mirrors"
		echo " add "
		echo " delete"
		echo " ls"
		echo " update"
		;;
	*)
		exec "$@"
		;;
esac

if [[ -z $1 ]]
then
	exec bash
fi
