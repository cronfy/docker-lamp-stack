export PATH=$HOME/bin:$HOME/.composer/vendor/bin:$PATH

SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    #ps ${SSH_AGENT_PID} doesn't work under cywgin
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi

alias S=/usr/bin/ssh-add

cd /app

if [ -e $HOME/.ssh/id_rsa ] && ! ssh-add -l > /dev/null 2>&1 ; then
        echo " -- В контейнере есть ключ ssh, но он не загружен."
        echo " -- Для загрузки запустите команду:"
        echo
        echo "S"
        echo
fi

