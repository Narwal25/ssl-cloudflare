#!/bin/bash

print_dns_token_message(){
    echo -e "\033[31m DNS Token Not Found: \033[0;33m
    Create a file called dns_token_file.sh in the same directory.
    Inside that file, add the following line: \033[0m"
    echo "export <your_root_domain>=\"dns_cloudflare_api_token = <your_cloudflare_api_token>\""
}

packages_install() {
    if [ -x "$(command -v pacman)" ]; then
        sudo pacman -S certbot python-pip sed gawk newt python-certbot-dns-cloudflare --no-confirm
    elif [ -x "$(command -v apt)" ]; then
        sudo apt update
        sudo apt install certbot python3-pip sed gawk whiptail python3-certbot-dns-cloudflare -y
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf install certbot python3-pip sed gawk whiptail python3-certbot-dns-cloudflare -y
    else
        echo -e "\033[31m FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install \033[0m"
        exit 1
    fi
}

check_certbot_compatiblity(){
    certbot_version=$(certbot --version | awk '{print $2}')
    major_version=$(echo "$certbot_version" | cut -d'.' -f1)
    minor_version=$(echo "$certbot_version" | cut -d'.' -f2)
    
    required_major=2
    required_minor=3
    
    if [ "$major_version" -lt "$required_major" ] || { [ "$major_version" -eq "$required_major" ] && [ "$minor_version" -lt "$required_minor" ]; }; then
        echo -e "\033[31m Error: Certbot version is less than 2.3. \033[0m Current version: $certbot_version"
        echo "This version is not compatible with the Cloudflare DNS token."
    fi

    if [ -x "$(command -v apt)" ]; then
        sudo apt purge certbot python3-certbot-dns-cloudflare
        sudo apt install python3 python3-venv libaugeas0
        sudo python3 -m venv /opt/certbot/
        sudo /opt/certbot/bin/pip install --upgrade pip
        sudo /opt/certbot/bin/pip install certbot certbot-dns-cloudflare
        sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
    fi
    certbot_version=$(certbot --version | awk '{print $2}')
    major_version=$(echo "$certbot_version" | cut -d'.' -f1)
    minor_version=$(echo "$certbot_version" | cut -d'.' -f2)
    
    required_major=2
    required_minor=3
    
    if [ "$major_version" -lt "$required_major" ] || { [ "$major_version" -eq "$required_major" ] && [ "$minor_version" -lt "$required_minor" ]; }; then
        echo -e "\033[31m Error: Certbot version is less than 2.3. \033[0m Current version: $certbot_version"
        echo "This version is not compatible with the Cloudflare DNS token."
        exit 1
    fi
}

load_token(){
    if [ -f "dns_token_file.sh" ]; then
        source dns_token_file.sh
    else
        print_dns_token_message
        exit 1
    fi
}

get_domains(){
    local inputmessage="Enter the domains for which you want to generate an SSL certificate: (separate them with spaces)."
    if [ $# -eq 0 ]; then
        DOMAINS=$(whiptail --title "SSL Certificate Generator" --inputbox "$inputmessage" 10 60 "" 3>&1 1>&2 2>&3)
        if [ -z "$DOMAINS" ]; then
            whiptail --title "Error" --msgbox "Domain name cannot be empty. Exiting." 8 45
            exit 1
        fi
    else
        DOMAINS=$*
    fi
    echo "$DOMAINS"
}

get_root_domain() {
    local full_domain=$1
    IFS='.' read -r -a domain_parts <<< "$full_domain"

    if [ ${#domain_parts[@]} -lt 2 ]; then
        echo -e "\033[31m Invalid domain: \033[0m $full_domain"
        exit 1
    fi

    echo "${domain_parts[-2]}.${domain_parts[-1]}"
}


process_domains() {
    local domains=$1
    local first_root_domain=""
    local all_same=true
    
    for DOMAIN in $domains; do
        ROOT_DOMAIN=$(get_root_domain "$DOMAIN")
        
        if [ $? -ne 0 ]; then
            echo "Error: $ROOT_DOMAIN Exiting."
            exit 1
        fi
        if [ -z "$first_root_domain" ]; then
            first_root_domain=$ROOT_DOMAIN
            elif [ "$ROOT_DOMAIN" != "$first_root_domain" ]; then
            all_same=false
        fi
    done
    
    if $all_same; then
        echo "$first_root_domain"
    else
        echo -e "\033[31m Root domains are not all the same. \033[0m"
        exit 1
    fi
    
    ROOT_DOMAIN=${ROOT_DOMAIN//./_}
}

write_token() {
    if [ -z "${!ROOT_DOMAIN+x}" ]; then
        print_dns_token_message
    else
        if [ -f /etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini ]; then
            mv /etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini /etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini.backup-ssl-script
        fi
        mkdir -p /etc/letsencrypt
        echo "${!ROOT_DOMAIN}" > /etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini
    fi
}

generate_ssl_cloudflare() {
    EMAIL="pardeepnarwal.ck789@webkul.in"
    token_file_path=/etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini
    
    if [ ! -f "$token_file_path" ]; then
        echo -e "\033[31m Cloudflare credentials file not found. Please create /etc/letsencrypt/cloudflare-narwal-$ROOT_DOMAIN.ini with your API token. \033[0m"
        exit 1
    fi
    
    chmod 600 "$token_file_path"
    
    sudo certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials "$token_file_path" \
    --dns-cloudflare-propagation-seconds 60 \
    -d ${DOMAINS// / -d } --email "$EMAIL" --agree-tos --no-eff-email
    
    if [ $? -ne 0 ]; then
        echo -e "\033[31m Error: SSL certificate generation failed. Exiting. \033[0m"
        exit 1
    fi
    echo -e "\033[0;32m SSL certificate generation with Cloudflare API Token completed. \033[0m"
    
}


main() {
    packages_install
    check_certbot_compatiblity
    load_token
    DOMAINS=$(get_domains "$@")
    process_domains "$DOMAINS"
    write_token "$ROOT_DOMAIN"
    generate_ssl_cloudflare
}

main "$@"