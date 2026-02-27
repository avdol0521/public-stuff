---
title: Fun Linux Commands
tags:
  - child
---
- tired of learning boring technical linux stuff? have some fun with these commands Vorpidi made a list of for a while :D
- make sure to do `sudo apt update` before installing any packages :)
# export `/usr/games` to your PATH env variable for most of these to work. just copy paste the command below if you don't know how :)
```sh
echo "export PATH=$PATH:/usr/games" >> ~/.zshrc
source ~/.zshrc
```
- you only need to do this once 
## cmatrix: welcome to the matrix :)
- installation:
```sh
sudo apt install cmatrix
```
- launch:
```sh
cmatrix
```
## hollywood: hack da wooorld 8)
- installation:
```sh
sudo apt install hollywood -y
```
- launch:
```sh
hollywood
```
## oneko: a cat that follows your mouse cursor around :3
- installation:
```sh
sudo apt install oneko
```
- launch:
```sh
oneko &
```
## xeyes: they're watching >:)
- installation:
```sh
sudo apt install x11-apps
```
- launch:
```sh
xeyes &
```
## pacman4console: exactly what it sounds like :)
- installation:
```sh
sudo apt install pacman4console
```
- launch:
```sh
pacman4console
```
## cowsay: the name is quite literal... 
- installation:
```sh
sudo apt install cowsay
```
- launch:
```sh
cowsay hello :)
```

```sh
cowthink thoughts....
```

- do `cowthink -h` to see all the different flags for the fun variations :)
## fortune: fortune cookies :P
- installation:
```sh
sudo apt install fortune -y
```
- launch:
```sh
fortune
```
- you can combine this with cowsay and put it in your `zshrc`/`bashrc` file to have a fortune every time you open a terminal :P
```sh
fortune | cowsay
```

```sh
fortune | cowthink
```
## rig: generate random fake identities like a real hackerman 8)
- installation: 
```sh
sudo apt install rig
```
- launch:
```sh
rig
```
## sl: ls typo punishment lol
- installation:
```sh
sudo apt install sl
```
- launch:
```sh
sl
```
## asciiquarium: ASCII Aquarium :)
- installation: (just copy paste this into the terminal as root)
```sh
sudo apt install libcurses-perl
cd /tmp
wget http://search.cpan.org/CPAN/authors/id/K/KB/KBAUCOM/Term-Animation-2.6.tar.gz
tar -zxvf Term-Animation-2.6.tar.gz
cd Term-Animation-2.6
perl Makefile.PL &&  make &&   make test
make install
cd /tmp
wget --no-check-certificate https://robobunny.com/projects/asciiquarium/asciiquarium.tar.gz
tar -zxvf asciiquarium.tar.gz
cd asciiquarium_1.1
sudo cp asciiquarium /usr/local/bin/
sudo chmod 0755 /usr/local/bin/asciiquarium
```
- launch:
```sh
asciiquarium
```
## pipes: pipes :v
- installation:
```sh
sudo apt install pipes-sh
```
- launch:
```sh
pipes
```

```sh
pipes -p 20 -r 0 -R
```
## nyancat: i have that melody burned into my head lol
- installation
```sh
sudo apt install nyancat
```
- launch:
```sh
nyancat
```
## espeak: talking terminal
- installation:
```sh
sudo apt install espeak -y
```
- launch:
```sh
espeak "hello im a talking terminal"
```
## fork bomb (trollface):
- launch:
```sh
:(){ :|: & };:
```
- just reboot your machine its fine xD
## parrot.live : parrot partyyyyyyyyyyyyyyyyyyyyyy
- launch:
```sh
curl parrot.live
```
## BB: BB :)
- installation:
```sh
sudo apt install bb -y
```
- launch:
```sh
bb
```
- do y and then 8 to start the thing :)
## aafire: AAAAAAAAAA FIREEEEEEEEEE
- installation:
```sh
sudo apt install libaa-bin
```
- launch:
```sh
aafire -extended
```
## run it and find out lol:
- launch:
```sh
curl -L http://bit.ly/10hA8iC | bash
```
## typewriting effect: replace the text with what you want :)
- launch:
```sh
echo "milk inside a bag of milk inside a bag of milk and milk outside a bag of milk outside a bag of milk" | pv -qL 50
```
## asciimap: exactly what it sounds like
- launch:
```sh
telnet mapscii.me
```
## infinite spam :)
- launch
```sh
yes "balls"
```

```sh
while (true) do echo -n "balls"; done
```
## cool-retro-term: retro terminal 
- installation:
```sh
sudo apt install cool-retro-term -y
```
- launch:
```sh
cool-retro-term
```
## figlet and toilet: lets make some cool hackerman banners >:D
- installation:
```sh
sudo apt install figlet toilet -y
```
- usage:
	- do `showfigfonts` to see what fonts are available. you can find hundreds of other fonts online. do your own digging if you're interested :)
```sh
toilet -cf standard hackerman 
```
## lolcat: for the RGB heads
- installation
```sh
apt install lolcat
```
- usage:
```sh
toilet -ctf standard hackerman | lolcat
```

```sh
toilet -ctf standard "wow RGB" | lolcat -a
```
## rev: reverses text 
- usage:
```sh
echo "hello world" > test.txt
rev test.txt
```

```sh
echo "hello world" | rev
```
## multiplication table:
```sh
for i in {1..10}; do for j in $(seq 1 $i); do echo -ne $i*$j=$((i*j))\\t;done; echo;done
```
## factor: outputs the factor of a given number
- usage example:
```sh
factor 12
```
## see this link to find some more fun stuff to mess around with that im too lazy to include here:
- https://github.com/jrcharney/hacktop/wiki/Linux-Toys