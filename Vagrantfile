# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

swift_url = "https://swift.org/builds/swift-3.0-release/ubuntu1404/swift-3.0-RELEASE/swift-3.0-RELEASE-ubuntu14.04.tar.gz"
kubectl_url = "https://storage.googleapis.com/kubernetes-release/release/v1.3.7/bin/linux/amd64/kubectl"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define 'swift' do |swift|
      swift.vm.box = "ubuntu/trusty64"
      swift.vm.network "private_network", ip: "192.168.9.2"
      swift.vm.synced_folder ".", "/vagrant", disabled: true
      swift.vm.synced_folder ".", "/home/vagrant/swift-tests"

      swift.vm.provision "file", source: "~/.vagrant.d/insecure_private_key", destination: "/home/vagrant/.vagrant.d/insecure_private_key"
      swift.vm.provision "shell", inline: "chmod 600 /home/vagrant/.vagrant.d/insecure_private_key"

      swift.vm.provision "shell", privileged: false, inline: <<-SWIFT
          sudo apt-get -qq update

          echo "Installing clang and git..."
          sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y install clang git libssl-dev > /dev/null

          echo "Installing kubectl..."
          sudo curl -sSLo /usr/local/bin/kubectl "#{kubectl_url}"
          sudo chmod +x /usr/local/bin/kubectl

          echo "Installing swift..."
          curl -sSLo swift.tar.gz "#{swift_url}"
          sudo tar -zxf swift.tar.gz -C / --strip 1
          rm -f swift.tar.gz
      SWIFT

      swift.vm.provider "virtualbox" do |virtualbox|
          virtualbox.name = "swift"
      end
    end
end
