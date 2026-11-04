.PHONY: install serve build deploy

install:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt

serve:
	.venv/bin/mkdocs serve

build:
	.venv/bin/mkdocs build --strict

deploy:
	.venv/bin/mkdocs gh-deploy --force
