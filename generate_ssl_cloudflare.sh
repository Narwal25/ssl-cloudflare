#!/bin/bash
EMAIL="pardeepnarwal.ck789@webkul.in"

print_dns_token_message(){
    echo "DNS Token Not Found
    Create a file called dns_token_file.sh in the same directory.
    Inside that file, add the following line:
export <your_root_domain>=\"dns_cloudflare_api_token = <your_cloudflare_api_token>\""
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
        echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install"
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
        echo "Error: Certbot version is less than 2.3. Current version: $certbot_version"
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
    DOMAINS=$(whiptail --title "SSL Certificate Generator" --inputbox \
    "Enter the domains for which you want to generate an SSL certificate: (separate them with spaces)." 10 60 "" 3>&1 1>&2 2>&3)
    if [ -z "$DOMAINS" ]; then
        whiptail --title "Error" --msgbox "Domain name cannot be empty. Exiting." 8 45
        exit 1
    fi
    echo "$DOMAINS"
}

get_root_domain() {
    local full_domain=$1
    IFS='.' read -r -a domain_parts <<< "$full_domain"
    
if [ ${#domain_parts[@]} -lt 2 ]; then
        echo "Invalid domain: $full_domain"
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
        echo "Root domains are not all the same."
        exit 1
    fi

    ROOT_DOMAIN=${ROOT_DOMAIN//./_}
}

write_token() {
    if [ -z "${!ROOT_DOMAIN+x}" ]; then
        print_dns_token_message
    else
        if [ -f /etc/letsencrypt/cloudflare-narwal.ini ]; then
            mv /etc/letsencrypt/cloudflare-narwal.ini /etc/letsencrypt/cloudflare-narwal.ini.backup-ssl-script
        fi
        mkdir -p /etc/letsencrypt
        echo "${!ROOT_DOMAIN}" > /etc/letsencrypt/cloudflare-narwal.ini
    fi
}

generate_ssl_cloudflare() {
    token_file_path=/etc/letsencrypt/cloudflare-narwal.ini
    
    if [ ! -f "$token_file_path" ]; then
        echo "Cloudflare credentials file not found. Please create /etc/letsencrypt/cloudflare-narwal.ini with your API token."
        exit 1
    fi
    
    chmod 600 "$token_file_path"

    sudo certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials "$token_file_path" \
    --dns-cloudflare-propagation-seconds 60 \
    -d ${DOMAINS// / -d } --email "$EMAIL" --agree-tos --no-eff-email
    
    if [ $? -ne 0 ]; then
        echo "Error: SSL certificate generation failed. Exiting."
        exit 1
    fi
    echo "SSL certificate generation with Cloudflare API Token completed."
    
}


main() {
    packages_install
    check_certbot_compatiblity
    load_token
    DOMAINS=$(get_domains)
    process_domains "$DOMAINS"
    write_token "$ROOT_DOMAIN"
    generate_ssl_cloudflare
}

main
