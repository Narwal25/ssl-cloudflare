# SSL Certificate Generator Script using Cloudflare API Token

This Bash script automates the process of generating SSL certificates for domains using the [Certbot](https://certbot.eff.org/) tool with Cloudflare DNS validation.

The script does the following:
1. Installs required packages.
2. Verifies Certbot compatibility (version 2.3 or higher is required).
3. Loads the Cloudflare API token from a configuration file.
4. Collects domain names from the user.
5. Validates that the domains share the same root domain.
6. Writes the Cloudflare API token to a file for Certbot.
7. Uses the Cloudflare DNS API to generate SSL certificates via Certbot.

## Prerequisites

- **Certbot**: The script uses Certbot for SSL certificate generation.
- **Cloudflare API Token**: You need a Cloudflare API token to perform DNS validation for SSL certificate issuance.
  
Ensure you have a Cloudflare API token with the `Zone.DNS` permission. You can create a Cloudflare API token from [here](https://developers.cloudflare.com/fundamentals/api/keys/).

## Installation

### 1. Clone this repository (or download the script)

```bash
git clone https://github.com/Narwal25/ssl-cloudflare.git
cd ssl-cloudflare
```

### 2. Create a Cloudflare API Token File

You need to create a file `dns_token_file.sh` in the same directory as the script, containing your Cloudflare API token in the following format:

```bash
export <your_root_domain>="dns_cloudflare_api_token = <your_cloudflare_api_token>"
```

For example, if your root domain is `example.com` and your Cloudflare API token is `abcdef123456`, the file should look like:

```bash
export example_com="dns_cloudflare_api_token = abcdef123456"
```

## Usage

1. **Run the Script**: Once the setup is done, simply run the script to generate the SSL certificate:

   ```bash
   ./generate_ssl_cloudflare.sh
   ```

2. **Enter Domain Names**: The script will prompt you to enter the domains for which you want to generate an SSL certificate. Enter the domains separated by spaces.

   Example input:
   ```
   example.com www.example.com blog.example.com
   ```

3. **Verify and Process Domains**: The script will check that all domains share the same root domain. If the root domains are different, it will exit with an error.

4. **Generate SSL Certificate**: The script will use your Cloudflare API token to generate the SSL certificate via Certbot. This will involve DNS validation using Cloudflare's DNS API.

5. **Completion**: Once the SSL certificate generation is successful, the script will output a success message.

## Troubleshooting

- If the script reports that Certbot is incompatible with your version, you need to upgrade Certbot to at least version 2.3.
- If the Cloudflare API token is not found or the token file is missing, make sure you have correctly created `dns_token_file.sh` and followed the proper format.
  
## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---