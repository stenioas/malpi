<h1 align="center">
  malpi
</h1>
<p align="center"><strong>Meu Instalador Pessoal do <a href=https://www.archlinux.org/>Arch Linux</a></strong>, um script em shell simples e amador para instalar o Arch Linux nos meus computadores pessoais.</p><p align="center">Você pode usá-lo e modificá-lo como quiser.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
  <img src="https://img.shields.io/github/license/stenioas/malpi?style=for-the-badge">
  <img src="https://img.shields.io/github/issues/stenioas/malpi?color=violet&style=for-the-badge">
  <img src="https://img.shields.io/github/stars/stenioas/malpi?style=for-the-badge">
</p>

## Notas
* Se preferir você pode particionar seu disco antes de executar este script.
* Você pode testar em uma **Máquina Virtual** primeiro se preferir.
* O script, temporariamente, altera a fonte do console.
* Tenho intensões de migrar o script para a ferramenta [**whiptail**](https://linux.die.net/man/1/whiptail).

## Pré-requisitos

- Uma conexão de internet funcionando.
- Estar logado como usuário 'root'.

## Obtendo o script

### curl
	curl -L stenioas.github.io/malpi/malpi > malpi

### wget
	wget stenioas.github.io/malpi/malpi

### git
	git clone git://github.com/stenioas/malpi

## Como usar

### Informações importantes:

1. Somente o modo [**UEFI**](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface) é suportado.
2. Este script utiliza apenas duas partições, [**ESP**](https://wiki.archlinux.org/index.php/EFI_system_partition_(Português)) e **ROOT**.
3. A partição raiz será formatada com o sistema de arquivos [**BTRFS**](https://wiki.archlinux.org/index.php/Btrfs_(Português)).
4. A partição EFI pode ser formatada em FAT32 se o usuário quiser.
5. [**SWAP**](https://wiki.archlinux.org/index.php/Swap_(Português)) não é suportada.
6. Este script irá criar três [**subvolumes**](https://wiki.archlinux.org/index.php/Btrfs_(Português)#Subvolumes):
	- **@** for /
	- **@home** for /home
	- **@.snapshots** for /.snapshots
7. Somente o [**XORG**](https://wiki.archlinux.org/index.php/Xorg_(Português)) é suportado(*[**Wayland**](https://wiki.archlinux.org/index.php/Wayland_(Português)) estará disponível em breve*).
8. O carregador de inicialização [**GRUB**](https://wiki.archlinux.org/index.php/GRUB_(Português)) é instalado por padrão(*[**Systemd-boot**](https://wiki.archlinux.org/index.php/Systemd-boot) estará disponível em breve*).
9. O script pode ser cancelado a qualquer momento com **CTRL+C**.
10. **ESTE SCRIPT AINDA NÃO ESTÁ COMPLETO!**

### Primeira etapa (*Instalação da base*)

> A primeira etapa oferece a instalação do sistema básico.

Inicialize a última [imagem do Arch Linux](https://www.archlinux.org/download/) com um [dispositivo bootável](https://wiki.archlinux.org/index.php/USB_flash_installation_media_(Português)).

Em seguida, certifique-se de ter uma conexão com a Internet na iso live do Arch. Se você tiver uma conexão sem fio, o comando [`iwctl`](https://wiki.archlinux.org/index.php/Iwd_(Português)#iwctl) pode ser útil para você. Você também pode ler a  [Configuração de rede](https://wiki.archlinux.org/index.php/USB_flash_installation_medium_(Português))) do guia do Arch Linux para obter instruções mais detalhadas.

Finalmente, inicie a primeira etapa do script com o comando abaixo:

    sh malpi -i

Em seguida, siga as instruções na tela para concluir.

##### Funcionalidades
- Configura a fonte do console
- Configura o ntp como true `timedatectl set-ntp true`
- Atualiza o archlinux-keyring
- Classifica os espelhos por país
- Seleciona e particiona o disco
- Formata e monta as partições **EFI** e **ROOT**
- Seleciona a versão do kernel (*Você pode inserir a versão do kernel que você quer instalar*)
- Seleciona a versão do microcode
- Instala a base
- Configura o fstab
- Configura o fuso horário
- Configura o relógio de hardware
- Configura a localidade
- Configura a rede(arquivos ***hostname** e **hosts***)
- Configura o mkinitcpio
- Configura a senha de root
- Instala o bootloader

### Segunda etapa (*Pós-Instalação*) ###

> A segunda etapa oferece a pós-instalação.

Inicie a segunda etapa do script, após obter sucesso na primeira etapa, com o comando abaixo:

	sh malpi -p

##### Funcionalidades
- Cria e configura um novo usuário
- Habilita o repositório Multilib
- Instala pacotes essenciais
	- dosfstools
	- mtools
	- udisks2
	- dialog
	- wget
	- git
	- nano
	- reflector
	- bash-completion
	- xdg-utils
	- xdg-user-dirs
- Instala o Xorg
	- xorg
	- xorg-apps
	- xorg-xinit
	- xterm
- Instala um drive de vídeo (*Atualmente apenas intel e virtualbox disponíveis*)
- Instala um Desktop Environment ou Window Manager ***(Opcional)***
- Instala um Display Manager ou Xinit(*Incompleto!*) ***(Opcional)***
- Instala pacotes extras ***(Opcional)***
	- Utilitários: `usbutils lsof dmidecode neofetch bashtop htop avahi nss-mdns logrotate sysfsutils mlocate`
	- Ferramentas de compressão: `zip unzip unrar p7zip lzop`
	- Ferramentas de sistema de arquivos: `ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs`
	- Ferramentas de som: `alsa-utils pulseaudio`
- Instala pacotes para laptops ***(Opcional)***
	- `wpa_supplicant wireless_tools bluez bluez-utils pulseaudio-bluetooth xf86-input-synaptics`
- Instala o YAY ***(Opcional)***

---

## Referências

- [**Archwiki**](https://wiki.archlinux.org/index.php/Main_page_(Português))
- [**archfi**](https://github.com/MatMoul/archfi) script by [***MatMoul***](https://github.com/MatMoul)
- [**aui**](https://github.com/helmuthdu/aui) script by [***Helmuthdu***](https://github.com/helmuthdu)
- [**pos-alpine**](https://terminalroot.com.br/2019/12/alpine-linux-com-awesomewm-nao-recomendado-para-usuarios-nutella.html) script by [***Terminal Root***](https://terminalroot.com.br/)

---
<h1 align="center">Btw, obrigado pelo seu tempo!</h1>