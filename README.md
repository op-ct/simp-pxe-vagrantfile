

####
<!-- vim-markdown-toc GFM -->

* [Description](#description)
* [Setup](#setup)
  * [Requirements](#requirements)
* [Usage](#usage)
* [Reference](#reference)
* [Limitations](#limitations)
* [Development](#development)

<!-- vim-markdown-toc -->

## Description

Use [vagrant] to spin up a **network-isolated** SIMP puppetserver and PXE
kickstart EL6, EL7, EL8 clients.

Features:

* Uploads OS ISOs to `/var/simp/ISOs`
* Unpacks OS ISOs with `--unpack-yum --unpack-pxe -v <SPECIFIC_OS_VERSION>`
* Configures all VM consoles with VRDE, so you can see each client kickstart from its console.
* Data configured from `Vagrantfile.yaml`

## Setup

### Requirements

* [Vagrant]
* [Puppet Bolt] 2.30+
* [simp-packer]-generated Vagrant .json and .box file for a SIMP server
* [CentOS]/[RedHat] OS ISOs to use for yum/tftpboot (for PXE kickstarting)

If you are using RVM, make sure to `rvm use system` to disable it before running Bolt.

## Usage

1. Configure `Vagrantfile.yaml` with the correct paths to all files
2. Bring up the puppetserver:

   ```sh
   vagrant up puppetserver
   ```

3. Bring up the pxe clients to kickstart

   ```sh
   vagrant up pxe8
   vagrant up pxe7
   vagrant up pxe6
   vagrant up uefi8
   vagrant up uefi7
   vagrant up uefi6
   ```

## Reference

## Limitations

* Vagrant can't SSH into an EL6 puppetserver

## Development

[simp-packer]: https://github.com/simp/simp-packer
[vagrant]: https://vagrantup.com/
[puppet bolt]: https://puppet.com/docs/bolt/latest/bolt.html
[centos]: https://centos.org/centos-linux/
[redhat]: https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux
