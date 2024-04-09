install:
	pip install --upgrade pip &&\
		pip install -r requirements.txt

test:
	python -m pytest -vv test_*.py

format:	
	terraform fmt

lint:
	pylint --disable=R,C --ignore-patterns=test_.*?py *.py 

refactor: format lint

all: install refactor test