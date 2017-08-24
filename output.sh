#!/bin/bash

for folder in verify/alfy/*
do
	for file in $folder/*.alfy
	do
		echo $file
		node main.js $file
	done
done
