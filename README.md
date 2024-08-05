# TSSH

> TSSH is currently under development and not usable. For further information,
> look in the dev branch.

The TSSH project is a collection of Bash scripts designed to simplify the
creation of a secure client-server ecosystem based on the current stable
release of Debian GNU/Linux. The server functions as a router, firewall, print
and file server with DHCP, DNS, TFTP, and SFTP capabilities. The client runs
a streamlined version of the GNOME desktop environment, featuring core stable
GTK4 applications and custom configuration defaults, to create an optimal Linux
environment for development, multimedia, and office work.

Data resilience and security are among the project's main goals. Both the
client and server support Btrfs RAID 1 configuration, ensuring that all user
data is securely synchronized over SFTP between clients and servers. This data
remains accessible even when clients are outside the server's network and persist
server OS reinstallations.

The primary objective of the project is to automate and test the entire
infrastructure, making it maintainable for an individual over the long term
while minimizing dependencies.

## Installation

TSSH always runs on the latest stable release of Debian. The main script,
tssh.sh, includes an install option that automatically copies all the required
files and installs the necessary packages. The uninstall option can be used to
remove all the installed files and packages.

```shell
sudo bash tssh.sh install
```

## Usage

TSSH has the folowing options:

### Install TSSH

Install TSSH and dependencies to the system.

```shell
sudo tssh install
```
### Remove TSSH

Remove TSSH from the system, but leave dependencies.

```shell
sudo tssh remove
```

### Setup Installmedia

Create a live installation medium for server and clients.

```shell
sudo tssh setup-install \
    -d <live medium e.g. /dev/sda or live.img> \
    -k <root password for live login>
```

### Setup Server

Install server role to the current machine.

- TSSH will always build a Btrfs raid 1 if multiple drives a specified.
- The second drive is always optional but recommended for data resilience.
- The root password will become your master key that is needed to set up clients.
- The -u and -p flags are only relevant when you use PPP as your wan connection
  for MS-CHAP authentication.

```shell
sudo tssh setup-server \
    -d <btrfs-pool-drive1 e.g. /dev/sda> [-d <btrfs-pool-drive2>] \
    -k <root-password (Masterkey)> \
    -w <network interface connect to the modem e.g. enp5s0> \
    -m <dhcp | ppp> \
    [-u <ppp username>] \
    [-p <ppp password>]
```

### Setup Client

Install client role on the current machine and pull user data and configuration
from the server.

- TSSH will always build a Btrfs raid 1 if multiple drives a specified.
- The second drive is always optional but recommended for data resilience.
- The username will be the first name in lowercase.
- The first and last name, as well as the hostname, can only contain characters
  A-Z and numbers 0-9, and must be a maximum of 30 characters long.
- The root password is the (Masterkey) and needed to get the client
  configuration form the server.

```shell
sudo tssh setup-client \
    -d <btrfs-pool-drivei1 e.g. /dev/sda> [-d <btrfs-pool-drive2>] \
    -h <Hostname>
    -f <Firstname (machine owner name) e.g. Nick> \
    -l <Lastname (machine owner name) e.g. Hildebrandt> \
    -k <root-password (Masterkey)>
```

### Deploy (Test Configuration)

The configuration can be tested with the Deploy option, which generates a live
image and installs a server and client KVM connected over an internal network
bridge.

```shell
sudo tssh deploy \
    -c (Force Generate live and server)
```

## Contributing

I am very grateful for all feedback. A good piece of software can only be
achieved when people test it and report errors and bugs. Feel free to create an
issue on GitHub when you encounter problems, bugs, or errors. For code
contributions, use the pull request feature on GitHub, and I will be thankful
to include your work.
