#!/bin/bash

for folder in verify/superfils/*
do
	for file in $folder/*.superfils
	do
		echo $file
		node main.js $file
	done
done