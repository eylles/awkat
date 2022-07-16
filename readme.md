# AWKat

somewhat of a bat in awk


<p align="center">
<a href="https://github.com/eylles/awkat" alt="GitHub"><img src="https://img.shields.io/badge/Github-2B3137?style=for-the-badge&logo=Github&logoColor=FFFFFF"></a>
<a href="https://gitlab.com/eylles/awkat" alt="GitLab"><img src="https://img.shields.io/badge/Gitlab-380D75?style=for-the-badge&logo=Gitlab"></a>
<a href="https://codeberg.org/eylles/awkat" alt="CodeBerg"><img src="https://img.shields.io/badge/Codeberg-2185D0?style=for-the-badge&logo=codeberg&logoColor=F2F8FC"></a>
</p>

## why ?

i'm not installing all the rust deps when i can just wrap some stuff i got installed already in a script /s


## usage

just run make to install or uninstall, all this depends on is awk ( bsd awk should work ), a shell interpreter and a highlighter program like [highlight](http://www.andre-simon.de/doku/highlight/highlight.php) or [source-highlight](https://www.gnu.org/software/src-highlite/), alternatively you can provide your own highlighter command with the `HIGHLIGHTER` env var

in debian and derivates just run:
```sh 
sudo apt install highlight
```
or
```sh 
sudo apt install source-highlight
```

in arch and derivates:
```sh
sudo pacman -S highlight
```
or 
```sh
sudo pacman -S source-highlight
```


## TODO

- [ ] add screenshots
- [x] try to have just one awk command
- [ ] env vars to config file name color (doing some tests it seems this one aint doable)
- [x] try to have dynamic box draw char lenght or use env var for lenght (AWKAT_COLS)

