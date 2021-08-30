PACKAGE_NAME := $(shell basename `pwd`)

.PHONY: clean clean-test clean-pyc clean-build docs help test
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -rf {} +
	find . -name '*.egg' -exec rm -rf {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache
	rm -fr allure_report

lint: ## check style with flake8
	flake8 my_project_template tests

behave: clean-test ## run the behave tests, generate and serve report
	- behave -f allure_behave.formatter:AllureFormatter -o allure_report
	allure serve allure_report

pytest: clean-test ## run tests quickly with the default Python
	PYTHONPATH=. pytest

test: clean-test ## run tests on every Python version with tox
	PYTHONPATH=. pytest
	behave

coverage: ## check code coverage quickly with the default Python
	coverage run --source my_project_template -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/my_project_template.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ my_project_template
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	pip install --upgrade pip
	python setup.py install
	pip install -r requirements.txt
	pip install -r requirements-tests.txt
	pip install -r requirements-dev.txt

venv: ## creates a Python3 virtualenv environment in venv
	python3 -m venv venv --prompt $(PACKAGE_NAME)-venv
	@echo "====================================================================="
	@echo "To activate the new virtual environment, execute the following from your shell"
	@echo "source venv/bin/activate"

activate: ## activate a virtual environment. Run `make venv` before activating.
	@echo "====================================================================="
	@echo "To activate the new virtual environment, execute the following from your shell"
	@echo "source venv/bin/activate"

