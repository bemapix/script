#!/bin/bash
curl -s https://ollama.com/library | grep -oE 'href="/library/[a-zA-Z0-9._-]+"' | cut -d'"' -f2 | cut -d'/' -f3 | sort -u
