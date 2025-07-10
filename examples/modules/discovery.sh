while true; do
    result=$(curl -fsSL 169.254.169.254/openstack/2020-10-14/user_data)
    echo $result >&2

    url=$(echo "$result" | jq -r .dispenser)

    if [[ -n "$url" ]]; then
        echo "Dispenser retrieved!" >&2
        echo $url

        importctl --verify=no --class=sysext pull-raw $url hello.sysext.raw
        systemd-sysext merge
        exit 0
    fi
    sleep 2
done
