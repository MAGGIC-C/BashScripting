#!/bin/bash

pag="$1"
curl -s "$pag" | grep -Eo '<!--.*' >> comments.txt
curl -s "$pag" | grep -Eo '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' >> emails.txt
