
Linux??
`docker run --pull always --rm -it -u $(id -u):$(id -g) -v "$PWD":"/$PWD" -w "/$PWD" demonnic/muddler "$@"`


for windows...

BUILD IT....
`docker run --pull always --rm -it -v "${PWD}:/workspace" -w /workspace demonnic/muddler`cd 